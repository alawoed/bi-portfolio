CREATE OR REPLACE TABLE gold.fact_encounters
USING DELTA
AS
WITH ordered_encounters AS (
    SELECT
        encounter_id,
        start_timestamp,
        stop_timestamp,
        patient_id,
        organization_id,
        payer_id,
        encounter_class,
        encounter_code,
        encounter_description,
        base_encounter_cost,
        total_claim_cost,
        payer_coverage,
        reason_code,
        reason_description,
        encounter_duration_hours,
        is_over_24_hours,
        encounter_date,
        encounter_year,
        encounter_quarter,
        encounter_month,
        zero_payer_coverage_flag,
        LAG(encounter_date) OVER (
            PARTITION BY patient_id
            ORDER BY encounter_date, encounter_id
        ) AS previous_encounter_date
    FROM silver.silver_encounters
    WHERE is_current = TRUE
)
SELECT
    encounter_id,
    CAST(date_format(encounter_date, 'yyyyMMdd') AS INT) AS encounter_date_key,
    start_timestamp,
    stop_timestamp,
    patient_id,
    organization_id,
    payer_id,
    encounter_class,
    encounter_code,
    encounter_description,
    base_encounter_cost,
    total_claim_cost,
    payer_coverage,
    COALESCE(total_claim_cost, 0) - COALESCE(payer_coverage, 0) AS patient_responsibility_amount,
    reason_code,
    reason_description,
    encounter_duration_hours,
    is_over_24_hours,
    encounter_date,
    encounter_year,
    encounter_quarter,
    encounter_month,
    zero_payer_coverage_flag,
    previous_encounter_date,
    DATEDIFF(encounter_date, previous_encounter_date) AS days_since_previous_encounter,
    CASE
        WHEN previous_encounter_date IS NOT NULL
         AND DATEDIFF(encounter_date, previous_encounter_date) BETWEEN 1 AND 30
        THEN TRUE
        ELSE FALSE
    END AS is_readmission_30_days,
    1 AS encounter_count
FROM ordered_encounters;

CREATE OR REPLACE TABLE gold.fact_procedures
USING DELTA
AS
SELECT
    procedure_event_id,
    CAST(date_format(procedure_date, 'yyyyMMdd') AS INT) AS procedure_date_key,
    start_timestamp,
    stop_timestamp,
    patient_id,
    encounter_id,
    procedure_code,
    procedure_description,
    base_cost,
    reason_code,
    reason_description,
    procedure_duration_minutes,
    procedure_date,
    procedure_year,
    procedure_quarter,
    procedure_month,
    1 AS procedure_count
FROM silver.silver_procedures
WHERE is_current = TRUE;
