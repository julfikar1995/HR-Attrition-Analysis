CREATE DATABASE hr_attrition_analysis;
USE hr_attrition_analysis;

CREATE TABLE hr_raw (
  Age INT,
  Attrition VARCHAR(5),
  BusinessTravel VARCHAR(30),
  Department VARCHAR(50),
  DistanceFromHome INT,
  Gender VARCHAR(10),
  JobInvolvement INT,
  JobLevel INT,
  JobRole VARCHAR(50),
  JobSatisfaction INT,
  MaritalStatus VARCHAR(15),
  MonthlyIncome INT,
  NumCompaniesWorked INT,
  OverTime VARCHAR(5),
  PercentSalaryHike INT,
  PerformanceRating INT,
  StockOptionLevel INT,
  TotalWorkingYears INT,
  TrainingTimesLastYear INT,
  YearsAtCompany INT,
  YearsSinceLastPromotion INT,
  YearsWithCurrManager INT,
  Higher_Education VARCHAR(30),
  Date_of_Hire VARCHAR(15),
  Status_of_leaving VARCHAR(30),
  Mode_of_work VARCHAR(10),
  Leaves INT,
  Absenteeism INT,
  Work_accident VARCHAR(5),
  Source_of_Hire VARCHAR(30),
  Job_mode VARCHAR(15)
);

