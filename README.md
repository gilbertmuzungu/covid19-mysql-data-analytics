# 🦠 COVID-19 Data Analysis with MySQL

This project explores COVID-19 trends using structured SQL queries on global  data. It includes analysis on case growth, mortality rates, vaccination rollout, and infection patterns using MySQL features such as `JOIN`, `CTE`, `WINDOW FUNCTIONS`, and `AGGREGATION`.

---

## 📊 Project Objectives

- Analyze new cases, total deaths, and population impacts globally and in Kenya
- Track mortality rates, doubling rates, and vaccine coverage
- Detect weekly and daily trends (spikes, drops, and rolling averages)
- Visualize and prepare data for dashboards or further analytics

---

## 🔧 Tools & Technologies

- **Language:** SQL (MySQL syntax)
- **Database:** COVID-19 public dataset (Our World With Data)
- **Environment:** MySQL Workbench 
- **Platform (for hosting):** GitHub

---

## 🗂️ Datasets Used

- `coviddeaths`: Contains COVID-19 case and death information
- `covidvaccinations`: Contains vaccination-related data by country

Both tables are joined on `location` and `date` to produce cumulative insights.

---

## 🧠 Key SQL Concepts Applied

| Category            | Skills Used                                   |
|---------------------|-----------------------------------------------|
| **Data Exploration** | `SELECT`, `WHERE`, `ORDER BY`, `GROUP BY`    |
| **Joins**           | `INNER JOIN` on date and location             |
| **Aggregation**     | `SUM()`, `AVG()`, `MAX()`, `MIN()`, `COUNT()` |
| **Window Functions**| `LAG()`, `LEAD()`, `ROW_NUMBER()`, `OVER()`   |
| **CTEs**            | `WITH` clause for breaking complex logic      |
| **Views**           | `CREATE VIEW` for reusable outputs            |
| **Trend Detection** | Rolling averages, growth factors, doubling rate|

---

## 📈 Insights Generated

✅ 7-day rolling average of new cases  
✅ Growth factor of infections  
✅ Doubling rate of deaths  
✅ Vaccination coverage by population  
✅ Kenya-specific trend monitoring  
✅ Global rankings by infection and death rates  
✅ Detection of recovery phases  
✅ Invalid or missing data checks

---

## 📌 Sample Queries

- Total deaths per million
- Countries with highest percent of population infected
- New cases vs. population
- First recovery milestone (cases < 100)
- Vaccine coverage across continents

---
# covid19-mysql-data-analytics
SQL-based data analysis of global COVID-19 trends trends, including case progression, death rates, and vaccination rollout using MySQL.
