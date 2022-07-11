# Metabolomics postgres upload UI

ui <- fluidPage(theme = shinytheme("journal"), useShinyjs(),
                
                titlePanel(h2("Upload metabolomics data to Postgres", align = "center")),
                
                tabsetPanel(tabPanel("Biobank", fluid=TRUE,
                                     
                                     # 1. Upload file ------------------------------------------------------------------
                                     
                                     fluidRow(
                                       h3("1. INPUT DATA"),
                                       column(6,
                                              selectInput("Input_filename", label="Select csv file to upload", width="650px",
                                                          rev(list.files(wddir, 
                                                                         pattern = ".*bile.*csv|.*PFBBr.*csv|.*Indole.*csv|.*Tryptophan.*csv|.*TMS*csv",
                                                                         ignore.case = T))),
                                              actionButton("Button_refresh_csv", "Refresh", icon("sync"), width="100px"),
                                              actionButton("Button_upload_csv", "Upload", icon("upload"), width="100px"),
                                              textOutput("Textout_panel"),
                                              textOutput("Textout_type"),
                                              actionButton("Button_new_file", "Upload New File", icon("upload"), width="150px")),
                                       
                                       column(3, offset=1,
                                              actionButton("Button_permitted_compounds", "Permitted Compound-names", icon("tv"), width="300px"),
                                              bsModal("Modal_permitted_compounds", "Permitted Compound-names", "Button_permitted_compounds", 
                                                      size = "large", DT::dataTableOutput("Table_permitted_compounds"))
                                              )
                                       ),
                                     
                                     hr(style = "border-top: 1px solid #000000;"),
                                     
                                     # 2. Uploaded data ----------------------------------------------------------------
                                     
                                     fluidRow(h3("2. CHECK DATA"),
                                              ),
                            
                                     fluidRow(column(12,
                                                     h5("Please check if the data looks correct"),
                                                     DT::dataTableOutput("Table_data"))
                                              ),
                                     
                                     
                                     hr(style = "border-top: 1px solid #000000;"),
                                     
                                     ### 1.2.3 Row 3/3 Buttons ---------------------------------------------------------------------------------
                                     
                                     fluidRow(
                                       column(5, offset=1,
                                              h3("3. CHECK IF COMPOUND NAMES ARE CORRECT"),
                                              actionButton("Button_check_columns", "Check Names", width='200px'), 
                                              textOutput("Textout_check_columns")),
                                     column(5,
                                            h3("4. FINALLY, UPLOAD TO POSTGRES!"),
                                            actionButton("Button_upload", "Upload", width='200px'),  
                                            textOutput("Textout_upload"))

                                     )
                                     )
                )
)