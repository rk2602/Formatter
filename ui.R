#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Contact Nicholas Parham at nick-99@att.net for comments or corrections.

library(shiny)
library(DT)
library(dplyr)
library(PeriodicTable)
library(shinycssloaders)
library(shinythemes)
library(sjmisc)

options(shiny.maxRequestSize = 30*1024^2) # max file size set at 30 MB

# Define UI for application that draws a histogram
navbarPage(title = tags$div(img(src='llnl-logo.png', height = 25, width = 150), 'SCDC'), theme = shinytheme('readable'),

  tabPanel(title = 'Home',
           
    # Page title
    titlePanel('LLNL Surface Complexation Database Formatter'),
    br(),
    h4('Welcome'),
    br(),
    h4('User Guide'),
    br(),
    em('The Formatter'),
    p('This tab serves to subset and format the output from the Unifier so that it is ready-to-use in PHREEQC 
      or PEST.  It requires four user inputs:'),
    tags$ol(tags$li(strong('sc.subset.csv'), '- output from', em('the Filterer')),
            tags$li(strong('sample.txt'), '- user specified output format, denoting information placement
                    with !column_name!'),
            tags$li(strong('Program'), '- choice between PHREEQC or PEST (control/instruction) 
                    formats based on the sample.txt used'),
            tags$li(strong('Weighting'), '- user specified weighting formula in R syntax, using the letter ', 
                    em('s'), ' as the placeholder for SD')),
    
    br(),
    h4('Scan Tool'),
    p('Scan your Dataset.csv file for missing minerals from mineral-ref.xlsx below:'),
    fileInput('dataset.test', label = 'Select Dataset.csv file'),
    fileInput('mineral.test', label = 'Select mineral-ref.xlsx file'),
    actionButton('scan', 'Scan'),
    br(),
    tableOutput('missing'),
    br(),
    p('Note: Densities are g/cm3, molar masses are g/mol, sites are sites/nm2, and names 
    are case sensitive.  If nothing shows, there are no minerals or compounds missing.')
  ),    
  
  tabPanel(title = 'Formatter',
           
           # Page title
           titlePanel('LLNL Surface Complexation Database Formatter'),
           
           # Sidebar area with user inputs
           sidebarPanel(
             
             # User inputs here
             fileInput('sub.dataset', label = h4('Select sc.subset file')),
             hr(),
             fileInput('sample', label = h4('Select sample.txt file')),
             hr(),
             selectInput('program', label = h4('Select program format'), 
                         choices = c('phreeqc', 'pest-control', 'pest-instruction'), selected = NULL),
             hr(),
             textInput('weighting', label = h4('Write weighting formula'), value = "s ^ -1"),
             hr(),
             actionButton('format', 'Format'),
             hr(),
             downloadButton('downloadOutfile', 'Download')
           ),
           
           # Main display area
           mainPanel(
             withSpinner(verbatimTextOutput('outfile'), size = 2, proxy.height = '500px')
           )
  ),
  
  tabPanel(title = 'Contact',
           
           # Page title
           titlePanel('LLNL Surface Complexation Database Formatter'),
           br(),
           h4('Contact Info'),
           p('Please contact Nicholas Parham at ', strong('(305) 877 8223'), ' or ', strong('nick-99@att.net'), 
           ' with questions, comments, or corrections.  This application was sponsored by Mavrik Zavarin, PhD.')
           )
)  

