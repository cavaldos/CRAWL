source("global.R")
# Define server logic required to draw a histogram
server <- function(input, output) {
  get_n_documents_by_year <- reactive({
    start_year <- as.numeric(input$years[1])
    end_year <- as.numeric(input$years[2])
    # Create an empty dataframe to store the number of papers
    n_documents_by_year <-
      data.frame(matrix(ncol = 6, nrow = end_year - start_year + 1))
    colnames(n_documents_by_year) <- c("year", editorials, "ALL")
    n_documents_by_year$year <- start_year:end_year
    aux <-
      rbind(n_documents_by_year, c("ALL", rep(0, length(editorials) + 1)))
    n_documents_by_year <- aux
    for (i in start_year:end_year) {
      aux_df = subset(papers_all, year == i)
      n_documents_by_year[n_documents_by_year$year == i, "ALL"] = nrow(aux_df)
      n_documents_by_year[n_documents_by_year$year == "ALL", "ALL"] = as.numeric(n_documents_by_year[n_documents_by_year$year == "ALL", "ALL"]) + as.numeric(n_documents_by_year[n_documents_by_year$year == i, "ALL"])
      for (f in editorials) {
        n_documents_by_year[n_documents_by_year$year == i, f]  = nrow(subset(aux_df, editorial == f))
        n_documents_by_year[n_documents_by_year$year == "ALL", f] = as.numeric(n_documents_by_year[n_documents_by_year$year == "ALL", f]) + as.numeric(n_documents_by_year[n_documents_by_year$year == i, f])
      }
    }
    n_documents_by_year
    
  })
  
  get_top10_data <- reactive({
    start_year <- as.numeric(input$years[1])
    end_year <- as.numeric(input$years[2])
    d <- data.frame(rang = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10))
    for (i in start_year:end_year) {
      aux <- topics(subset(papers_all, year == i)['title'])[, 1]
      if(length(aux) < 10){
        aux <- c(aux, rep("-", 10 - length(aux)))
      }
      d[, paste(i)] <- head(aux, 10)
    }
    d$rang <- as.integer(d$rang)
    d
  })
  
  
  
  
  output$resumeTable <- renderTable(striped = TRUE, align = 'c', spacing = 'xs',width = '100%',{
    n_documents_by_year <- get_n_documents_by_year()
    transposed_n_documents_by_year <- t(n_documents_by_year)
    colnames(transposed_n_documents_by_year) <-
      transposed_n_documents_by_year[1, ]
    transposed_n_documents_by_year <-
      transposed_n_documents_by_year[-1, ]
    transposed_n_documents_by_year <-
      cbind(Platform = c(editorials, "ALL"),
            transposed_n_documents_by_year)
    transposed_n_documents_by_year
    
  })
  
  output$totalByPlataform <- renderPlot({
    n_documents_by_year <- head(get_n_documents_by_year(), -1)
    n_documents_by_year[] <-
      lapply(n_documents_by_year, as.numeric)
    # Define the plot
    plot  <- ggplot(data = n_documents_by_year)
    # Add lines and points for each editorial
    for (f in editorials) {
      plot = plot + geom_line(aes_string(
        x = "year",
        y = f,
        color = shQuote(f)
      ), show.legend = TRUE)
      plot <-
        plot + geom_point(aes_string(
          x = "year",
          y = f,
          color = shQuote(f)
        ))
    }
    plot  <- plot + xlab("Year")
    plot  <- plot + ylab("Generated Documents")
    # Plot the chart
    plot
    
  })
  
  
  
  output$totalByYear <- renderPlot({
    n_documents_by_year <- head(get_n_documents_by_year(), -1)
    n_documents_by_year[] <-
      lapply(n_documents_by_year, as.numeric)
    df <- n_documents_by_year$ALL
    evolution <- diff(df)
    
    percentage_evolution <-
      round((evolution / df[-length(df)]) * 100, 2)

    
    greater_than_9999 <- df[-length(df)] > 9999
    df_label <- ifelse(greater_than_9999,
                       paste(format(df[-length(df)], big.mark = ","), " (", percentage_evolution, "%)", sep = ""),
                       paste(df[-length(df)], " (", percentage_evolution, "%)", sep = ""))
    

    n_documents_by_year_evolution <-
      n_documents_by_year[2:(as.numeric(input$years[2]) - as.numeric(input$years[1]) +
                               1), ]
    n_documents_by_year_evolution$labels <- df_label
    
    generated_documents_plot = ggplot(data = n_documents_by_year_evolution, aes(x = year, y = ALL, group = 1)) +
      geom_line(aes(x = year, y = ALL), color = "black") +
      geom_point(aes(x = year, y = ALL), color = "black") +
      geom_text(
        aes(label = labels),
        hjust = -0.1,
        vjust = 2,
        size = 3
      ) +
      xlab("Year") +
      ylab("Generated Documents") +
      scale_x_continuous(breaks = seq(as.numeric(input$years[1]) + 1, as.numeric(input$years[2]), 1),
                         expand = c(0.1, 0.9)) +
      scale_y_continuous(labels = function(x) ifelse(x > 9999, format(x, big.mark = ","), x)) +
      theme(legend.title = element_blank())
    
    ggsave("generated_documents.png", generated_documents_plot, dpi=300) # Decomment to save on a folder a big plot 
    generated_documents_plot
    
  })
  
  
  output$top10_table <- renderTable(striped = TRUE,align = 'c', {
    get_top10_data()
  })
  
  
  
  output$top_10_terms <- renderTable(striped = TRUE,colnames = FALSE,align = 'c', spacing = 'xs',width = '100%',{
    start_year <- as.numeric(input$years[1])
    end_year <- as.numeric(input$years[2])
    n_years = end_year - start_year + 1
    
    d <- get_top10_data()
    
    aux_map <- list()
    for (i in 2:ncol(d)) {
      for (f in 1:nrow(d)) {
        word <- d[f, i]
        if (!(word %in% names(aux_map))) {
          aux_map[[word]] <- 0
        }
      }
    }
    aux_map = names(aux_map)
    aux_map<-aux_map[aux_map != '-']
    aux_map
  })
  
  
  output$top10_plot <- renderPlot({
    start_year <- as.numeric(input$years[1])
    end_year <- as.numeric(input$years[2])
    n_years = end_year - start_year + 1
    
    d <- get_top10_data()
    aux_map <- list()
    for (i in 2:ncol(d)) {
      for (f in 1:nrow(d)) {
        word <- d[f, i]
        if (!(word %in% names(aux_map))) {
          aux_map[[word]] <- c(rep(NA, times = n_years))
        }
        aux_map[[word]][i - 1] <- f
      }
    }
    Word = c()
    Top10 = c()
    for (key in names(aux_map)) {
      for (i in rep(key, times = n_years))
        Word <- c(Word, i)
      for (i in aux_map[[key]])
        Top10 <- c(Top10, i)
    }
    Year <-
      c(rep(start_year:end_year, times = length(names(aux_map))))
    graf <- data.frame(Year = Year,
                       Top10 = Top10,
                       Word = Word)
    top10_plot = ggplot(
      data = graf,
      aes(x = Year, y = Top10, label = Word),
      ylim = c(10, 1),
      show.legend = FALSE
    )  +
      geom_line(aes(colour = Word), size = 0.3)  +
      geom_point(aes(colour = Word)) +
      geom_text(hjust = 0.5,
                vjust = 2,
                size = 2.5) +
      scale_y_continuous(
        name = "Top 10",
        trans = "reverse",
        breaks = c(10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
      ) +
      scale_x_continuous(name = "Year", breaks = c(start_year:end_year)) +
      guides(color = FALSE, size = FALSE) + guides(color = FALSE, size = FALSE) 
    
    #ggsave("top10_graph.png", top10_plot, dpi=300) #Decomment to save on a folder a big plot 
    top10_plot 
    
    
  })
  output$top_3_by_year <- renderTable(striped = TRUE,spacing = 'xs',width = '100%',{
    start_year <- as.numeric(input$years[1])
    end_year <- as.numeric(input$years[2])
    top3_docs <-
      papers_all %>%  group_by(year) %>% top_n(3, citations)
    top3_docs <-
      top3_docs %>% filter(between(year, start_year, end_year))
    top3_docs[order(top3_docs$year, top3_docs$citations), ]
  })
  
  
  
  
}