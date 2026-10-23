-- ============================================================
-- HR Attrition Analysis | Step 4: SQL Analysis and Views
-- Database: hr_attrition_analysis
-- ============================================================
USE hr_attrition_analysis;

-- ---------- Q1. Company-wide KPIs ----------
SELECT COUNT(*)                                            AS employees,
       SUM(attrition_flag)                                 AS leavers,
       COUNT(*) - SUM(attrition_flag)                      AS current_employees,
       ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)    AS attrition_pct,
       ROUND(AVG(age), 1)                                  AS avg_age,
       ROUND(AVG(monthly_income), 2)                       AS avg_income,
       ROUND(AVG(years_at_company), 1)                     AS avg_tenure_years
FROM employees;

-- ---------- Q2. Attrition by department ----------
SELECT department,
       COUNT(*)                                            AS employees,
       SUM(attrition_flag)                                 AS leavers,
       ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)    AS attrition_pct
FROM employees
GROUP BY department
ORDER BY attrition_pct DESC;

-- ---------- Q3. Attrition by job role (with rank and share of all leavers) ----------
SELECT job_role,
       COUNT(*)                                                         AS employees,
       SUM(attrition_flag)                                              AS leavers,
       ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)                 AS attrition_pct,
       RANK() OVER (ORDER BY SUM(attrition_flag) * 1.0 / COUNT(*) DESC) AS attrition_rank,
       ROUND(SUM(attrition_flag) * 100.0 / SUM(SUM(attrition_flag)) OVER (), 1) AS share_of_all_leavers_pct
FROM employees
GROUP BY job_role
ORDER BY attrition_rank;

-- ---------- Q4. Attrition by job level ----------
SELECT job_level,
       COUNT(*)                                            AS employees,
       SUM(attrition_flag)                                 AS leavers,
       ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)    AS attrition_pct
FROM employees
GROUP BY job_level
ORDER BY job_level;

-- ---------- Q5. Overtime ----------
SELECT overtime,
       COUNT(*)                                            AS employees,
       SUM(attrition_flag)                                 AS leavers,
       ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)    AS attrition_pct
FROM employees
GROUP BY overtime
ORDER BY overtime;

-- ---------- Q6. Business travel ----------
SELECT business_travel,
       COUNT(*)                                            AS employees,
       SUM(attrition_flag)                                 AS leavers,
       ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)    AS attrition_pct
FROM employees
GROUP BY business_travel
ORDER BY attrition_pct DESC;

-- ---------- Q7. Marital status ----------
SELECT marital_status,
       COUNT(*)                                            AS employees,
       SUM(attrition_flag)                                 AS leavers,
       ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)    AS attrition_pct
FROM employees
GROUP BY marital_status
ORDER BY attrition_pct DESC;

-- ---------- Q8. Job satisfaction ----------
SELECT job_satisfaction,
       satisfaction_label,
       COUNT(*)                                            AS employees,
       SUM(attrition_flag)                                 AS leavers,
       ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)    AS attrition_pct
FROM employees
GROUP BY job_satisfaction, satisfaction_label
ORDER BY job_satisfaction;

-- ---------- Q9. Stock option level ----------
SELECT stock_option_level,
       COUNT(*)                                            AS employees,
       SUM(attrition_flag)                                 AS leavers,
       ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)    AS attrition_pct
FROM employees
GROUP BY stock_option_level
ORDER BY stock_option_level;

-- ---------- Q10. Gender ----------
SELECT gender,
       COUNT(*)                                            AS employees,
       SUM(attrition_flag)                                 AS leavers,
       ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)    AS attrition_pct
FROM employees
GROUP BY gender
ORDER BY gender;

-- ---------- Q11. Leavers vs stayers (averages) ----------
SELECT attrition,
       COUNT(*)                                AS employees,
       ROUND(AVG(age), 1)                      AS avg_age,
       ROUND(AVG(monthly_income), 0)           AS avg_income,
       ROUND(AVG(years_at_company), 1)         AS avg_tenure_years,
       ROUND(AVG(distance_from_home), 1)       AS avg_distance,
       ROUND(AVG(salary_hike_pct), 1)          AS avg_salary_hike_pct,
       ROUND(AVG(years_since_promotion), 1)    AS avg_years_since_promotion,
       ROUND(AVG(trainings_last_year), 1)      AS avg_trainings
FROM employees
GROUP BY attrition
ORDER BY attrition;

-- ---------- Q12. Overtime and marital status together ----------
SELECT overtime,
       marital_status,
       COUNT(*)                                            AS employees,
       SUM(attrition_flag)                                 AS leavers,
       ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)    AS attrition_pct
FROM employees
GROUP BY overtime, marital_status
ORDER BY attrition_pct DESC;

-- ---------- Q13. Hire-year cohorts (2014 onwards) ----------
SELECT hire_year,
       COUNT(*)                                            AS employees,
       SUM(attrition_flag)                                 AS leavers,
       ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)    AS attrition_pct
FROM employees
WHERE hire_year >= 2014
GROUP BY hire_year
ORDER BY hire_year;

-- ---------- Q14. Riskiest job role + overtime segments (CTE) ----------
WITH segment AS (
    SELECT job_role,
           overtime,
           COUNT(*)                                            AS employees,
           SUM(attrition_flag)                                 AS leavers,
           ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)    AS attrition_pct
    FROM employees
    GROUP BY job_role, overtime
)
SELECT *
FROM segment
WHERE employees >= 30
ORDER BY attrition_pct DESC, employees DESC
LIMIT 5;

-- ============================================================
-- VIEWS
-- ============================================================

-- View 1: main table for Power BI (employees + simple risk score)
-- Risk score = 1 point for each: overtime, income under 3,000, tenure 0-1 yrs,
-- single, job level 1, frequent travel, no stock options (0 to 7 points)
CREATE OR REPLACE VIEW vw_employee_analysis AS
SELECT s.*,
       CASE WHEN s.risk_score >= 4 THEN 'High'
            WHEN s.risk_score >= 2 THEN 'Medium'
            ELSE 'Low' END AS risk_level,
       CASE WHEN s.risk_score >= 4 THEN 3
            WHEN s.risk_score >= 2 THEN 2
            ELSE 1 END AS risk_order
FROM (
    SELECT e.*,
           (e.overtime = 'Yes')
         + (e.monthly_income < 3000)
         + (e.years_at_company <= 1)
         + (e.marital_status = 'Single')
         + (e.job_level = 1)
         + (e.business_travel = 'Travel Frequently')
         + (e.stock_option_level = 0) AS risk_score
    FROM employees e
) s;

-- View 2: attrition by job role
CREATE OR REPLACE VIEW vw_attrition_by_job_role AS
SELECT department,
       job_role,
       COUNT(*)                                            AS employees,
       SUM(attrition_flag)                                 AS leavers,
       ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)    AS attrition_pct,
       ROUND(AVG(monthly_income), 0)                       AS avg_income
FROM employees
GROUP BY department, job_role;

-- View 3: leavers vs stayers
CREATE OR REPLACE VIEW vw_leavers_vs_stayers AS
SELECT attrition,
       COUNT(*)                                AS employees,
       ROUND(AVG(age), 1)                      AS avg_age,
       ROUND(AVG(monthly_income), 0)           AS avg_income,
       ROUND(AVG(years_at_company), 1)         AS avg_tenure_years,
       ROUND(AVG(distance_from_home), 1)       AS avg_distance,
       ROUND(AVG(salary_hike_pct), 1)          AS avg_salary_hike_pct,
       ROUND(AVG(years_since_promotion), 1)    AS avg_years_since_promotion
FROM employees
GROUP BY attrition;

-- ---------- Check the risk score works (Q15) ----------
SELECT risk_level,
       COUNT(*)                                            AS employees,
       SUM(attrition_flag)                                 AS leavers,
       ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 1)    AS attrition_pct
FROM vw_employee_analysis
GROUP BY risk_level, risk_order
ORDER BY risk_order;

-- ---------- Q16. Current employees at high risk ----------
SELECT COUNT(*) AS high_risk_current_employees
FROM vw_employee_analysis
WHERE attrition = 'No' AND risk_level = 'High';

SELECT employee_id, department, job_role, age, monthly_income, years_at_company, overtime, risk_score
FROM vw_employee_analysis
WHERE attrition = 'No' AND risk_level = 'High'
ORDER BY risk_score DESC, employee_id
LIMIT 10;
