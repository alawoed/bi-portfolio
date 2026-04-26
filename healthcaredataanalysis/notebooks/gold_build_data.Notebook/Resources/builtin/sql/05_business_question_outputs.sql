SELECT 'Objective 1a - Encounters by Year' AS section;
SELECT * FROM gold.vw_encounters_by_year;

SELECT 'Objective 1b - Encounter Class Percentage by Year' AS section;
SELECT * FROM gold.vw_encounter_class_percentage_by_year;

SELECT 'Objective 1c - Encounter Duration Breakdown' AS section;
SELECT * FROM gold.vw_encounter_duration_breakdown;

SELECT 'Objective 2a - Zero Payer Coverage' AS section;
SELECT * FROM gold.vw_zero_payer_coverage;

SELECT 'Objective 2b - Top 10 Frequent Procedures' AS section;
SELECT * FROM gold.vw_top_10_frequent_procedures;

SELECT 'Objective 2c - Top 10 Highest Cost Procedures' AS section;
SELECT * FROM gold.vw_top_10_highest_cost_procedures;

SELECT 'Objective 2d - Average Claim Cost by Payer' AS section;
SELECT * FROM gold.vw_average_claim_cost_by_payer;

SELECT 'Objective 3a - Unique Patients by Quarter' AS section;
SELECT * FROM gold.vw_unique_patients_by_quarter;

SELECT 'Objective 3b - Readmissions within 30 Days' AS section;
SELECT * FROM gold.vw_readmissions_30_days;

SELECT 'Objective 3c - Patients with Most Readmissions' AS section;
SELECT * FROM gold.vw_patients_with_most_readmissions;
