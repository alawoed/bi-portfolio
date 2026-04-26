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

# # Build Gold Analytics Model from Silver Data
# 
# I use this notebook to build the Gold layer for the Healthcare Provider Operations Analytics project.
# 
# The Silver layer contains clean and versioned tables. In this notebook, I create analytics-ready dimensions, fact tables, and business views that can be consumed directly by Power BI.

# MARKDOWN ********************

# ## 1. Configure notebook parameters
# 
# I define the SQL resource folder and the schemas used for the Silver and Gold layers.

# CELL ********************

SQL_RESOURCE_FOLDER = "builtin/sql"

SILVER_SCHEMA = "silver"
GOLD_SCHEMA = "gold"

sql_files = [
    "00_create_gold_schema.sql",
    "01_create_gold_dimensions.sql",
    "02_create_gold_facts.sql",
    "03_create_gold_business_views.sql",
    "04_quality_checks.sql",
    "05_business_question_outputs.sql"
]

print(f"SQL resource folder: {SQL_RESOURCE_FOLDER}")
print(f"Silver schema: {SILVER_SCHEMA}")
print(f"Gold schema: {GOLD_SCHEMA}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 2. Confirm Lakehouse context
# 
# I confirm that the notebook is attached to the correct Lakehouse and that the Silver schema is available.

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
# I check that all required Gold SQL files are available before running the pipeline.

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
# I use these helper functions to read, prepare, split, and run each SQL file.

# CELL ********************

def read_sql(file_name: str) -> str:
    path = f"{SQL_RESOURCE_FOLDER}/{file_name}"
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def replace_schema_refs(sql_text: str) -> str:
    updated_sql = sql_text

    updated_sql = updated_sql.replace("silver.", f"{SILVER_SCHEMA}.")
    updated_sql = updated_sql.replace("gold.", f"{GOLD_SCHEMA}.")

    return updated_sql


def split_sql(sql_text: str):
    statements = []

    for statement in sql_text.split(";"):
        clean_statement = statement.strip()
        if clean_statement:
            statements.append(clean_statement)

    return statements


def run_sql_file(file_name: str, show_sql: bool = False):
    print(f"\nRunning {file_name}")

    raw_sql = read_sql(file_name)
    prepared_sql = replace_schema_refs(raw_sql)
    statements = split_sql(prepared_sql)

    print(f"Found {len(statements)} SQL statement(s).")

    last_result = None

    for index, statement in enumerate(statements, start=1):
        if show_sql:
            print(f"\n--- Statement {index} ---")
            print(statement)

        print(f"Executing statement {index} of {len(statements)}.")
        last_result = spark.sql(statement)

    print(f"Completed {file_name}")
    return last_result

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 5. Create Gold schema
# 
# I create the Gold schema that will store reporting-ready tables and views.

# CELL ********************

run_sql_file("00_create_gold_schema.sql")

print("Created the Gold schema.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 6. Create Gold dimensions
# 
# I create dimension tables for patients, payers, organizations, procedures, and dates.

# CELL ********************

run_sql_file("01_create_gold_dimensions.sql")

print("Created the Gold dimension tables.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 7. Create Gold fact tables
# 
# I create the encounter and procedure fact tables. I also calculate readmission logic, payer responsibility, duration flags, and reporting date keys.

# CELL ********************

run_sql_file("02_create_gold_facts.sql")

print("Created the Gold fact tables.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 8. Create Gold business views
# 
# I create business views that directly answer the main analytical questions for the project.

# CELL ********************

run_sql_file("03_create_gold_business_views.sql")

print("Created the Gold business views.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 9. Run Gold quality checks
# 
# I run row-count checks to confirm that the Gold tables were created successfully.

# CELL ********************

quality_df = run_sql_file("04_quality_checks.sql")
display(quality_df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 10. Preview business question outputs
# 
# I run the business question SQL file and display the final query result returned from the script.

# CELL ********************

business_output_df = run_sql_file("05_business_question_outputs.sql")
display(business_output_df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 11. Preview Gold objects
# 
# I confirm the Gold objects created in the Lakehouse.

# CELL ********************

print("Successfully built the Gold layer.")

spark.sql(f"SHOW TABLES IN {GOLD_SCHEMA}").show(truncate=False)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
