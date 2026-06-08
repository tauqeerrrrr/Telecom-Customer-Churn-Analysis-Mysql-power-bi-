
# 📊 Telecom Customer Churn Analysis
### SQL + Power BI End-to-End Data Analytics Project

![Dashboard Preview](dashboard_preview.png)

---

## 🏢 Business Problem

**TeleConnect** is a mid-size telecom company facing a serious challenge — **14.49% of its 3,333 customers have churned**, resulting in significant revenue loss every month.

The management asked:
> *"Who is churning, why are they churning, and what can we do to stop it?"*

This project answers all three questions using a complete data pipeline — from raw data in MySQL to an interactive Power BI dashboard.

---

## 🎯 Project Objectives

- Identify the overall churn rate and active vs churned customer split
- Find which customer segments have the highest churn risk
- Analyze the relationship between customer service calls and churn
- Segment customers by tenure (New / Growing / Mature / Loyal)
- Build an interactive dashboard for business decision-makers

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| **MySQL** | Data storage, cleaning, and SQL analysis queries |
| **Power BI Desktop** | Data modeling, DAX measures, and interactive dashboard |
| **Power Query (M)** | Data transformation and custom column creation |
| **DAX** | KPI measures, churn rate calculations, segmentation logic |

---

## 📁 Project Structure

```
telecom-churn-analysis/
│
├── data/
│   └── telecom_churn_raw.csv          # Original dataset
│
├── sql/
│   ├── 01_create_tables.sql           # Database & table setup
│   ├── 02_data_cleaning.sql           # Null handling, type fixes
│   ├── 03_churn_analysis.sql          # Core churn queries
│   ├── 04_retention_analysis.sql      # At-risk customer queries
│   └── 05_segment_analysis.sql        # Customer segmentation
│
├── powerbi/
│   └── telecom_churn_dashboard.pbix   # Power BI report file
│
├── screenshots/
│   └── dashboard_preview.png          # Dashboard screenshot
│
└── README.md
```

---

## 🗄️ Dataset Overview

**Source:** Telecom customer dataset (3,333 rows)

| Column | Description |
|--------|-------------|
| `Churn` | 1 = churned, 0 = active |
| `AccountWeeks` | How many weeks customer has been with company |
| `ContractRenewal` | 1 = recently renewed contract |
| `DataPlan` | 1 = has data plan, 0 = no plan |
| `DataUsage` | GB of data used per month |
| `CustServCalls` | Number of customer service calls made |
| `DayMins` | Total daytime call minutes |
| `DayCalls` | Total daytime calls count |
| `MonthlyCharge` | Monthly bill amount ($) |
| `OverageFee` | Extra usage charges ($) |
| `RoamMins` | Roaming minutes used |

---

## 🗃️ SQL Workflow

### Step 1 — Database Setup & Data Import

```sql
CREATE DATABASE telecom_db;
USE telecom_db;

CREATE TABLE churn_data (
    customer_id    INT PRIMARY KEY AUTO_INCREMENT,
    Churn          INT,
    AccountWeeks   INT,
    ContractRenewal INT,
    DataPlan       INT,
    DataUsage      FLOAT,
    CustServCalls  INT,
    DayMins        FLOAT,
    DayCalls       INT,
    MonthlyCharge  FLOAT,
    OverageFee     FLOAT,
    RoamMins       FLOAT
);
```

### Step 2 — Data Cleaning

```sql
-- Check for nulls
SELECT
    SUM(CASE WHEN Churn IS NULL THEN 1 ELSE 0 END)          AS null_churn,
    SUM(CASE WHEN CustServCalls IS NULL THEN 1 ELSE 0 END)   AS null_calls,
    SUM(CASE WHEN MonthlyCharge IS NULL THEN 1 ELSE 0 END)   AS null_charge
FROM churn_data;

-- Remove any invalid rows
DELETE FROM churn_data
WHERE MonthlyCharge <= 0 OR AccountWeeks <= 0;

-- Add customer segment column
ALTER TABLE churn_data ADD COLUMN CustomerSegment VARCHAR(20);

UPDATE churn_data
SET CustomerSegment = CASE
    WHEN AccountWeeks <= 26  THEN 'New'
    WHEN AccountWeeks <= 52  THEN 'Growing'
    WHEN AccountWeeks <= 104 THEN 'Mature'
    ELSE 'Loyal'
END;
```

### Step 3 — Core Churn Analysis

```sql
-- Overall churn metrics
SELECT
    COUNT(*)                                        AS Total_Customers,
    SUM(Churn)                                      AS Total_Churned,
    SUM(1 - Churn)                                  AS Total_Active,
    ROUND(AVG(Churn) * 100, 2)                      AS Churn_Rate_Pct
FROM churn_data;
-- Result: 3333 total | 483 churned | 2850 active | 14.49%

-- Churn rate by CustServCalls
SELECT
    CustServCalls,
    COUNT(*)                               AS Total_Customers,
    SUM(Churn)                             AS Churned,
    ROUND(AVG(Churn) * 100, 2)            AS Churn_Rate_Pct
FROM churn_data
GROUP BY CustServCalls
ORDER BY CustServCalls;
-- Key finding: 9 calls = 100% churn rate!

-- Churn by customer segment
SELECT
    CustomerSegment,
    COUNT(*)                               AS Total,
    SUM(Churn)                             AS Churned,
    ROUND(AVG(Churn) * 100, 2)            AS Churn_Rate_Pct,
    ROUND(COUNT(*) * 100.0 /
          (SELECT COUNT(*) FROM churn_data), 2) AS Pct_of_Total
FROM churn_data
GROUP BY CustomerSegment
ORDER BY Churn_Rate_Pct DESC;
```

### Step 4 — Retention & Risk Analysis

```sql
-- High-risk active customers (priority retention targets)
SELECT
    customer_id,
    AccountWeeks,
    CustServCalls,
    MonthlyCharge,
    OverageFee,
    ContractRenewal,
    CustomerSegment
FROM churn_data
WHERE Churn = 0
  AND CustServCalls >= 3
  AND ContractRenewal = 0
  AND OverageFee > (SELECT AVG(OverageFee) FROM churn_data)
ORDER BY CustServCalls DESC, OverageFee DESC;

-- Revenue at risk from high-risk active customers
SELECT
    COUNT(*)                         AS At_Risk_Customers,
    ROUND(SUM(MonthlyCharge), 2)     AS Monthly_Revenue_At_Risk,
    ROUND(SUM(MonthlyCharge) * 12, 2) AS Annual_Revenue_At_Risk
FROM churn_data
WHERE Churn = 0
  AND CustServCalls >= 3
  AND ContractRenewal = 0;

-- DataPlan upsell opportunity
SELECT
    COUNT(*)                           AS No_Plan_High_Usage,
    ROUND(AVG(OverageFee), 2)          AS Avg_Overage,
    ROUND(AVG(Churn) * 100, 2)        AS Churn_Rate_Pct
FROM churn_data
WHERE DataPlan = 0
  AND DataUsage > (SELECT AVG(DataUsage) FROM churn_data);
```

---

## 📊 Power BI Dashboard

### DAX Measures Used

```dax
-- Core KPIs
Total Customers = COUNTROWS(churn_data)

Total Churn Cust = CALCULATE(COUNTROWS(churn_data), churn_data[Churn] = 1)

Total Churn Cust Rate = DIVIDE([Total Churn Cust], [Total Customers], 0)

Total Active Cust = CALCULATE(COUNTROWS(churn_data), churn_data[Churn] = 0)

-- Churn Rate by CustServCalls
Churn Rate by Calls =
    CALCULATE(
        DIVIDE(
            COUNTROWS(FILTER(churn_data, churn_data[Churn] = 1)),
            COUNTROWS(churn_data),
            0
        )
    )

-- Customer Segment (Calculated Column)
CustomerSegment =
    SWITCH(
        TRUE(),
        churn_data[AccountWeeks] <= 26,  "New",
        churn_data[AccountWeeks] <= 52,  "Growing",
        churn_data[AccountWeeks] <= 104, "Mature",
        "Loyal"
    )
```

### Dashboard Components

| Visual | Insight |
|--------|---------|
| 4 KPI Cards | Total customers, churned, churn rate, active |
| Horizontal Bar Chart | Active customers by CustServCalls count |
| Table | Churn rate % by each CustServCalls level |
| Pie Chart (dual) | Churn rate vs total customers by segment |

---

## 📈 Key Findings

### 1. Overall Churn
- **3,333 total customers** — **483 churned (14.49%)**
- **2,850 customers** are still active

### 2. Customer Service Calls = Strongest Churn Signal
| Calls | Churn Rate |
|-------|-----------|
| 0–1 | ~10–13% |
| 3 | 45.78% |
| 5 | 60.61% |
| 7 | 55.56% |
| 9 | **100%** |

> **Insight:** Any customer calling support 3+ times is at serious churn risk. Proactive outreach should trigger at the 3rd call.

### 3. Customer Segment Analysis
| Segment | Churn Rate | % of Total Customers |
|---------|-----------|---------------------|
| Loyal | 13.33% | 23.56% |
| Mature | 14.76% | 26.08% |
| Growing | 13.43% | 23.73% |
| New | **15.06%** | 26.62% |

> **Insight:** New customers churn the most — the first 6 months (0–26 weeks) are the critical retention window.

---

## 💡 Business Recommendations

**1. Trigger proactive outreach after 3 customer service calls**
Set up an automated alert in CRM: if `CustServCalls >= 3`, assign to retention team immediately.

**2. Focus new customer onboarding (0–26 weeks)**
New segment has highest churn at 15.06%. A 30/60/90 day onboarding program can significantly reduce early churn.

**3. DataPlan upsell campaign for no-plan high-usage customers**
Customers without a data plan but with above-average usage pay high overage fees — they churn more AND cost the company satisfaction. Offer them a plan proactively.

**4. Contract renewal incentive for `ContractRenewal = 0` customers**
These customers are month-to-month and more likely to leave. A small discount for annual contract renewal reduces churn significantly.

---

## 🚀 How to Run This Project

### MySQL Setup
```bash
# 1. Create database
mysql -u root -p < sql/01_create_tables.sql

# 2. Import CSV data
LOAD DATA INFILE 'telecom_churn_raw.csv'
INTO TABLE churn_data
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

# 3. Run cleaning and analysis scripts
mysql -u root -p telecom_db < sql/02_data_cleaning.sql
mysql -u root -p telecom_db < sql/03_churn_analysis.sql
```

### Power BI Setup
1. Open `powerbi/telecom_churn_dashboard.pbix` in Power BI Desktop
2. Go to **Transform Data** → update MySQL server credentials
3. Click **Refresh** to load latest data
4. Publish to Power BI Service for sharing

---

## 📚 Skills Demonstrated

- ✅ MySQL database design and data import
- ✅ SQL data cleaning (null handling, type validation)
- ✅ SQL analytical queries (aggregation, GROUP BY, CASE WHEN)
- ✅ Customer segmentation using SQL and DAX
- ✅ Churn and retention analysis
- ✅ Power BI data modeling (relationships, star schema)
- ✅ DAX measures (CALCULATE, DIVIDE, SWITCH, COUNTROWS)
- ✅ Interactive dashboard design (KPI cards, charts, tables)
- ✅ Business insight communication

---

## 👤 Author

**[Touqeer Hasan]**
Data Analyst | SQL · Python · Power BI · Excel

- 🔗 [LinkedIn](www.linkedin.com/in/tauqeerhasan)
- 📧 hasantauqeer128@gmail.com

---www.linkedin.com/in/tauqeerhasan


