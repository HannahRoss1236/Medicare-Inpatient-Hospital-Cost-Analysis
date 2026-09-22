Analysis
--total Discharges and total payments by DRG code and by year 2024
\set yr 2024
SELECT d.drg_code, d.drg_description,
       SUM(f.discharges) AS discharges,
       ROUND(SUM(f.total_payments)) AS total_payments
FROM analytics.fact_inpatient f
JOIN analytics.dim_drg d USING (drg_code)
WHERE f.data_year = :yr
GROUP BY 1, 2
ORDER BY total_payments DESC
LIMIT 10;

--by state the total discharges and the charge the hospital is charging versus the payment ratio
SELECT p.state,
       SUM(f.discharges) AS discharges,
       ROUND(SUM(f.total_charges) / SUM(f.total_payments), 2) AS charge_to_payment_ratio
FROM analytics.fact_inpatient f
JOIN analytics.dim_provider p USING (provider_id)
WHERE f.data_year = :yr
GROUP BY 1
ORDER BY charge_to_payment_ratio DESC;

--the minimum, maximum, and median total payment from each hopsital with a count of over 50 discharges  
SELECT f.drg_code, d.drg_description,
    COUNT(*) AS hospitals,
    ROUND(MIN(f.avg_total_payment)) AS min_pay,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.avg_total_payment)::numeric) AS median_pay,
    ROUND(MAX(f.avg_total_payment)) AS max_pay,
    ROUND(MAX(f.avg_total_payment) / NULLIF(MIN(f.avg_total_payment), 0), 1) AS max_min_ratio
FROM analytics.fact_inpatient f
JOIN analytics.dim_drg d USING (drg_code)
WHERE f.data_year = :yr AND f.discharges >= 11
GROUP BY 1, 2
HAVING COUNT(*) > 50
ORDER BY max_min_ratio DESC
LIMIT 15;

--average payment by the total payments and the total number of discharges by the procedure 
WITH yearly AS (
    SELECT data_year, drg_code,
           SUM(total_payments) / SUM(discharges) AS avg_payment
    FROM analytics.fact_inpatient
    GROUP BY 1, 2
)
--year over year percentage change using the previous years average 
SELECT y.data_year, y.drg_code, d.drg_description,
       ROUND(y.avg_payment) AS avg_payment,
       ROUND(100.0 * (y.avg_payment - LAG(y.avg_payment) OVER w)
             / NULLIF(LAG(y.avg_payment) OVER w, 0), 1) AS yoy_pct
FROM yearly y
JOIN analytics.dim_drg d USING (drg_code)
WINDOW w AS (PARTITION BY y.drg_code ORDER BY y.data_year)
ORDER BY y.drg_code, y.data_year;
