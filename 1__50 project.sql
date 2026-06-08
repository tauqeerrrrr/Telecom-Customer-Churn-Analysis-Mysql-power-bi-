create database churn_db;
use churn_db;
select * from telecom_churn;

-- BASIC PROBLEMS
##KPIS
#Total customers
select count(*) from telecom_churn;

-- Churn rate
select round(sum(case when Churn =1 then 1 else 0 end)*100/count(*),2) as "Churn Rate"
from telecom_churn;
DESCRIBE telecom_churn;

#Column definitions (quick reference)
-- Churn — 1=left company, 0=still active  |  AccountWeeks — kitne weeks se customer hai  |
--   ContractRenewal — 1=recently renewed, 0=nahi  |  DataPlan — 1=data plan hai, 0=nahi  |
--   DataUsage — GB data use kiya  |  CustServCalls — kitni baar customer service call ki  |
--   DayMins — daytime minutes used  |  DayCalls — daytime calls count  | 
--   MonthlyCharge — monthly bill ₹  |  OverageFee — extra usage charges  |  RoamMins — roaming minutes

-- missing values find karo
select * from telecom_churn
where AccountWeeks is null ;
select ContractRenewal, avg(Churn)*100 from telecom_churn
group by ContractRenewal;

-- Customer Service Calls vs Churn
select CustServCalls, avg(Churn)*100 as Churnrate from telecom_churn
group by 1 ;

SELECT
    CustServCalls,
    COUNT(*) AS TotalCustomers,
    SUM(Churn) AS ChurnedCustomers,
    ROUND(AVG(Churn) * 100, 2) AS ChurnRate
FROM telecom_churn
GROUP BY CustServCalls
ORDER BY CustServCalls;



-- MonthlyCharge distribution: Churned vs Active
SELECT
    Churn,
    COUNT(*) AS Total_Customers,
    ROUND(AVG(MonthlyCharge),2) AS Avg_MonthlyCharge
FROM telecom_churn
GROUP BY Churn;

SELECT
    Churn,
    COUNT(*) AS Customers,
    MIN(MonthlyCharge) AS Min_Charge,
    ROUND(AVG(MonthlyCharge),2) AS Avg_Charge,
    MAX(MonthlyCharge) AS Max_Charge
FROM telecom_churn
GROUP BY Churn;

-- Intermediate problems;

-- Tenure (AccountWeeks) analysis — do old customers also churn?
WITH customer_segments AS (
    SELECT *,
           CASE
               WHEN AccountWeeks < 24 THEN 'New'
               WHEN AccountWeeks < 48 THEN 'Growing'
               WHEN AccountWeeks < 96 THEN 'Mature'
               ELSE 'Loyal'
           END AS Customer_Label
    FROM telecom_churn
)
SELECT
    Customer_Label,
    COUNT(*) AS Total_Customers,
    ROUND(AVG(Churn) * 100, 2) AS Churn_Rate
FROM customer_segments
GROUP BY Customer_Label
ORDER BY
    CASE Customer_Label
        WHEN 'New' THEN 1
        WHEN 'Growing' THEN 2
        WHEN 'Mature' THEN 3
        WHEN 'Loyal' THEN 4
    END;
    
    
--    High-risk customer segment identify karo 
    WITH risk_table AS
(
SELECT *,
       (CASE WHEN CustServCalls > 3 THEN 1 ELSE 0 END +
        CASE WHEN OverageFee > 50 THEN 1 ELSE 0 END +
        CASE WHEN MonthlyCharge > 70 THEN 1 ELSE 0 END +
        CASE WHEN AccountWeeks < 20 THEN 1 ELSE 0 END +
        CASE WHEN DataPlan = 0 THEN 1 ELSE 0 END) AS RiskScore
FROM telecom_churn
)

SELECT *
FROM risk_table
WHERE RiskScore >= 4
ORDER BY RiskScore DESC;



