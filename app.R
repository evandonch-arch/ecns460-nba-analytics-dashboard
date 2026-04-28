# ECNS 460 - Stage 3: NBA Analytics Shiny Dashboard
# Interactive dashboard to explore NBA team stats and payroll from 2015-2024

# shiny runs the app, ggplot2/dplyr are for plotting and data wrangling like we did all semester,
# scales handles formatting like percent signs and dollar signs on axes
library(shiny)
library(ggplot2)
library(dplyr)
library(scales)


# Load and prep data

# read in the cleaned dataset from Stage 2
nba = read.csv("data/clean/nba_data.csv", stringsAsFactors = FALSE)

# convert payroll from raw dollars to millions so it reads better on plots
nba$payroll_M = nba$payroll / 1e6

# store unique seasons and teams to use in dropdowns and axis labels later
seasons = sort(unique(nba$season))
teams   = sort(unique(nba$team))


# Variable labels and formatting helpers

# named vector that maps the readable dropdown label (what the user sees)
# to the actual column name in the data (e.g. "Winning Percentage" -> "win_pct")
var_choices = c(
  "Winning Percentage"      = "win_pct",
  "Payroll ($M)"            = "payroll_M",
  "Offensive Rating"        = "ortg",
  "Defensive Rating"        = "drtg",
  "Pace"                    = "pace",
  "3-Point Attempt Rate"    = "three_par",
  "True Shooting %"         = "ts_pct",
  "Wins"                    = "wins",
  "Losses"                  = "losses"
)

# given a column name like "win_pct", returns the readable label like "Winning Percentage"
# used to automatically set axis titles and plot titles based on what the user picks
var_label = function(var) names(var_choices)[var_choices == var]

# returns the right scale formatter so axes always display the right format
# percentage stats show as 65.3%, payroll shows as $85M, everything else is plain numbers
axis_formatter = function(var) {
  if (var %in% c("win_pct", "three_par", "ts_pct")) return(percent_format(accuracy = 0.1))
  if (var == "payroll_M") return(dollar_format(suffix = "M", accuracy = 1))
  return(waiver())
}


# Custom theme

# I created a custom theme so every plot in the app has consistent styling
# it's built on theme_minimal from class with a few tweaks like removing minor gridlines
theme_nba = function() {
  theme_minimal(base_size = 13) +
    theme(
      plot.title       = element_text(face = "bold", size = 14),
      plot.subtitle    = element_text(color = "gray40", size = 11),
      plot.caption     = element_text(color = "gray55", size = 9),
      panel.grid.minor = element_blank(),
      legend.position  = "none"
    )
}


# UI
# the UI defines everything the user sees - the layout, buttons, dropdowns, and where plots go
# in Shiny the UI and server are always kept separate: UI handles appearance, server handles logic

ui = fluidPage(

  # a small block of CSS to make the app look cleaner - controls background color, font, borders
  tags$head(tags$style(HTML("
    body { background-color: #f8f9fa; font-family: 'Helvetica Neue', sans-serif; }
    .well { background-color: #ffffff; border: 1px solid #dee2e6; border-radius: 8px; }
    h2.app-title { color: #1a1a2e; font-weight: 700; margin-bottom: 4px; }
    p.app-subtitle { color: #6c757d; margin-bottom: 20px; font-size: 14px; }
    .nav-tabs > li > a { font-weight: 600; }
  "))),

  # app title and description at the top of the page
  div(style = "padding: 20px 30px 0 30px;",
    h2("NBA Team Analytics Dashboard", class = "app-title"),
    p("Explore team performance, payroll, and efficiency across NBA seasons (2015-2024).",
      class = "app-subtitle")
  ),

  # split the page into a narrow sidebar (width 3) and wider main content area (width 9)
  # widths always have to add up to 12 in Shiny's grid system
  fluidRow(

    # Sidebar - contains filters that apply across all six tabs
    column(3,
      div(style = "padding: 10px 15px;",
        wellPanel(

          h4("Season Range", style = "margin-top:0; font-weight:700;"),
          # range slider so the user can filter which seasons appear in the plots
          sliderInput("season_range", label = NULL,
                      min = 2015, max = 2024, value = c(2015, 2024),
                      sep = "", step = 1),
          hr(),

          h4("Select Teams to Highlight", style = "font-weight:700;"),
          p("Leave blank to show all teams.", style = "color:gray; font-size:12px; margin-top:-8px;"),
          # multi-select dropdown - picking teams highlights them in blue across all plots
          # leaving it empty shows all 30 teams
          selectInput("highlight_teams", label = NULL,
                      choices = teams, multiple = TRUE, selected = NULL),
          # convenience buttons so the user doesn't have to click through all 30 teams
          actionButton("select_all", "Select All", class = "btn-sm btn-outline-secondary",
                       style = "margin-right:5px;"),
          actionButton("clear_all", "Clear", class = "btn-sm btn-outline-secondary"),
          hr(),

          # data source attribution on every page
          h4("Data Sources", style = "font-weight:700;"),
          tags$ul(style = "padding-left: 18px; font-size: 12px; color: #555;",
            tags$li("Basketball Reference (team stats)"),
            tags$li("HoopsHype (team payroll)")
          )
        )
      )
    ),

    # Main panel - holds all six tabs
    column(9,
      div(style = "padding: 10px 15px;",
        tabsetPanel(id = "tabs",

          # Tab 1: Top Teams
          # shows a ranked horizontal bar chart of teams by whichever stat the user picks
          # user can also control how many teams appear with the slider
          tabPanel("Top Teams",
            br(),
            fluidRow(
              column(6,
                selectInput("top_metric", "Rank teams by:",
                            choices = var_choices, selected = "win_pct")
              ),
              column(6,
                sliderInput("top_n", "Number of teams to show:",
                            min = 5, max = 30, value = 10, step = 1)
              )
            ),
            # plotOutput is a placeholder - the actual plot is built in the server below
            plotOutput("top_teams_plot", height = "480px"),
            br(),
            p("Bars show the average value across the selected season range.",
              style = "color:gray; font-size:12px;")
          ),

          # Tab 2: Compare Teams
          # lets users pick specific teams and compare them side by side
          # toggle between a line chart (shows change over time) or bar chart (shows averages)
          tabPanel("Compare Teams",
            br(),
            fluidRow(
              column(6,
                selectInput("compare_var", "Statistic to compare:",
                            choices = var_choices, selected = "win_pct")
              ),
              column(6,
                # radio buttons to switch between the two chart types
                radioButtons("compare_type", "Chart type:",
                             choices = c("Line chart (over time)" = "line",
                                         "Bar chart (season average)" = "bar"),
                             inline = TRUE)
              )
            ),
            plotOutput("compare_plot", height = "460px"),
            br(),
            p("Select teams using the sidebar. If no teams selected, all teams are shown.",
              style = "color:gray; font-size:12px;")
          ),

          # Tab 3: Scatter Explorer
          # the most flexible tab - user picks both axes to explore any relationship in the data
          # optional checkboxes to add team labels and a regression line
          tabPanel("Scatter Explorer",
            br(),
            fluidRow(
              column(4,
                selectInput("scatter_x", "X-axis variable:",
                            choices = var_choices, selected = "payroll_M")
              ),
              column(4,
                selectInput("scatter_y", "Y-axis variable:",
                            choices = var_choices, selected = "win_pct")
              ),
              column(4,
                checkboxInput("scatter_labels", "Label selected teams", value = TRUE),
                checkboxInput("scatter_lm", "Show trend line", value = TRUE)
              )
            ),
            plotOutput("scatter_plot", height = "460px"),
            br(),
            p("Each point = one team-season. Highlighted teams (sidebar) are colored; others are gray.",
              style = "color:gray; font-size:12px;")
          ),

          # Tab 4: Efficiency Dashboard
          # four key efficiency stats vs winning percentage arranged in a 2x2 grid
          # I added this based on peer feedback to group the scatter plots together
          tabPanel("Efficiency Dashboard",
            br(),
            p("Four key efficiency metrics vs. Winning Percentage - filtered by season range."),
            fluidRow(
              column(6, plotOutput("eff_ortg", height = "300px")),
              column(6, plotOutput("eff_drtg", height = "300px"))
            ),
            br(),
            fluidRow(
              column(6, plotOutput("eff_ts",   height = "300px")),
              column(6, plotOutput("eff_3par", height = "300px"))
            )
          ),

          # Tab 5: Team Profile
          # deep dive into one team - shows their stats over time vs the league average
          # user picks which stats to display and the plots are generated dynamically
          tabPanel("Team Profile",
            br(),
            fluidRow(
              column(6,
                selectInput("profile_team", "Select team:",
                            choices = teams, selected = "Golden State Warriors")
              ),
              column(6,
                # multi-select for stats - each one gets its own line chart
                selectInput("profile_vars", "Statistics to display:",
                            choices = var_choices,
                            selected = c("win_pct", "payroll_M", "ortg", "drtg"),
                            multiple = TRUE)
              )
            ),
            # uiOutput is a placeholder for content built dynamically in the server
            # used here because we don't know how many plots to show until the user picks
            uiOutput("team_profile_plots")
          ),

          # Tab 6: League Trends
          # shows how any stat has changed across the whole league from 2015 to 2024
          # solid line is the league average, shaded band shows the spread between best and worst
          tabPanel("League Trends",
            br(),
            selectInput("trend_var", "Statistic to track:",
                        choices = var_choices, selected = "three_par",
                        width = "300px"),
            plotOutput("trend_plot", height = "420px"),
            br(),
            p("Solid line = league average each season. Shaded band = min-max range across teams.",
              style = "color:gray; font-size:12px;")
          )

        )
      )
    )
  )
)


# Server
# the server contains all the R code that actually runs when the user changes something
# reactive() expressions are key to Shiny - they automatically re-run whenever an input
# they depend on changes, so plots update in real time without any extra code needed

server = function(input, output, session) {

  # when the user clicks Select All or Clear, update the team dropdown accordingly
  observeEvent(input$select_all, {
    updateSelectInput(session, "highlight_teams", selected = teams)
  })
  observeEvent(input$clear_all, {
    updateSelectInput(session, "highlight_teams", selected = character(0))
  })

  # reactive filtered dataset - automatically updates whenever the season slider moves
  # every plot that calls dat() will re-render when the slider changes
  dat = reactive({
    nba %>% filter(season >= input$season_range[1],
                   season <= input$season_range[2])
  })

  # returns the currently selected teams, or an empty vector if nothing is selected
  # I use this in multiple places so I wrote it once as a reactive to avoid repeating code
  hi_teams = reactive({
    if (length(input$highlight_teams) == 0) character(0)
    else input$highlight_teams
  })


  # Tab 1: Top Teams plot
  output$top_teams_plot = renderPlot({

    var = input$top_metric
    n   = input$top_n
    lbl = var_label(var)

    # group by team, average the selected stat, sort, and keep the top n teams
    # also flag whether each team is in the highlighted set for coloring
    df = dat() %>%
      group_by(team) %>%
      summarise(val = mean(.data[[var]], na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(val)) %>%
      slice_head(n = n) %>%
      mutate(highlighted = if (length(hi_teams()) == 0) TRUE else team %in% hi_teams())

    # pick the right label format based on variable type (%, $, or plain number)
    fmt = if (var %in% c("win_pct", "three_par", "ts_pct")) {
      function(x) percent(x, accuracy = 0.1)
    } else if (var == "payroll_M") {
      function(x) paste0("$", round(x, 1), "M")
    } else {
      function(x) round(x, 1)
    }

    # horizontal bar chart - reorder() sorts bars by value, coord_flip() turns them horizontal
    # highlighted teams show in blue, non-highlighted teams are grayed out
    ggplot(df, aes(x = reorder(team, val), y = val,
                   fill = highlighted, alpha = highlighted)) +
      geom_col() +
      geom_text(aes(label = fmt(val)), hjust = -0.1, size = 3.5, color = "#333333") +
      scale_fill_manual(values = c("TRUE" = "#2166ac", "FALSE" = "#aaaaaa")) +
      scale_alpha_manual(values = c("TRUE" = 1, "FALSE" = 0.45)) +
      scale_y_continuous(labels = axis_formatter(var),
                         expand = expansion(mult = c(0, 0.18))) +
      coord_flip() +
      labs(
        title    = paste0("Top ", n, " Teams by Average ", lbl),
        subtitle = paste0(input$season_range[1], "-", input$season_range[2], " NBA Seasons"),
        x = NULL, y = lbl,
        caption  = "Sources: Basketball Reference, HoopsHype"
      ) +
      theme_nba()
  })


  # Tab 2: Compare Teams plot
  output$compare_plot = renderPlot({

    var = input$compare_var
    lbl = var_label(var)
    df  = dat()
    sel = hi_teams()

    # filter to only the selected teams if any are chosen in the sidebar
    if (length(sel) > 0) df = df %>% filter(team %in% sel)

    if (input$compare_type == "line") {
      # line chart version - one line per team, good for seeing trends over time
      # viridis turbo palette gives clearly different colors even with many teams
      ggplot(df, aes(x = season, y = .data[[var]], color = team, group = team)) +
        geom_line(linewidth = 1.1) +
        geom_point(size = 2.5) +
        scale_x_continuous(breaks = seasons) +
        scale_y_continuous(labels = axis_formatter(var)) +
        scale_color_viridis_d(option = "turbo") +
        labs(
          title    = paste(lbl, "Over Time"),
          subtitle = if (length(sel) == 0) "All teams" else paste(sel, collapse = ", "),
          x = "Season", y = lbl,
          caption  = "Sources: Basketball Reference, HoopsHype",
          color    = "Team"
        ) +
        theme_nba() +
        theme(legend.position = "right",
              axis.text.x = element_text(angle = 45, hjust = 1))

    } else {
      # bar chart version - averages across selected seasons, sorted highest to lowest
      avg_df = df %>%
        group_by(team) %>%
        summarise(val = mean(.data[[var]], na.rm = TRUE), .groups = "drop") %>%
        arrange(desc(val))

      ggplot(avg_df, aes(x = reorder(team, val), y = val, fill = team)) +
        geom_col(show.legend = FALSE) +
        scale_fill_viridis_d(option = "turbo") +
        scale_y_continuous(labels = axis_formatter(var),
                           expand = expansion(mult = c(0, 0.12))) +
        coord_flip() +
        labs(
          title    = paste("Average", lbl),
          subtitle = paste0(input$season_range[1], "-", input$season_range[2]),
          x = NULL, y = lbl,
          caption  = "Sources: Basketball Reference, HoopsHype"
        ) +
        theme_nba()
    }
  })


  # Tab 3: Scatter Explorer plot
  output$scatter_plot = renderPlot({

    xvar = input$scatter_x
    yvar = input$scatter_y
    xlbl = var_label(xvar)
    ylbl = var_label(yvar)
    df   = dat()
    sel  = hi_teams()

    # add a column to flag which points should be highlighted
    # if no teams are selected, everything is highlighted so all points show in blue
    df = df %>%
      mutate(highlighted = if (length(sel) == 0) TRUE else team %in% sel)

    # highlighted teams are blue and larger, background teams are gray and smaller
    p = ggplot(df, aes(x = .data[[xvar]], y = .data[[yvar]])) +
      geom_point(aes(color = highlighted, alpha = highlighted, size = highlighted)) +
      scale_color_manual(values = c("TRUE" = "#2166ac", "FALSE" = "#aaaaaa")) +
      scale_alpha_manual(values = c("TRUE" = 0.85, "FALSE" = 0.30)) +
      scale_size_manual(values  = c("TRUE" = 2.8,  "FALSE" = 1.8)) +
      scale_x_continuous(labels = axis_formatter(xvar)) +
      scale_y_continuous(labels = axis_formatter(yvar)) +
      labs(
        title    = paste(xlbl, "vs.", ylbl),
        subtitle = paste0(input$season_range[1], "-", input$season_range[2],
                          " - each point = one team-season"),
        x = xlbl, y = ylbl,
        caption  = "Sources: Basketball Reference, HoopsHype"
      ) +
      theme_nba()

    # optionally overlay a linear regression line with a confidence interval shading
    if (input$scatter_lm) {
      p = p + geom_smooth(method = "lm", se = TRUE,
                          color = "#e07b00", fill = "#fde8c8",
                          linewidth = 1, alpha = 0.25)
    }

    # if specific teams are selected, label all their points
    # if no teams are selected, only label the most extreme outlier points to avoid clutter
    if (input$scatter_labels && length(sel) > 0) {
      label_df = df %>% filter(highlighted)
      p = p + geom_text(
        data = label_df,
        aes(label = paste0(substr(team, 1, 3), " '", season %% 100)),
        size = 3, vjust = -0.6, color = "#1a1a2e", fontface = "bold"
      )
    } else if (input$scatter_labels && length(sel) == 0) {
      # find outliers using distance from the center of the plot
      top_pts = df %>%
        mutate(dist = scale(.data[[xvar]])^2 + scale(.data[[yvar]])^2) %>%
        arrange(desc(dist)) %>%
        slice_head(n = 8)
      p = p + geom_text(
        data = top_pts,
        aes(label = paste0(substr(team, 1, 3), " '", season %% 100)),
        size = 2.8, vjust = -0.7, color = "#333333"
      )
    }

    p
  })


  # Tab 4: Efficiency Dashboard plots

  # helper function so I don't repeat the same ggplot code four times
  # takes the variable, title, and colors as arguments and returns a finished scatter plot
  eff_scatter = function(xvar, title, color_pt, color_line, color_fill) {
    df = dat()
    ggplot(df, aes(x = .data[[xvar]], y = win_pct)) +
      geom_point(color = color_pt, alpha = 0.55, size = 2) +
      geom_smooth(method = "lm", se = TRUE,
                  color = color_line, fill = color_fill, linewidth = 1) +
      scale_y_continuous(labels = percent_format(accuracy = 1)) +
      scale_x_continuous(labels = axis_formatter(xvar)) +
      labs(title = title, x = var_label(xvar), y = "Winning %",
           caption = "Source: Basketball Reference") +
      theme_nba() +
      theme(plot.title = element_text(size = 12))
  }

  # render all four panels using the helper - each gets a different color scheme
  output$eff_ortg = renderPlot(
    eff_scatter("ortg", "Offensive Rating vs. Win %",
                "#2166ac", "#053061", "#d1e5f0"))

  output$eff_drtg = renderPlot(
    eff_scatter("drtg", "Defensive Rating vs. Win %  (lower = better)",
                "#d6604d", "#67001f", "#fddbc7"))

  output$eff_ts = renderPlot(
    eff_scatter("ts_pct", "True Shooting % vs. Win %",
                "#4dac26", "#276419", "#d9f0d3"))

  output$eff_3par = renderPlot(
    eff_scatter("three_par", "3-Point Attempt Rate vs. Win %",
                "#8e44ad", "#4a235a", "#e8daef"))


  # Tab 5: Team Profile

  # builds the grid of plots dynamically based on how many stats the user picked
  # since we don't know the number of plots ahead of time, the layout has to be
  # created inside the server using renderUI instead of being hard-coded in the UI
  output$team_profile_plots = renderUI({
    vars = input$profile_vars
    if (length(vars) == 0) return(p("Select at least one statistic above."))

    n_plots  = length(vars)
    plot_ids = paste0("profile_plot_", seq_len(n_plots))

    # use lapply to build rows of two plots each
    rows = ceiling(n_plots / 2)
    plot_rows = lapply(seq_len(rows), function(r) {
      cols = ((r - 1) * 2 + 1):min(r * 2, n_plots)
      fluidRow(lapply(cols, function(i) {
        column(6, plotOutput(plot_ids[i], height = "270px"))
      }))
    })

    do.call(tagList, c(list(br()), plot_rows))
  })

  # renders a line chart for each selected stat showing the team vs the league average
  # local() inside the for loop is needed to avoid a scoping issue where all plots
  # would otherwise end up showing the last variable in the list instead of their own
  observe({
    vars = input$profile_vars
    team = input$profile_team
    if (length(vars) == 0 || is.null(team)) return()

    team_dat   = nba %>% filter(team == !!team) %>% arrange(season)
    league_avg = nba %>%
      group_by(season) %>%
      summarise(across(all_of(vars), mean, na.rm = TRUE), .groups = "drop")

    for (i in seq_along(vars)) {
      local({
        v   = vars[i]
        pid = paste0("profile_plot_", i)
        t_d = team_dat
        l_d = league_avg

        output[[pid]] = renderPlot({
          # dashed gray line is the league average, solid blue line is the selected team
          ggplot(t_d, aes(x = season, y = .data[[v]])) +
            geom_line(data = l_d, aes(y = .data[[v]]),
                      color = "gray70", linetype = "dashed", linewidth = 1) +
            geom_line(color = "#2166ac", linewidth = 1.3) +
            geom_point(color = "#2166ac", size = 3) +
            scale_x_continuous(breaks = seasons) +
            scale_y_continuous(labels = axis_formatter(v)) +
            labs(
              title    = paste(team, "-", var_label(v)),
              subtitle = "Dashed = league average",
              x = "Season", y = var_label(v),
              caption  = "Sources: Basketball Reference, HoopsHype"
            ) +
            theme_nba() +
            theme(axis.text.x = element_text(angle = 45, hjust = 1))
        })
      })
    }
  })


  # Tab 6: League Trends plot
  output$trend_plot = renderPlot({

    var = input$trend_var
    lbl = var_label(var)

    # summarize across all 30 teams for each season to get the average, min, and max
    trend_df = nba %>%
      group_by(season) %>%
      summarise(
        avg = mean(.data[[var]], na.rm = TRUE),
        lo  = min(.data[[var]],  na.rm = TRUE),
        hi  = max(.data[[var]],  na.rm = TRUE),
        .groups = "drop"
      )

    # geom_ribbon draws the shaded band between the min and max values each season
    # the average line is then layered on top
    ggplot(trend_df, aes(x = season)) +
      geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#2166ac", alpha = 0.12) +
      geom_line(aes(y = avg), color = "#2166ac", linewidth = 1.5) +
      geom_point(aes(y = avg), color = "#2166ac", size = 3.5) +
      scale_x_continuous(breaks = seasons) +
      scale_y_continuous(labels = axis_formatter(var)) +
      labs(
        title    = paste("League-Wide Trend:", lbl),
        subtitle = "Solid line = league average  |  Shaded band = full range (min-max)",
        x = "Season", y = lbl,
        caption  = "Sources: Basketball Reference, HoopsHype"
      ) +
      theme_nba()
  })

}

shinyApp(ui, server)
