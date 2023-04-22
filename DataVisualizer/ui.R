source("global.R")

sidebar <- dashboardSidebar(
  hr(),
  sidebarMenu(
    id = "tabs",
    menuItem("Evolution", tabName = "evolution", icon = icon("table")),
    menuItem(
      "Hot terms",
      tabName = "hot_terms",
      icon = icon("line-chart")
    ),
    menuItem("Top Papers", tabName = "TopPapers", icon = icon("question"))
  ),
  hr(),
  fluidRow(column(
    12,
    sliderInput(
      "years",
      "Years Range",
      min = start_year_by_file,
      max = end_year_by_file,
      value = c(start_year_by_file, end_year_by_file)
    )
  ),),
  hr(),
  HTML(paste("<p style='text-align:center;'> Data obtained on", search_date, "</p>"))
)


body <- dashboardBody(tabItems(
  tabItem(tabName = "evolution",
          fluidRow(
            column(
              12,
              box(
                width = NULL,
                status = "primary",
                solidHeader = TRUE,
                title = "Editorials blockchain documents creation",
                tableOutput("resumeTable"),style="overflow-y: scroll;"
              )
            ),
            column(
              6,
              box(
                width = NULL,
                status = "primary",
                solidHeader = TRUE,
                title = "Editorials collected documents per year",
                plotOutput("totalByPlataform")
              )
            ),
            column(
              6,
              box(
                width = NULL,
                status = "primary",
                solidHeader = TRUE,
                title = "Collected documents per year",
                plotOutput("totalByYear")
              )
            )
          )),
  tabItem(tabName = "hot_terms",
          fluidRow(column(
            10, fluidRow(column(
              12,
              box(
                width = NULL,
                status = "primary",
                solidHeader = TRUE,
                title = "TOP 10 terms by year",
                tableOutput("top10_table"),style="overflow-y: scroll;"
              )
            ),
            column(
              12,
              box(
                width = NULL,
                status = "primary",
                solidHeader = TRUE,
                title = "TOP 10 terms by year evolution plot",
                plotOutput("top10_plot")
              )
            ),)
          ),
          column(
            2,
            box(
              width = NULL,
              status = "primary",
              solidHeader = TRUE,
              title = "HOT Terms",
              tableOutput("top_10_terms")
            )
          ))),
  tabItem(tabName = "TopPapers",
          fluidRow(column(
            12,
            box(
              width = NULL,
              status = "primary",
              solidHeader = TRUE,
              title = "Top papers by year",
              tableOutput("top_3_by_year"), style="overflow-y: scroll;"
            )
          )))
))



# Define UI for application that draws a histogram

ui <- dashboardPage(dashboardHeader(title = paste(toupper(search_term), " Analisis")),
                    sidebar,
                    body)