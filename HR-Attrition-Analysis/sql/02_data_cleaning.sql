-- ============================================================
-- HR Attrition Analysis | Step 3: Data Cleaning
-- Database: hr_attrition_analysis
-- ============================================================
USE hr_attrition_analysis;

-- ------------------------------------------------------------
-- 3A. Give every employee an ID (the raw file has none)
-- Run this ONLY ONCE
-- ------------------------------------------------------------
ALTER TABLE hr_raw ADD COLUMN emp_row INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- ------------------------------------------------------------
-- 3B. Data quality checks (all results should be 0 unless noted)
-- ------------------------------------------------------------

-- Check 1: duplicate rows
SELECT COUNT(*) - COUNT(DISTINCT CONCAT_WS('|', Age, Attrition, BusinessTravel, Department,
       DistanceFromHome, Gender, JobInvolvement, JobLevel, JobRole, JobSatisfaction,
       MaritalStatus, MonthlyIncome, NumCompaniesWorked, OverTime, PercentSalaryHike,
       PerformanceRating, StockOptionLevel, TotalWorkingYears, TrainingTimesLastYear,
       YearsAtCompany, YearsSinceLastPromotion, YearsWithCurrManager, Higher_Education,
       Date_of_Hire, Status_of_leaving, Mode_of_work, Leaves, Absenteeism, Work_accident,
       Source_of_Hire, Job_mode)) AS duplicate_rows
FROM hr_raw;

-- Check 2: missing values in key columns
SELECT SUM(Attrition IS NULL OR Attrition = '')
     + SUM(Department IS NULL OR Department = '')
     + SUM(JobRole IS NULL OR JobRole = '')
     + SUM(Date_of_Hire IS NULL OR Date_of_Hire = '')
     + SUM(MonthlyIncome IS NULL)
     + SUM(Age IS NULL) AS missing_values
FROM hr_raw;

-- Check 3: impossible or illogical values
SELECT SUM(Age NOT BETWEEN 18 AND 65)                AS bad_age,
       SUM(MonthlyIncome <= 0)                       AS bad_income,
       SUM(JobSatisfaction NOT BETWEEN 1 AND 4)      AS bad_satisfaction,
       SUM(YearsAtCompany > TotalWorkingYears)       AS tenure_more_than_experience,
       SUM(YearsWithCurrManager > YearsAtCompany)    AS manager_years_more_than_tenure,
       SUM(Attrition NOT IN ('Yes', 'No'))           AS bad_attrition_values
FROM hr_raw;

-- Check 4: extra spaces in text columns
SELECT SUM(Department <> TRIM(Department))
     + SUM(JobRole <> TRIM(JobRole))
     + SUM(Gender <> TRIM(Gender))
     + SUM(Attrition <> TRIM(Attrition)) AS text_spacing_issues
FROM hr_raw;

-- Check 5: dates that cannot be converted
SELECT COUNT(*) AS bad_dates
FROM hr_raw
WHERE STR_TO_DATE(Date_of_Hire, '%d-%m-%Y') IS NULL;

-- Check 6 (logic issue, NOT zero): leaving reason is filled even for current employees
SELECT Attrition, COUNT(Status_of_leaving) AS rows_with_leaving_reason
FROM hr_raw
GROUP BY Attrition;

-- ------------------------------------------------------------
-- 3C. Build the clean table: employees
-- ------------------------------------------------------------
DROP TABLE IF EXISTS employees;

CREATE TABLE employees AS
SELECT
    CONCAT('EMP', LPAD(emp_row, 4, '0'))                       AS employee_id,
    Age                                                        AS age,
    CASE WHEN Age <= 25 THEN '1. 18-25'
         WHEN Age <= 35 THEN '2. 26-35'
         WHEN Age <= 45 THEN '3. 36-45'
         ELSE '4. 46-60' END                                   AS age_group,
    TRIM(Gender)                                               AS gender,
    TRIM(MaritalStatus)                                        AS marital_status,
    TRIM(Higher_Education)                                     AS education,
    TRIM(Department)                                           AS department,
    TRIM(JobRole)                                              AS job_role,
    JobLevel                                                   AS job_level,
    REPLACE(TRIM(BusinessTravel), '_', ' ')                    AS business_travel,
    DistanceFromHome                                           AS distance_from_home,
    CASE WHEN DistanceFromHome <= 5  THEN '1. 1-5'
         WHEN DistanceFromHome <= 10 THEN '2. 6-10'
         WHEN DistanceFromHome <= 20 THEN '3. 11-20'
         ELSE '4. 21+' END                                     AS distance_band,
    TRIM(OverTime)                                             AS overtime,
    CASE WHEN TRIM(Mode_of_work) = 'WFH' THEN 'Work From Home'
         ELSE 'Office' END                                     AS work_mode,
    CASE WHEN TRIM(Job_mode) = 'FullTime' THEN 'Full Time'
         ELSE TRIM(Job_mode) END                               AS employment_type,
    TRIM(Source_of_Hire)                                       AS hire_source,
    STR_TO_DATE(Date_of_Hire, '%d-%m-%Y')                      AS hire_date,
    YEAR(STR_TO_DATE(Date_of_Hire, '%d-%m-%Y'))                AS hire_year,
    YearsAtCompany                                             AS years_at_company,
    CASE WHEN YearsAtCompany <= 1  THEN '1. 0-1 yrs'
         WHEN YearsAtCompany <= 3  THEN '2. 2-3 yrs'
         WHEN YearsAtCompany <= 5  THEN '3. 4-5 yrs'
         WHEN YearsAtCompany <= 10 THEN '4. 6-10 yrs'
         ELSE '5. 11+ yrs' END                                 AS tenure_band,
    TotalWorkingYears                                          AS total_working_years,
    NumCompaniesWorked                                         AS num_companies_worked,
    YearsSinceLastPromotion                                    AS years_since_promotion,
    YearsWithCurrManager                                       AS years_with_manager,
    MonthlyIncome                                              AS monthly_income,
    CASE WHEN MonthlyIncome < 3000 THEN '1. Under 3,000'
         WHEN MonthlyIncome < 5000 THEN '2. 3,000-4,999'
         WHEN MonthlyIncome < 8000 THEN '3. 5,000-7,999'
         ELSE '4. 8,000+' END                                  AS income_band,
    PercentSalaryHike                                          AS salary_hike_pct,
    StockOptionLevel                                           AS stock_option_level,
    TrainingTimesLastYear                                      AS trainings_last_year,
    PerformanceRating                                          AS performance_rating,
    CASE PerformanceRating WHEN 1 THEN 'Low'
                           WHEN 2 THEN 'Good'
                           WHEN 3 THEN 'Excellent'
                           WHEN 4 THEN 'Outstanding' END       AS performance_label,
    JobSatisfaction                                            AS job_satisfaction,
    CASE JobSatisfaction WHEN 1 THEN 'Low'
                         WHEN 2 THEN 'Medium'
                         WHEN 3 THEN 'High'
                         WHEN 4 THEN 'Very High' END           AS satisfaction_label,
    JobInvolvement                                             AS job_involvement,
    CASE JobInvolvement WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                        WHEN 4 THEN 'Very High' END            AS involvement_label,
    Leaves                                                     AS leaves,
    Absenteeism                                                AS absenteeism,
    TRIM(Work_accident)                                        AS work_accident,
    TRIM(Attrition)                                            AS attrition,
    CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END              AS attrition_flag,
    CASE WHEN Attrition = 'Yes' THEN TRIM(Status_of_leaving)
         ELSE NULL END                                         AS leaving_reason
FROM hr_raw;

ALTER TABLE employees ADD PRIMARY KEY (employee_id);
