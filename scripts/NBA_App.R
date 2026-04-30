# Loading libraries
library(shiny)
library(ggplot2)
library(dplyr)
library(scales)

# reading in the csv
nba = read.csv("../data/clean/nba_data.csv",
               stringsAsFactors = FALSE)
# convert payroll from raw dollars to millions so it can read better
nba$payroll_M = nba$payroll / 1e6

# make sure season is numeric
nba$season = as.numeric(nba$season)

# store the unique seasons and teams so we can use them in drop down menus
seasons = sort(unique(nba$season))
teams = sort(unique(nba$team))

# ui defines everything the user sees
ui = fluidPage(
  h2("NBA Team Analytics Dashboard", style = "padding: 15px 25px 0 25px;"),
     p("Explore NBA team performance and payroll from 2015-2024.", 
       style = "padding: 0 25px; color: #6c757d;"),
  
  # fluid row splits page into columns - width have to add to 12
  fluidRow(
    # sidebar on left - width 3 out of 12
    column(3,
           wellPanel( # puts a boc around the sidebar content
             h4("Season Range"),
             # slider lets user filter which seasons show up in plots
             sliderInput("season_range", label = NULL,
                         min = 2015, max = 2024, value = c(2015, 2024), sep = "", step = 1),
             h4("Select Teams"),
             # multi select dropdown so the user can select specific teams
             selectInput("highlight_teams", label = NULL, choices = teams, multiple = TRUE,
                         selected = NULL),
             
             h4("Rank teams by"),
             # dropdown to pick which stat the bar chart ranks teams by
             selectInput("top_metric", label = NULL,
                         choices = c("Winning %" = "win_pct",
                                     "Payroll ($M)" = "payroll_M",
                                     "Offensive Rating" = "ortg",
                                     "Defensive Rating" = "drtg"),
                         selected = "win_pct"),
             
             h4("Compare teams by"),
             # dropdown to pick which stat to compare across teams
             selectInput("compare_var", label = NULL, choices = c("Winning %" = "win_pct",
                                                                  "Payroll ($M)" = "payroll_M",
                                                                  "Offensive Rating" = "ortg",
                                                                  "Defensive Rating" = "drtg"),
                         selected = "win_pct"),
             
             h4("Scatter X axis"),
             # dropdown to pick x axis varible for scatter
             selectInput("scatter_x", label = NULL, choices = c(
               "Winning %" = "win_pct",
               "Payroll ($M)" = "payroll_M",
               "Offensive Rating" = "ortg",
               "Defensive Rating" = "drtg"),
               selected = "payroll_M"),
             
             h4("Scatter Y axis"),
             # dropdown to pick y axis variable
             selectInput("scatter_y", label = NULL, choices = c(
               "Winning %" = "win_pct",
               "Payroll ($M)" = "payroll_M",
               "Offensive Rating" = "ortg",
               "Defensive Rating" = "drtg"),
               selected = "win_pct"),
             
             h4("League Trend stat"),
             # dropdown to pick which stat to track over time
             selectInput("trend_var", label = NULL,
                         choices = c("Winning %" = "win_pct",
                                     "Payroll ($M)" = "payroll_M",
                                     "Offensive Rating" = "ortg",
                                     "Defensive Rating" = "drtg"),
                         selected = "payroll_M"),
             
             # adding where the data is from at the bottem
             hr(),
             h4("Data Sources"),
             tags$ul(style = "font-size: 11px; color: #555; padding-left: 0; list-style-position: inside;",
                     tags$li("Basketball Reference (team stats)"),
                     tags$li("HoopsHype (team payroll)")
             )
               
           )
          ),
    
    # main content area on right - width 9 out of 12
    column(9, 
           # tabsetPanle creates the clickable tabs
           tabsetPanel(
             
             #each tabPanel is one tab - first argument is the tab label
             tabPanel("Top Teams",
                      br(),
    
           # plotOutput is just a placeholder that tells Shiny where to draw the plot
           # the actual plot gets built in the server
           plotOutput("top_teams_plot", height = "500px")
           ),
           # filling in tabs for plots
           tabPanel("Compare Teams",
                    br(),
                    plotOutput("compare_plot", height = "500px"),
                    p("Select teams in the sidebar to compare them.  Shows all teams if none selected.",
                      style = "color:gray; font-size:12px;")
                    ),
           
           tabPanel("Scatter Explorer",
                    br(),
                    plotOutput("scatter_plot", height = "500px"),
                    p("Each point is one team-season. Select teams in the sidebar to highlight them.",
                      style = "color:gray; font-size:12px;")
                    ),
           
           tabPanel("League Trends",
                    br(),
                    plotOutput("trend_plot", height = "500px"),
                    p("Solid line = league average each season. Shaded band = min to max range across teams.",
                      style = "color:gray; font-size:12px;")
           ),
           # new tab - 2x2 grid of efficiency stats vs winning percentage
           # ties back to the scatter plots from Stage 2
           tabPanel("Efficiency Dashboard",
                    br(),
                    p("Four key efficiency metrics vs. Winning Percentage.",
                      style = "color:gray; font-size:12px;"),
                    # two plots side by side in the top row
                    fluidRow(
                      column(6, plotOutput("eff_ortg", height = "300px")),
                      column(6, plotOutput("eff_drtg", height = "300px"))
                    ),
                    br(),
                    # two more plots side by side in the bottom row
                    fluidRow(
                      column(6, plotOutput("eff_ts",   height = "300px")),
                      column(6, plotOutput("eff_3par", height = "300px"))
                    )
           ),
           )
    )
  )
)

# server is where the r code runs, reads the users inputs and sends plots and results to UI
server = function(input, output, session) {
  # reactive filtered dataset - automatically re-runs whenever the season slider moves
  # any plot that calls dat() will update too
  dat = reactive({
    nba |> filter(season >= input$season_range[1],
                  season <= input$season_range[2])
  })
  
    # build the top teams bar chart
    output$top_teams_plot = renderPlot({
      
      #average the selected stat by team and take the top 10
      df = dat() |>
        group_by(team) |>
        summarise(val = mean(.data[[input$top_metric]], na.rm = TRUE), .groups = "drop") |>
        arrange(desc(val)) |>
        slice_head(n = 10)
      
      # horizontal bar chart sorted by value
      ggplot(df, aes(x = reorder(team, val), y = val)) +
        geom_col(fill = "#2166ac") +
        coord_flip() +
        labs(title = "Top 10 Teams",
             x = NULL, y = input$top_metric) +
        theme_minimal()
    })
    
    # compare teams line chart
    output$compare_plot = renderPlot({
      
      df = dat()
      
      # if teams are selected in the sidebar, filter down to just those teams
      # otherwise show all 30
      if (length(input$highlight_teams) > 0) {
        df = df |> filter(team %in% input$highlight_teams)
      }
      
      # one line per team showing the selected stat over time
      ggplot(df, aes(x = season, y = .data[[input$compare_var]],
                     color = team, group = team)) +
        geom_line(linewidth = 1.1) +
        geom_point(size = 2.5) +
        scale_x_continuous(breaks = seasons) +
        labs(title = "Team Comparison Over Time",
             x = "Season", y = input$compare_var,
             color = "Team") +
        theme_minimal() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
    })
    
    # scatter plot - user picks both axes
    output$scatter_plot = renderPlot({
      
      df = dat()
      
      # flag which points to hightlight - if no teams selected highlight everything
      df = df |> mutate(highlighted = if
                        (length(input$highlight_teams) == 0) TRUE
                        else team %in%
                          input$highlight_teams)
      
      # highlighted teams show in blue, background are grey
      ggplot(df, aes(x = .data[[input$scatter_x]], y = .data[[input$scatter_y]])) +
                       geom_point(aes(color = highlighted, size = highlighted, alpha = highlighted)) +
                       scale_color_manual(values = c("TRUE" = "#2166ac", "FALSE" = "#aaaaaa")) +
                       scale_size_manual(values = c("TRUE" = 3, "FALSE" = 1.8)) +
                       scale_alpha_manual(values = c("TRUE" = 0.9, "FALSE" = 0.3)) +
                       geom_smooth(method = "lm", se = TRUE, color = "#e07b00", fill = "#fde8c8") +
                       labs(title = paste(input$scatter_x, "vs", input$scatter_y),
                            x = input$scatter_x, y = input$scatter_y) +
                       theme_minimal()
    })
    
    # league trends plot
    output$trend_plot = renderPlot({
      
      # summarize across all 30 teams for each season
      # getting the average, min, and max so we can draw the ribbon
      trend_df = nba |>
        group_by(season) |>
        summarise(
          avg = mean(.data[[input$trend_var]], na.rm = TRUE),
          lo  = min(.data[[input$trend_var]], na.rm = TRUE),
          hi  = max(.data[[input$trend_var]], na.rm = TRUE),
          .groups = "drop"
        )
      
      # geom_ribbon draws the shaded band between min and max
      # then the average line gets layered on top
      ggplot(trend_df, aes(x = season)) +
        geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#2166ac", alpha = 0.15) +
        geom_line(aes(y = avg), color = "#2166ac", linewidth = 1.5) +
        geom_point(aes(y = avg), color = "#2166ac", size = 3.5) +
        scale_x_continuous(breaks = seasons) +
        labs(title = paste("League Trend:", input$trend_var),
             x = "Season", y = input$trend_var) +
        theme_minimal()
    })
    
    # helper function so I don't repeat the same plot code 4 times
    # takes the variable, title, and colors and returns a finished scatter plot
    eff_plot = function(xvar, title, color_pt, color_line, color_fill) {
      df = dat()
      ggplot(df, aes(x = .data[[xvar]], y = win_pct)) +
        geom_point(color = color_pt, alpha = 0.55, size = 2) +
        geom_smooth(method = "lm", se = TRUE,
                    color = color_line, fill = color_fill, linewidth = 1) +
        scale_y_continuous(labels = percent_format(accuracy = 1)) +
        labs(title = title, x = xvar, y = "Winning %",
             caption = "Source: Basketball Reference") +
        theme_minimal() +
        theme(plot.title = element_text(size = 12))
    }
    
    # render each of the four panels using the helper function
    output$eff_ortg = renderPlot(
      eff_plot("ortg", "Offensive Rating vs Win %", "#2166ac", "#053061", "#d1e5f0"))
    
    output$eff_drtg = renderPlot(
      eff_plot("drtg", "Defensive Rating vs Win %", "#d6604d", "#67001f", "#fddbc7"))
    
    output$eff_ts = renderPlot(
      eff_plot("ts_pct", "True Shooting % vs Win %", "#4dac26", "#276419", "#d9f0d3"))
    
    output$eff_3par = renderPlot(
      eff_plot("three_par", "3-Point Attempt Rate vs Win %", "#8e44ad", "#4a235a", "#e8daef"))
}



# this is how you launch the app by combining the UI and server together
shinyApp(ui, server)
