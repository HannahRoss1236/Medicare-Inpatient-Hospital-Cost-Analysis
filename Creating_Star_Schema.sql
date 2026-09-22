--Create Star Schema
CREATE TABLE analytics.dim_provider AS
SELECT DISTINCT ON (Rndrng_Prvdr_CCN)
    Rndrng_Prvdr_CCN          AS provider_id,
    Rndrng_Prvdr_Org_Name     AS provider_name,
    Rndrng_Prvdr_City         AS city,
    Rndrng_Prvdr_State_Abrvtn AS state,
    Rndrng_Prvdr_Zip5         AS zip,
    Rndrng_Prvdr_RUCA_Desc    AS rural_urban_type
FROM staging.inpatient_raw
ORDER BY Rndrng_Prvdr_CCN, data_year DESC;
ALTER TABLE analytics.dim_provider ADD PRIMARY KEY (provider_id);
--*second dimension table with Diagnosis-Related Group (DRG) codes and descriptions 
CREATE TABLE analytics.dim_drg AS
SELECT DISTINCT ON (DRG_Cd)
    DRG_Cd   AS drg_code,
    DRG_Desc AS drg_description
FROM staging.inpatient_raw
ORDER BY DRG_Cd, data_year DESC;
ALTER TABLE analytics.dim_drg ADD PRIMARY KEY (drg_code);
--facts table 
CREATE TABLE analytics.fact_inpatient AS
SELECT
    Rndrng_Prvdr_CCN      AS provider_id,
    DRG_Cd                AS drg_code,
    data_year,
    Tot_Dschrgs           AS discharges,
    Avg_Submtd_Cvrd_Chrg  AS avg_charge,
    Avg_Tot_Pymt_Amt      AS avg_total_payment,
    Avg_Mdcr_Pymt_Amt     AS avg_medicare_payment,
    Tot_Dschrgs * Avg_Submtd_Cvrd_Chrg AS total_charges,
    Tot_Dschrgs * Avg_Tot_Pymt_Amt     AS total_payments
FROM staging.inpatient_raw;
