SELECT * FROM Public."CovidDeaths"
ORDER BY 3,4;


--SELECTING data we will be using 
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Public."CovidDeaths"
ORDER BY 1,2;

--Looking at total cases vs Total Deaths
--Shows likelihood of dying if contracting COVID in your country
SELECT Location, date, total_cases, total_deaths, ((CAST(total_deaths AS float))/(CAST(total_cases AS float)))*100 DeathPercentage
FROM Public."CovidDeaths"
ORDER BY 1,2;

--Looking at USA
SELECT Location, date, total_cases, total_deaths, ((CAST(total_deaths AS float))/(CAST(total_cases AS float)))*100 DeathPercentage
FROM Public."CovidDeaths"
WHERE location ILIKE '%states%'
ORDER BY 1,2;


--Looking at Total Cases vs Population
--Shows percentage of population in USA got COVID-19 at some point

SELECT Location, date, Population, total_cases, ((CAST(total_cases AS float))/(CAST(population AS float)))*100 PercentPopulationInfected
FROM Public."CovidDeaths"
WHERE location ILIKE '%states%'
ORDER BY 1,2;


--Looking at countries with highest infection rate compared to their population
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((CAST(total_cases AS float))/(CAST(population AS float)))*100 PercentPopulationInfected
FROM Public."CovidDeaths"
GROUP BY Location, Population
ORDER BY 4 DESC;

--Showing countries with the highest death count per population
SELECT location, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM Public."CovidDeaths"
WHERE Total_deaths IS NOT null AND continent IS NOT null
GROUP BY location
ORDER BY TotalDeathCount DESC;


--BREAKING THINGS DOWN BY CONTINENT


--Showing continents with the highest death count per population
SELECT location, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM Public."CovidDeaths"
WHERE continent IS null --location is the continent when continent column is null
GROUP BY location
ORDER BY TotalDeathCount DESC;


SELECT continent, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM Public."CovidDeaths"
WHERE continent IS NOT null 
GROUP BY continent
ORDER BY TotalDeathCount DESC;



--GLOBAL NUMBERS

--By date
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, 
SUM(CAST(New_deaths AS FLOAT))/SUM(CAST(New_cases AS FLOAT))*100 AS DeathPercentage
FROM Public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

--Total
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, 
SUM(CAST(New_deaths AS FLOAT))/SUM(CAST(New_cases AS FLOAT))*100 AS DeathPercentage
FROM Public."CovidDeaths"
WHERE continent IS NOT NULL
ORDER BY 1,2;


--Looking at Total Population vs Vaccinations

--Rolling count of new vax by country
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (Partition BY dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM Public."CovidDeaths" dea
JOIN Public."CovidVaccinations" vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;


--Using CTE to find percent of people vaccinated on a given day by country
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (Partition BY dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM Public."CovidDeaths" dea
JOIN Public."CovidVaccinations" vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (CAST(RollingPeopleVaccinated AS FLOAT))/(CAST(Population AS FLOAT))*100
FROM PopVsVac;



--Using a TEMP table to achieve same goal
DROP TABLE if exists PercentPopulationVaccinated;
CREATE TEMP TABLE PercentPopulationVaccinated
(
Continent char (255),
Location char(255),
Date date,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);


INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (Partition BY dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM Public."CovidDeaths" dea
JOIN Public."CovidVaccinations" vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, (CAST(RollingPeopleVaccinated AS FLOAT))/(CAST(Population AS FLOAT))*100
FROM PercentPopulationVaccinated;


--Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (Partition BY dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM Public."CovidDeaths" dea
JOIN Public."CovidVaccinations" vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
--ORDER BY 2,3;
