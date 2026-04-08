# visualization portion
# install graphing packages
# install.packages(c("tidyverse", "scales"))

# load in packages
library(tidyverse)
library(scales)

# load in clean data
load("data/clean/nba_data.RData")

# making sure output folder exists
if (!dir.exists("output/figures")) {
  dir.create("output/figures", recursive = TRUE)
}

# setting a theme for plots so they all follow a same layout
theme_set(
  theme_minimal(base_size = 13) +
    theme(
      plot.title = element_text(face = "bold", size = 15),
      plot.subtitle = element_text(size = 11),
      axis.title = element_text(face = "bold"),
      panel.grid.minor = element_blank(),
      legend.postion = "bottom"
    )
)

# Figure 1: Payroll vs Winning Percentage
# Does spending more actually lead to more winning?
fig1 = ggplot(nba_data,aes(x = payroll, y = win_pct)) +
  geom_point(alpha = 0.7, size = 2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1) +
  scale_x_continuous(labels = label_dollar()) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "Team Payroll and Winning Percentage",
    subtitle = "Higher payroll is associated with more winning, but the relationship is far from perfect.",
    x = "Team Payroll",
    y = "Winning Percentage",
    caption = "Source: Basketball Reference and HoopsHype"
  )

ggsave(
  filename = "output/figures/fig1_payroll_vs_winpct.png",
  plot = fig1,
  width = 9,
  height = 6,
  dpi = 300
)

# Figure 2: Offensive Rating vs Winning Percentage
# Whether strong offense is associated with success

fig2 = ggplot(nba_data, aes(x = ortg, y = win_pct)) +
  geom_point(alpha = 0.7, size = 2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "Offensive Rating and Winning Percentage",
    subtitle = "Teams with more efficient offenses tend to win more games.",
    x = "Offensive Rating",
    y = "Winning Percentage",
    caption = "Source: Basketball Reference and HoopsHype"
  )

ggsave(
  filename = "output/figures/fig2_ortg_vs_winpct.png",
  plot = fig2,
  width = 9,
  height = 6,
  dpi = 300
)


# Figure 3: Defensive Rating vs Winning Percentage
# whether defense is associated with success
# to note a lower defensive rating is better

fig3 = ggplot(nba_data, aes(x = drtg, y = win_pct)) +
  geom_point(alpha = 0.7, size = 2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "Defensive Rating and Winning Percentage",
    subtitle = "Teams that allow fewer points per 100 possessions tend to win more.",
    x = "Defensive Rating",
    y = "Winning Percentage",
    caption = "Lower defensive rating is better. Source: Basketball Reference and HoopsHype"
  )

ggsave(
  filename = "output/figures/fig3_drtg_vs_winpct.png",
  plot = fig3,
  width = 9,
  height = 6,
  dpi = 300
)


# Figure 4: Three-point attempt rate vs winning percentage
# is modern shot selection tied to winning

fig4 = ggplot(nba_data, aes(x = three_par, y = win_pct)) +
  geom_point(alpha = 0.7, size = 2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1) +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "Three-Point Attempt Rate and Winning Percentage",
    subtitle = "Teams that take a larger share of shots from three often win more.",
    x = "Three-Point Attempt Rate",
    y = "Winning Percentage",
    caption = "Source: Basketball Reference and HoopsHype"
  )

ggsave(
  filename = "output/figures/fig4_3par_vs_winpct.png",
  plot = fig4,
  width = 9,
  height = 6,
  dpi = 300
)


# Figure 5: True shooting percentage vs Winning percentage
fig5 = ggplot(nba_data, aes(x = ts_pct, y = win_pct)) +
  geom_point(alpha = 0.7, size = 2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1) +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "True Shooting Percentage and Winning Percentage",
    subtitle = "Scoring efficiency is strongly associated with team success.",
    x = "True Shooting Percentage",
    y = "Winning Percentage",
    caption = "Source: Basketball Reference and HoopsHype"
  )

ggsave(
  filename = "output/figures/fig5_tspct_vs_winpct.png",
  plot = fig5,
  width = 9,
  height = 6,
  dpi = 300
)


# Figure 6: League trend in three-point attempt rate
# show how nba strategy has changed over time
league_trend = nba_data |>
  group_by(season) |>
  summarize(avg_three_par = mean(three_par, na.rm = TRUE), .groups = "drop")

fig6 = ggplot(league_trend, aes(x = season, y = avg_three_par)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = league_trend$season) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "League-Wide Growth in Three-Point Attempt Rate",
    subtitle = "The average NBA team has steadily increased its share of shots from three.",
    x = "Season",
    y = "Average Three-Point Attempt Rate",
    caption = "Source: Basketball Reference and HoopsHype"
  )

ggsave(
  filename = "output/figures/fig6_league_3par_trend.png",
  plot = fig6,
  width = 9,
  height = 6,
  dpi = 300
)


# display of plots
fig1
fig2
fig3
fig4
fig5
fig6
