## Data cleaning if NBA data

# install libraries
library(tidyverse)
library(readxl)

# setting file paths
stats_folder = "data/raw/NBA Team stats"
salary_file  = "data/raw/NBASalaryDATA.xlsx"
clean_folder = "data/clean"

if (!dir.exists(clean_folder)) {
  dir.create(clean_folder, recursive = TRUE)
}


# read and combine team stats csv files
stats_folder = "data/raw/NBA Team stats"

stat_files = list.files(
  path = stats_folder,
  pattern = "^\\d{4}-\\d{2}_stats\\.csv$",
  full.names = TRUE
)

team_stats = map_dfr(stat_files, function(file) {
  
  file_name = basename(file)
  season_start = str_extract(file_name, "^\\d{4}")
  season = as.numeric(season_start) + 1
  
  read_csv(file, skip = 1, show_col_types = FALSE) |>
    filter(!is.na(Team)) %>%
    filter(Team != "League Average") |>
    mutate(
      team = str_remove(Team, "\\*$"),
      season = season,
      wins = as.numeric(W),
      losses = as.numeric(L),
      ortg = as.numeric(ORtg),
      drtg = as.numeric(DRtg),
      pace = as.numeric(Pace),
      three_par = as.numeric(`3PAr`),
      ts_pct = as.numeric(`TS%`),
      off_efg = as.numeric(`eFG%...19`),
      off_tov = as.numeric(`TOV%...20`),
      orb_pct = as.numeric(`ORB%`),
      def_efg = as.numeric(`eFG%...24`),
      def_tov = as.numeric(`TOV%...25`),
      drb_pct = as.numeric(`DRB%`)
    ) |>
    select(
      team, season, wins, losses, ortg, drtg, pace,
      three_par, ts_pct, off_efg, off_tov, orb_pct,
      def_efg, def_tov, drb_pct
    ) |>
    mutate(
      win_pct = wins / (wins + losses)
    )
})



# read and combine salary sheets
salary_sheets = excel_sheets(salary_file)

salaries = map_dfr(salary_sheets, function(sheet_name) {
  
  raw = read_excel(salary_file, sheet = sheet_name, col_names = FALSE)
  
  # remove header row
  raw = raw[-1, ]
  
  # split into two parts
  payroll_rows = raw %>% slice(seq(1, n(), by = 2))
  team_rows    = raw %>% slice(seq(2, n(), by = 2))
  
  tibble(
    team = team_rows$`...2`,
    payroll = payroll_rows$`...3`,
    season = as.numeric(str_extract(sheet_name, "^\\d{4}")) + 1
  ) |>
    filter(!is.na(team), !is.na(payroll))
})



# fixing team names so data is able to be joined
fix_team_names = function(df) {
  df |>
    mutate(
      team = case_when(
        team == "Clippers" ~ "Los Angeles Clippers",
        team == "Lakers" ~ "Los Angeles Lakers",
        team == "Warriors" ~ "Golden State Warriors",
        team == "Spurs" ~ "San Antonio Spurs",
        team == "Thunder" ~ "Oklahoma City Thunder",
        team == "Cavaliers" ~ "Cleveland Cavaliers",
        team == "Trail Blazers" ~ "Portland Trail Blazers",
        team == "Rockets" ~ "Houston Rockets",
        team == "Grizzlies" ~ "Memphis Grizzlies",
        team == "Hawks" ~ "Atlanta Hawks",
        team == "Pelicans" ~ "New Orleans Pelicans",
        team == "Mavericks" ~ "Dallas Mavericks",
        team == "Heat" ~ "Miami Heat",
        team == "Knicks" ~ "New York Knicks",
        team == "Raptors" ~ "Toronto Raptors",
        team == "Bulls" ~ "Chicago Bulls",
        team == "Nets" ~ "Brooklyn Nets",
        team == "Hornets" ~ "Charlotte Hornets",
        team == "Pistons" ~ "Detroit Pistons",
        team == "Celtics" ~ "Boston Celtics",
        team == "Pacers" ~ "Indiana Pacers",
        team == "Kings" ~ "Sacramento Kings",
        team == "Suns" ~ "Phoenix Suns",
        team == "Jazz" ~ "Utah Jazz",
        team == "Nuggets" ~ "Denver Nuggets",
        team == "Timberwolves" ~ "Minnesota Timberwolves",
        team == "Magic" ~ "Orlando Magic",
        team == "76ers" ~ "Philadelphia 76ers",
        team == "Bucks" ~ "Milwaukee Bucks",
        team == "Wizards" ~ "Washington Wizards",
        TRUE ~ team
      )
    )
}

team_stats = fix_team_names(team_stats)
salaries   = fix_team_names(salaries)

# before merging check unmatched rows
stats_not_in_salaries = anti_join(team_stats, salaries, by = c("team", "season"))
salaries_not_in_stats = anti_join(salaries, team_stats, by = c("team", "season"))

stats_not_in_salaries
salaries_not_in_stats

# since both empty we can merge

# merging
nba_data = left_join(team_stats, salaries, by = c("team", "season"))

# make sure merged correctly
glimpse(nba_data)
summary(nba_data)
head(nba_data)

# checking for missing payroll
nba_data |>
  summarize(missing_payroll = sum(is.na(payroll)))

# since 0 no missing payroll values

# save outputs
write_csv(team_stats, "data/clean/team_stats_clean.csv")
write_csv(salaries, "data/clean/salaries_clean.csv")
write_csv(nba_data, "data/clean/nba_data.csv")

save(team_stats, salaries, nba_data, file = "data/clean/nba_data.RData")
