# E-Commerce Funnel & Cohort Analysis

> **Analyzing 100K+ orders to optimize conversion and customer retention**

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![SQL](https://img.shields.io/badge/SQL-Advanced-blue)](https://github.com/yourusername/ecommerce-cohort-analysis)
[![Status](https://img.shields.io/badge/Status-In%20Progress-yellow)](https://github.com/yourusername/ecommerce-cohort-analysis)

---

## 📊 Project Overview

This project analyzes 2 years of Brazilian e-commerce data (100,000+ orders) to identify opportunities for improving conversion rates and customer retention. Using advanced SQL techniques including window functions, CTEs, and cohort logic, I'm uncovering critical insights about funnel drop-off points, repeat purchase behavior, and customer lifetime value distribution.

**Current Status:** Database setup complete ✅ | Analysis in progress 🔄

---

## 🎯 Project Goals

### Primary Objectives
1. **Funnel Analysis:** Identify conversion drop-off points in the order journey
2. **Cohort Analysis:** Measure customer retention by acquisition month
3. **CLV Segmentation:** Identify high-value customers and their characteristics

### Expected Deliverables
- Advanced SQL queries demonstrating analytical thinking
- Interactive visualizations (Tableau/Python)
- Actionable business recommendations
- Complete documentation and methodology

---

## 🛠️ Tools & Technologies

- **Database:** PostgreSQL 18
- **SQL Client:** DBeaver Community Edition
- **SQL Techniques:** Window functions, CTEs, cohort analysis, RFM segmentation
- **Visualization:** Tableau Public (planned)
- **Data Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

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
│   ├── 01_create_schema.sql           # ✅ Database schema creation
│   ├── 02_load_data.sql               # ✅ CSV import script
│   ├── 03_data_exploration.sql        # 🔄 Coming soon
│   ├── 04_funnel_analysis.sql         # 🔄 Coming soon
│   ├── 05_cohort_analysis.sql         # 🔄 Coming soon
│   ├── 06_clv_segmentation.sql        # 🔄 Coming soon
│   └── 07_business_insights.sql       # 🔄 Coming soon
│
├── visualizations/                    # 🔄 Coming soon
│   └── (Tableau dashboards and charts)
│
└── docs/                              # 🔄 Coming soon
    └── (Methodology and recommendations)
```

---

## 📦 Dataset Information

**Source:** Brazilian E-Commerce Public Dataset by Olist  
**Platform:** Kaggle  
**Size:** ~100,000 orders from September 2016 to August 2018  
**Tables Used:** 6 core tables

### Tables
1. **olist_customers** (~99,000 customers) - Customer demographics
2. **olist_orders** (~99,000 orders) - Order details and timestamps
3. **olist_order_items** (~112,000 items) - Line items and pricing
4. **olist_order_payments** (~103,000 payments) - Payment information
5. **olist_order_reviews** (~99,000 reviews) - Customer satisfaction scores
6. **olist_products** (~32,000 products) - Product categories and attributes

---

## 🚀 How to Reproduce (Setup Phase)

### Prerequisites
- PostgreSQL 15+ installed
- DBeaver (or another SQL client)
- Dataset downloaded from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

### Setup Steps (Completed ✅)

1. **Clone this repository**
   ```bash
   git clone https://github.com/yourusername/ecommerce-cohort-analysis.git
   cd ecommerce-cohort-analysis
   ```

2. **Download the dataset**
   - Visit [Kaggle Olist Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
   - Download and extract CSVs to `data/` folder (not tracked in git)

3. **Create database**
   ```sql
   CREATE DATABASE ecommerce_analysis;
   ```

4. **Run schema creation script**
   - Open `sql/01_create_schema.sql` in DBeaver
   - Execute the entire script
   - Verify 6 tables created with proper relationships

5. **Load data**
   - Update file paths in `sql/02_load_data.sql` to match your local setup
   - Execute the script
   - Verify row counts match expected values

### Expected Results After Setup
- ✅ 6 tables created with proper foreign keys
- ✅ ~99,000 rows in olist_orders
- ✅ ~99,000 rows in olist_customers
- ✅ ~112,000 rows in olist_order_items
- ✅ ~103,000 rows in olist_order_payments
- ✅ All integrity checks passing

---

## 🔍 Analysis Plan (Upcoming)

### Phase 1: Data Exploration ⏳
- Customer demographics and geographic distribution
- Order trends (monthly, daily, hourly patterns)
- Revenue analysis and payment types
- Product category performance

### Phase 2: Funnel Analysis ⏳
- Order status funnel (placed → approved → shipped → delivered)
- Conversion rates at each stage
- Drop-off analysis and revenue impact
- Time spent in each funnel stage

### Phase 3: Cohort Analysis ⏳
- Customer cohorts by first purchase month
- Month-over-month retention rates
- Repeat purchase behavior
- Time to second purchase analysis

### Phase 4: CLV Segmentation ⏳
- Customer lifetime value calculation
- RFM (Recency, Frequency, Monetary) segmentation
- High-value customer characteristics
- Opportunity identification (win-back, upsell)

### Phase 5: Business Insights ⏳
- Executive summary of key findings
- Actionable recommendations
- Expected impact analysis

---

## 💡 Technical Highlights

### SQL Techniques Demonstrated
- ✅ Complex table schema design with referential integrity
- ✅ Composite primary keys for handling data quality issues
- ✅ Performance indexing strategy
- 🔄 Window functions (ROW_NUMBER, FIRST_VALUE, PERCENTILE_CONT)
- 🔄 Multi-level CTEs for complex calculations
- 🔄 Date manipulation and cohort logic
- 🔄 Self-joins for sequential analysis

---

## 📚 Documentation

> **Note:** Documentation will be added as analysis progresses

- [ ] Data Dictionary - Complete schema documentation
- [ ] Methodology - How cohorts and CLV are calculated
- [ ] Business Recommendations - Full executive summary
- [ ] Visualization Guide - Dashboard usage instructions

---

## 🎓 Skills Demonstrated

✅ **Database Design:** Schema creation, referential integrity, indexing strategy  
✅ **Data Quality:** Handling duplicates, missing values, data type selection  
🔄 **SQL Mastery:** Complex queries, window functions, CTEs (in progress)  
🔄 **Business Acumen:** Translating data into insights (in progress)  
🔄 **Data Visualization:** Tableau dashboards (planned)  
🔄 **Communication:** Documentation and storytelling (in progress)

---

## 🙏 Acknowledgments

- Dataset provided by [Olist](https://olist.com/) via [Kaggle](https://www.kaggle.com/olistbr)
- Inspired by real-world e-commerce analytics challenges

---