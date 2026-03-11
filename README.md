# ecns460-nba-analytics-dashboard
ECNS 460 Advanced Data Analytics Project: NBA Team Performance Dashboard

# ECNS 460 Project: NBA Analytics Dashboard

## Author
Evan Donch

---

## Topic
This project focuses on NBA team performance analytics. The goal is to explore how different team statistics and financial factors relate to winning in the NBA and to create a tool that allows users to interactively analyze team performance.

---

## Product Plan

### Goal
The goal of this project is to build an interactive NBA analytics dashboard that allows users to explore relationships between team statistics, team payroll, and winning.

### Intended Audience
This dashboard is intended for:

- NBA fans  
- Sports analysts  
- Students interested in basketball analytics  

### Product Description
The final product will be an interactive web dashboard built using **R Shiny**.

The dashboard will allow users to:

- Select an NBA season  
- Choose teams to compare  
- Visualize how team statistics and payroll relate to winning  
- Explore trends across the league over time  

Example visualizations may include:

- Win percentage vs offensive rating  
- Three-point attempts vs winning  
- Win percentage vs team payroll  

---

## Challenge
The primary challenge for this project will be learning how to build an interactive Shiny web application, which is a new tool for me.

This will involve learning how to:

- Build user interface (UI) layouts  
- Create reactive plots and visualizations  
- Connect user inputs to dynamic outputs  
- Deploy an interactive data product  

---

## Datasets

### Dataset 1: NBA Team Statistics
**Source:** Basketball Reference  
https://www.basketball-reference.com/

This dataset contains NBA team performance statistics such as:

- Team  
- Season  
- Wins  
- Losses  
- Offensive rating  
- Defensive rating  
- Rebounds  
- Turnovers  
- Shooting percentages  

**Timespan:** Multiple NBA seasons  
**Coverage:** All NBA teams

---

### Dataset 2: NBA Team Payroll
**Source:** HoopsHype  
https://hoopshype.com/salaries/teams/

This dataset contains financial information about NBA teams including:

- Team payroll totals by season

**Timespan:** Multiple NBA seasons with yearly payroll totals  
**Coverage:** All NBA teams

---

## Relationship Between Datasets
Both datasets contain the variables **team** and **season**, which allows them to be merged into a single dataset. After merging, each observation will represent a **team-season**, allowing users to explore how team performance statistics and payroll relate to winning.
