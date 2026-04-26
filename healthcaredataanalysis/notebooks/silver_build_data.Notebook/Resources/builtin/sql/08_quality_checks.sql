SELECT 'silver_patients' AS table_name, COUNT(*) AS row_count, SUM(CASE WHEN is_current THEN 1 ELSE 0 END) AS current_row_count FROM silver.silver_patients
UNION ALL
SELECT 'silver_payers', COUNT(*), SUM(CASE WHEN is_current THEN 1 ELSE 0 END) FROM silver.silver_payers
UNION ALL
SELECT 'silver_organizations', COUNT(*), SUM(CASE WHEN is_current THEN 1 ELSE 0 END) FROM silver.silver_organizations
UNION ALL
SELECT 'silver_encounters', COUNT(*), SUM(CASE WHEN is_current THEN 1 ELSE 0 END) FROM silver.silver_encounters
UNION ALL
SELECT 'silver_procedures', COUNT(*), SUM(CASE WHEN is_current THEN 1 ELSE 0 END) FROM silver.silver_procedures;
