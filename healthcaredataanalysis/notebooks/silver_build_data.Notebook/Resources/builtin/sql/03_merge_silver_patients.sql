-- Step 1: Expire current records where the staged version has changed
MERGE INTO silver.silver_patients AS t
USING silver.vw_stage_patients AS s
ON t.patient_id = s.patient_id
   AND t.is_current = TRUE
WHEN MATCHED AND t.record_hash <> s.record_hash THEN
  UPDATE SET
    t.valid_to = current_timestamp(),
    t.is_current = FALSE;

-- Step 2: Insert new records and changed current versions
INSERT INTO silver.silver_patients (
    patient_id,
    birth_date,
    death_date,
    prefix,
    first_name,
    last_name,
    suffix,
    maiden_name,
    marital_status,
    race,
    ethnicity,
    gender,
    birthplace,
    address,
    city,
    state,
    county,
    zip,
    latitude,
    longitude,
    is_deceased,
    valid_from,
    valid_to,
    is_current,
    record_hash,
    _source_file,
    _source_system,
    _ingestion_batch_id,
    _silver_loaded_at_utc
)
SELECT
    s.patient_id,
    s.birth_date,
    s.death_date,
    s.prefix,
    s.first_name,
    s.last_name,
    s.suffix,
    s.maiden_name,
    s.marital_status,
    s.race,
    s.ethnicity,
    s.gender,
    s.birthplace,
    s.address,
    s.city,
    s.state,
    s.county,
    s.zip,
    s.latitude,
    s.longitude,
    s.is_deceased,
    current_timestamp(),
    CAST(NULL AS TIMESTAMP),
    TRUE,
    s.record_hash,
    s._source_file,
    s._source_system,
    s._ingestion_batch_id,
    s._silver_loaded_at_utc
FROM silver.vw_stage_patients AS s
LEFT JOIN silver.silver_patients AS t
    ON t.patient_id = s.patient_id
   AND t.is_current = TRUE
WHERE t.patient_id IS NULL;
