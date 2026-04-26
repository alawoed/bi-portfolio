-- Step 1: Expire current records where the staged version has changed
MERGE INTO silver.silver_procedures AS t
USING silver.vw_stage_procedures AS s
ON t.procedure_event_id = s.procedure_event_id
   AND t.is_current = TRUE
WHEN MATCHED AND t.record_hash <> s.record_hash THEN
  UPDATE SET
    t.valid_to = current_timestamp(),
    t.is_current = FALSE;

-- Step 2: Insert new records and changed current versions
INSERT INTO silver.silver_procedures (
    procedure_event_id,
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
    s.procedure_event_id,
    s.start_timestamp,
    s.stop_timestamp,
    s.patient_id,
    s.encounter_id,
    s.procedure_code,
    s.procedure_description,
    s.base_cost,
    s.reason_code,
    s.reason_description,
    s.procedure_duration_minutes,
    s.procedure_date,
    s.procedure_year,
    s.procedure_quarter,
    s.procedure_month,
    current_timestamp(),
    CAST(NULL AS TIMESTAMP),
    TRUE,
    s.record_hash,
    s._source_file,
    s._source_system,
    s._ingestion_batch_id,
    s._silver_loaded_at_utc
FROM silver.vw_stage_procedures AS s
LEFT JOIN silver.silver_procedures AS t
    ON t.procedure_event_id = s.procedure_event_id
   AND t.is_current = TRUE
WHERE t.procedure_event_id IS NULL;
