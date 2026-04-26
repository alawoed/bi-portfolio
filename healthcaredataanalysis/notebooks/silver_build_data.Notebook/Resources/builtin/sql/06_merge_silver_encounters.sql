-- Step 1: Expire current records where the staged version has changed
MERGE INTO silver.silver_encounters AS t
USING silver.vw_stage_encounters AS s
ON t.encounter_id = s.encounter_id
   AND t.is_current = TRUE
WHEN MATCHED AND t.record_hash <> s.record_hash THEN
  UPDATE SET
    t.valid_to = current_timestamp(),
    t.is_current = FALSE;

-- Step 2: Insert new records and changed current versions
INSERT INTO silver.silver_encounters (
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
    s.encounter_id,
    s.start_timestamp,
    s.stop_timestamp,
    s.patient_id,
    s.organization_id,
    s.payer_id,
    s.encounter_class,
    s.encounter_code,
    s.encounter_description,
    s.base_encounter_cost,
    s.total_claim_cost,
    s.payer_coverage,
    s.reason_code,
    s.reason_description,
    s.encounter_duration_hours,
    s.is_over_24_hours,
    s.encounter_date,
    s.encounter_year,
    s.encounter_quarter,
    s.encounter_month,
    s.zero_payer_coverage_flag,
    current_timestamp(),
    CAST(NULL AS TIMESTAMP),
    TRUE,
    s.record_hash,
    s._source_file,
    s._source_system,
    s._ingestion_batch_id,
    s._silver_loaded_at_utc
FROM silver.vw_stage_encounters AS s
LEFT JOIN silver.silver_encounters AS t
    ON t.encounter_id = s.encounter_id
   AND t.is_current = TRUE
WHERE t.encounter_id IS NULL;
