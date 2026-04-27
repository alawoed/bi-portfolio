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
),
base_dates AS (
    SELECT
        date_value,
        CURRENT_DATE() AS today_date
    FROM date_series
)
SELECT
    CAST(date_format(date_value, 'yyyyMMdd') AS INT) AS date_key,

    date_value,

    YEAR(date_value) AS year,
    QUARTER(date_value) AS quarter,
    MONTH(date_value) AS month,
    DAY(date_value) AS day,

    date_format(date_value, 'MMMM') AS month_name,
    date_format(date_value, 'MMM') AS month_short_name,
    date_format(date_value, 'EEEE') AS day_name,
    date_format(date_value, 'E') AS day_short_name,

    DAYOFWEEK(date_value) AS day_of_week,
    DAYOFMONTH(date_value) AS day_of_month,
    DAYOFYEAR(date_value) AS day_of_year,

    WEEKOFYEAR(date_value) AS week_of_year,

    CONCAT(CAST(YEAR(date_value) AS STRING), '-Q', CAST(QUARTER(date_value) AS STRING)) AS year_quarter,
    date_format(date_value, 'yyyy-MM') AS year_month,

    DATE_TRUNC('week', date_value) AS week_start_date,
    DATE_ADD(DATE_TRUNC('week', date_value), 6) AS week_end_date,

    DATE_TRUNC('month', date_value) AS month_start_date,
    LAST_DAY(date_value) AS month_end_date,

    DATE_TRUNC('quarter', date_value) AS quarter_start_date,
    ADD_MONTHS(DATE_TRUNC('quarter', date_value), 3) - INTERVAL 1 DAY AS quarter_end_date,

    DATE_TRUNC('year', date_value) AS year_start_date,
    ADD_MONTHS(DATE_TRUNC('year', date_value), 12) - INTERVAL 1 DAY AS year_end_date,

    DATEDIFF(date_value, today_date) AS day_offset,

    FLOOR(DATEDIFF(date_value, today_date) / 7) AS week_offset,

    (YEAR(date_value) - YEAR(today_date)) * 12
        + (MONTH(date_value) - MONTH(today_date)) AS month_offset,

    (YEAR(date_value) - YEAR(today_date)) * 4
        + (QUARTER(date_value) - QUARTER(today_date)) AS quarter_offset,

    YEAR(date_value) - YEAR(today_date) AS year_offset,

    CASE WHEN date_value = today_date THEN TRUE ELSE FALSE END AS is_today,
    CASE WHEN date_value < today_date THEN TRUE ELSE FALSE END AS is_past_date,
    CASE WHEN date_value > today_date THEN TRUE ELSE FALSE END AS is_future_date,

    CASE
        WHEN YEAR(date_value) = YEAR(today_date)
         AND MONTH(date_value) = MONTH(today_date)
        THEN TRUE ELSE FALSE
    END AS is_current_month,

    CASE
        WHEN YEAR(date_value) = YEAR(today_date)
         AND QUARTER(date_value) = QUARTER(today_date)
        THEN TRUE ELSE FALSE
    END AS is_current_quarter,

    CASE
        WHEN YEAR(date_value) = YEAR(today_date)
        THEN TRUE ELSE FALSE
    END AS is_current_year

FROM base_dates;