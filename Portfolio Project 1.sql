SELECT *
FROM covidDeaths
WHERE continent IS NOT NULL --We added this bcz thee were places below in the column in which continent name was in loaction as it was causing trouble as groupig continents aslocation --me
ORDER BY 3,4

SELECT *
FROM covidDeaths
WHERE continent IS NULL --This Gives us where the loaction is set to continent name like the whole continent included --me
ORDER BY 3,4

SELECT *
FROM CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3,4 --(this means order the table by 3rd and 4th column and by default it orders is ascending) --me

--SELECTING DATA WE ARE USING 

SELECT location,date, total_cases, new_cases, total_deaths, population
FROM covidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Looking at total cases vs total deaths
--Shows Likelihood of dying if you contract covid in your country

SELECT location,date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 AS deathPer
FROM covidDeaths
WHERE location = 'Pakistan'
ORDER BY 1,2


--Looking at the total cases vs population
--Shows What percentage got covid

SELECT location,date, population, total_cases, (total_cases/population)*100 AS AffectedPercentage
FROM covidDeaths
WHERE location = 'Pakistan'
ORDER BY 1,2

--Looking at countries with Highest infection rates compared to population 

SELECT location, 
       population, 
       MAX(total_cases) AS HighestInfectionCount, 
       MAX((total_cases/population))*100 AS InfectionCountPercent
FROM covidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectionCountPercent DESC

-- Showing the countries with the highest death count per population

SELECT location, population, max(total_cases), max(total_deaths) AS HighestDeathRate
FROM covidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY HighestDeathRate DESC  --this query is correct i did it on my own by there is another query

SELECT location, max(total_deaths) AS HighestDeathCount
FROM covidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeathCount DESC   --In this output we see a problem that it is grouping continents too

--To change a data type we use cast function as :
--CAST(total_deaths as int)

--LET'S BREAK THINGS DOWN BY CONTITNENT

SELECT continent, max(total_deaths) AS HighestDeathCount
FROM covidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC  --It doesnt gives us the right results so ...

SELECT location, max(total_deaths) AS HighestDeathCount
FROM covidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY HighestDeathCount DESC

--Looking for continents for highest death count per population

SELECT continent,population, max(total_deaths) AS HighestDeathCount
FROM covidDeaths
WHERE continent IS NOT NULL
GROUP BY continent,population
ORDER BY HighestDeathCount DESC  --We took the wring one I know

--GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths
FROM covidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2  --This one tells by date so to see it altogether we have to remove the date

SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths
FROM covidDeaths
WHERE continent IS NOT NULL --It will give all deaths and total cases

--CovidVaccinations

SELECT *
FROM covidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
ORDER BY 3,4

--Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rollingPeopleVaccinated
FROM covidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Now we want to know the percentage of people vaccinated so we need to devide the new column we just made to the population but we can't just use the column we just created as it is in a diff query so we will store it into cte first

--Using CTE (COMMON TABLE EXPRESSION)

WITH PopVsVac (continent, location, date, population, new_vaccinations,rollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rollingPeopleVaccinated
FROM covidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--The order by clause is invalid in ctes
)
-- Now we can use the rolling column in further calculations 
SELECT *, (rollingPeopleVaccinated/population)*100 
FROM PopVsVac 

--Using Temp Table (It will give the same result as above)

DROP TABLE IF EXISTS #PercentPopulationVaccinated --We added this because everytime we alter this and try to run again it will give error that the temp table already exist so we drop it everytime and then run
CREATE TABLE #PercentPopulationVaccinated 
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rollingPeopleVaccinated
FROM covidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (rollingPeopleVaccinated/population)*100 AS Percentage
FROM #PercentPopulationVaccinated 

--Creating View for later data visualiztion

CREATE VIEW PopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rollingPeopleVaccinated
FROM covidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * 
FROM PopulationVaccinated
