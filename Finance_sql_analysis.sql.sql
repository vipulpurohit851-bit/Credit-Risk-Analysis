CREATE DATABASE FINANCE;
USE  FINANCE;

CREATE OR REPLACE TABLE APPLICATION_TRAIN(
SK_ID_CURR	INT PRIMARY KEY,
TARGET INT,
NAME_CONTRACT_TYPE	TEXT,
CODE_GENDER	TEXT,
LAG_OWN_CAR	TEXT,
FLAG_OWN_REALTY	TEXT,
CNT_CHILDREN	INT,
AMT_INCOME_TOTAL  FLOAT,
AMT_CREDIT	FLOAT,
AMT_ANNUITY	FLOAT,
AMT_GOODS_PRICE FLOAT,
NAME_INCOME_TYPE  TEXT,
NAME_FAMILY_STATUS	TEXT,
OCCUPATION_TYPE	TEXT,
CNT_FAM_MEMBERS	INT,
REGION_RATING_CLIENT INT 
);

CREATE OR REPLACE TABLE BUREAU(
SK_ID_CURR	INT PRIMARY KEY,
CREDIT_ACTIVE	TEXT,
DAYS_CREDIT	INT,
AMT_CREDIT_SUM	FLOAT,
AMT_CREDIT_SUM_DEBT	FLOAT,
AMT_CREDIT_SUM_OVERDUE	FLOAT,
CREDIT_TYPE TEXT,

FOREIGN KEY(SK_ID_CURR) REFERENCES APPLICATION_TRAIN(SK_ID_CURR)
);

CREATE OR REPLACE TABLE PREVIOUS_APPLICATION(
SK_ID_CURR	INT PRIMARY KEY,
NAME_CONTRACT_TYPE	TEXT,
AMT_APPLICATION	FLOAT,
AMT_CREDIT	FLOAT,
AMT_ANNUITY	FLOAT,
NAME_CONTRACT_STATUS	TEXT,
NAME_PAYMENT_TYPE	TEXT,
NAME_CLIENT_TYPE	TEXT,
NAME_GOODS_CATEGORY	TEXT,
CNT_PAYMENT	INT,
DAYS_DECISION INT,

FOREIGN KEY(SK_ID_CURR) REFERENCES APPLICATION_TRAIN(SK_ID_CURR)
);

CREATE OR REPLACE TABLE INSTALLMENT_SUMMARY(
SK_ID_CURR	INT PRIMARY KEY,
TOTAL_PAYMENT	FLOAT,
TOTAL_INSTALMENT FLOAT,
AVG_DELAY FLOAT,

FOREIGN KEY(SK_ID_CURR) REFERENCES APPLICATION_TRAIN(SK_ID_CURR)
);

CREATE OR REPLACE TABLE CREDIT_CARD_SUMMARY(
SK_ID_CURR	INT  PRIMARY KEY,
AVG_BALANCE	FLOAT,
AVG_CREDIT_LIMIT	FLOAT,
TOTAL_CC_PAYMENT	FLOAT,
TOTAL_RECEIVABLE FLOAT,

FOREIGN KEY(SK_ID_CURR) REFERENCES APPLICATION_TRAIN(SK_ID_CURR)
);

CREATE OR REPLACE TABLE POS_CASH_SUMMARY(
SK_ID_CURR	INT PRIMARY KEY,
AVG_INSTALMENTS	FLOAT,
AVG_INSTALMENTS_FUTURE	FLOAT,
AVG_DPD	FLOAT,
AVG_DPD_DEF FLOAT,

FOREIGN KEY(SK_ID_CURR) REFERENCES APPLICATION_TRAIN(SK_ID_CURR)
);


SELECT * FROM APPLICATION_TRAIN;
SELECT * FROM BUREAU;
SELECT * FROM PREVIOUS_APPLICATION;
SELECT * FROM INSTALLMENT_SUMMARY;
SELECT * FROM CREDIT_CARD_SUMMARY;
SELECT * FROM POS_CASH_SUMMARY;

-- 1. Total Customers

SELECT COUNT(*)AS TOTAL_CUSTOMERS FROM APPLICATION_TRAIN;

# TOTAL CUSTOMERS IS 307511


-- 2. DEFAULT RATE

SELECT COUNT(CASE WHEN TARGET = 1 THEN 1 END)* 100.0 / COUNT(*) AS DEFAULT_RATE
FROM APPLICATION_TRAIN;

# DEFAULT RATE IS 8.07

-- 3. CUSTOMER BY GENDER 

SELECT CODE_GENDER,COUNT(*)AS TOTAL_CUSTOMERS
FROM APPLICATION_TRAIN
GROUP BY CODE_GENDER;

# FEMALE CUSTOMERS IS 202448.
# MALE CUSTOMERS IS 105059.

-- 4. DEFAULT RATE BY GENDER 

SELECT CODE_GENDER,COUNT(CASE WHEN TARGET = 1 THEN 1 END)* 100.0 / COUNT(*) AS DEFAULT_RATE
FROM APPLICATION_TRAIN
GROUP BY CODE_GENDER;

# FEMALE DEFAULT RATE IS 7.
# MALE DEFAULT RATE IS 10.14.

-- 5. Income vs Default

SELECT 
CASE 
WHEN AMT_INCOME_TOTAL < 100000 THEN 'LOW'
WHEN AMT_INCOME_TOTAL < 300000 THEN 'MEDIUM'
ELSE 'HIGH'
END AS INCOME_GROUP,
AVG(TARGET)AS DEFAULT_RATE
FROM APPLICATION_TRAIN
GROUP BY INCOME_GROUP;

# HIGH INCOME GROUP DEFAULT RATE IS 6%.
# MEDIUM INCOME GROUP DEFAULT RATE IS 8.25%.
# LOW INCOME GROUP DEFAULT RATE IS 8.20%.

# High-income customers exhibit lower default rates compared to medium and low-income groups. However, the similarity in default rates between medium and low-income groups indicates that income alone is not a strong predictor of default risk.

-- 6. CREDIT-TO-INCOME RATIO

SELECT TARGET,AVG(AMT_CREDIT/AMT_INCOME_TOTAL)AS AVG_RATIO
FROM APPLICATION_TRAIN
GROUP BY TARGET;

# The average credit-to-income ratio is similar for both default and non-default customers, indicating that mean values alone may not capture the underlying risk pattern. However, distribution analysis shows that higher ratios are associated with increased default risk.

SELECT 
CASE 
WHEN AMT_CREDIT/AMT_INCOME_TOTAL < 2 THEN 'LOW'
WHEN AMT_CREDIT/AMT_INCOME_TOTAL < 5 THEN 'MEDIUM'
ELSE 'HIGH'
END AS RATIO_GROUP,
AVG(TARGET)AS DEFAULT_RATE
FROM APPLICATION_TRAIN
GROUP BY RATIO_GROUP;

# The analysis shows that customers with medium credit-to-income ratios have the highest default rate, indicating a non-linear relationship between credit burden and risk. Extremely high ratios may be filtered during loan approval, resulting in relatively lower observed default rates.

# 1. 8.7% MEDIUM ratio has highest risk.
# 2. 7.37% HIGH ratio is NOT highest (important).
# 3. 7.4% LOW and HIGH are similar.

-- 7. EMI Burden

SELECT TARGET,AVG(AMT_ANNUITY/AMT_INCOME_TOTAL)AS EMI_RATIO
FROM APPLICATION_TRAIN
GROUP BY TARGET;

SELECT 
CASE 
WHEN AMT_ANNUITY/AMT_INCOME_TOTAL < 0.1 THEN 'LOW'
WHEN AMT_ANNUITY/AMT_INCOME_TOTAL < 0.3 THEN 'MEDIUM'
ELSE 'HIGH'
END AS EMI_GROUP,
AVG(TARGET)AS DEFAULT_RATE
FROM APPLICATION_TRAIN
GROUP BY EMI_GROUP;

# Default rates increase with higher EMI-to-income ratios,
-- indicating that customers with greater repayment burden are more likely to default. 
-- The medium and high EMI groups show significantly higher risk compared to low EMI customers.

-- 8.Average Payment Delay vs Default

SELECT A.TARGET,AVG(I.AVG_DELAY)AS AVG_DELAY
FROM APPLICATION_TRAIN A
LEFT JOIN INSTALLMENT_SUMMARY I
ON A.SK_ID_CURR=I.SK_ID_CURR
GROUP BY A.TARGET;

# Both default and non-default customers tend to make payments before the due date; however,
--  defaulters pay closer to the due date, indicating relatively weaker repayment discipline.

-- 9.Credit Card Utilization

SELECT A.TARGET,
AVG(C.AVG_BALANCE/NULLIF(C.AVG_CREDIT_LIMIT,0))AS Utilization
FROM APPLICATION_TRAIN A 
LEFT JOIN CREDIT_CARD_SUMMARY C
ON A.SK_ID_CURR=C.SK_ID_CURR
GROUP BY A.TARGET;


# Customers with higher credit card utilization show significantly higher default risk, 
-- indicating that heavy reliance on available credit reflects financial stress and reduced repayment capacity.

-- 10. Customers with High Risk (Top 10%)

SELECT *,
(AMT_CREDIT/AMT_INCOME_TOTAL)AS CREDIT_RATIO
FROM APPLICATION_TRAIN
ORDER BY CREDIT_RATIO DESC
LIMIT 10;

SELECT *,
CASE 
WHEN AMT_CREDIT / AMT_INCOME_TOTAL < 5 THEN 'LOW_RISK'
WHEN AMT_CREDIT / AMT_INCOME_TOTAL < 15 THEN 'MEDIUM RISK'
ELSE 'HIGH RISK'
END AS RISK_CATEGORY
FROM APPLICATION_TRAIN;

-- 11. Active Loans vs Default

SELECT A.TARGET,AVG(B.LOAN_COUNT)AS AVG_LOANS
FROM APPLICATION_TRAIN A
LEFT JOIN(
SELECT B.SK_ID_CURR,COUNT(*)AS LOAN_COUNT 
FROM BUREAU B
GROUP BY B.SK_ID_CURR
)B 
ON A.SK_ID_CURR=B.SK_ID_CURR
GROUP BY A.TARGET;

# Customers with a higher number of loans show a slightly increased likelihood of default, indicating that increased financial exposure may contribute to higher credit risk.

-- 12.Overdue Amount vs Default

SELECT A.TARGET,
AVG(B.AMT_CREDIT_SUM_OVERDUE)AS AVG_OVERDUE
FROM APPLICATION_TRAIN A 
LEFT JOIN BUREAU B 
ON A.SK_ID_CURR=B.SK_ID_CURR
GROUP BY A.TARGET;

# Customers with higher overdue amounts show significantly higher default risk, with defaulters having nearly six times higher overdue compared to non-defaulters. This indicates that overdue amount is a critical indicator of poor repayment behavior.

-- 13.Refused Applications vs Default


SELECT A.TARGET,AVG(P.REFUSED_COUNT)AS AVG_REFUSED
FROM APPLICATION_TRAIN A
LEFT JOIN (
SELECT P.SK_ID_CURR,
SUM(CASE WHEN NAME_CONTRACT_STATUS='Refused' THEN 1 ELSE 0 END)AS REFUSED_COUNT
FROM PREVIOUS_APPLICATION P 
GROUP BY P.SK_ID_CURR
)P
ON A.SK_ID_CURR=P.SK_ID_CURR
GROUP BY A.TARGET;

# Customers with a higher number of previously refused applications show a higher likelihood of default, indicating that past rejection history reflects underlying credit risk.

SELECT A.SK_ID_CURR,
A.TARGET,
(A.AMT_CREDIT / A.AMT_INCOME_TOTAL)AS CREDIT_RATIO,
I.AVG_DELAY,
C.AVG_PRICE/C.AVG_CREDIT_LIMIT AS CC_Utilization
FROM APPLICATION_TRAIN A 
LEFT JOIN INSTALLMENT_SUMMARY I 
ON A.SK_ID_CURR=I.SK_ID_CURR
LEFT JOIN CREDIT_CARD_SUMMARY C 
ON A.SK_ID_CURR=C.SK_ID_CURR;


-- ============================================================
-- DETAILED ANALYSIS & INSIGHTS 
-- ============================================================

-- ============================================================
-- SECTION A: DEMOGRAPHIC RISK PROFILING
-- ============================================================

-- Q1. DEFAULT RATE BY OCCUPATION TYPE
-- INSIGHT: Low-skill Laborers (17.15%) default 3.5x more than Accountants (4.83%)
-- Occupations involving manual/unskilled labor show highest default rates.
-- Skill-level correlates inversely with credit risk.

SELECT OCCUPATION_TYPE, COUNT(*)AS TOTAL_CUSTOMERS,
SUM(TARGET)AS DEFAULTS,
ROUND(SUM(TARGET)*100.0/COUNT(*),2)AS DEFAULT_RATE_PCT,
ROUND(AVG(AMT_INCOME_TOTAL),0)AS AVG_INCOME,
ROUND(AVG(AMT_CREDIT),0)AS AVG_CREDIT,
FROM APPLICATION_TRAIN
WHERE OCCUPATION_TYPE IS NOT NULL
GROUP BY OCCUPATION_TYPE
ORDER BY DEFAULT_RATE_PCT DESC;

-- Q2. DEFAULT RATE BY FAMILY STATUS
-- INSIGHT: Civil marriage (9.94%) and Single (9.81%) clients default most.
-- Married (7.56%) and Widow (5.82%) clients show lower default rates.
-- Possible explanation: shared financial responsibility in formal marriages reduces risk.

SELECT NAME_FAMILY_STATUS,COUNT(*)AS TOTAL_CUSTOMERS,
SUM(TARGET) AS DEFAULTS,
ROUND(SUM(TARGET)*100.0/COUNT(*),2)AS DEFAULT_RATE_PCT,
ROUND(AVG(AMT_INCOME_TOTAL),0)AS AVG_INCOME
FROM APPLICATION_TRAIN
GROUP BY NAME_FAMILY_STATUS
ORDER BY DEFAULT_RATE_PCT DESC;

-- Q3. REGION RATING VS DEFAULT RISK
-- INSIGHT: Clear linear relationship — Region 3 (worst-rated) = 11.1% default,
-- Region 1 (best) = 4.82%. Region rating is a strong default predictor.
-- Region 3 clients also have lowest avg income (152K) vs Region 1 (242K).

SELECT REGION_RATING_CLIENT,COUNT(*)AS TOTAL_CUSTOMERS,
SUM(TARGET)AS DEFAULTS,
ROUND(SUM(TARGET)*100.0/COUNT(*),2)AS DEFAULT_RATE_PCT,
ROUND(AVG(AMT_INCOME_TOTAL),0)AS AVG_INCOME,
ROUND(AVG(AMT_CREDIT),0)AS AVG_CREDIT
FROM APPLICATION_TRAIN
GROUP BY REGION_RATING_CLIENT
ORDER BY REGION_RATING_CLIENT;



-- Q4. ASSET OWNERSHIP (CAR + REALTY) VS DEFAULT
-- INSIGHT: No car, No realty = highest default (8.99%).
-- Car owners default less regardless of realty (7.04-7.33%).
-- Car ownership is a stronger risk differentiator than realty ownership.


SELECT LAG_OWN_CAR,FLAG_OWN_REALTY,
COUNT(*) AS TOTAL_CUSTOMERS,
SUM(TARGET) AS DEFAULTS,
ROUND(SUM(TARGET)*100.0/COUNT(*),2)AS DEFAULT_RATE_PCT,
ROUND(AVG(AMT_INCOME_TOTAL),0)AS AVG_INCOME
FROM APPLICATION_TRAIN
GROUP BY  LAG_OWN_CAR,FLAG_OWN_REALTY
ORDER BY DEFAULT_RATE_PCT DESC;

SELECT * FROM APPLICATION_TRAIN;

-- Q5. NUMBER OF CHILDREN VS DEFAULT RISK
-- INSIGHT: Default rate rises with children count: 0 kids=7.71%, 3 kids=9.63%, 4 kids=12.82%.
-- Higher dependents = greater financial strain = higher default probability.

SELECT CNT_CHILDREN,COUNT(*)AS TOTAL_CUSTOMERS,
SUM(TARGET)AS DEFAULTS,
ROUND(SUM(TARGET)*100.0/COUNT(*),2)AS DEFAULT_RATE_PCT
FROM APPLICATION_TRAIN
WHERE CNT_CHILDREN <= 5
GROUP BY CNT_CHILDREN
ORDER BY DEFAULT_RATE_PCT;


-- ============================================================
-- SECTION B: FINANCIAL RISK PROFILING
-- ============================================================

-- Q1. INCOME BAND ANALYSIS
-- INSIGHT: Inverse relationship — Lower income = higher default.
-- 100K-150K band has highest default rate (8.62%) and highest volume (91K clients).
-- 500K+ income clients default at only 5.40% — income is protective.

SELECT CASE 
WHEN AMT_INCOME_TOTAL < 100000 THEN '1. BELOW 100K'
WHEN AMT_INCOME_TOTAL < 150000 THEN '2. 100K-150K'
WHEN AMT_INCOME_TOTAL < 200000 THEN '3. 150K-200K'
WHEN AMT_INCOME_TOTAL < 300000 THEN '4. 200K-300K'
WHEN AMT_INCOME_TOTAL < 500000 THEN '5. 300K-500K'
ELSE '6. 500+'
END AS INCOME_BAND,
COUNT(*)AS TOTAL_CUSTOMERS,
SUM(TARGET)AS DEFAULTS,
ROUND(SUM(TARGET)*100.0/COUNT(*),2)AS DEFAULT_RATE_PCT,
ROUND(AVG(AMT_CREDIT),0)AS AVG_CREDIT,
ROUND(AVG(AMT_ANNUITY),0)AS AVG_EMI,
ROUND(AVG(AMT_CREDIT/NULLIF(AMT_INCOME_TOTAL,0)),2)AS AVG_CREDIT_TO_INCOME
FROM APPLICATION_TRAIN
GROUP BY INCOME_BAND
ORDER BY INCOME_BAND;


-- Q2. CREDIT AMOUNT BAND VS DEFAULT
-- INSIGHT: Non-linear relationship — mid-range credits (400K-600K) have HIGHEST default rate (10.10%). 
-- Very large credits (1.5M+) have LOWEST default (4.43%).
-- Explanation: Large credits go through stricter due diligence.

SELECT CASE
WHEN AMT_CREDIT < 200000 THEN '1. BELOW 200K'
WHEN AMT_CREDIT < 400000 THEN '2. 200K-400K'
WHEN AMT_CREDIT < 600000 THEN '3. 400K-600K'
WHEN AMT_CREDIT < 900000 THEN '4. 600K-900K'
WHEN AMT_CREDIT < 1500000 THEN '5. 900K-1.5M'
ELSE '6. 1.5+'
END AS CREDIT_BAND,
COUNT(*) AS TOTAL,
SUM(TARGET) AS DEFAULTS,
ROUND(SUM(TARGET)*100.0/COUNT(*),2) AS DEFAULT_RATE_PCT,
ROUND(AVG(AMT_ANNUITY),0) AS AVG_EMI,
ROUND(AVG(AMT_GOODS_PRICE),0) AS AVG_GOODS_PRICE
FROM APPLICATION_TRAIN
GROUP BY CREDIT_BAND
ORDER BY CREDIT_BAND;


-- Q3. GOODS-TO-CREDIT RATIO (LOAN PREMIUM ANALYSIS)
-- INSIGHT: 50-75% goods/credit ratio = HIGHEST default (13.06%).
-- This means borrowers paying a large premium over goods value = red flag.
-- Near-100% ratio (no premium) = lower default (6.59%).

SELECT CASE
WHEN AMT_GOODS_PRICE/NULLIF(AMT_CREDIT,0) < 0.50 THEN '1. BELOW 50%'
WHEN AMT_GOODS_PRICE/NULLIF(AMT_CREDIT,0) < 0.75 THEN '2. 50%-75%'
WHEN AMT_GOODS_PRICE/NULLIF(AMT_CREDIT,0) < 0.90 THEN '3. 75-90%'
WHEN AMT_GOODS_PRICE/NULLIF(AMT_CREDIT,0) < 1.00 THEN '4. 90-100%'
ELSE '5. OVER 100%'
END AS  GOODS_TO_CREDIT_RATIO,
COUNT(*)AS TOTAL_CUSTOMERS,
SUM(TARGET)AS DEFAULTS,
ROUND(SUM(TARGET)*100.0/COUNT(*),2)AS DEFAULT_RATE_PCT
FROM APPLICATION_TRAIN
WHERE AMT_CREDIT > 0 AND AMT_GOODS_PRICE IS NOT NULL
GROUP BY GOODS_TO_CREDIT_RATIO
ORDER BY GOODS_TO_CREDIT_RATIO;


-- Q4. ANNUITY-TO-INCOME RATIO (EMI BURDEN DEEP DIVE)
-- INSIGHT: Surprisingly, below 10% EMI ratio has LOWEST default (7.26%).
-- 20-30% band has highest (8.76%). Above 40% = 8.27% (not highest).
-- Non-linear relationship — moderate EMI burden is riskiest segment.

SELECT CASE
WHEN AMT_ANNUITY/NULLIF(AMT_INCOME_TOTAL,0)< 0.10 THEN '1. BELOW 10%'
WHEN AMT_ANNUITY/NULLIF(AMT_INCOME_TOTAL,0)< 0.20 THEN '2. 10%-20%'
WHEN AMT_ANNUITY/NULLIF(AMT_INCOME_TOTAL,0)< 0.30 THEN '3. 20%-30%'
WHEN AMT_ANNUITY/NULLIF(AMT_INCOME_TOTAL,0)< 0.40 THEN '4. 30%-40%'
ELSE '5. 40%+'
END AS ANNUITY_TO_INCOME_RATIO,
COUNT(*)AS TOTAL_CUSTOMERS,
SUM(TARGET)AS DEFAULTS,
ROUND(SUM(TARGET)*100.0/COUNT(*),2)AS DEFAULT_RATE_PCT
FROM APPLICATION_TRAIN
WHERE AMT_INCOME_TOTAL > 0 AND AMT_ANNUITY IS NOT NULL
GROUP BY ANNUITY_TO_INCOME_RATIO
ORDER BY ANNUITY_TO_INCOME_RATIO;

SELECT 
MIN(AMT_ANNUITY/AMT_INCOME_TOTAL),
MAX(AMT_ANNUITY/AMT_INCOME_TOTAL),
AVG(AMT_ANNUITY/AMT_INCOME_TOTAL)
FROM APPLICATION_TRAIN;

-- ============================================================
-- SECTION C: BUREAU CREDIT HISTORY DEEP DIVE
-- ============================================================

-- Q1. BUREAU DEBT-TO-CREDIT RATIO AND OVERDUE SEVERITY
-- INSIGHT: Active credits have 1.6x debt-to-credit ratio (overleveraged).
-- Only 0.64% of active credits have overdue — but bad debt = 41.67% overdue rate.
-- Closed credits have near-zero debt (0.43% ratio) — good repayment history.

SELECT CREDIT_ACTIVE,COUNT(*)AS TOTAL_CUSTOMERS,
ROUND(AVG(AMT_CREDIT_SUM),0)AS AVG_TOTAL_CREDIT,
ROUND(AVG(AMT_CREDIT_SUM_DEBT/NULLIF(AMT_CREDIT_SUM,0)),4)AS AVG_DEBT_TO_CREDIT_RATIO,
SUM(CASE WHEN AMT_CREDIT_SUM_OVERDUE > 0 THEN 1 ELSE 0 END)AS CNT_WITH_OVERDUE,
ROUND(SUM(CASE WHEN AMT_CREDIT_SUM_OVERDUE > 0 THEN 1 ELSE 0 END)*100.0/COUNT(*),2)AS PCT_WITH_OVERDUE,
ROUND(AVG(CASE WHEN AMT_CREDIT_SUM_OVERDUE > 0 THEN AMT_CREDIT_SUM_OVERDUE END),0)AS AVG_OVERDUE_AMT_WHEN_OVERDUE
FROM BUREAU
GROUP BY CREDIT_ACTIVE
ORDER BY TOTAL_CUSTOMERS DESC;


-- Q2. CREDIT RECENCY ANALYSIS — HOW OLD ARE BUREAU CREDITS?
-- INSIGHT: Recent credits (within 1yr) carry highest active debt (341K avg).
-- Older credits (5+ yrs) still active show 174K avg debt — long-standing obligations.
-- Sold debt decreases over time (139K recent → 45K old), showing recovery patterns.

SELECT CASE
WHEN DAYS_CREDIT >= -365 THEN '1. WITHIN 1YR'
WHEN DAYS_CREDIT >= -730 THEN '2. 1-2YRS AGO'
WHEN DAYS_CREDIT >= -1825 THEN '3. 2-5YRS AGO'
ELSE '4. 5+YRS AGO'
END AS CREDIT_RECENCY,
CREDIT_ACTIVE,
COUNT(*)AS TOTAL_LOANS,
ROUND(AVG(AMT_CREDIT_SUM),0)AS AVG_CREDIT_SUM,
ROUND(AVG(AMT_CREDIT_SUM_DEBT),0)AS AVG_DEBT,
ROUND(AVG(AMT_CREDIT_SUM_DEBT/NULLIF(AMT_CREDIT_SUM,0)),2)AS DEBT_RATIO
FROM BUREAU
GROUP BY CREDIT_RECENCY,CREDIT_ACTIVE
ORDER BY CREDIT_RECENCY,CREDIT_ACTIVE; 


-- ============================================================
-- SECTION D: PREVIOUS APPLICATION BEHAVIOR
-- ============================================================

-- Q1. NEW VS REPEAT CLIENTS
-- INSIGHT: New clients have 93.67% approval rate but lower loan amounts (106K).
-- Repeat clients only 55.84% approval rate but apply for 2x larger amounts (198K).
-- Refreshed clients sit between (73.78%). Banks are stricter with repeat applicants.


SELECT NAME_CLIENT_TYPE,
COUNT(*)AS TOTAL_APPLICATIONS,
SUM(CASE WHEN NAME_CONTRACT_STATUS = 'Approved' THEN 1 ELSE 0 END)AS APPROVED,
ROUND(SUM(CASE WHEN NAME_CONTRACT_STATUS = 'Approved' THEN 1 ELSE 0 END)*100.0/COUNT(*),2)AS APPROVED_RATE_PCT,
ROUND(AVG(AMT_APPLICATION),0)AS AVG_APP_AMT,
ROUND(AVG(AMT_CREDIT),0)AS AVG_CREDIT,
ROUND(AVG(AMT_CREDIT-AMT_APPLICATION),0)AS CREDIT,
ROUND(AVG(AMT_CREDIT/NULLIF(AMT_APPLICATION,0)),2)AS APPROVAL_RATIO
FROM PREVIOUS_APPLICATION
GROUP BY NAME_CLIENT_TYPE
ORDER BY TOTAL_CUSTOMERS DESC;

-- Q2. GOODS CATEGORY APPROVAL RATES
-- INSIGHT: Fitness (100%), Other (95.4%), Medicine (93.5%) = highest approval.
-- Mobile (83.1%), Computers (83.5%) = lower approval — higher fraud/default risk categories.
-- Unknown category (45.7%) = heavily scrutinized, likely incomplete applications.

SELECT NAME_GOODS_CATEGORY,
COUNT(*)AS TOTAL_APPLICATIONS,
SUM(CASE WHEN NAME_CONTRACT_STATUS = 'Approved' THEN 1 ELSE 0 END)AS APPROVED,
SUM(CASE WHEN NAME_CONTRACT_STATUS = 'Refused' THEN 1 ELSE 0 END)AS REFUSED,
ROUND(SUM(CASE WHEN NAME_CONTRACT_STATUS = 'Approved' THEN 1 ELSE 0 END)*100.0/COUNT(*),2)AS APPROVED_RATE_PCT,
ROUND(AVG(AMT_APPLICATION),0)AS AVG_APPLICATION_AMOUNT
FROM PREVIOUS_APPLICATION
GROUP BY NAME_GOODS_CATEGORY
HAVING COUNT(*)>= 100
ORDER BY APPROVED_RATE_PCT DESC;

-- ============================================================
-- SECTION E: CROSS-TABLE BEHAVIORAL ANALYSIS
-- ============================================================

-- Q1. POS CASH DAYS PAST DUE (DPD) VS DEFAULT
-- Defaulters show higher delinquency behavior compared to non-defaulters.
 -- Around 22.15% of defaulters have experienced payment delays versus 17.40% of non-defaulters. Additionally, the average delay (DPD) for defaulters is about 23% higher, and severe delinquency (DPD_DEF) is more than twice as high, indicating that past payment delays are strong predictors of default.

SELECT CASE WHEN A.TARGET = 1 THEN 'DEFAULTER' ELSE 'NON-DEFAULTER' END AS STATUS,
ROUND(AVG(P.AVG_DPD),2)AS AVG_DPD,
ROUND(AVG(P.AVG_DPD_DEF),2)AS AVG_DPD_DEFAULT,
ROUND(AVG(P.AVG_INSTALMENTS),2)AS AVG_INSTALMENTS,
ROUND(AVG(P.AVG_INSTALMENTS_FUTURE),2)AS AVG_FUTURE_INSTALMENTS,
SUM(CASE WHEN P.AVG_DPD > 0 THEN 1 ELSE 0 END)AS CNT_WITH_ANY_DPD,
ROUND(SUM(CASE WHEN P.AVG_DPD > 0 THEN 1 ELSE 0 END)*100.0/COUNT(*),2)AS PCT_WITH_DPD
FROM APPLICATION_TRAIN A LEFT JOIN POS_CASH_SUMMARY P 
ON A.SK_ID_CURR=P.SK_ID_CURR
GROUP BY STATUS;

-- Q2. INSTALLMENT PAYMENT BEHAVIOR VS DEFAULT
-- Non-defaulters tend to overpay their instalments on average, while defaulters underpay,
-- indicating weaker repayment capacity. Additionally, the proportion of late payments is about 1.5 times higher among defaulters. Although both groups show early payment behavior on average, defaulters exhibit less consistent payment discipline, making repayment behavior a strong predictor of default risk.

SELECT CASE WHEN A.TARGET = 1 THEN 'DEFAULTER' ELSE 'NON-DEFAULTER' END AS STATUS,
ROUND(AVG(I.TOTAL_PAYMENT),0)AS AVG_TOTAL_PAYMENT,
ROUND(AVG(I.TOTAL_INSTALMENT),0)AS AVG_TOTAL_INSTALMENT,
ROUND(AVG(I.TOTAL_PAYMENT-I.TOTAL_INSTALMENT),0)AS AVG_OVERPAYMENT,
ROUND(AVG(I.AVG_DELAY),2)AS AVG_DELAY,
ROUND(AVG(CASE WHEN I.AVG_DELAY > 0 THEN 1 ELSE 0 END)*100,2)AS PCT_WITH_LATE_PAYMENTS,
ROUND(AVG(I.TOTAL_PAYMENT/NULLIF(I.TOTAL_INSTALMENT,0)),2)AS PAYMENT_RATIO
FROM APPLICATION_TRAIN A LEFT JOIN INSTALLMENT_SUMMARY I 
ON A.SK_ID_CURR=I.SK_ID_CURR
GROUP BY STATUS;

-- Q3. CREDIT CARD UTILIZATION ANALYSIS
-- INSIGHT: Defaulters have 47.48% credit card utilization vs 31.66% for non-defaulters.
-- Defaulters carry 49% higher balances (102K vs 69K) on similar credit limits.
-- High CC utilization is a STRONG default indicator (50% higher utilization).

SELECT CASE WHEN A.TARGET = 1 THEN 'DEFAULTER' ELSE 'NON-DEFAULTER' END AS STATUS,
ROUND(AVG(C.AVG_BALANCE),0)AS AVG_CC_BALANCE,
ROUND(AVG(C.AVG_CREDIT_LIMIT),0)AS AVG_CC_LIMIT,
ROUND(AVG(C.AVG_BALANCE/NULLIF(C.AVG_CREDIT_LIMIT,0))*100,2)AS  AVG_UTILIZATION_PCT,
ROUND(AVG(C.TOTAL_CC_PAYMENT),0)AS AVG_CC_PAYMENT,
ROUND(AVG(C.TOTAL_RECEIVABLE),0)AS AVG_RECEIVABLE
FROM APPLICATION_TRAIN A JOIN CREDIT_CARD_SUMMARY C 
ON A.SK_ID_CURR=C.SK_ID_CURR
GROUP BY STATUS;


-- ============================================================
-- SECTION F: COMPOSITE RISK SEGMENTATION MODEL
-- ============================================================

-- Q1. MULTI-FACTOR RISK SCORING
-- INSIGHT: HIGH RISK segment (Region 3 + Single/Civil marriage + Income <150K) = 14.18% default.
-- LOW RISK segment (Region 1 + Income 200K+) = only 4.36% default.
-- 3.25x difference between high and low risk segments.
-- This segmentation can be used as a rule-based credit scoring model.


SELECT 
CASE 
WHEN REGION_RATING_CLIENT = 3 
AND NAME_FAMILY_STATUS IN ('Civil marriage','Single / not married')
AND AMT_INCOME_TOTAL < 150000 THEN 'HIGH RISK'
WHEN REGION_RATING_CLIENT >=2 AND AMT_INCOME_TOTAL < 200000 
AND AMT_CREDIT > 500000 THEN 'MEDIUM-HIGH RISK'
WHEN REGION_RATING_CLIENT = 1 AND AMT_INCOME_TOTAL >= 200000 
THEN 'LOW RISK'
ELSE 'MEDIUM RISK'
END AS RISK_SEGMENT,
COUNT(*)AS TOTAL_CUSTOMERS,
SUM(TARGET)AS DEFAULTS,
ROUND(SUM(TARGET)*100.0/COUNT(*),2)AS DEFAULT_RATE_PCT,
ROUND(AVG( AMT_INCOME_TOTAL),0)AS AVG_INCOME,
ROUND(AVG(AMT_CREDIT),0)AS AVG_CREDIT,
ROUND(AVG(AMT_ANNUITY),0)AS AVG_EMI
FROM APPLICATION_TRAIN
GROUP BY RISK_SEGMENT
ORDER BY DEFAULT_RATE_PCT DESC;




-- ============================================================
-- SECTION G: KEY BUSINESS RECOMMENDATIONS (SUMMARY)
-- ============================================================
-- 
-- 1. TOP DEFAULT RISK FACTORS (ranked by impact):
--    a) Occupation: Low-skill Laborers 17.15% default (vs 4.83% Accountants)
--    b) Region: Rating 3 areas = 11.10% default (vs 4.82% Rating 1)
--    c) Family Status: Civil marriage/Single = ~10% (vs 5.82% Widow)
--    d) Credit Card Utilization: Defaulters use 47% of limit (vs 32%)
--    e) Bureau Overdue: Defaulters have 6.4x higher overdue amounts
--    f) Children: 4+ children = 12.82% default rate
--
-- 2. NON-INTUITIVE FINDINGS:
--    a) Mid-range credits (400K-600K) default MORE than large credits (1.5M+)
--    b) Goods-to-credit ratio 50-75% = 13% default (highest among all bands)
--    c) Car ownership reduces risk MORE than realty ownership
--    d) New clients get 94% approval but repeaters only 56%
--    e) High EMI burden (40%+) does NOT have highest default — 20-30% does
--
-- 3. RECOMMENDED CREDIT POLICY CHANGES:
--    a) Increase scrutiny for Region 3 + Single + Low-income applicants
--    b) Monitor credit card utilization > 40% as an early warning signal
--    c) Flag applicants with goods-to-credit ratio < 75%
--    d) Use installment overpayment/underpayment as a behavioral indicator
--    e) Weight occupation type heavily in credit scoring models
--
-- 4. MODEL BUILDING RECOMMENDATIONS:
--    a) Handle class imbalance (92%/8%) with SMOTE or class weights
--    b) Top features: REGION_RATING, OCCUPATION_TYPE, CC_UTILIZATION, BUREAU_OVERDUE
--    c) Create engineered features: ANNUITY_TO_INCOME, GOODS_TO_CREDIT ratio
--    d) Use the 4-tier risk segmentation as a baseline model
