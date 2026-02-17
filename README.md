# E-Commerce Funnel & Cohort Analysis

> **Analyzing 95,000 customers and $15.8M in revenue to optimize conversion and retention**

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![SQL](https://img.shields.io/badge/SQL-Advanced-blue)](https://github.com/yourusername/ecommerce-cohort-analysis)
[![Status](https://img.shields.io/badge/Status-In%20Progress-yellow)](https://github.com/yourusername/ecommerce-cohort-analysis)

---

## 📊 Project Overview

This project analyzes 2 years of e-commerce transactional data (95,000 customers, 98,000+ orders) to identify opportunities for improving conversion rates and customer retention. Using advanced SQL techniques including window functions, CTEs, and cohort logic, I am uncovering critical insights about funnel drop-off points, repeat purchase behavior, and customer lifetime value distribution.

**Current Status:** Database setup ✅ | Exploration & Funnel Analysis ✅ | Cohort Analysis ✅ | CLV Segmentation 🔄

---

### 🔑 Key Findings So Far

1. **🚨 Retention Crisis:** Only **3% of customers** ever make a second purchase (industry standard: 25%+)
2. **📉 Worsening Over Time:** Cohort repeat rates collapsed **10x** from 5.38% (mid-2017) to 0.56% (mid-2018)
3. **🔽 Funnel Drop-off:** **$317,366** in approved orders never delivered — immediately recoverable
4. **⏰ 7-Day Window:** 38% of repeat customers return within 1 week of delivery
5. **📦 Delivery Gap:** Late deliveries drop satisfaction by **1.73 points** (4.29 → 2.57)

---

## 🛠️ Tools & Technologies

- **Database:** PostgreSQL 18
- **SQL Client:** DBeaver Community Edition
- **SQL Techniques:** Window functions, CTEs, cohort analysis, self-joins, date manipulation
- **Data Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Visualization:** Coming in Phase 3

---

## 📁 Project Structure

```
ecommerce-cohort-analysis/
│
├── README.md                          # Project documentation (you are here)
├── .gitignore                         # Excludes data files and credentials
│
├── data/
│   └── README.md                      # Dataset information and download instructions
│
├── sql/
│   ├── 01_create_schema.sql           # ✅ Database schema (6 tables, indexes, constraints)
│   ├── 02_load_data.sql               # ✅ CSV import script
│   ├── 03_data_exploration.sql        # ✅ EDA - customer overview, revenue, delivery
│   ├── 04_funnel_analysis.sql         # ✅ Funnel conversion, drop-off, segmentation
│   ├── 05_cohort_analysis.sql         # ✅ Retention matrix, repeat purchase behavior
│   ├── 06_clv_segmentation.sql        # 🔄 CLV calculation, RFM segmentation
│   └── 07_business_insights.sql       # 🔄 Executive summary & recommendations
│
└── visualizations/                    # ⏳ Coming in Phase 3
```

---

## 📦 Dataset Information

**Source:** Brazilian E-Commerce Public Dataset by Olist
**Size:** ~100,000 orders | September 2016 - August 2018
**Tables Used:** 6 core tables

| Table | Rows | Description |
|-------|------|-------------|
| olist_customers | 99,441 | Customer demographics |
| olist_orders | 99,441 | Order details and timestamps |
| olist_order_items | 112,650 | Line items and pricing |
| olist_order_payments | 103,886 | Payment information |
| olist_order_reviews | 99,224 | Customer satisfaction scores |
| olist_products | 32,951 | Product categories and attributes |

---

## 🔍 Analysis So Far

### 1. 📊 Data Exploration

**Business Scale:**
- **94,990** unique customers | **98,207** total orders | **$15,810,806** total revenue
- Average order value: **$161.72** | Average review score: **4.11 / 5.0**

**Customer Behavior:**
- **96.88%** are one-time customers — only **3.12%** ever return
- **90%** of orders contain just **1 item** (low basket size)
- Peak ordering hours: **10 AM - 8 PM** | Busiest day: **Monday**

**Delivery Performance:**
- **97.02%** overall delivery rate | Average delivery time: **12.1 days**
- On-time: **91.89%** | Late deliveries drop satisfaction from **4.29 → 2.57**

[View SQL →](sql/03_data_exploration.sql)

---

### 2. 🔽 Funnel Analysis

**Funnel Conversion:**

| Stage | Orders | Drop-off Rate |
|-------|--------|---------------|
| 1. Order Placed | 98,207 | — |
| 2. Order Approved | 98,188 | **0.02%** |
| 3. Order Shipped | 97,583 | **0.62%** |
| 4. Order Delivered | 96,470 | **1.14%** 🚨 |

**Key Findings:**
- Overall conversion rate: **98.23%**
- **$317,366** in approved orders never delivered (1,729 stuck orders)
- High-value orders ($200+) have **worse** delivery rates than low-value — counterintuitive!
- **BA state** worst delivery (97.37%) vs **RS state** best (98.76%) — 1.4% regional gap

[View SQL →](sql/04_funnel_analysis.sql)

---

### 3. 🔁 Cohort Analysis

**Retention Summary:**

| Metric | Value |
|--------|-------|
| Average Month-1 Retention | **0.45%** 🚨 |
| Best Cohort (Jun 2017) | **5.38%** repeat rate |
| Worst Cohort (Aug 2018) | **0.56%** repeat rate |
| Average Cohort Repeat Rate | **3.38%** |

**Critical Finding — Retention Collapse:**
- Mid-2017 cohorts: **~5% repeat rate**
- Mid-2018 cohorts: **~0.5% repeat rate**
- **10x deterioration in 12 months** — structural problem, not seasonal

**Time to Second Purchase:**

| Timeframe | % of Repeat Customers |
|-----------|----------------------|
| Within 1 week | **37.67%** 🏆 |
| Within 1 month | 13.43% |
| Within 2 months | 10.53% |
| After 6 months | 17.04% |

**38% of repeat customers return within 7 days** — critical re-engagement window.

[View SQL →](sql/05_cohort_analysis.sql)

---

### 4. 💰 CLV Segmentation & Business Insights
> 🔄 **In progress** — results coming soon

---

## 💡 Technical Highlights

### SQL Techniques Used So Far

- ✅ **Window Functions:** `ROW_NUMBER()`, `FIRST_VALUE()`, `PERCENTILE_CONT()`
- ✅ **Multi-level CTEs:** Complex cohort calculations with 3-4 nested CTE layers
- ✅ **Date Manipulation:** `DATE_TRUNC()`, `AGE()`, `EXTRACT(EPOCH FROM ...)` for time-based cohorts
- ✅ **Self-Joins:** Customer order sequence for repeat purchase timing
- ✅ **Cohort Logic:** Acquisition cohorts with month-over-month retention tracking
- ✅ **Conditional Aggregation:** `COUNT(CASE WHEN ...)` for pivot-style analysis
- 🔄 **RFM Segmentation:** `NTILE(5)` scoring — coming in script 06

### Data Quality Issues Handled
- Duplicate `review_id` values in source data → Fixed with composite primary key `(review_id, order_id)`
- NULL timestamps for in-progress orders → Handled with `IS NOT NULL` filters
- Ambiguous column references across JOINs → Resolved with explicit table aliases
- `FIRST_VALUE()` aggregation conflict → Refactored to pre-aggregated CTE approach

---

## 🚀 How to Reproduce

### Prerequisites
- PostgreSQL 15+ installed
- DBeaver (or another SQL client)
- Dataset from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

### Setup Steps

1. **Clone this repository**
   ```bash
   git clone https://github.com/yourusername/ecommerce-cohort-analysis.git
   cd ecommerce-cohort-analysis
   ```

2. **Download the dataset**
   - Visit [Kaggle Olist Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
   - Extract CSVs to `data/` folder

3. **Create database**
   ```sql
   CREATE DATABASE ecommerce_analysis;
   ```

4. **Run scripts in order**
   ```
   01_create_schema.sql    → Creates 6 tables with indexes and constraints
   02_load_data.sql        → Update file paths, then load all CSVs
   03_data_exploration.sql → Exploratory data analysis
   04_funnel_analysis.sql  → Funnel conversion metrics
   05_cohort_analysis.sql  → Customer retention analysis
   ```

   > **Note:** Update file paths in `02_load_data.sql` to match your local directory

---

## 📊 Sample Query

### Cohort Retention Calculation
```sql
-- Group customers by their first purchase month (cohort)
-- Then track what % return in each subsequent month
WITH cohort_data AS (
    SELECT 
        cc.customer_unique_id,
        cc.cohort_month,
        -- Calculate how many months after cohort month this purchase happened
        EXTRACT(YEAR FROM AGE(
            DATE_TRUNC('month', o.order_purchase_timestamp), 
            cc.cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(
            DATE_TRUNC('month', o.order_purchase_timestamp), 
            cc.cohort_month)) as months_since_cohort
    FROM customer_cohorts cc
    JOIN olist_customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN olist_orders o ON c.customer_id = o.customer_id
)
SELECT 
    cohort_month,
    -- Month 0 = cohort size (everyone who joined that month)
    -- Month 1 = how many came back the next month
    ROUND(COUNT(DISTINCT CASE WHEN months_since_cohort = 1 
        THEN customer_unique_id END) * 100.0 / 
        COUNT(DISTINCT CASE WHEN months_since_cohort = 0 
        THEN customer_unique_id END), 2) as month_1_retention
FROM cohort_data
GROUP BY cohort_month
ORDER BY cohort_month;
```
---

## 🎓 Skills Demonstrated

- ✅ **Database Design:** Schema creation, referential integrity, indexing strategy
- ✅ **Data Quality:** Handling duplicates, NULL values, ambiguous references
- ✅ **SQL Mastery:** Window functions, multi-level CTEs, self-joins, date arithmetic
- ✅ **Analytical Thinking:** Identified retention collapse and funnel revenue leakage
- 🔄 **Business Acumen:** Recommendations in progress (script 07)
- ⏳ **Data Visualization:** Tableau dashboards — Phase 3

---

## 🙏 Acknowledgments

- Dataset provided by [Olist](https://olist.com/) via [Kaggle](https://www.kaggle.com/olistbr)
- Inspired by real-world e-commerce analytics challenges

---