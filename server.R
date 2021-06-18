#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Contact Nicholas Parham (NP) at nick-99@att.net for comments or corrections.

library(shiny)
library(readxl)
library(dplyr)
library(DT)
library(sjmisc)
library(PeriodicTable)
library(data.table)

   #########################
###### FILE DEPENDENCIES ######
   #########################

elements.list = read.csv('elementlist.csv') # should be a dependency
elements = elements.list$symbols

   #################
###### FUNCTIONS ######
   #################

s_element = function(element){ # isolate element name for use in mass() function
    if (unlist(stringr::str_split(element, '[(]'), use.names = F)[1] %in% elements){
        if (length(unlist(stringr::str_split(element, '[+]'), use.names = F)) > 1){
            symbol = unlist(stringr::str_split(element, '[(]'), use.names = F)[1]
        }else if (length(unlist(stringr::str_split(element, '[-]'), use.names = F)) > 1){
            symbol = unlist(stringr::str_split(element, '[(]'), use.names = F)[1]
        }else{
            symbol = 'H' # default if element not found
        }
        if (is.null(symbol) | is.na(symbol)){
            symbol = 'H'
        }
    }else{
        symbol = 'H'
    }
    return(symbol)
}

   ####################
###### SERVER LOGIC ######
   ####################

shinyServer(function(input, output) {
    
       ################
    ###### HOME TAB ######
       ################
    
    missingInput = eventReactive(input$scan, {
        filepath = input$dataset.test
        dataset = read.csv(filepath$datapath)
        filepath2 = input$mineral.test
        mineral.ref = read_excel(filepath2$datapath)
        
        minerals = unique(c(dataset$Mineral, 
                            dataset$Electrolyte1,
                            dataset$Electrolyte2,
                            dataset$Electrolyte3,
                            dataset$Electrolyte4,
                            dataset$Electrolyte5,
                            dataset$Electrolyte6,
                            dataset$Sorbent))
        ref.minerals = unique(mineral.ref$minerals)
        elements.list = read.csv('elementlist.csv') # should be a dependency
        elements = elements.list$symbols
        
        # filter out elements
        for (i in c(1:length(minerals))){
            if (unlist(stringr::str_split(minerals[i], '[(]'), use.names = F)[1] %in% elements){
                if (length(unlist(stringr::str_split(minerals[i], '[+]'), use.names = F)) > 1){
                    minerals[i] = 'Element'
                }else if (length(unlist(stringr::str_split(minerals[i], '[-]'), use.names = F)) > 1){
                    minerals[i] = 'Element'
                }else{
                    # not element
                }
            }
        }

        missing = minerals[!(minerals %in% ref.minerals) & !(minerals == '') & !(is.na(minerals)) 
                           & !(minerals == 'Element') & !(minerals == 'pH')]
        missing = data.frame(missing = missing) # output missing from mineral-ref
        missing
    })
    
    output$missing = renderTable({
        missing = missingInput()
        missing
    })
    
       #####################
    ###### FORMATTER TAB ######
       #####################
    
    sub.datasetInput = reactive({ # read in sc.subset.xlsx as dataframe
        filepath = input$sub.dataset
        sub.dataset = read.csv(filepath$datapath)
        sub.dataset
    })
    
    sample.formatInput = reactive({ # read in sample.txt as dataframe
        filepath = input$sample
        sample.format = readChar(filepath$datapath, file.info(filepath$datapath)$size)
        sample.format = stringr::str_remove_all(sample.format, '\r')
        sample.format
    })
    
    outfile = eventReactive(input$format, {
        subset.data = sub.datasetInput()
        format.sample = sample.formatInput()
        format.output = data.frame()
        
        for (k in c(1:nrow(subset.data))){
            chunk = format.sample
            chunk = unlist(stringr::str_split(chunk, '\n'), use.names = F)
            locators = c('Num', 'Obs', 'Weighting', colnames(subset.data))
            for (i in c(1:length(chunk))){
                for (n in c(1:length(locators))){
                    if (stringr::str_detect(chunk[i], locators[n])){
                        if (locators[n] == 'Num'){
                            val = k
                        }else if (locators[n] == 'Obs'){
                            val = paste('Obs', k, sep = '')
                        }else if(locators[n] == 'Weighting'){
                            s = subset.data[k, 'Aq_SD']
                            val = signif(eval(parse(text = input$weighting)), 6)
                        }else{
                            val = subset.data[k, locators[n]]
                        }
                        
                        locator = paste('!', locators[n], '!', sep = '')
                        
                        if (is.null(val)){
                            chunk[i] = ''
                            next
                        }else if(is.na(val)){
                            chunk[i] = ''
                            next
                        }
                        
                        if (input$program == 'phreeqc'){ # special vase added 16JUL20 # 19JUL20
                            if ((locators[n] %like% 'Gas') & ((locators[n] %like% '_val') | (locators[n] %like% '_SD'))){
                                val = log(val, base = 10)
                            }
                        }
                        
                        if (input$program == 'pest-instruction'){ # special case added 16JUL20
                            val = paste('!', val, '!', sep = '')
                        }else if(locators[n] != 'Obs' & locators[n] != 'Num' & is.numeric(val)){
                            val = formatC(val, digits = 3, format = 'E')
                        }
                        
                        val = as.character(val)
                        chunk[i] = stringr::str_replace_all(chunk[i], locator, val)
                    }
                }
            }
            
            chunk = chunk[chunk != '']
            chunk = do.call(paste, c(as.list(chunk), sep = '\n'))
            format.output = c(format.output, chunk)
            format.output = do.call(paste, c(as.list(format.output), sep = '\n'))
        }
        
        format.output
    })
    
    output$outfile = renderText({
        outfile = outfile()
        outfile
    })
    
    output$downloadOutfile = downloadHandler(
        filename = function() {
            paste(input$program, '-format', '.txt', sep = '')
        },
        content = function(file) {
            write.table(outfile(), file, row.names = F, col.names = F, quote = F)
        })
})
