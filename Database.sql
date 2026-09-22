Creating and Cleaning Database
* ========================================================================= Hannah Ross DATE: 2026-09-21 PURPOSE: Clean and Create 3 datasets for a star schema. ========================================================================= */
--1. Open Postgresql
brew services start postgresql@18
psql postgres
psql
--Create a temporary staging dataset based off of public dataset and upload the three years
CREATE DATABASE medicare_analysis
 \c medicare_analysis
CREATE SCHEMA staging;
CREATE TABLE staging.tmp_load (
    Rndrng_Prvdr_CCN          VARCHAR(10),
    Rndrng_Prvdr_Org_Name     TEXT,
    Rndrng_Prvdr_City         TEXT,
    Rndrng_Prvdr_St           TEXT,
    Rndrng_Prvdr_State_FIPS   VARCHAR(5),
    Rndrng_Prvdr_Zip5         VARCHAR(10),
    Rndrng_Prvdr_State_Abrvtn VARCHAR(5),
    Rndrng_Prvdr_RUCA         VARCHAR(10),
    Rndrng_Prvdr_RUCA_Desc    TEXT,
    DRG_Cd                    VARCHAR(10),
    DRG_Desc                  TEXT,
    Tot_Dschrgs               INT,
    Avg_Submtd_Cvrd_Chrg      NUMERIC(14,2),
    Avg_Tot_Pymt_Amt          NUMERIC(14,2),
    Avg_Mdcr_Pymt_Amt         NUMERIC(14,2)
);

CREATE TABLE staging.inpatient_raw (LIKE staging.tmp_load);
ALTER TABLE staging.inpatient_raw ADD COLUMN data_year INT;
 \copy staging.tmp_load FROM '/Applications/Coding projects/POSTGRESQL/Project #1 /MUP_INP_RY26_P03_V10_DY24_PrvSvc.CSV' CSV HEADER
INSERT INTO staging.inpatient_raw SELECT *, 2024 FROM staging.tmp_load;
TRUNCATE staging.tmp_load;
\copy staging.tmp_load FROM '/Applications/Coding projects/POSTGRESQL/Project #1 /Medicare_IP_Hospitals_by_Provider_and_Service_2023.csv' WITH (FORMAT csv, HEADER true, ENCODING 'WIN1252')
INSERT INTO staging.inpatient_raw SELECT *, 2023 FROM staging.tmp_load;
TRUNCATE staging.tmp_load;
\copy staging.tmp_load FROM '/Applications/Coding projects/POSTGRESQL/Project #1 /Medicare_IP_Hospitals_by_Provider_and_Service_2022.csv' WITH (FORMAT csv, HEADER true, ENCODING 'WIN1252')
INSERT INTO staging.inpatient_raw SELECT *, 2022 FROM staging.tmp_load;
SELECT data_year, COUNT(*) FROM staging.inpatient_raw GROUP BY 1;
TRUNCATE staging.tmp_load;
