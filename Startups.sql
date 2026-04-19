/* ============================================================
PROJECT: Global Startup Investment Analysis
============================================================ */

-- Data preparation 

ALTER TABLE "global_startup_success_dataset.csv" RENAME COLUMN "TotalFunding($M)" TO total_funding;
ALTER TABLE "global_startup_success_dataset.csv" RENAME COLUMN "Valuation($B)" TO valuation;
ALTER TABLE "global_startup_success_dataset.csv" RENAME COLUMN "numberofemployees" TO employee_count;

ALTER TABLE "global_startup_success_dataset.csv" 
ALTER COLUMN total_funding TYPE numeric USING (REPLACE(REPLACE(REPLACE(REPLACE(total_funding::text, '{', ''), '}', ''), '$', ''), ',', ''))::numeric,
ALTER COLUMN valuation TYPE numeric USING (REPLACE(REPLACE(REPLACE(REPLACE(valuation::text, '{', ''), '}', ''), '$', ''), ',', ''))::numeric,
ALTER COLUMN employee_count TYPE numeric USING (REPLACE(REPLACE(employee_count::text, '{', ''), '}', ''))::numeric;

UPDATE "global_startup_success_dataset.csv"
SET country = TRIM(REPLACE(REPLACE(country::text, '{', ''), '}', '')),
    industry = TRIM(REPLACE(REPLACE(industry::text, '{', ''), '}', ''));

--------------------------------------------------------------------------------------------------

-- 1. Capital Efficiency 
SELECT 
    country,
    ROUND(AVG(total_funding), 2) AS avg_funding_millions,
    ROUND(SUM(total_funding) / NULLIF(SUM(employee_count), 0), 2) AS funding_per_employee
FROM "global_startup_success_dataset.csv"
GROUP BY country
HAVING COUNT(*) > 5
ORDER BY funding_per_employee DESC;

-- 2. Top 3 Market Leaders by Country 
SELECT country, startupname, industry, total_funding, funding_rank
FROM (
    SELECT 
        country, startupname, industry, total_funding,
        DENSE_RANK() OVER (PARTITION BY country ORDER BY total_funding DESC) as funding_rank
    FROM "global_startup_success_dataset.csv"
) ranked_table
WHERE funding_rank <= 3
ORDER BY country, funding_rank;

-- 3. Industry Market Share Percentage per Country
SELECT 
    country, 
    industry, 
    ROUND(SUM(total_funding), 2) AS industry_funding,
    ROUND((SUM(total_funding) / SUM(SUM(total_funding)) OVER(PARTITION BY country)) * 100, 2) AS market_share_percentage
FROM "global_startup_success_dataset.csv"
GROUP BY country, industry
ORDER BY country, market_share_percentage DESC;

-- 4. Success Probability (Exit Rate per Industry)
SELECT 
    industry,
    COUNT(*) AS total_startups,
    SUM(CASE WHEN "Acquired?"::text LIKE '%Y%' OR "IPO?"::text LIKE '%Y%' THEN 1 ELSE 0 END) AS total_exits,
    ROUND(AVG(CASE WHEN "Acquired?"::text LIKE '%Y%' OR "IPO?"::text LIKE '%Y%' THEN 100.0 ELSE 0.0 END), 2) AS success_rate_percentage
FROM "global_startup_success_dataset.csv"
GROUP BY industry
ORDER BY total_exits DESC;

-- 5. Strategic Management Correlation 
SELECT 
    m."Management Focus", 
    COUNT(s.startupname) AS startup_count,
    ROUND(AVG(s.total_funding), 2) AS avg_funding
FROM "global_startup_success_dataset.csv" s
JOIN "Mapping.csv" m ON s.fundingstage = m."Funding Stage"
GROUP BY m."Management Focus"
ORDER BY avg_funding DESC;

SELECT * FROM "global_startup_success_dataset.csv";