CREATE OR REPLACE VIEW silver.vw_stage_patients AS
SELECT
    TRIM(id) AS patient_id,
    TO_DATE(TRIM(birthdate)) AS birth_date,
    TO_DATE(TRIM(deathdate)) AS death_date,
    NULLIF(TRIM(prefix), '') AS prefix,
    NULLIF(TRIM(first), '') AS first_name,
    NULLIF(TRIM(last), '') AS last_name,
    NULLIF(TRIM(suffix), '') AS suffix,
    NULLIF(TRIM(maiden), '') AS maiden_name,
    NULLIF(UPPER(TRIM(marital)), '') AS marital_status,
    INITCAP(NULLIF(TRIM(race), '')) AS race,
    LOWER(NULLIF(TRIM(ethnicity), '')) AS ethnicity,
    CASE
        WHEN UPPER(TRIM(gender)) IN ('M', 'MALE') THEN 'Male'
        WHEN UPPER(TRIM(gender)) IN ('F', 'FEMALE') THEN 'Female'
        ELSE 'Unknown'
    END AS gender,
    NULLIF(TRIM(birthplace), '') AS birthplace,
    NULLIF(TRIM(address), '') AS address,
    NULLIF(TRIM(city), '') AS city,
    NULLIF(TRIM(state), '') AS state,
    NULLIF(TRIM(county), '') AS county,
    NULLIF(TRIM(zip), '') AS zip,
    CAST(lat AS DOUBLE) AS latitude,
    CAST(lon AS DOUBLE) AS longitude,
    CASE WHEN TO_DATE(TRIM(deathdate)) IS NOT NULL THEN TRUE ELSE FALSE END AS is_deceased,
    sha2(concat_ws('||',
        coalesce(TRIM(id), ''),
        coalesce(TRIM(birthdate), ''),
        coalesce(TRIM(deathdate), ''),
        coalesce(TRIM(prefix), ''),
        coalesce(TRIM(first), ''),
        coalesce(TRIM(last), ''),
        coalesce(TRIM(suffix), ''),
        coalesce(TRIM(maiden), ''),
        coalesce(TRIM(marital), ''),
        coalesce(TRIM(race), ''),
        coalesce(TRIM(ethnicity), ''),
        coalesce(TRIM(gender), ''),
        coalesce(TRIM(birthplace), ''),
        coalesce(TRIM(address), ''),
        coalesce(TRIM(city), ''),
        coalesce(TRIM(state), ''),
        coalesce(TRIM(county), ''),
        coalesce(TRIM(zip), ''),
        coalesce(CAST(lat AS STRING), ''),
        coalesce(CAST(lon AS STRING), '')
    ), 256) AS record_hash,
    _source_file,
    _source_system,
    _ingestion_batch_id,
    current_timestamp() AS _silver_loaded_at_utc
FROM bronze.bronze_patients
WHERE id IS NOT NULL;

CREATE OR REPLACE VIEW silver.vw_stage_payers AS
SELECT
    TRIM(id) AS payer_id,
    INITCAP(NULLIF(TRIM(name), '')) AS payer_name,
    NULLIF(TRIM(address), '') AS address,
    NULLIF(TRIM(city), '') AS city,
    UPPER(NULLIF(TRIM(state_headquartered), '')) AS state_headquartered,
    NULLIF(TRIM(zip), '') AS zip,
    NULLIF(TRIM(phone), '') AS phone,
    sha2(concat_ws('||',
        coalesce(TRIM(id), ''),
        coalesce(TRIM(name), ''),
        coalesce(TRIM(address), ''),
        coalesce(TRIM(city), ''),
        coalesce(TRIM(state_headquartered), ''),
        coalesce(TRIM(zip), ''),
        coalesce(TRIM(phone), '')
    ), 256) AS record_hash,
    _source_file,
    _source_system,
    _ingestion_batch_id,
    current_timestamp() AS _silver_loaded_at_utc
FROM bronze.bronze_payers
WHERE id IS NOT NULL;

CREATE OR REPLACE VIEW silver.vw_stage_organizations AS
SELECT
    TRIM(id) AS organization_id,
    INITCAP(NULLIF(TRIM(name), '')) AS organization_name,
    NULLIF(TRIM(address), '') AS address,
    NULLIF(TRIM(city), '') AS city,
    UPPER(NULLIF(TRIM(state), '')) AS state,
    NULLIF(TRIM(zip), '') AS zip,
    CAST(lat AS DOUBLE) AS latitude,
    CAST(lon AS DOUBLE) AS longitude,
    sha2(concat_ws('||',
        coalesce(TRIM(id), ''),
        coalesce(TRIM(name), ''),
        coalesce(TRIM(address), ''),
        coalesce(TRIM(city), ''),
        coalesce(TRIM(state), ''),
        coalesce(TRIM(zip), ''),
        coalesce(CAST(lat AS STRING), ''),
        coalesce(CAST(lon AS STRING), '')
    ), 256) AS record_hash,
    _source_file,
    _source_system,
    _ingestion_batch_id,
    current_timestamp() AS _silver_loaded_at_utc
FROM bronze.bronze_organizations
WHERE id IS NOT NULL;

CREATE OR REPLACE VIEW silver.vw_stage_encounters AS
WITH parsed_source AS (
    SELECT
        *,
        TO_TIMESTAMP(TRIM(start), "yyyy-MM-dd'T'HH:mm:ss'Z'") AS original_start_timestamp,
        TO_TIMESTAMP(TRIM(stop), "yyyy-MM-dd'T'HH:mm:ss'Z'") AS original_stop_timestamp
    FROM bronze.bronze_encounters
),
shifted_source AS (
    SELECT
        *,
        original_start_timestamp + INTERVAL 14 YEARS AS shifted_start_timestamp,
        TO_TIMESTAMP(
            FROM_UNIXTIME(
                UNIX_TIMESTAMP(original_start_timestamp + INTERVAL 14 YEARS)
                + (UNIX_TIMESTAMP(original_stop_timestamp) - UNIX_TIMESTAMP(original_start_timestamp))
            )
        ) AS shifted_stop_timestamp
    FROM parsed_source
)
SELECT
    TRIM(id) AS encounter_id,
    shifted_start_timestamp AS start_timestamp,
    shifted_stop_timestamp AS stop_timestamp,
    TRIM(patient) AS patient_id,
    TRIM(organization) AS organization_id,
    TRIM(payer) AS payer_id,
    LOWER(NULLIF(TRIM(encounterclass), '')) AS encounter_class,
    CAST(code AS STRING) AS encounter_code,
    NULLIF(TRIM(description), '') AS encounter_description,
    CAST(base_encounter_cost AS DECIMAL(18,2)) AS base_encounter_cost,
    CAST(total_claim_cost AS DECIMAL(18,2)) AS total_claim_cost,
    CAST(payer_coverage AS DECIMAL(18,2)) AS payer_coverage,
    CAST(reasoncode AS STRING) AS reason_code,
    NULLIF(TRIM(reasondescription), '') AS reason_description,
    ROUND((UNIX_TIMESTAMP(shifted_stop_timestamp) - UNIX_TIMESTAMP(shifted_start_timestamp)) / 3600.0, 2) AS encounter_duration_hours,
    CASE
        WHEN (UNIX_TIMESTAMP(shifted_stop_timestamp) - UNIX_TIMESTAMP(shifted_start_timestamp)) / 3600.0 > 24 THEN TRUE
        ELSE FALSE
    END AS is_over_24_hours,
    TO_DATE(shifted_start_timestamp) AS encounter_date,
    YEAR(shifted_start_timestamp) AS encounter_year,
    QUARTER(shifted_start_timestamp) AS encounter_quarter,
    MONTH(shifted_start_timestamp) AS encounter_month,
    CASE WHEN COALESCE(CAST(payer_coverage AS DECIMAL(18,2)), 0) = 0 THEN TRUE ELSE FALSE END AS zero_payer_coverage_flag,
    sha2(concat_ws('||',
        coalesce(TRIM(id), ''),
        coalesce(CAST(shifted_start_timestamp AS STRING), ''),
        coalesce(CAST(shifted_stop_timestamp AS STRING), ''),
        coalesce(TRIM(patient), ''),
        coalesce(TRIM(organization), ''),
        coalesce(TRIM(payer), ''),
        coalesce(TRIM(encounterclass), ''),
        coalesce(CAST(code AS STRING), ''),
        coalesce(TRIM(description), ''),
        coalesce(CAST(base_encounter_cost AS STRING), ''),
        coalesce(CAST(total_claim_cost AS STRING), ''),
        coalesce(CAST(payer_coverage AS STRING), ''),
        coalesce(CAST(reasoncode AS STRING), ''),
        coalesce(TRIM(reasondescription), '')
    ), 256) AS record_hash,
    _source_file,
    _source_system,
    _ingestion_batch_id,
    current_timestamp() AS _silver_loaded_at_utc
FROM shifted_source
WHERE id IS NOT NULL;

CREATE OR REPLACE VIEW silver.vw_stage_procedures AS
WITH parsed_source AS (
    SELECT
        *,
        TO_TIMESTAMP(TRIM(start), "yyyy-MM-dd'T'HH:mm:ss'Z'") AS original_start_timestamp,
        TO_TIMESTAMP(TRIM(stop), "yyyy-MM-dd'T'HH:mm:ss'Z'") AS original_stop_timestamp
    FROM bronze.bronze_procedures
),
description_cleaned AS (
    SELECT
        *,
        CASE
            WHEN CAST(code AS STRING) = '5880005'
                THEN 'Physical examination'
            WHEN CAST(code AS STRING) = '90226004'
                THEN 'Cytopathology procedure preparation of smear genital source'
            WHEN CAST(code AS STRING) = '399208008'
                THEN 'Chest X-ray'
            WHEN CAST(code AS STRING) = '171207006'
                THEN 'Depression screening'
            ELSE NULLIF(TRIM(description), '')
        END AS procedure_description_clean
    FROM parsed_source
),
shifted_source AS (
    SELECT
        *,
        original_start_timestamp + INTERVAL 14 YEARS AS shifted_start_timestamp,
        TO_TIMESTAMP(
            FROM_UNIXTIME(
                UNIX_TIMESTAMP(original_start_timestamp + INTERVAL 14 YEARS)
                + (UNIX_TIMESTAMP(original_stop_timestamp) - UNIX_TIMESTAMP(original_start_timestamp))
            )
        ) AS shifted_stop_timestamp
    FROM description_cleaned
)
SELECT
    sha2(concat_ws('||',
        coalesce(TRIM(encounter), ''),
        coalesce(TRIM(patient), ''),
        coalesce(TRIM(start), ''),
        coalesce(CAST(code AS STRING), '')
    ), 256) AS procedure_event_id,
    shifted_start_timestamp AS start_timestamp,
    shifted_stop_timestamp AS stop_timestamp,
    TRIM(patient) AS patient_id,
    TRIM(encounter) AS encounter_id,
    CAST(code AS STRING) AS procedure_code,
    procedure_description_clean AS procedure_description,
    CAST(base_cost AS DECIMAL(18,2)) AS base_cost,
    CAST(reasoncode AS STRING) AS reason_code,
    NULLIF(TRIM(reasondescription), '') AS reason_description,
    ROUND((UNIX_TIMESTAMP(shifted_stop_timestamp) - UNIX_TIMESTAMP(shifted_start_timestamp)) / 60.0, 2) AS procedure_duration_minutes,
    TO_DATE(shifted_start_timestamp) AS procedure_date,
    YEAR(shifted_start_timestamp) AS procedure_year,
    QUARTER(shifted_start_timestamp) AS procedure_quarter,
    MONTH(shifted_start_timestamp) AS procedure_month,
    sha2(concat_ws('||',
        coalesce(CAST(shifted_start_timestamp AS STRING), ''),
        coalesce(CAST(shifted_stop_timestamp AS STRING), ''),
        coalesce(TRIM(patient), ''),
        coalesce(TRIM(encounter), ''),
        coalesce(CAST(code AS STRING), ''),
        coalesce(procedure_description_clean, ''),
        coalesce(CAST(base_cost AS STRING), ''),
        coalesce(CAST(reasoncode AS STRING), ''),
        coalesce(TRIM(reasondescription), '')
    ), 256) AS record_hash,
    _source_file,
    _source_system,
    _ingestion_batch_id,
    current_timestamp() AS _silver_loaded_at_utc
FROM shifted_source
WHERE encounter IS NOT NULL
  AND patient IS NOT NULL
  AND start IS NOT NULL
  AND code IS NOT NULL;