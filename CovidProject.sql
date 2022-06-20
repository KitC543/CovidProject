-- Confirming data imported

SELECT *
FROM CovidProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1,2

SELECT *
FROM CovidProject.dbo.CovidVaccinations
WHERE continent is not null
ORDER BY 1,2


-- Looking at Total Cases vs. Total Deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM CovidProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Looking at Total Cases vs population

SELECT location, date, population, total_cases, (total_cases/population)*100 
FROM CovidProject..CovidDeaths
ORDER BY 1,2


-- Looking at countries with highest infection rates compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentageofPopulationInfected 
FROM CovidProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentageofPopulationInfected DESC


-- Showing the countries with highest death count per population

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY TotalDeathCount DESC

 
 -- Breaking down by continent

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Showing the continents with highest death count

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Global numbers

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2


-- Vaccinations
-- Total population vs. Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location)
FROM CovidProject..CovidDeaths dea  -- used to specify which tables
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Can use CONVERT rather than CAST to convert to int
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
as RollingPeopleVaccinated, (RollingPeopleVaccinated/population)*100
FROM CovidProject..CovidDeaths dea  -- used to specify which tables
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Use CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
as RollingPeopleVaccinated 
--(RollingPeopleVaccinated/population)*100
FROM CovidProject..CovidDeaths dea  -- used to specify which tables
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac


-- Temp table

DROP TABLE IF exists #PercentPopulationVaccinated  --
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
as RollingPeopleVaccinated 
--(RollingPeopleVaccinated/population)*100
FROM CovidProject..CovidDeaths dea  -- used to specify which tables
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated



-- Creating View to store data for later visualisations

CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
as RollingPeopleVaccinated 
--(RollingPeopleVaccinated/population)*100
FROM CovidProject..CovidDeaths dea  -- used to specify which tables
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

-- Can now use this View for further calculations or later visualisations
SELECT *
FROM PercentPopulationVaccinated