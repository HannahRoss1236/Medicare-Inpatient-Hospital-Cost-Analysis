# Medicare Inpatient Hospital Cost Analysis

Analyzing $90B+ in Medicare inpatient payments to identify cost variation across hospitals, states, and procedures, using PostgreSQL for data modeling and Tableau Public for visualization.

**[View the live dashboard on Tableau Public →][(YOUR_TABLEAU_PUBLIC_LINK_HERE)](https://public.tableau.com/app/profile/hannah.ross4193/vizzes) **

![Overview Dashboard] <img width="1998" height="1598" alt="Overview" src="https://github.com/user-attachments/assets/20ca7974-056a-4deb-b508-492e4fb2e359" />

<img width="1998" height="1598" alt="Price Variation" src="https://github.com/user-attachments/assets/7b33f0c8-bab6-4dc7-aec2-fe7bcc7235ff" />


## The Question

How much does Medicare actually pay for the same procedure across different hospitals, and where is the $90B in annual inpatient spending going? This project explores cost variation, state level differences, and the gap between hospital list prices and what Medicare actually pays.

## Data Source

- **Dataset:** [Medicare Inpatient Hospitals by Provider and Service](https://data.cms.gov)
- **Publisher:** Centers for Medicare & Medicaid Services (CMS)
- **Years used:** 2022, 2023, 2024
- **Size:** ~438,000 records (hospital + DRG + year combinations)
- **Note:** Public, de-identified, hospital-level aggregate data. Not patient-level records. CMS suppresses any hospital/DRG combination with 10 or fewer discharges.

## Tools

- **PostgreSQL** — data cleaning, modeling, and analysis
- **Tableau Public** — dashboard and visualization

## Data Model

Built as a star schema:

- `fact_inpatient` — one row per hospital, DRG, and year (discharges, charges, payments)
- `dim_provider` — hospital name, city, state, rural/urban classification
- `dim_drg` — diagnosis-related group code and description

## Methodology
1. Loaded 3 years of raw CMS CSVs into PostgreSQL staging tables
2. Cleaned and deduplicated records; resolved encoding issues (WIN1252 → UTF8)
3. Built a star schema (fact table + two dimension tables)
4. Wrote analysis queries using window functions, weighted averages, and year-over-year comparisons
5. Exported a flattened dataset to CSV and built interactive dashboards in Tableau Public

## Key Findings

- **Total Medicare inpatient payments were $90.9B in 2024**, across 4.95M hospital stays
- **Hospitals' list prices average about 5x what Medicare actually pays**, the gap between "charges" and "payments" is important to analyze further and identify the reasoning behind
- **Payment per stay varies nearly 2.5x by state**, from ~$13,100 in Mississippi to ~$33,000 in DC
- **Sepsis is the single largest spending category** at $10.5B, this could be driven by volume (577K stays) rather than high cost per case and can be elevated for a consistent count
- **For hip/knee replacement (DRG 470), payments range from $6,400 to over $42,000** across 1,212 hospitals, the middle 80% of hospitals fall between $13,000 and $21,600

## SQL Highlights

**Weighted average payment with state-level ranking (window function):**
```sql
SELECT p.state, p.provider_name, f.discharges, f.avg_total_payment,
       RANK() OVER (PARTITION BY p.state ORDER BY f.avg_total_payment DESC) AS state_rank
FROM analytics.fact_inpatient f
JOIN analytics.dim_provider p USING (provider_id)
WHERE f.drg_code = '470' AND f.data_year = 2024
ORDER BY p.state, state_rank;
```

**Price variation across hospitals for the same procedure:**
```sql
SELECT f.drg_code, d.drg_description,
       COUNT(*) AS hospitals,
       ROUND(MIN(f.avg_total_payment)) AS min_pay,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.avg_total_payment)::numeric) AS median_pay,
       ROUND(MAX(f.avg_total_payment)) AS max_pay
FROM analytics.fact_inpatient f
JOIN analytics.dim_drg d USING (drg_code)
WHERE f.data_year = 2024 AND f.discharges >= 11
GROUP BY 1, 2
HAVING COUNT(*) > 50
ORDER BY max_pay DESC;
```

More queries are in [Open Analysis Script](analysis.sql)

## Repo Structure
├── sql/
│ ├── Database.sql
│ ├── Creating_Star_Schema.sql
│ └── Analysis.sql
├── images/
│ └── dashboard_overview.png
└── README.md

## Limitations

- Covers Medicare fee-for-service only — not private insurance or Medicare Advantage
- CMS suppresses hospital/DRG combinations with 10 or fewer discharges, which can skew rankings for rare procedures
