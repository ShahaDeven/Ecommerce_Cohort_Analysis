# Ecommerce Cohort Analysis — CLAUDE.md

## Project Overview

A pure-SQL analytics project analyzing the Olist Brazilian E-Commerce dataset (99K+ orders, $15.8M revenue) using PostgreSQL. The pipeline covers funnel analysis, cohort retention, CLV/RFM segmentation, and business insights, with exports for a Tableau Public dashboard.

---

## Project Structure

```
Ecommerce_Cohort_Analysis/
├── data/
│   ├── README.md                       # Dataset info & Kaggle download link
│   ├── olist_customers_dataset.csv     # 99,441 customers (gitignored)
│   ├── olist_orders_dataset.csv        # 99,441 orders with timestamps
│   ├── olist_order_items_dataset.csv   # 112,650 line items
│   ├── olist_order_payments_dataset.csv
│   ├── olist_order_reviews_dataset.csv
│   ├── olist_products_dataset.csv
│   └── exports/
│       ├── funnel_data.csv             # Tableau: funnel visualization
│       ├── cohort_retention.csv        # Tableau: retention heatmap
│       ├── clv_segments.csv            # Tableau: customer segmentation
│       └── monthly_revenue.csv         # Tableau: revenue trend
│
├── sql/
│   ├── 01_schema_creation.sql          # 6 tables, indexes, constraints
│   ├── 02_data_loading.sql             # COPY statements (update paths first!)
│   ├── 03_data_exploration.sql         # EDA — row counts, distributions, nulls
│   ├── 04_funnel_analysis.sql          # Order status funnel + conversion rates
│   ├── 05_cohort_analysis.sql          # Monthly retention cohorts
│   ├── 06_clv_segmentation.sql         # CLV, RFM scoring, customer tiers
│   └── 07_business_insights.sql        # Consolidated metrics + recommendations
│
└── visualizations/
    └── dashboard_preview.png
```

There are no Python files or notebooks — this is a pure SQL project.

---

## Tech Stack

| Component | Technology |
|---|---|
| **Database** | PostgreSQL 15+ |
| **SQL Client** | DBeaver Community Edition |
| **Visualization** | Tableau Public |
| **Dataset** | Olist Brazilian E-Commerce (Kaggle) |
| **Version Control** | Git |

---

## How to Run

### Prerequisites

- PostgreSQL 15+ running locally
- DBeaver (or `psql`)
- Dataset CSVs downloaded from Kaggle: `https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce`

### Setup

```sql
-- 1. Create the database
CREATE DATABASE ecommerce_analysis;
```

Then run the SQL scripts **in order** in DBeaver or psql:

```
01_schema_creation.sql   → creates 6 tables with indexes/constraints
02_data_loading.sql      → loads CSVs (update file paths first — see below)
03_data_exploration.sql  → EDA queries (run selectively, not all at once)
04_funnel_analysis.sql   → funnel metrics
05_cohort_analysis.sql   → retention cohorts
06_clv_segmentation.sql  → CLV & RFM segmentation
07_business_insights.sql → executive summary
```

### Updating File Paths in 02_data_loading.sql

Before running, replace the path placeholders with your local paths:

```sql
-- Windows
COPY olist_customers FROM 'C:/Users/YourName/path/to/data/olist_customers_dataset.csv' ...

-- Mac/Linux
COPY olist_customers FROM '/Users/YourName/path/to/data/olist_customers_dataset.csv' ...
```

### Exporting for Tableau

Run the export queries in the analysis scripts and save results as CSV to `data/exports/`. Upload to Tableau Public.

---

## Database Schema

6-table relational schema with referential integrity:

```
olist_customers   ──→  olist_orders  ──→  olist_order_items  ──→  olist_products
                            │
                            ├──→  olist_order_payments
                            └──→  olist_order_reviews
```

**Note on `olist_order_reviews`**: uses a composite primary key `(review_id, order_id)` to handle duplicate `review_id` values in the source data.

**Strategic indexes**: `order_purchase_timestamp`, `customer_unique_id`, `order_status`, `review_score` — do not remove these; they are critical for cohort query performance.

---

## SQL Coding Conventions

### File Headers

Every script starts with a consistent comment block:

```sql
-- =====================================================
-- E-COMMERCE FUNNEL & COHORT ANALYSIS PROJECT
-- 05 - COHORT ANALYSIS
-- =====================================================
```

### Section Headers

Numbered sections within each script:

```sql
-- =====================================================
-- SECTION 1: CUSTOMER COHORT DEFINITIONS
-- =====================================================
```

### Naming

- **Tables**: `olist_` prefix, snake_case — `olist_order_items`
- **Columns**: snake_case — `order_purchase_timestamp`, `customer_unique_id`
- **CTEs**: descriptive noun phrases reflecting purpose — `cohort_data`, `rfm_scores`, `monthly_funnel`
- **Aliases**: always use `AS` with a meaningful name — `AS total_revenue`, `AS funnel_stage`
- **Views**: `CREATE OR REPLACE VIEW` for reusable logic — `customer_cohorts`, `customer_lifetime_value`

### Query Patterns

**JOINs**: always use explicit `JOIN ... ON` syntax, never comma-separated tables.

**Filtering canceled/unavailable orders** — standard filter applied consistently:
```sql
WHERE order_status NOT IN ('canceled', 'unavailable')
```

**Conditional aggregation**:
```sql
COUNT(CASE WHEN condition THEN 1 END)
COUNT(DISTINCT CASE WHEN condition THEN customer_id END)
```

**Safe division** (always use NULLIF to avoid divide-by-zero):
```sql
metric * 100.0 / NULLIF(denominator, 0)
```

**Percentile calculations** — use CTE + CROSS JOIN pattern (not inline window functions):
```sql
WITH percentiles AS (
    SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY value) AS p75
    FROM table
)
SELECT t.*, p.p75
FROM table t CROSS JOIN percentiles p
```

**Multi-level CTEs** for complex logic — build up in stages, each CTE named for what it produces:
```sql
WITH base_data AS (...),
     aggregated AS (...),
     ranked AS (...)
SELECT ... FROM ranked
```

**Date operations**:
```sql
DATE_TRUNC('month', order_purchase_timestamp)   -- month grouping
EXTRACT(DAY FROM age(date2, date1))             -- interval in days
EXTRACT(EPOCH FROM interval) / 3600             -- convert to hours
```

**Segmentation with CASE WHEN**:
```sql
CASE
    WHEN days <= 7  THEN '0-7 days'
    WHEN days <= 30 THEN '8-30 days'
    ELSE '30+ days'
END AS time_bucket
```

**Ranking with window functions**:
```sql
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC)
NTILE(5) OVER (ORDER BY metric DESC)   -- for RFM quintiles
```

### Formatting

- Indent CTEs and subqueries consistently (4 spaces)
- Put each selected column on its own line for queries with 4+ columns
- Group related columns together (IDs, dates, metrics, flags)
- Use `ROUND(value, 2)` for all monetary and percentage outputs

---

## Key Architectural Decisions

- **Script ordering is mandatory**: scripts 01–07 have dependencies; always run in sequence.
- **Views over subqueries**: `customer_cohorts` and `customer_lifetime_value` are views because they are referenced across multiple scripts. Do not inline them.
- **No Python**: all analysis is SQL-only by design. Do not add Python scripts or notebooks.
- **Exports are manual**: run the relevant query, export via DBeaver/psql `\copy`, save to `data/exports/`. No automation script exists.
- **Data CSVs are gitignored**: never commit the raw Olist CSVs (large files, Kaggle terms).

---

## Key Metrics (for context)

| Metric | Value |
|---|---|
| Unique customers | 94,990 |
| Total orders | 98,207 |
| Total revenue | $15.8M |
| One-time customer rate | 96.88% |
| Top 5% revenue share | 35.4% |
| Repeat purchase within 7 days | 38% |
| Stuck revenue (approved, undelivered) | $317K |
