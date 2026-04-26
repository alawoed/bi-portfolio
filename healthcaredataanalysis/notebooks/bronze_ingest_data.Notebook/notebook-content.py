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

# # Ingest Raw JSON Files into Bronze Lakehouse
# 
# This notebook ingests raw JSON files for the Healthcare Provider Operations Analytics project into the **Bronze layer** of a Microsoft Fabric Lakehouse.
# 
# ## Purpose
# 
# The goal of this notebook is to:
# - Read raw JSON files from the python Notebook Resource Files area
# - Standardize table names
# - Add ingestion metadata
# - Write the files into Bronze Delta tables
# - Keep the Bronze layer close to the original source structure
# 
# ## Source Files
# 
# Expected JSON files:
# - `patients.json`
# - `payers.json`
# - `procedures.json`
# - `encounters.json`
# - `organizations.json`
# - `data_dictionary.json`
# 
# ## Target Bronze Tables
# 
# - `bronze_patients`
# - `bronze_payers`
# - `bronze_procedures`
# - `bronze_encounters`
# - `bronze_organizations`
# - `bronze_data_dictionary`

# MARKDOWN ********************

# ## 1. Configure Notebook Parameters
# 
# Update `RAW_FOLDER_PATH` if your JSON files are placed in a different Lakehouse folder.
# 
# Recommended python notebook resource file path:
# 
# ```text
# builtin/raw/
# ```

# CELL ********************

from pyspark.sql import functions as F
from datetime import datetime
import json
import pandas as pd

# ============================================================
# CONFIGURATION
# ============================================================

RAW_FOLDER_PATH = "builtin/raw"
BRONZE_SCHEMA = "bronze"

SOURCE_SYSTEM = "Healthcare_ERP_CRM_API"
INGESTION_BATCH_ID = datetime.utcnow().strftime("%Y%m%d%H%M%S")

# ============================================================
# VALIDATE RAW FILES EXIST
# ============================================================

import os

print(f"Checking files in: {RAW_FOLDER_PATH}\n")

try:
    available_files = os.listdir(RAW_FOLDER_PATH)
    
    print("Available files:")
    for f in available_files:
        print(f" - {f}")

except Exception as e:
    raise Exception(f"❌ Unable to access RAW folder: {e}")

json_sources = [
    {"source_file": "patients.json", "target_table": "bronze_patients"},
    {"source_file": "payers.json", "target_table": "bronze_payers"},
    {"source_file": "procedures.json", "target_table": "bronze_procedures"},
    {"source_file": "encounters.json", "target_table": "bronze_encounters"},
    {"source_file": "organizations.json", "target_table": "bronze_organizations"},
    {"source_file": "data_dictionary.json", "target_table": "bronze_data_dictionary"}
]

print(f"Ingestion Batch ID: {INGESTION_BATCH_ID}")





# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 2. Confirm Lakehouse Context
# 
# Run this section to confirm that the notebook is attached to the correct Fabric Lakehouse.

# CELL ********************

spark.sql("SHOW SCHEMAS").show(truncate=False)

print("Current Catalog:")
spark.sql("SELECT current_catalog()").show(truncate=False)

print("Current Schema / Database:")
spark.sql("SELECT current_database()").show(truncate=False)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 3. Create Bronze Schema
# 
# This creates the Bronze schema if it does not already exist.

# CELL ********************

spark.sql(f"CREATE SCHEMA IF NOT EXISTS {BRONZE_SCHEMA}")
print(f"Schema ready: {BRONZE_SCHEMA}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 4. Define Helper Functions
# 
# These functions are used to:
# - Clean column names
# - Read JSON files
# - Add ingestion metadata
# - Write data to Bronze Delta tables

# CELL ********************

# ============================================================
# COLUMN STANDARDIZATION
# ============================================================

def standardize_column_name(column_name: str) -> str:
    return (
        column_name.strip()
        .lower()
        .replace(" ", "_")
        .replace("-", "_")
        .replace("/", "_")
        .replace(".", "_")
        .replace("(", "")
        .replace(")", "")
    )


def standardize_dataframe_columns(df):
    """Applies standardized column names to a Spark DataFrame."""
    for original_col in df.columns:
        new_col = standardize_column_name(original_col)
        if original_col != new_col:
            df = df.withColumnRenamed(original_col, new_col)
    return df


# ============================================================
# METADATA
# ============================================================

def add_ingestion_metadata(df, source_file: str):
    return (
        df
        .withColumn("_source_file", F.lit(source_file))
        .withColumn("_source_system", F.lit(SOURCE_SYSTEM))
        .withColumn("_ingestion_batch_id", F.lit(INGESTION_BATCH_ID))
        .withColumn("_ingested_at_utc", F.current_timestamp())
    )


# ============================================================
# READ JSON (FIXED FOR BUILTIN PATH)
# ============================================================

def read_json_file(file_name: str):
    """
    Reads JSON from notebook resources (builtin path),
    then converts to Spark DataFrame.
    """
    file_path = f"{RAW_FOLDER_PATH}/{file_name}"

    with open(file_path, "r", encoding="utf-8") as f:
        records = json.load(f)

    pandas_df = pd.DataFrame(records)

    return spark.createDataFrame(pandas_df)


# ============================================================
# WRITE TO BRONZE (FIXED VARIABLE)
# ============================================================

def write_to_bronze_table(df, table_name: str):
    full_table_name = f"{BRONZE_SCHEMA}.{table_name}"

    (
        df.write
        .format("delta")
        .mode("overwrite")  # OK for your portfolio
        .option("overwriteSchema", "true")
        .saveAsTable(full_table_name)
    )

    return full_table_name

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 5. Ingest JSON Files into Bronze Tables
# 
# This loop reads each JSON source file and writes it into its corresponding Bronze table.

# CELL ********************

ingestion_results = []

for source in json_sources:
    source_file = source["source_file"]
    target_table = source["target_table"]

    print(f"Processing {source_file} -> {BRONZE_SCHEMA}.{target_table}")

    try:
        raw_df = read_json_file(source_file)
        standardized_df = standardize_dataframe_columns(raw_df)
        bronze_df = add_ingestion_metadata(standardized_df, source_file)

        full_table_name = write_to_bronze_table(bronze_df, target_table)

        row_count = int(bronze_df.count())
        column_count = int(len(bronze_df.columns))

        ingestion_results.append({
            "source_file": source_file,
            "target_table": full_table_name,
            "status": "SUCCESS",
            "row_count": row_count,
            "column_count": column_count,
            "error_message": ""
        })

        print(f"SUCCESS: {full_table_name} | Rows: {row_count} | Columns: {column_count}")

    except Exception as e:
        ingestion_results.append({
            "source_file": source_file,
            "target_table": f"{BRONZE_SCHEMA}.{target_table}",
            "status": "FAILED",
            "row_count": 0,
            "column_count": 0,
            "error_message": str(e)
        })

        print(f"FAILED: {source_file}")
        print(str(e))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 6. Review Ingestion Results
# 
# This displays a summary of files processed into Bronze.

# CELL ********************

results_df = spark.createDataFrame(ingestion_results)
display(results_df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 7. Validate Bronze Tables
# 
# This section confirms that each Bronze table was created and shows row counts.

# CELL ********************

for source in json_sources:
    table_name = f"{BRONZE_SCHEMA}.{source['target_table']}"
    print(f"Preview: {table_name}")
    spark.sql(f"SELECT COUNT(*) AS row_count FROM {table_name}").show()
    spark.sql(f"SELECT * FROM {table_name} LIMIT 5").show(truncate=False)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 8. Create Bronze Ingestion Audit Table
# 
# This audit table records each ingestion run and makes the pipeline easier to monitor.

# CELL ********************

audit_table_name = f"{BRONZE_SCHEMA}.bronze_ingestion_audit"

(
    results_df
    .withColumn("ingestion_batch_id", F.lit(INGESTION_BATCH_ID))
    .withColumn("source_system", F.lit(SOURCE_SYSTEM))
    .withColumn("audit_created_at_utc", F.current_timestamp())
    .write
    .format("delta")
    .mode("append")
    .saveAsTable(audit_table_name)
)

print(f"Audit table updated: {audit_table_name}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## 9. Bronze Layer Completion Notes
# 
# At this stage, the Bronze layer should contain raw JSON-ingested Delta tables.
# 
# The next notebook would create the **Silver layer**, where we will:
# - Parse and standardize dates
# - Convert costs and numeric fields
# - Remove duplicates
# - Handle nulls and invalid values
# - Build clean dimensions and fact tables
# - Prepare a star schema for Power BI

# CELL ********************

print("Bronze ingestion completed successfully.")
print(f"Batch ID: {INGESTION_BATCH_ID}")

spark.sql(f"SHOW TABLES IN {BRONZE_SCHEMA}").show(truncate=False)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
