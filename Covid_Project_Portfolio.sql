
/*
Covid 19 Data Exploration

Skills Used: Data Cleaning & Quality Checks,Data Exploration & Aggregation,Window Functions ,Joins,CTEs (Common Table Expressions),Views (Reusable SQL Logic),Analytical Thinking,Problem Solving,Trend Detection & Metrics Design,Data Visualization Preparation.

*/




-- Retrieve all data from the coviddeaths table
-- Sorted by country name and date (columns 3 and 4) to view trends over time

Select *
from coviddeaths
order by 3,4;

-- Retrieve all data from the covidvaccinations table
-- Sorted by country name and date (columns 3 and 4) for time-series analysis

Select *
from covidvaccinations
order by 3,4;

-- select Data that we are going to be using

Select location,date,new_cases,total_deaths,population
from coviddeaths
order by 1,2;

-- Identifying duplicate rows
-- Identify duplicate entries in the coviddeaths table
-- Groups data by date and location, and counts occurrences
-- Returns only those combinations where more than one record exists 

SELECT date, location, COUNT(*) AS count
FROM coviddeaths
GROUP BY date, location
HAVING COUNT(*) > 1;

-- Detect invalid or negative values
-- Identify invalid or suspicious records where reported new cases or deaths are negative
-- Negative values are not logically valid in epidemiological reporting
-- These could indicate data entry errors or corrections in source data
-- Useful for cleaning or flagging issues before analysis

SELECT *
FROM coviddeaths
WHERE new_cases < 0 OR new_deaths < 0;

-- Check for date Inconsistencies
-- Check the date range of available data for each location
-- Retrieves the earliest (MIN) and latest (MAX) reported dates per country/region
-- Useful for identifying inconsistencies or missing time periods in the dataset

SELECT location, MIN(date) AS first_reported_date, MAX(date) AS last_reported_date
FROM coviddeaths
GROUP BY location;

-- Verify Geographic Hierarchies
-- Ensure each location maps to a valid continent
SELECT location, COUNT(DISTINCT continent) AS continent_count
FROM coviddeaths
GROUP BY location
HAVING continent_count > 1;

-- Spot Columns with Too Many Nulls
-- Calculate the percentage of missing (NULL) values in key columns of the coviddeaths table
-- Specifically checks total_deaths and population columns
-- Helps assess data quality and determine whether columns are usable for analysis

SELECT
 ROUND(SUM(CASE WHEN total_deaths IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_null_total_deaths,
  ROUND(SUM(CASE WHEN population IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_null_population
FROM coviddeaths;

-- Standardize or Validate Population Data
-- Check for inconsistencies in population data for each location
-- Counts how many unique population values exist per location
-- Returns only those locations where population varies over time (which ideally shouldn't happen)

SELECT location, COUNT(DISTINCT population) AS unique_population_entries
FROM coviddeaths
GROUP BY location
HAVING unique_population_entries > 1;

-- Find Outliers in Cases
-- Identify unusually high spikes in new COVID-19 cases
-- Filters records where new_cases is greater than 0
-- Orders results by new_cases in descending order to highlight the largest daily case counts first

SELECT *
FROM coviddeaths
WHERE new_cases > 0
ORDER BY new_cases DESC
LIMIT 10;

-- Peak periods of new infections or deaths by country
-- Identify the day with the highest number of new COVID-19 cases for each country
-- Filters out entries where continent is NULL (i.e., excludes summary/global records)
-- Uses a correlated subquery to compare each row's new_cases value to the max for that country
-- Orders by new_cases in descending order to show countries with the highest peaks at the top

SELECT location, date, new_cases
FROM coviddeaths
WHERE continent IS NOT NULL
AND new_cases =
 (
  SELECT MAX(new_cases)
  FROM coviddeaths AS sub
  WHERE sub.location = coviddeaths.location
)
ORDER BY new_cases DESC;

 
-- monthly average of new cases globally
-- Calculate the global monthly average of new COVID-19 cases
-- Converts each date to 'YYYY-MM' format to group by month
-- Averages new_cases per month across all locations
-- Filters out NULL values to ensure accurate averages
-- Results are ordered chronologically

SELECT STRFTIME('%Y-%m', date) AS month,
       AVG(new_cases) AS avg_monthly_cases
FROM coviddeaths
WHERE new_cases IS NOT NULL
GROUP BY month
ORDER BY month;

-- Detect weeks with rising new cases (acceleration)
-- Analyze changes in daily new COVID-19 cases for Kenya
-- Uses LAG window function to retrieve the previous day's new cases
-- Calculates the difference between current and previous day's cases (change_in_cases)
-- Helps detect days with rising or falling case trends

SELECT 
  date,
  location,
  new_cases,
  LAG(new_cases) OVER (PARTITION BY location ORDER BY date) AS prev_day_cases,
  (new_cases - LAG(new_cases) OVER (PARTITION BY location ORDER BY date)) AS change_in_cases
FROM coviddeaths
WHERE location = 'Kenya'
  AND new_cases IS NOT NULL
ORDER BY date;

-- Total number of deaths globally
SELECT  SUM(total_deaths) AS total_deaths_global
       FROM coviddeaths;
       
-- Infetion Multiplication rate
-- Approximate how quickly infections multiplied every X days
-- Cases 7 days apart to approximate growth factor
-- Estimate the weekly growth factor of COVID-19 new cases in Kenya
-- Uses LAG to compare current day's cases with cases reported 7 days earlier
-- Calculates growth_factor = current new_cases / new_cases from 7 days ago
-- ROUND is used for readability; NULLIF prevents division by zero
-- Helps approximate how rapidly infections are increasing week over week

SELECT 
  location, 
  date,
  new_cases,
  LAG(new_cases, 7) OVER (PARTITION BY location ORDER BY date) AS cases_last_week,
  ROUND(
    new_cases * 1.0 / NULLIF(LAG(new_cases, 7) OVER (PARTITION BY location ORDER BY date), 0),
    2
  ) AS growth_factor
FROM coviddeaths
WHERE location = 'Kenya'
ORDER BY date;

-- Days it took for death count to double
-- Estimate how quickly total deaths from COVID-19 doubled in Kenya
-- Use a CTE (common table expression) to calculate previous day's total_deaths
-- Calculate the growth_multiplier = current total_deaths / previous total_deaths
-- A value around 2.0 indicates the death count has doubled since the last entry
-- NULLIF avoids division by zero

-- Days it took for death count to double in Kenya

WITH ranked AS (
    SELECT
        date,
        total_deaths,
        LAG(total_deaths) OVER (PARTITION BY location ORDER BY date) AS prev_deaths
    FROM coviddeaths
    WHERE location = 'Kenya'
)
SELECT
    date,
    total_deaths,
    ROUND(total_deaths * 1.0 / NULLIF(prev_deaths, 0), 2) AS growth_multiplier
FROM ranked
WHERE prev_deaths IS NOT NULL
ORDER BY date;




-- looking at total_deaths vs new_cases
-- showing the likelihood of dying if you contract covid
-- Compare new COVID-19 cases to total deaths to estimate death likelihood
-- Calculates a crude case fatality rate: (total_deaths / new_cases) * 100
-- Filters for locations containing 'states' (e.g., United States)


Select location,date,new_cases,total_deaths,(total_deaths/new_cases)*100 AS Deathpercentage
from coviddeaths
where location like '%states%'
order by 1,2;

-- looking at new_cases vs population
-- Estimate the percentage of Africa's population infected daily by COVID-19
-- Calculates (new_cases / population) * 100 to get daily infection rate as a percentage
-- Filters for the 'Africa' region only
-- Helps assess the scale of daily infections relative to population size


Select location,date,new_cases,population,(new_cases/population)*100 AS percentpopulationinfected
from coviddeaths
where location = 'Africa'
order by 1,2;

-- Daily new cases from kenya
-- Retrieve daily reported new COVID-19 cases in Kenya
-- Filters data to only include records where location is 'Kenya'
-- Orders results chronologically to observe case trends over time

SELECT date, new_cases
FROM coviddeaths
WHERE location = 'Kenya'
ORDER BY date;

-- 7-day moving average for Kenya
-- Calculate the 7-day moving average of new COVID-19 cases for Kenya
-- Uses a window function to average new_cases over the current day and the 6 previous days
-- Helps smooth out daily spikes and identify underlying infection trends
-- Partitioned by location in case more countries are included later

SELECT 
    date, 
    ROUND(
        AVG(new_cases) OVER (
            PARTITION BY location 
            ORDER BY date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS rolling_avg_cases
FROM coviddeaths
WHERE location = 'Kenya'
ORDER BY date;

         


-- Total deaths per million people
-- Calculate total COVID-19 deaths per million people by country
-- Uses MAX(total_deaths) and MAX(population) to get final cumulative values per country
-- Filters out entries where continent is NULL (to exclude global/aggregate data)
-- Groups by location and orders results by deaths_per_million in descending order
-- This allows fair comparison between countries of different population sizes

SELECT location,
    MAX(total_deaths) / MAX(population) * 1000000 AS deaths_per_million   
	FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY deaths_per_million DESC;


-- looking at countries with highest new_cases compared to population
-- Identify countries with the highest single-day infection spike relative to population
-- MAX(new_cases) gives the highest number of new cases reported in a single day per country
-- MAX(new_cases / population) estimates the highest one-day infection rate as a percentage
-- Groups by country and population, then orders by percent infected in descending order
-- Highlights countries with most intense transmission events


select location,population, MAX(new_cases) AS Highestinfectioncount,MAX(new_cases/population) AS percentpopulationinfected
From coviddeaths
Group by location,population
order by percentpopulationinfected desc;

-- showing countries with Highest death count per population
-- Show the top 10 countries with the highest total COVID-19 death counts
-- Uses MAX(total_deaths) to capture final cumulative death totals per country
-- Excludes aggregate rows like "World" or continents by filtering where continent IS NOT NULL
-- Groups by country and orders in descending order of deaths
-- LIMIT 10 restricts the result to the top 10 most affected countries

select location, MAX(total_deaths) AS TotalDeathCount
From coviddeaths
where continent is not null
group by location
order by TotalDeathCount desc
limit 10;

-- First date when new cases dropped below 100 after a peak
-- Identify the first date when daily new COVID-19 cases dropped below 100 for each country
-- Filters rows where new_cases < 100
-- Uses MIN(date) to get the earliest such date per country
-- Helps approximate when a country may have begun recovery after major peaks

SELECT location, MIN(date) AS recovery_start
FROM coviddeaths
WHERE new_cases < 100 
GROUP BY location;

-- Count how many days it took for Kenya’s cases to drop by 50% from peak
-- Calculate the first date when Kenya's daily new COVID-19 cases dropped to 50% of its peak
-- CTE 'peak' finds the highest new_cases value (peak) in Kenya
-- CTE 'decline' finds all dates where new_cases were <= half of that peak
-- Final SELECT finds the earliest such date (MIN(date)) indicating the start of decline

WITH peak AS (
    SELECT MAX(new_cases) AS peak_cases
    FROM coviddeaths
    WHERE location = 'Kenya'
),
decline AS (
    SELECT date, new_cases
    FROM coviddeaths
    WHERE location = 'Kenya'
      AND new_cases <= (SELECT peak_cases / 2 FROM peak)
)
SELECT MIN(date) AS start_of_decline
FROM decline;



-- Lets break things by Continent
-- Show the highest reported total COVID-19 deaths per continent
-- Filters out global or null entries by ensuring continent IS NOT NULL
-- Groups by continent and uses MAX(total_deaths) to show the highest reported figure per continent
-- Orders the result from most to least affected

SELECT continent, 
       MAX(total_deaths) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Showing the Continents with the highest death count
-- Display the maximum total COVID-19 deaths recorded for each continent
-- Filters out any records where continent is NULL
-- Groups the data by continent
-- Uses MAX(total_deaths) to show the highest recorded death count per continent
-- Orders results in descending order to highlight most affected continents

select continent, MAX(total_deaths) AS TotalDeathCount
From coviddeaths
where continent is not  null
group by continent
order by TotalDeathCount desc;

-- Cases and deaths aggregated by continent
-- Aggregate total new COVID-19 cases and deaths by continent
-- Filters out rows without a continent value
-- Uses SUM() to total all reported new_cases and new_deaths per continent
-- Groups the data by continent for comparative analysis

SELECT continent,
       SUM(new_cases) AS total_new_cases,
       SUM(new_deaths) AS total_new_deaths
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent;

-- Global Numbers
-- Show global daily total of new COVID-19 cases and deaths
-- Filters out entries without continent data to avoid world/aggregate rows
-- Groups data by date to track daily global totals
-- Sums new_cases and new_deaths across all countries per date
-- Multiplies deaths by 100 — possibly for visualization emphasis or scaling

Select date,Sum(new_cases),sum(new_deaths)*100 
from coviddeaths
where continent is not null
Group by date
order by 1,2;

-- Explore_COVIDvaccination_table
-- Retrieve all columns from the covidvaccinations table for exploratory analysis

select *
from covidvaccinations;

-- Lets join coviddeaths table with covidvaccinations table
-- looking at total population vs vaccinations
-- Join coviddeaths and covidvaccinations on location and date
-- Analyze vaccination rollout by tracking cumulative vaccinations per country
-- Shows: continent, country, date, population, daily vaccinations, and running total of vaccinations
-- Filters out rows without continent data (to remove global/aggregated rows)
-- Uses a window function (SUM OVER PARTITION BY) to calculate cumulative vaccinations per country over time



SELECT 
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations) OVER (
        PARTITION BY cd.location 
        ORDER BY cd.date
    ) AS RollingPeopleVaccinated
FROM coviddeaths AS cd
JOIN covidvaccinations AS cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, cd.date;


-- Vaccination vs Mortality rate
-- Compare total COVID-19 deaths with total vaccinations per country
-- Joins coviddeaths and covidvaccinations tables on both location and date
-- Aggregates data using MAX() to get final total deaths and vaccinations for each country
-- Calculates a ratio: total deaths divided by total vaccinations
-- NULLIF prevents division by zero in case of missing vaccination data

SELECT cd.location,
       MAX(cd.total_deaths) AS total_deaths,
       MAX(cv.total_vaccinations) AS total_vaccinations,
       ROUND(MAX(cd.total_deaths) * 1.0 / NULLIF(MAX(cv.total_vaccinations), 0), 4) AS deaths_per_vaccine_ratio
FROM coviddeaths AS cd
JOIN covidvaccinations  AS cv
  ON cd.location = cv.location AND cd.date = cv.date
GROUP BY cd.location
ORDER BY deaths_per_vaccine_ratio;

-- Track Kenya’s Vaccine Rollout vs. Case Trajectory
-- Analyze Kenya’s daily COVID-19 cases, deaths, and vaccinations
-- Joins coviddeaths and covidvaccinations tables on date and location
-- Filters for Kenya only
-- Displays how new_cases, new_deaths, and new_vaccinations evolved over time
-- Helps observe trends and possible effects of vaccination rollout on case/death numbers

SELECT cd.date,
       cd.new_cases,
       cd.new_deaths,
       cv.new_vaccinations
FROM coviddeaths  AS cd
JOIN covidvaccinations AS cv
  ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.location = 'Kenya'
ORDER BY cd.date;

-- Vaccines per Capita by Country
-- Calculates the percentage of each country’s population that has received at least one COVID-19 vaccine dose
-- Joins coviddeaths and covidvaccinations on location and date
-- Uses MAX() to get the latest total_vaccinations and population values per country
-- Results are sorted in descending order of vaccination coverage

SELECT cd.location,
       MAX(cv.total_vaccinations) / MAX(cd.population) * 100 AS vaccination_coverage_pct
FROM coviddeaths AS cd
JOIN covidvaccinations  AS cv
  ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
GROUP BY cd.location
ORDER BY vaccination_coverage_pct DESC;




-- Use CTE
-- Using a Common Table Expression (CTE) to calculate cumulative vaccinations per country over time
-- popvsvac CTE: joins coviddeaths and covidvaccinations on date and location
-- Includes: continent, country, date, population, daily vaccinations, and a rolling (cumulative) count of people vaccinated
-- Filters out global or aggregate rows by excluding null continents
-- Final SELECT pulls all data from the popvsvac CTE


WITH popvsvac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated) AS (
    SELECT 
        cd.continent,
        cd.location,
        cd.date,
        cd.population,
        cv.new_vaccinations,
        SUM(cv.new_vaccinations) OVER (
            PARTITION BY cd.location 
            ORDER BY cd.date
        ) AS rolling_people_vaccinated
    FROM coviddeaths AS cd
    JOIN covidvaccinations AS cv
        ON cd.location = cv.location
        AND cd.date = cv.date
    WHERE cd.continent IS NOT NULL
)

SELECT * 
FROM popvsvac;


-- Creating view to store data for later visualization
-- Create a SQL view that stores cumulative vaccination progress by country
-- Joins coviddeaths and covidvaccinations tables using location and date
-- Tracks daily vaccinations and computes a running total per country
-- Includes population data to later calculate vaccination coverage
-- Filters out records without a valid continent (removing global aggregates)
-- View can be used for dashboards or further queries without repeating logic



CREATE VIEW totalpopulationvaccinated AS
SELECT 
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations) OVER (
        PARTITION BY cd.location 
        ORDER BY cd.date
    ) AS rolling_people_vaccinated
FROM coviddeaths AS cd
JOIN covidvaccinations AS cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;

SELECT *
FROM totalpopulationvaccinated
ORDER BY location, date;










