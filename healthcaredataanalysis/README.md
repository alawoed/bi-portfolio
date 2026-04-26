# Healthcare Data Analysis – End-to-End Enterprise BI Solution (Microsoft Fabric)

This project demonstrates an end-to-end enterprise-grade Business Intelligence solution built on Microsoft Fabric, implementing a Medallion Architecture (Bronze, Silver, Gold) to transform raw healthcare data into analytics-ready insights.

The solution simulates a real-world Healthcare ERP/CRM SaaS platform, where data is exposed via APIs (represented as JSON files), ingested into a Lakehouse, transformed using SQL and PySpark, and modeled into a highly optimized reporting layer.

---

## Architecture Overview

This project follows a Medallion Architecture pattern to structure data processing into distinct layers.

### Bronze Layer (Raw Data)

- JSON files simulate API responses from a healthcare platform
- Ingested into Fabric Lakehouse using PySpark
- Minimal transformation applied
- Ingestion metadata captured for traceability:
  - _source_file  
  - _source_system  
  - _ingestion_batch_id  
  - _ingested_at_utc  

---

### Silver Layer (Clean and Standardized Data)

- SQL-driven transformations using staging views
- Data cleansing, normalization, and standardization
- Includes:
  - Data type enforcement (timestamps, costs, identifiers)
  - Deduplication logic
  - Null handling and normalization
  - Standardization of categorical attributes
  - Temporal adjustments for realistic analytics

- Implements Slowly Changing Dimension (SCD Type 2):
  - valid_from  
  - valid_to  
  - is_current  
  - record_hash  

---

### Gold Layer (Analytics and Semantic Modeling)

- Star schema design optimized for reporting
- Fact and dimension tables created:

Fact Tables:
- fact_encounters  
- fact_procedures  

Dimension Tables:
- dim_patient  
- dim_payer  
- dim_organization  
- dim_procedure  
- dim_date  

- Business logic applied:
  - 30-day readmission tracking  
  - Encounter duration classification  
  - Cost and payer coverage calculations  

---

## Reporting Layer (Power BI)

- Power BI Project (PBIP) implementation
- Optimized semantic model design
- Query folding applied for performance optimization
- Incremental refresh implemented for scalability
- Row-Level Security (RLS) applied for user-based data access
- Object-Level Security (OLS) applied for sensitive data governance
- Data model aligned with Gold layer star schema

---

## Business Impact

This solution enables:

- Improved visibility into healthcare operations and patient activity  
- Identification of cost drivers and payer coverage gaps  
- Monitoring of patient readmissions and utilization trends  
- Data-driven decision-making for operational efficiency  
- Scalable and secure enterprise reporting  

---

## Technology Stack

- Microsoft Fabric (Lakehouse)
- PySpark (Data ingestion)
- SQL (Transformations and modeling)
- Delta Tables
- Power BI (PBIP)

---

## Data Flow

1. JSON files simulate API responses  
2. Data is ingested into Bronze using PySpark  
3. Data is transformed in Silver using SQL and SCD Type 2 logic  
4. Data is modeled into Gold star schema  
5. Data is consumed through optimized Power BI semantic models  

---

## Project Structure

```
healthcaredataanalysis/
│
├── HealthLakehouse.Lakehouse
├── notebooks/
│   ├── bronze_ingest_data.ipynb
│   ├── silver_build_data.ipynb
│   ├── gold_build_data.ipynb
│
├── sql/
│   ├── silver/
│   ├── gold/
│
└── README.md
```

---

## Key Highlights

- End-to-end enterprise data and BI architecture implementation  
- Medallion Architecture using Microsoft Fabric  
- API-based ingestion simulation using JSON data  
- SQL-driven transformation pipelines with SCD Type 2  
- Star schema data modeling for analytics  
- Performance-optimized Power BI semantic model (PBIP)  
- Query folding and incremental refresh implementation  
- Row-Level Security (RLS) and Object-Level Security (OLS)  
- Alignment of data engineering with business analytics outcomes  

---

## Author

David Alawoe  
Senior Data Analyst | Fabric Engineer