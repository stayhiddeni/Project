SELECT *
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2

-- looking at total cases vs population
-- shows that percentage of population got covid

SELECT Location, date, Population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
WHERE Location LIKE '%states%'
AND continent IS NOT NULL
ORDER BY 1,2

-- looking at countries with highest infection rate compared to population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
-- WHERE Location LIKE '%states%'
-- WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

SELECT Location, Population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
-- WHERE Location LIKE '%states%'
-- WHERE continent IS NOT NULL
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC

-- showing countries with highest death count per population

SELECT Location, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
-- WHERE Location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- let's break things down by continent

SELECT continent, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
-- WHERE Location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- the table didn't include Canada bc of "not null", so try "is null"

SELECT location, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
-- WHERE Location LIKE '%states%'
WHERE continent IS NULL
AND location NOT IN ('World', 'Upper middle income', 'High income', 'Lower middle income', 'European Union', 'Low income', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- showing continents with the highest death count per population

SELECT continent, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
-- WHERE Location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- global numbers

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as INT)) as total_deaths, SUM(CAST(new_deaths as INT))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2

-- looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
	-- or CONVERT(bigint, vac.newvaccinations), the sum value now has exceeded 2,147,483,647 so instead of converting it to "int", will need to convert to "bigint"
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- USE CTE

WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
AS(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
	-- or CONVERT(bigint, vac.newvaccinations), the sum value now has exceeded 2,147,483,647 so instead of converting it to "int", will need to convert to "bigint"
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- TEMP TABLE

DROP TABLE IF exists #PercentaPopulationVaccinated
CREATE TABLE #PercentaPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentaPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
	-- or CONVERT(bigint, vac.newvaccinations), the sum value now has exceeded 2,147,483,647 so instead of converting it to "int", will need to convert to "bigint"
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentaPopulationVaccinated

-- creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
	-- or CONVERT(bigint, vac.newvaccinations), the sum value now has exceeded 2,147,483,647 so instead of converting it to "int", will need to convert to "bigint"
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated