-- Step 1: Expire current records where the staged version has changed
MERGE INTO silver.silver_payers AS t
USING silver.vw_stage_payers AS s
ON t.payer_id = s.payer_id
   AND t.is_current = TRUE
WHEN MATCHED AND t.record_hash <> s.record_hash THEN
  UPDATE SET
    t.valid_to = current_timestamp(),
    t.is_current = FALSE;

-- Step 2: Insert new records and changed current versions
INSERT INTO silver.silver_payers (
    payer_id,
    payer_name,
    address,
    city,
    state_headquartered,
    zip,
    phone,
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
    s.payer_id,
    s.payer_name,
    s.address,
    s.city,
    s.state_headquartered,
    s.zip,
    s.phone,
    current_timestamp(),
    CAST(NULL AS TIMESTAMP),
    TRUE,
    s.record_hash,
    s._source_file,
    s._source_system,
    s._ingestion_batch_id,
    s._silver_loaded_at_utc
FROM silver.vw_stage_payers AS s
LEFT JOIN silver.silver_payers AS t
    ON t.payer_id = s.payer_id
   AND t.is_current = TRUE
WHERE t.payer_id IS NULL;
