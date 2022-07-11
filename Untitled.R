# Metabolomics postgres upload UI

ui <- fluidPage(theme = shinytheme("journal"), useShinyjs(),
                
                titlePanel(h2("Upload metabolomics data to Postgres", align = "center")),
                
                tabsetPanel(tabPanel("Clinical quant", fluid=TRUE,
                                     
                                     # 1. Upload file ------------------------------------------------------------------
                                     
                                     fluidRow(
                                       h3("1. READ DATA"),
                                       h5("Example: removed_qcs_quant_results_20201214_PFBBr_CLIN012_20211206"),
                                       fileInput("Filein_data", "Choose CSV File", multiple = F, accept = ".csv", placeholder = "No file selected"),
                                       tags$style(".progress-bar {background-color:green}"),
                                       textOutput("Textout_panel"),
                                       actionButton("Button_new_file", "Upload New File", icon("upload"), width="150px",
                                                    style="color: #fff; background-color: #2346b0; border-color: #2e6da4")
                                       ),
                                     
                                     hr(style = "border-top: 1px solid #000000;"),
                                     
                                     # 2. Uploaded data ----------------------------------------------------------------
                                     
                                     fluidRow(h3("2. DATA"),
                                              h5("Please check if the data looks correct")
                                              ),
                            
                                     fluidRow(column(4, DT::dataTableOutput("Table_quant"))
                                              ),
                                     
                                     hr(style = "border-top: 1px solid #000000;"),
                                     
                                     ### 1.2.3 Row 3/3 Buttons ---------------------------------------------------------------------------------
                                     
                                     fluidRow(h3("3. UPLOAD TO POSTGRES")
                                              ),
                                     
                                     fluidRow(
                                       column(4,
                                              actionButton("Button_check_columns_quant", "Check", width='200px'), 
                                              textOutput("Textout_check_columns")),
                                       column(4, 
                                              actionButton("Button_upload_quant", "Upload to Postgres", width='200px'),  
                                              textOutput("Textout_upload_quant"))
                                     )
                                     )
                )
)