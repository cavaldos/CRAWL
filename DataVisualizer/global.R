#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#


required_packages <- c(
  "shiny",
  "ggplot2",
  "SnowballC",
  "tm",
  "wordcloud",
  "RColorBrewer",
  "tidyverse",
  "ngram",
  "dplyr",
  "shinydashboard"
)


# install missing packages
new.packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]

if (length(new.packages)) {
  install.packages(new.packages)
}


library(shiny)
# Extra libraries
library(ggplot2)
library(tm)
library(SnowballC)
library(wordcloud)
library(RColorBrewer)
library(tidyverse)
library(ngram)
library(dplyr)
library(shinydashboard) # Graphic UI



data_folder = "./data/"

search_term <- readLines(paste(data_folder, "term.csv", sep =''))
search_date <- readLines(paste(data_folder, "time.csv", sep =''))
search_date <- as.Date(search_date)
search_date <- strftime(search_date, format = "%d %B, %Y")

# Define the column names
column_names <- c('year', 'title', 'citations', 'authors')
# Read papers data
papers_all <- read.csv(file = paste(data_folder, "all.csv", sep =''), header = TRUE, sep = ",")
papers_all$year <- as.integer(papers_all$year)
papers_all$citations <- as.integer(papers_all$citations)

papers_all <- papers_all[!duplicated(papers_all[c('title','authors')]), ] # Remove duplicated rows



editorials = sort(unique(papers_all$editorial))

# Read filters
excluded_words <-
  read.csv(file = "./filters/remove_words.csv", header = FALSE, sep = ",") %>% setNames(c("words")) # words to exclude from analysis # Concepts to transform to a singular word (only for top10 terms)
concepts_map <-
  read.csv(file = "./filters/concepts_map.csv", header = FALSE, sep = ",") %>% setNames(c("concept", "replacement")) # Concepts to transform to a singular word (only for top10 terms)

# Get the start and end years from the data
start_year_by_file <- as.numeric(min(papers_all$year))
end_year_by_file <- as.numeric(max(papers_all$year))


# Loop through the years and calculate the number of papers
get_words <- function(df, row_name) {
  text = paste(df[, row_name], collapse = " ")
  text
}
toSpace <-
  content_transformer(function (x , pattern)
    gsub(pattern, " ", x))
topics <- function (text) {
  # Load the data as a corpus
  docs <- VCorpus(VectorSource(text))
  docs <- tm_map(docs, toSpace, "/")
  docs <- tm_map(docs, toSpace, "@")
  docs <- tm_map(docs, toSpace, "\\|")
  docs <- tm_map(docs, toSpace, "-")
  docs <- tm_map(docs, toSpace, "—")
  docs <- tm_map(docs, toSpace, "–")
  docs <- tm_map(docs, toSpace, "‘")
  docs <-
    tm_map(docs, toSpace, "’") #Es diferent que el de sobre
  docs <- tm_map(docs, toSpace, "“")
  
  # Convert the text to lower case
  docs <- tm_map(docs, content_transformer(tolower))
  # Remove numbers
  docs <- tm_map(docs, removeNumbers)
  # Remove english common stopwords
  docs <- tm_map(docs, removeWords, stopwords("english"))
  # Remove concepts that do not add value
  docs <- tm_map(docs, removeWords, excluded_words[[1]])
  # Remove punctuations
  docs <- tm_map(docs, removePunctuation)
  # Remove extra white spaces
  docs <- tm_map(docs, stripWhitespace)
  
  
  # Map the concepts of more than one word to one
  for (i in 1:nrow(concepts_map)) {
    docs <-
      tm_map(docs, content_transformer(
        function(x)
          gsub(x, pattern = concepts_map[i, 1], replacement = concepts_map[i, 2])
      ))
  }
  tdm <- TermDocumentMatrix(docs)
  m <- as.matrix(tdm)
  v <- sort(rowSums(m), decreasing = TRUE)
  d <- data.frame(word = names(v), freq = v)
  return(d)
}
