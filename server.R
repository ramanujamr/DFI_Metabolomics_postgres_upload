# Metabolomics postgres upload - server

# check compound names conversion in dataframe
# check compound names compatibility in qc shiny
# convert compound names to standard


server <- function(input, output, session)
{
  
  rvalues <- reactiveValues()
  shinyjs::hide("Button_new_file")
  shinyjs::hide("Button_check_columns")
  shinyjs::hide("Button_upload")
  shinyjs::hide("Button_permitted_compounds")
  
  ## 0.1 Upload new file ===============================================================================================
  observeEvent(input$Button_new_file, ignoreInit = T, ignoreNULL = T, {
    session$reload()
  })
  
  ## 0.2 Refresh CSV list when hit button ==============================================================================
  observeEvent(input$Button_refresh_csv, ignoreInit = T, ignoreNULL = T, {
    updateSelectInput(session, 'Input_filename', choices = rev(list.files(wddir, 
                                                                    pattern = ".*bile.*csv|.*PFBBr.*csv|.*Indole.*csv|.*Tryptophan.*csv", 
                                                                    ignore.case = T)))
  })
  


  
  # 1. Check file name =================================================================================================
  
  observeEvent(input$Button_upload_csv, {

    shinyjs::hide("Input_filename")
    shinyjs::hide("Button_refresh_csv")
    shinyjs::hide("Button_upload_csv")
    shinyjs::show("Button_new_file")

    showModal(modalDialog("Fetching database info. Please wait...", footer=NULL))
    # Get data from postgres table 
    con <- dbConnect(dbDriver("PostgreSQL"),
                     host="128.135.41.32",
                     dbname="dfi_commensal_library",
                     user="dfi_admin",password="dfiadmin2022")
    
    rvalues$evnin_metabolomics <- tbl(con, "evnin_metabolomics") %>% collect()
    
    rvalues$uploaded_files <- rvalues$evnin_metabolomics %>% 
      distinct(filename)  %>% 
      pull(filename) 
    
    rvalues$uploaded_batches <- rvalues$evnin_metabolomics %>% 
      mutate(batch=paste0(trial, "_", metab_well)) %>% 
      pull(batch)
    
    dbDisconnect(con)
    removeModal()
    

    flag = T
    file <- input$Input_filename

    rvalues$df_data = read.csv(file.path(wddir,file), check.names = F) %>%
      mutate(trial = sub("_[^_]+$", "", sampleid), .after=sampleid) %>%
      mutate(metab_well = gsub("^.*\\_", "", sampleid), .after=trial)

    match = grepl(x = file, pattern = "removed_qcs_[A-Za-z]+_results_[0-9]{8}_[A-Za-z]+_[Ee][Vv][Ii][Tt][0-9]+_[0-9]+_[0-9]{8}", ignore.case = TRUE)

    if (match==F)
      {
      shinyalert(title = "Invalid file name", type = "error")
      flag = F
      }

    if(any(rvalues$uploaded_files==file))
      {
      shinyalert(title = "File already exists", type = "error")
      flag = F
      }

    # Check for existing trial and metab_well combination
    duplicates <- paste0(rvalues$df_data$trial, "_", rvalues$df_data$metab_well) %in% rvalues$uploaded_batches

    if(any(duplicates))
      {
      temp <- paste0(rvalues$df_data$trial, "_", rvalues$df_data$metab_well)[duplicates]
      temp <- paste(temp, collapse=", ")
      shinyalert(title = paste0("Data associated with this trial and well already exists: ", temp), type = "error", size = "l")
      flag = F
      }

    if (flag==T)
      {
      shinyalert(title = "Filename looks good!", type = "success")
      shinyjs::show("Button_check_columns")
      shinyjs::show("Button_permitted_compounds")

      rvalues$panel <- case_when(
        grepl("Bile", file, ignore.case = T) ~ "Bile acids",
        grepl("PFBBr|SCFA", file, ignore.case = T) ~ "SCFA",
        grepl("Tryptophan|Indole", file, ignore.case = T) ~ "Tryptophan",
        grepl("TMS", file, ignore.case = T) ~ "TMS-MOX",
        TRUE ~ "NOT IDENTIFIED... CHECK FILENAME")

      rvalues$type <- gsub(".*removed_qcs_(.+)_results_.*", "\\1", file)
      rvalues$type <- ifelse(rvalues$type=="quant", "quant", "normalized")


      # Get long form df
      rvalues$df_data_long <- rvalues$df_data %>%
        mutate(filename = file) %>%
        mutate(panel = rvalues$panel) %>%
        mutate(type = rvalues$type) %>%
        pivot_longer(cols=c(-sampleid, -filename, -trial, -metab_well, -panel, -type), names_to = "compound", values_to = "value") %>%
        dplyr::select(-sampleid) %>%
        mutate(compound = tolower(compound),
               compound = gsub(" |\\.", "-", compound),
               compound = gsub("-acid", " acid", compound))



      # Display data table
      output$Table_data <- DT::renderDataTable(rvalues$df_data_long, options = list(pageLength = 10))

      # Display allowed compound names(bsModal)
      output$Table_permitted_compounds <- DT::renderDataTable({
        df_compounds %>%
          filter(panel == rvalues$panel,
                 type == rvalues$type) %>%
          dplyr::select(compound, panel, type) %>%
          datatable(options = list(columnDefs = list(list(className='dt-center', targets="_all"))))
      })

      }

    output$Textout_panel <- renderText({paste("Panel: ", rvalues$panel)})
    output$Textout_type <- renderText({paste("Type: ", rvalues$type)})
    
  })
  


  
  
  # 1. Check column names ==============================================================================================
  
  observeEvent(input$Button_check_columns, {
    
    input_compound_names <- unique(rvalues$df_data_long$compound)
    
    std_compound_names <- df_compounds %>% 
      filter(panel == rvalues$panel,
             type == rvalues$type) %>% 
      pull(compound)
    
    
    std_compound_names <- c("sampleid", std_compound_names)
    
    if (all(input_compound_names %in% std_compound_names) == F) 
    {
      '%ni%' = Negate('%in%')
      unknown_compounds = unique(input_compound_names[input_compound_names %ni% std_compound_names])
      shinyalert("Following metabolite names were not recognized: ",unknown_compounds)
      output$Textout_check_columns <- renderText("Invalid metabolite names")
    } else {
      
      shinyalert(title = "Column names look good!", type = "success")
      shinyjs::show("Button_upload") 
      output$Textout_check_columns <- renderText("Columns OK") 
      
    }
    
  })
  
  
  
  
  ## 3. Upload to postgres =============================================================================================
  
  observeEvent(input$Button_upload, { 
    
    file <- input$Input_filename
    #date_sample_processed = as.numeric(gsub(".*results_(.+)_[A-Za-z]+_.*", "\\1", file))
    #date_data_processed = as.numeric(str_extract(string = file, pattern = "([0-9]{8})(?=\\.csv)"))

    con <- dbConnect(dbDriver("PostgreSQL"),
                     host="128.135.41.32",
                     dbname="dfi_commensal_library",
                     user="dfi_admin",password="dfiadmin2022")
    
    dbWriteTable(con, "evnin_metabolomics", rvalues$df_data_long, row.names=F, append=T, overwrite=F)
    dbSendStatement(con, "GRANT SELECT ON scfa_v3 TO dfi_lab")
    dbSendStatement(con, "GRANT SELECT ON scfa_v3 TO dfi_user")
    
    shinyalert(title = "Upload successful", type = "success")
    output$upload_status <- renderText("Upload successful")
    
    dbDisconnect(con)
    
  })

  
  
}
      