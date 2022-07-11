# Metabolomics postgres upload

library(RPostgreSQL)
library(tidyverse)
library(shiny)
library(shinyalert)
library(shinyjs)
library(shinyBS)
library(shinythemes)
library(tidyr)
library(stringr)
library(dplyr)
library(DT)
library(stringr)
library(ggplot2)



#wddir <- "/Users/ramanujam/GitHub/DFI_Metabolomics_postgres_upload/test_files"
wddir <- "~/GitHub/DFI_Metabolomics_postgres_upload/Biobank_EVNIN/02_output_from_qc_shiny"
df_compounds <- read.csv("metabolites.csv")


# 1. Execution #########################################################################################################

source('ui.R', local=TRUE)
source('server.R', local=TRUE)
#shinyApp(ui=ui, server=server)
runApp(list(ui=ui, server=server), host="0.0.0.0",port=2500)
