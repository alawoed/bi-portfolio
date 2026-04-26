# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "308e8220-6410-4f1e-93b8-90b9044663f4",
# META       "default_lakehouse_name": "HealthLakehouse",
# META       "default_lakehouse_workspace_id": "c67813a7-70d6-4f9f-8278-8981a653c747",
# META       "known_lakehouses": [
# META         {
# META           "id": "308e8220-6410-4f1e-93b8-90b9044663f4"
# META         }
# META       ]
# META     }
# META   }
# META }

# MARKDOWN ********************

# # Build Clean Silver Tables from Bronze Data
# 
# I use this notebook to build the Silver layer for the Healthcare Provider Operations Analytics project.
# 
# The Bronze layer already contains the raw JSON-ingested Delta tables. In this notebook, I read SQL scripts from the notebook resource folder, create the Silver schema and tables, create staging views, and load clean Silver tables using SCD Type 2 logic.
# 
# This notebook assumes Bronze and Silver are in the same Lakehouse and separated by schemas.

# MARKDOWN ********************

# ## 1. Configure notebook parameters
# 
# I define the SQL resource folder and the schemas used for the Bronze and Silver layers.

# CELL ********************

# ============================================================
# CONFIGURATION
# ============================================================

SQL_RESOURCE_FOLDER = "builtin/sql"

BRONZE_SCHEMA = "bronze"
SILVER_SCHEMA = "silver"

sql_files = [
    "00_create_silver_schema.sql",
    "01_create_silver_tables.sql",
    "02_create_silver_stage_views.sql",
    "03_merge_silver_patients.sql",
    "04_merge_silver_payers.sql",
    "05_merge_silver_organizations.sql",
    "06_merge_silver_encounters.sql",
    "07_merge_silver_procedures.sql",
    "08_quality_checks.sql"
]

print("I have configured the Silver layer build.")
print(f"SQL resource folder: {SQL_RESOURCE_FOLDER}")
print(f"Bronze schema: {BRONZE_SCHEMA}")
print(f"Silver schema: {SILVER_SCHEMA}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 2. Confirm Lakehouse context
# 
# I confirm that the notebook is attached to the correct Lakehouse and that the Bronze and Silver schemas are visible.

# CELL ********************

spark.catalog.clearCache()

print("Available schemas:")
spark.sql("SHOW SCHEMAS").show(truncate=False)

print("Current catalog:")
spark.sql("SELECT current_catalog()").show(truncate=False)

print("Current database:")
spark.sql("SELECT current_database()").show(truncate=False)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 3. Validate SQL resource files
# 
# I check that all required SQL files are available in the notebook resource folder before running the pipeline.

# CELL ********************

import os

available_files = os.listdir(SQL_RESOURCE_FOLDER)

print("Available SQL files:")
for file_name in available_files:
    print(f" - {file_name}")

missing_files = [f for f in sql_files if f not in available_files]

if missing_files:
    raise Exception(f"I am missing required SQL files: {missing_files}")

print("All required SQL files are available.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 4. Define SQL helper functions
# 
# I use these helper functions to read SQL files, replace Bronze schema references if needed, split SQL statements, and execute each file.

# CELL ********************

def read_sql(file_name: str) -> str:
    path = f"{SQL_RESOURCE_FOLDER}/{file_name}"
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def replace_bronze_refs(sql_text: str) -> str:
    bronze_tables = [
        "bronze_patients",
        "bronze_payers",
        "bronze_procedures",
        "bronze_encounters",
        "bronze_organizations",
        "bronze_data_dictionary"
    ]

    updated_sql = sql_text

    for table_name in bronze_tables:
        updated_sql = updated_sql.replace(
            f"bronze.{table_name}",
            f"{BRONZE_SCHEMA}.{table_name}"
        )

        updated_sql = updated_sql.replace(
            f"`bronze`.`{table_name}`",
            f"{BRONZE_SCHEMA}.{table_name}"
        )

    return updated_sql


def split_sql(sql_text: str):
    statements = []

    for statement in sql_text.split(";"):
        clean_statement = statement.strip()
        if clean_statement:
            statements.append(clean_statement)

    return statements


def run_sql_file(file_name: str, show_sql: bool = False):
    print(f"\nI am running {file_name}")

    raw_sql = read_sql(file_name)
    prepared_sql = replace_bronze_refs(raw_sql)
    statements = split_sql(prepared_sql)

    print(f"I found {len(statements)} SQL statement(s).")

    last_result = None

    for index, statement in enumerate(statements, start=1):
        if show_sql:
            print(f"\n--- Statement {index} ---")
            print(statement)

        print(f"I am executing statement {index} of {len(statements)}.")
        last_result = spark.sql(statement)

    print(f"I completed {file_name}")
    return last_result

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 5. Validate Bronze table references
# 
# I preview the staging view SQL to confirm the Bronze table references are pointing to the Bronze schema in this Lakehouse.

# CELL ********************

test_sql = read_sql("02_create_silver_stage_views.sql")
preview_sql = replace_bronze_refs(test_sql)

print(preview_sql[:2000])

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 6. Create Silver schema and tables
# 
# I create the Silver schema and the Silver Delta tables that will store clean, typed, and versioned records.

# CELL ********************

run_sql_file("00_create_silver_schema.sql")
run_sql_file("01_create_silver_tables.sql")

print("I have created the Silver schema and Silver tables.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 7. Create Silver staging views
# 
# I create staging views that clean and standardize the Bronze data before loading it into Silver tables.

# CELL ********************

run_sql_file("02_create_silver_stage_views.sql")

print("I have created the Silver staging views.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 8. Load Silver tables with SCD Type 2 logic
# 
# I run the merge scripts that expire changed current records and insert new current versions into the Silver tables.

# CELL ********************

merge_files = [
    "03_merge_silver_patients.sql",
    "04_merge_silver_payers.sql",
    "05_merge_silver_organizations.sql",
    "06_merge_silver_encounters.sql",
    "07_merge_silver_procedures.sql"
]

for file_name in merge_files:
    run_sql_file(file_name)

print("I have completed the Silver SCD Type 2 loads.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 9. Run quality checks
# 
# I run row-count checks to confirm that the Silver tables were loaded successfully.

# CELL ********************

quality_df = run_sql_file("08_quality_checks.sql")
display(quality_df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 10. Preview current Silver records
# 
# I preview current records from each Silver table to confirm that the data is available for downstream Gold modeling.

# CELL ********************

silver_tables = [
    "silver_patients",
    "silver_payers",
    "silver_organizations",
    "silver_encounters",
    "silver_procedures"
]

for table_name in silver_tables:
    full_table_name = f"{SILVER_SCHEMA}.{table_name}"
    print(f"\nI am previewing {full_table_name}")

    spark.sql(f'''
        SELECT *
        FROM {full_table_name}
        WHERE is_current = TRUE
        LIMIT 5
    ''').show(truncate=False)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 11. Complete Silver build
# 
# I confirm the Silver objects created in the Lakehouse.

# CELL ********************

print("I have successfully built the Silver layer.")

spark.sql(f"SHOW TABLES IN {SILVER_SCHEMA}").show(truncate=False)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
