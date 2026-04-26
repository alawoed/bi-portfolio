SELECT 'dim_patient' AS object_name, COUNT(*) AS row_count FROM gold.dim_patient
UNION ALL
SELECT 'dim_payer', COUNT(*) FROM gold.dim_payer
UNION ALL
SELECT 'dim_organization', COUNT(*) FROM gold.dim_organization
UNION ALL
SELECT 'dim_procedure', COUNT(*) FROM gold.dim_procedure
UNION ALL
SELECT 'dim_date', COUNT(*) FROM gold.dim_date
UNION ALL
SELECT 'fact_encounters', COUNT(*) FROM gold.fact_encounters
UNION ALL
SELECT 'fact_procedures', COUNT(*) FROM gold.fact_procedures;
