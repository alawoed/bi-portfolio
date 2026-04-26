CREATE OR REPLACE VIEW gold.vw_encounters_by_year AS
SELECT
    encounter_year,
    COUNT(*) AS total_encounters
FROM gold.fact_encounters
GROUP BY encounter_year;

CREATE OR REPLACE VIEW gold.vw_encounter_class_percentage_by_year AS
WITH yearly_class_counts AS (
    SELECT
        encounter_year,
        encounter_class,
        COUNT(*) AS encounter_count
    FROM gold.fact_encounters
    GROUP BY encounter_year, encounter_class
),
yearly_totals AS (
    SELECT
        encounter_year,
        SUM(encounter_count) AS total_encounters
    FROM yearly_class_counts
    GROUP BY encounter_year
)
SELECT
    ycc.encounter_year,
    ycc.encounter_class,
    ycc.encounter_count,
    yt.total_encounters,
    ROUND((ycc.encounter_count / yt.total_encounters) * 100, 2) AS encounter_class_percentage
FROM yearly_class_counts ycc
JOIN yearly_totals yt
    ON ycc.encounter_year = yt.encounter_year;

CREATE OR REPLACE VIEW gold.vw_encounter_duration_breakdown AS
SELECT
    CASE
        WHEN is_over_24_hours THEN 'Over 24 Hours'
        ELSE 'Under 24 Hours'
    END AS duration_group,
    COUNT(*) AS encounter_count,
    ROUND((COUNT(*) / SUM(COUNT(*)) OVER ()) * 100, 2) AS percentage_of_encounters
FROM gold.fact_encounters
GROUP BY
    CASE
        WHEN is_over_24_hours THEN 'Over 24 Hours'
        ELSE 'Under 24 Hours'
    END;

CREATE OR REPLACE VIEW gold.vw_zero_payer_coverage AS
SELECT
    COUNT(*) AS zero_payer_coverage_encounters,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM gold.fact_encounters)) * 100, 2) AS percentage_of_total_encounters
FROM gold.fact_encounters
WHERE zero_payer_coverage_flag = TRUE;

CREATE OR REPLACE VIEW gold.vw_top_10_frequent_procedures AS
SELECT
    procedure_code,
    procedure_description,
    COUNT(*) AS procedure_count,
    ROUND(AVG(base_cost), 2) AS average_base_cost
FROM gold.fact_procedures
GROUP BY procedure_code, procedure_description
ORDER BY procedure_count DESC
LIMIT 10;

CREATE OR REPLACE VIEW gold.vw_top_10_highest_cost_procedures AS
SELECT
    procedure_code,
    procedure_description,
    ROUND(AVG(base_cost), 2) AS average_base_cost,
    COUNT(*) AS procedure_count
FROM gold.fact_procedures
GROUP BY procedure_code, procedure_description
ORDER BY average_base_cost DESC
LIMIT 10;

CREATE OR REPLACE VIEW gold.vw_average_claim_cost_by_payer AS
SELECT
    p.payer_id,
    p.payer_name,
    ROUND(AVG(e.total_claim_cost), 2) AS average_total_claim_cost,
    COUNT(*) AS encounter_count
FROM gold.fact_encounters e
LEFT JOIN gold.dim_payer p
    ON e.payer_id = p.payer_id
GROUP BY p.payer_id, p.payer_name
ORDER BY average_total_claim_cost DESC;

CREATE OR REPLACE VIEW gold.vw_unique_patients_by_quarter AS
SELECT
    encounter_year,
    encounter_quarter,
    CONCAT(CAST(encounter_year AS STRING), '-Q', CAST(encounter_quarter AS STRING)) AS year_quarter,
    COUNT(DISTINCT patient_id) AS unique_patients
FROM gold.fact_encounters
GROUP BY encounter_year, encounter_quarter
ORDER BY encounter_year, encounter_quarter;

CREATE OR REPLACE VIEW gold.vw_readmissions_30_days AS
SELECT
    COUNT(*) AS readmissions_within_30_days,
    COUNT(DISTINCT patient_id) AS unique_patients_readmitted
FROM gold.fact_encounters
WHERE is_readmission_30_days = TRUE;

CREATE OR REPLACE VIEW gold.vw_patients_with_most_readmissions AS
SELECT
    e.patient_id,
    p.first_name,
    p.last_name,
    p.gender,
    p.city,
    p.state,
    COUNT(*) AS readmission_count
FROM gold.fact_encounters e
LEFT JOIN gold.dim_patient p
    ON e.patient_id = p.patient_id
WHERE e.is_readmission_30_days = TRUE
GROUP BY
    e.patient_id,
    p.first_name,
    p.last_name,
    p.gender,
    p.city,
    p.state
ORDER BY readmission_count DESC
LIMIT 20;
