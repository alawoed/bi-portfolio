CREATE OR REPLACE TABLE gold.dim_patient
USING DELTA
AS
SELECT
    patient_id,
    birth_date,
    death_date,
    first_name,
    last_name,
    gender,
    race,
    ethnicity,
    marital_status,
    city,
    state,
    county,
    zip,
    latitude,
    longitude,
    is_deceased
FROM silver.silver_patients
WHERE is_current = TRUE;

CREATE OR REPLACE TABLE gold.dim_payer
USING DELTA
AS
SELECT
    payer_id,
    payer_name,
    address,
    city,
    state_headquartered,
    zip,
    phone
FROM silver.silver_payers
WHERE is_current = TRUE;

CREATE OR REPLACE TABLE gold.dim_organization
USING DELTA
AS
SELECT
    organization_id,
    organization_name,
    address,
    city,
    state,
    zip,
    latitude,
    longitude
FROM silver.silver_organizations
WHERE is_current = TRUE;

CREATE OR REPLACE TABLE gold.dim_procedure
USING DELTA
AS
SELECT DISTINCT
    procedure_code,
    procedure_description
FROM silver.silver_procedures
WHERE is_current = TRUE
  AND procedure_code IS NOT NULL;

CREATE OR REPLACE TABLE gold.dim_date
USING DELTA
AS
WITH date_bounds AS (
    SELECT
        MIN(encounter_date) AS min_date,
        MAX(encounter_date) AS max_date
    FROM silver.silver_encounters
    WHERE is_current = TRUE
),
date_series AS (
    SELECT explode(sequence(min_date, max_date, interval 1 day)) AS date_value
    FROM date_bounds
)
SELECT
    CAST(date_format(date_value, 'yyyyMMdd') AS INT) AS date_key,
    date_value,
    YEAR(date_value) AS year,
    QUARTER(date_value) AS quarter,
    MONTH(date_value) AS month,
    date_format(date_value, 'MMMM') AS month_name,
    DAY(date_value) AS day,
    DAYOFWEEK(date_value) AS day_of_week,
    date_format(date_value, 'EEEE') AS day_name,
    CONCAT(CAST(YEAR(date_value) AS STRING), '-Q', CAST(QUARTER(date_value) AS STRING)) AS year_quarter,
    date_format(date_value, 'yyyy-MM') AS year_month
FROM date_series;
