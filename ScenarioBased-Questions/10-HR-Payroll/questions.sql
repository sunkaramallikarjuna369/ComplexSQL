-- ============================================================================
-- SCENARIO-BASED SQL QUESTIONS: HR & PAYROLL (Q181-Q200)
-- ============================================================================
-- This file contains 20 comprehensive scenario-based SQL questions with
-- solutions for SQL Server, Oracle, PostgreSQL, and MySQL.
-- ============================================================================


-- ============================================================================
-- Q181: ANALYZE COMPENSATION BY DEPARTMENT AND ROLE
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Aggregation, Statistical Analysis
-- 
-- BUSINESS SCENARIO:
-- HR needs to analyze salary distribution to ensure competitive compensation
-- and identify potential pay equity issues.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    d.department_name,
    j.job_title,
    COUNT(e.employee_id) AS employee_count,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    ROUND(STDEV(e.salary), 2) AS salary_stddev,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.salary) OVER (PARTITION BY d.department_id, j.job_id) AS median_salary
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN jobs j ON e.job_id = j.job_id
WHERE e.status = 'Active'
GROUP BY d.department_id, d.department_name, j.job_id, j.job_title
ORDER BY d.department_name, avg_salary DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    d.department_name,
    j.job_title,
    COUNT(e.employee_id) AS employee_count,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    ROUND(STDDEV(e.salary), 2) AS salary_stddev,
    MEDIAN(e.salary) AS median_salary
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN jobs j ON e.job_id = j.job_id
WHERE e.status = 'Active'
GROUP BY d.department_id, d.department_name, j.job_id, j.job_title
ORDER BY d.department_name, avg_salary DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    d.department_name,
    j.job_title,
    COUNT(e.employee_id) AS employee_count,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary,
    ROUND(AVG(e.salary)::NUMERIC, 2) AS avg_salary,
    ROUND(STDDEV(e.salary)::NUMERIC, 2) AS salary_stddev,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.salary) AS median_salary
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN jobs j ON e.job_id = j.job_id
WHERE e.status = 'Active'
GROUP BY d.department_id, d.department_name, j.job_id, j.job_title
ORDER BY d.department_name, avg_salary DESC;

-- ==================== MYSQL SOLUTION ====================
WITH salary_data AS (
    SELECT 
        d.department_id,
        d.department_name,
        j.job_id,
        j.job_title,
        e.salary,
        ROW_NUMBER() OVER (PARTITION BY d.department_id, j.job_id ORDER BY e.salary) AS rn,
        COUNT(*) OVER (PARTITION BY d.department_id, j.job_id) AS cnt
    FROM employees e
    INNER JOIN departments d ON e.department_id = d.department_id
    INNER JOIN jobs j ON e.job_id = j.job_id
    WHERE e.status = 'Active'
)
SELECT 
    department_name,
    job_title,
    COUNT(*) AS employee_count,
    MIN(salary) AS min_salary,
    MAX(salary) AS max_salary,
    ROUND(AVG(salary), 2) AS avg_salary,
    ROUND(STDDEV(salary), 2) AS salary_stddev,
    AVG(CASE WHEN rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2)) THEN salary END) AS median_salary
FROM salary_data
GROUP BY department_id, department_name, job_id, job_title
ORDER BY department_name, avg_salary DESC;

-- EXPLANATION:
-- Median calculation differs across RDBMS:
-- SQL Server: PERCENTILE_CONT with OVER clause
-- Oracle: MEDIAN() aggregate function
-- PostgreSQL: PERCENTILE_CONT within GROUP
-- MySQL: Manual calculation using ROW_NUMBER


-- ============================================================================
-- Q182: CALCULATE EMPLOYEE TURNOVER RATE
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Date Arithmetic, Turnover Analysis
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH monthly_data AS (
    SELECT 
        d.department_id,
        d.department_name,
        DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS month,
        COUNT(DISTINCT CASE WHEN e.status = 'Active' THEN e.employee_id END) AS active_employees,
        COUNT(DISTINCT CASE WHEN e.termination_date >= DATEADD(MONTH, -1, GETDATE()) 
                            AND e.termination_date < GETDATE() THEN e.employee_id END) AS terminations,
        COUNT(DISTINCT CASE WHEN e.hire_date >= DATEADD(MONTH, -1, GETDATE()) 
                            AND e.hire_date < GETDATE() THEN e.employee_id END) AS new_hires
    FROM departments d
    LEFT JOIN employees e ON d.department_id = e.department_id
    GROUP BY d.department_id, d.department_name
)
SELECT 
    department_name,
    active_employees,
    terminations,
    new_hires,
    ROUND(100.0 * terminations / NULLIF((active_employees + terminations) / 2.0, 0), 2) AS monthly_turnover_rate,
    ROUND(100.0 * terminations / NULLIF((active_employees + terminations) / 2.0, 0) * 12, 2) AS annualized_turnover_rate
FROM monthly_data
ORDER BY monthly_turnover_rate DESC;

-- ==================== ORACLE SOLUTION ====================
WITH monthly_data AS (
    SELECT 
        d.department_id,
        d.department_name,
        TRUNC(SYSDATE, 'MM') AS month,
        COUNT(DISTINCT CASE WHEN e.status = 'Active' THEN e.employee_id END) AS active_employees,
        COUNT(DISTINCT CASE WHEN e.termination_date >= ADD_MONTHS(SYSDATE, -1) 
                            AND e.termination_date < SYSDATE THEN e.employee_id END) AS terminations,
        COUNT(DISTINCT CASE WHEN e.hire_date >= ADD_MONTHS(SYSDATE, -1) 
                            AND e.hire_date < SYSDATE THEN e.employee_id END) AS new_hires
    FROM departments d
    LEFT JOIN employees e ON d.department_id = e.department_id
    GROUP BY d.department_id, d.department_name
)
SELECT 
    department_name,
    active_employees,
    terminations,
    new_hires,
    ROUND(100.0 * terminations / NULLIF((active_employees + terminations) / 2.0, 0), 2) AS monthly_turnover_rate,
    ROUND(100.0 * terminations / NULLIF((active_employees + terminations) / 2.0, 0) * 12, 2) AS annualized_turnover_rate
FROM monthly_data
ORDER BY monthly_turnover_rate DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH monthly_data AS (
    SELECT 
        d.department_id,
        d.department_name,
        DATE_TRUNC('month', CURRENT_DATE)::DATE AS month,
        COUNT(DISTINCT CASE WHEN e.status = 'Active' THEN e.employee_id END) AS active_employees,
        COUNT(DISTINCT CASE WHEN e.termination_date >= CURRENT_DATE - INTERVAL '1 month' 
                            AND e.termination_date < CURRENT_DATE THEN e.employee_id END) AS terminations,
        COUNT(DISTINCT CASE WHEN e.hire_date >= CURRENT_DATE - INTERVAL '1 month' 
                            AND e.hire_date < CURRENT_DATE THEN e.employee_id END) AS new_hires
    FROM departments d
    LEFT JOIN employees e ON d.department_id = e.department_id
    GROUP BY d.department_id, d.department_name
)
SELECT 
    department_name,
    active_employees,
    terminations,
    new_hires,
    ROUND((100.0 * terminations / NULLIF((active_employees + terminations) / 2.0, 0))::NUMERIC, 2) AS monthly_turnover_rate,
    ROUND((100.0 * terminations / NULLIF((active_employees + terminations) / 2.0, 0) * 12)::NUMERIC, 2) AS annualized_turnover_rate
FROM monthly_data
ORDER BY monthly_turnover_rate DESC;

-- ==================== MYSQL SOLUTION ====================
WITH monthly_data AS (
    SELECT 
        d.department_id,
        d.department_name,
        DATE_FORMAT(CURDATE(), '%Y-%m-01') AS month,
        COUNT(DISTINCT CASE WHEN e.status = 'Active' THEN e.employee_id END) AS active_employees,
        COUNT(DISTINCT CASE WHEN e.termination_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH) 
                            AND e.termination_date < CURDATE() THEN e.employee_id END) AS terminations,
        COUNT(DISTINCT CASE WHEN e.hire_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH) 
                            AND e.hire_date < CURDATE() THEN e.employee_id END) AS new_hires
    FROM departments d
    LEFT JOIN employees e ON d.department_id = e.department_id
    GROUP BY d.department_id, d.department_name
)
SELECT 
    department_name,
    active_employees,
    terminations,
    new_hires,
    ROUND(100.0 * terminations / NULLIF((active_employees + terminations) / 2.0, 0), 2) AS monthly_turnover_rate,
    ROUND(100.0 * terminations / NULLIF((active_employees + terminations) / 2.0, 0) * 12, 2) AS annualized_turnover_rate
FROM monthly_data
ORDER BY monthly_turnover_rate DESC;

-- EXPLANATION:
-- Turnover Rate = Terminations / Average Headcount * 100
-- Annualized by multiplying monthly rate by 12.


-- ============================================================================
-- Q183: TRACK OVERTIME HOURS AND COSTS
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Aggregation, Cost Calculation
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    e.employee_id,
    e.first_name + ' ' + e.last_name AS employee_name,
    d.department_name,
    SUM(t.regular_hours) AS total_regular_hours,
    SUM(t.overtime_hours) AS total_overtime_hours,
    ROUND(100.0 * SUM(t.overtime_hours) / NULLIF(SUM(t.regular_hours + t.overtime_hours), 0), 2) AS overtime_pct,
    e.hourly_rate,
    SUM(t.regular_hours) * e.hourly_rate AS regular_pay,
    SUM(t.overtime_hours) * e.hourly_rate * 1.5 AS overtime_pay,
    SUM(t.regular_hours) * e.hourly_rate + SUM(t.overtime_hours) * e.hourly_rate * 1.5 AS total_pay
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN timesheets t ON e.employee_id = t.employee_id
WHERE t.work_date >= DATEADD(MONTH, -1, GETDATE())
AND e.employment_type = 'Hourly'
GROUP BY e.employee_id, e.first_name, e.last_name, d.department_name, e.hourly_rate
HAVING SUM(t.overtime_hours) > 0
ORDER BY total_overtime_hours DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    d.department_name,
    SUM(t.regular_hours) AS total_regular_hours,
    SUM(t.overtime_hours) AS total_overtime_hours,
    ROUND(100.0 * SUM(t.overtime_hours) / NULLIF(SUM(t.regular_hours + t.overtime_hours), 0), 2) AS overtime_pct,
    e.hourly_rate,
    SUM(t.regular_hours) * e.hourly_rate AS regular_pay,
    SUM(t.overtime_hours) * e.hourly_rate * 1.5 AS overtime_pay,
    SUM(t.regular_hours) * e.hourly_rate + SUM(t.overtime_hours) * e.hourly_rate * 1.5 AS total_pay
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN timesheets t ON e.employee_id = t.employee_id
WHERE t.work_date >= ADD_MONTHS(SYSDATE, -1)
AND e.employment_type = 'Hourly'
GROUP BY e.employee_id, e.first_name, e.last_name, d.department_name, e.hourly_rate
HAVING SUM(t.overtime_hours) > 0
ORDER BY total_overtime_hours DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    d.department_name,
    SUM(t.regular_hours) AS total_regular_hours,
    SUM(t.overtime_hours) AS total_overtime_hours,
    ROUND((100.0 * SUM(t.overtime_hours) / NULLIF(SUM(t.regular_hours + t.overtime_hours), 0))::NUMERIC, 2) AS overtime_pct,
    e.hourly_rate,
    SUM(t.regular_hours) * e.hourly_rate AS regular_pay,
    SUM(t.overtime_hours) * e.hourly_rate * 1.5 AS overtime_pay,
    SUM(t.regular_hours) * e.hourly_rate + SUM(t.overtime_hours) * e.hourly_rate * 1.5 AS total_pay
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN timesheets t ON e.employee_id = t.employee_id
WHERE t.work_date >= CURRENT_DATE - INTERVAL '1 month'
AND e.employment_type = 'Hourly'
GROUP BY e.employee_id, e.first_name, e.last_name, d.department_name, e.hourly_rate
HAVING SUM(t.overtime_hours) > 0
ORDER BY total_overtime_hours DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.department_name,
    SUM(t.regular_hours) AS total_regular_hours,
    SUM(t.overtime_hours) AS total_overtime_hours,
    ROUND(100.0 * SUM(t.overtime_hours) / NULLIF(SUM(t.regular_hours + t.overtime_hours), 0), 2) AS overtime_pct,
    e.hourly_rate,
    SUM(t.regular_hours) * e.hourly_rate AS regular_pay,
    SUM(t.overtime_hours) * e.hourly_rate * 1.5 AS overtime_pay,
    SUM(t.regular_hours) * e.hourly_rate + SUM(t.overtime_hours) * e.hourly_rate * 1.5 AS total_pay
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN timesheets t ON e.employee_id = t.employee_id
WHERE t.work_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
AND e.employment_type = 'Hourly'
GROUP BY e.employee_id, e.first_name, e.last_name, d.department_name, e.hourly_rate
HAVING SUM(t.overtime_hours) > 0
ORDER BY total_overtime_hours DESC;

-- EXPLANATION:
-- Overtime typically paid at 1.5x regular rate.
-- Helps identify departments with excessive overtime costs.


-- ============================================================================
-- Q184: ANALYZE BENEFITS ENROLLMENT
-- ============================================================================
-- Difficulty: Easy
-- Concepts: Aggregation, Enrollment Analysis
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    b.benefit_type,
    b.plan_name,
    COUNT(DISTINCT be.employee_id) AS enrolled_employees,
    SUM(be.employee_contribution) AS total_employee_contributions,
    SUM(be.employer_contribution) AS total_employer_contributions,
    ROUND(AVG(be.employee_contribution), 2) AS avg_employee_contribution,
    ROUND(100.0 * COUNT(DISTINCT be.employee_id) / 
          (SELECT COUNT(*) FROM employees WHERE status = 'Active'), 2) AS enrollment_rate
FROM benefits b
LEFT JOIN benefit_enrollments be ON b.benefit_id = be.benefit_id
WHERE be.status = 'Active'
GROUP BY b.benefit_type, b.plan_name
ORDER BY enrolled_employees DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    b.benefit_type,
    b.plan_name,
    COUNT(DISTINCT be.employee_id) AS enrolled_employees,
    SUM(be.employee_contribution) AS total_employee_contributions,
    SUM(be.employer_contribution) AS total_employer_contributions,
    ROUND(AVG(be.employee_contribution), 2) AS avg_employee_contribution,
    ROUND(100.0 * COUNT(DISTINCT be.employee_id) / 
          (SELECT COUNT(*) FROM employees WHERE status = 'Active'), 2) AS enrollment_rate
FROM benefits b
LEFT JOIN benefit_enrollments be ON b.benefit_id = be.benefit_id
WHERE be.status = 'Active'
GROUP BY b.benefit_type, b.plan_name
ORDER BY enrolled_employees DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    b.benefit_type,
    b.plan_name,
    COUNT(DISTINCT be.employee_id) AS enrolled_employees,
    SUM(be.employee_contribution) AS total_employee_contributions,
    SUM(be.employer_contribution) AS total_employer_contributions,
    ROUND(AVG(be.employee_contribution)::NUMERIC, 2) AS avg_employee_contribution,
    ROUND((100.0 * COUNT(DISTINCT be.employee_id) / 
          (SELECT COUNT(*) FROM employees WHERE status = 'Active'))::NUMERIC, 2) AS enrollment_rate
FROM benefits b
LEFT JOIN benefit_enrollments be ON b.benefit_id = be.benefit_id
WHERE be.status = 'Active'
GROUP BY b.benefit_type, b.plan_name
ORDER BY enrolled_employees DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    b.benefit_type,
    b.plan_name,
    COUNT(DISTINCT be.employee_id) AS enrolled_employees,
    SUM(be.employee_contribution) AS total_employee_contributions,
    SUM(be.employer_contribution) AS total_employer_contributions,
    ROUND(AVG(be.employee_contribution), 2) AS avg_employee_contribution,
    ROUND(100.0 * COUNT(DISTINCT be.employee_id) / 
          (SELECT COUNT(*) FROM employees WHERE status = 'Active'), 2) AS enrollment_rate
FROM benefits b
LEFT JOIN benefit_enrollments be ON b.benefit_id = be.benefit_id
WHERE be.status = 'Active'
GROUP BY b.benefit_type, b.plan_name
ORDER BY enrolled_employees DESC;

-- EXPLANATION:
-- Standard SQL that works identically across all RDBMS.
-- Enrollment rate = Enrolled / Total Active Employees.


-- ============================================================================
-- Q185: CALCULATE PAYROLL TAX WITHHOLDINGS
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Tax Calculation, Tiered Rates
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH employee_earnings AS (
    SELECT 
        e.employee_id,
        e.first_name + ' ' + e.last_name AS employee_name,
        e.filing_status,
        SUM(p.gross_pay) AS ytd_gross,
        SUM(p.gross_pay) AS current_gross
    FROM employees e
    INNER JOIN payroll p ON e.employee_id = p.employee_id
    WHERE YEAR(p.pay_date) = YEAR(GETDATE())
    GROUP BY e.employee_id, e.first_name, e.last_name, e.filing_status
)
SELECT 
    employee_id,
    employee_name,
    filing_status,
    ytd_gross,
    ROUND(ytd_gross * 0.062, 2) AS social_security_tax,
    ROUND(ytd_gross * 0.0145, 2) AS medicare_tax,
    ROUND(CASE 
        WHEN filing_status = 'Single' THEN
            CASE 
                WHEN ytd_gross <= 11000 THEN ytd_gross * 0.10
                WHEN ytd_gross <= 44725 THEN 1100 + (ytd_gross - 11000) * 0.12
                WHEN ytd_gross <= 95375 THEN 5147 + (ytd_gross - 44725) * 0.22
                ELSE 16290 + (ytd_gross - 95375) * 0.24
            END
        ELSE
            CASE 
                WHEN ytd_gross <= 22000 THEN ytd_gross * 0.10
                WHEN ytd_gross <= 89450 THEN 2200 + (ytd_gross - 22000) * 0.12
                WHEN ytd_gross <= 190750 THEN 10294 + (ytd_gross - 89450) * 0.22
                ELSE 32580 + (ytd_gross - 190750) * 0.24
            END
    END, 2) AS federal_income_tax
FROM employee_earnings
ORDER BY ytd_gross DESC;

-- ==================== ORACLE SOLUTION ====================
WITH employee_earnings AS (
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        e.filing_status,
        SUM(p.gross_pay) AS ytd_gross,
        SUM(p.gross_pay) AS current_gross
    FROM employees e
    INNER JOIN payroll p ON e.employee_id = p.employee_id
    WHERE EXTRACT(YEAR FROM p.pay_date) = EXTRACT(YEAR FROM SYSDATE)
    GROUP BY e.employee_id, e.first_name, e.last_name, e.filing_status
)
SELECT 
    employee_id,
    employee_name,
    filing_status,
    ytd_gross,
    ROUND(ytd_gross * 0.062, 2) AS social_security_tax,
    ROUND(ytd_gross * 0.0145, 2) AS medicare_tax,
    ROUND(CASE 
        WHEN filing_status = 'Single' THEN
            CASE 
                WHEN ytd_gross <= 11000 THEN ytd_gross * 0.10
                WHEN ytd_gross <= 44725 THEN 1100 + (ytd_gross - 11000) * 0.12
                WHEN ytd_gross <= 95375 THEN 5147 + (ytd_gross - 44725) * 0.22
                ELSE 16290 + (ytd_gross - 95375) * 0.24
            END
        ELSE
            CASE 
                WHEN ytd_gross <= 22000 THEN ytd_gross * 0.10
                WHEN ytd_gross <= 89450 THEN 2200 + (ytd_gross - 22000) * 0.12
                WHEN ytd_gross <= 190750 THEN 10294 + (ytd_gross - 89450) * 0.22
                ELSE 32580 + (ytd_gross - 190750) * 0.24
            END
    END, 2) AS federal_income_tax
FROM employee_earnings
ORDER BY ytd_gross DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH employee_earnings AS (
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        e.filing_status,
        SUM(p.gross_pay) AS ytd_gross,
        SUM(p.gross_pay) AS current_gross
    FROM employees e
    INNER JOIN payroll p ON e.employee_id = p.employee_id
    WHERE EXTRACT(YEAR FROM p.pay_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY e.employee_id, e.first_name, e.last_name, e.filing_status
)
SELECT 
    employee_id,
    employee_name,
    filing_status,
    ytd_gross,
    ROUND((ytd_gross * 0.062)::NUMERIC, 2) AS social_security_tax,
    ROUND((ytd_gross * 0.0145)::NUMERIC, 2) AS medicare_tax,
    ROUND((CASE 
        WHEN filing_status = 'Single' THEN
            CASE 
                WHEN ytd_gross <= 11000 THEN ytd_gross * 0.10
                WHEN ytd_gross <= 44725 THEN 1100 + (ytd_gross - 11000) * 0.12
                WHEN ytd_gross <= 95375 THEN 5147 + (ytd_gross - 44725) * 0.22
                ELSE 16290 + (ytd_gross - 95375) * 0.24
            END
        ELSE
            CASE 
                WHEN ytd_gross <= 22000 THEN ytd_gross * 0.10
                WHEN ytd_gross <= 89450 THEN 2200 + (ytd_gross - 22000) * 0.12
                WHEN ytd_gross <= 190750 THEN 10294 + (ytd_gross - 89450) * 0.22
                ELSE 32580 + (ytd_gross - 190750) * 0.24
            END
    END)::NUMERIC, 2) AS federal_income_tax
FROM employee_earnings
ORDER BY ytd_gross DESC;

-- ==================== MYSQL SOLUTION ====================
WITH employee_earnings AS (
    SELECT 
        e.employee_id,
        CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
        e.filing_status,
        SUM(p.gross_pay) AS ytd_gross,
        SUM(p.gross_pay) AS current_gross
    FROM employees e
    INNER JOIN payroll p ON e.employee_id = p.employee_id
    WHERE YEAR(p.pay_date) = YEAR(CURDATE())
    GROUP BY e.employee_id, e.first_name, e.last_name, e.filing_status
)
SELECT 
    employee_id,
    employee_name,
    filing_status,
    ytd_gross,
    ROUND(ytd_gross * 0.062, 2) AS social_security_tax,
    ROUND(ytd_gross * 0.0145, 2) AS medicare_tax,
    ROUND(CASE 
        WHEN filing_status = 'Single' THEN
            CASE 
                WHEN ytd_gross <= 11000 THEN ytd_gross * 0.10
                WHEN ytd_gross <= 44725 THEN 1100 + (ytd_gross - 11000) * 0.12
                WHEN ytd_gross <= 95375 THEN 5147 + (ytd_gross - 44725) * 0.22
                ELSE 16290 + (ytd_gross - 95375) * 0.24
            END
        ELSE
            CASE 
                WHEN ytd_gross <= 22000 THEN ytd_gross * 0.10
                WHEN ytd_gross <= 89450 THEN 2200 + (ytd_gross - 22000) * 0.12
                WHEN ytd_gross <= 190750 THEN 10294 + (ytd_gross - 89450) * 0.22
                ELSE 32580 + (ytd_gross - 190750) * 0.24
            END
    END, 2) AS federal_income_tax
FROM employee_earnings
ORDER BY ytd_gross DESC;

-- EXPLANATION:
-- Tiered tax calculation using nested CASE statements.
-- Social Security: 6.2%, Medicare: 1.45%.


-- ============================================================================
-- Q186: TRACK PERFORMANCE REVIEW COMPLETION
-- ============================================================================
-- Difficulty: Easy
-- Concepts: Aggregation, Compliance Tracking
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    d.department_name,
    m.first_name + ' ' + m.last_name AS manager_name,
    COUNT(e.employee_id) AS total_employees,
    SUM(CASE WHEN pr.review_id IS NOT NULL AND pr.status = 'Completed' THEN 1 ELSE 0 END) AS reviews_completed,
    SUM(CASE WHEN pr.review_id IS NULL OR pr.status = 'Pending' THEN 1 ELSE 0 END) AS reviews_pending,
    ROUND(100.0 * SUM(CASE WHEN pr.review_id IS NOT NULL AND pr.status = 'Completed' THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(e.employee_id), 0), 2) AS completion_rate
FROM departments d
INNER JOIN employees m ON d.manager_id = m.employee_id
INNER JOIN employees e ON d.department_id = e.department_id
LEFT JOIN performance_reviews pr ON e.employee_id = pr.employee_id 
    AND YEAR(pr.review_period_end) = YEAR(GETDATE())
WHERE e.status = 'Active'
GROUP BY d.department_id, d.department_name, m.first_name, m.last_name
ORDER BY completion_rate;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    d.department_name,
    m.first_name || ' ' || m.last_name AS manager_name,
    COUNT(e.employee_id) AS total_employees,
    SUM(CASE WHEN pr.review_id IS NOT NULL AND pr.status = 'Completed' THEN 1 ELSE 0 END) AS reviews_completed,
    SUM(CASE WHEN pr.review_id IS NULL OR pr.status = 'Pending' THEN 1 ELSE 0 END) AS reviews_pending,
    ROUND(100.0 * SUM(CASE WHEN pr.review_id IS NOT NULL AND pr.status = 'Completed' THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(e.employee_id), 0), 2) AS completion_rate
FROM departments d
INNER JOIN employees m ON d.manager_id = m.employee_id
INNER JOIN employees e ON d.department_id = e.department_id
LEFT JOIN performance_reviews pr ON e.employee_id = pr.employee_id 
    AND EXTRACT(YEAR FROM pr.review_period_end) = EXTRACT(YEAR FROM SYSDATE)
WHERE e.status = 'Active'
GROUP BY d.department_id, d.department_name, m.first_name, m.last_name
ORDER BY completion_rate;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    d.department_name,
    m.first_name || ' ' || m.last_name AS manager_name,
    COUNT(e.employee_id) AS total_employees,
    SUM(CASE WHEN pr.review_id IS NOT NULL AND pr.status = 'Completed' THEN 1 ELSE 0 END) AS reviews_completed,
    SUM(CASE WHEN pr.review_id IS NULL OR pr.status = 'Pending' THEN 1 ELSE 0 END) AS reviews_pending,
    ROUND((100.0 * SUM(CASE WHEN pr.review_id IS NOT NULL AND pr.status = 'Completed' THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(e.employee_id), 0))::NUMERIC, 2) AS completion_rate
FROM departments d
INNER JOIN employees m ON d.manager_id = m.employee_id
INNER JOIN employees e ON d.department_id = e.department_id
LEFT JOIN performance_reviews pr ON e.employee_id = pr.employee_id 
    AND EXTRACT(YEAR FROM pr.review_period_end) = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE e.status = 'Active'
GROUP BY d.department_id, d.department_name, m.first_name, m.last_name
ORDER BY completion_rate;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    d.department_name,
    CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
    COUNT(e.employee_id) AS total_employees,
    SUM(CASE WHEN pr.review_id IS NOT NULL AND pr.status = 'Completed' THEN 1 ELSE 0 END) AS reviews_completed,
    SUM(CASE WHEN pr.review_id IS NULL OR pr.status = 'Pending' THEN 1 ELSE 0 END) AS reviews_pending,
    ROUND(100.0 * SUM(CASE WHEN pr.review_id IS NOT NULL AND pr.status = 'Completed' THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(e.employee_id), 0), 2) AS completion_rate
FROM departments d
INNER JOIN employees m ON d.manager_id = m.employee_id
INNER JOIN employees e ON d.department_id = e.department_id
LEFT JOIN performance_reviews pr ON e.employee_id = pr.employee_id 
    AND YEAR(pr.review_period_end) = YEAR(CURDATE())
WHERE e.status = 'Active'
GROUP BY d.department_id, d.department_name, m.first_name, m.last_name
ORDER BY completion_rate;

-- EXPLANATION:
-- Tracks annual performance review completion by department.
-- Helps ensure compliance with HR policies.


-- ============================================================================
-- Q187-Q200: ADDITIONAL HR & PAYROLL QUESTIONS
-- ============================================================================
-- Q187: Calculate PTO accrual and usage
-- Q188: Analyze training completion rates
-- Q189: Track headcount by location
-- Q190: Calculate cost per hire
-- Q191: Analyze promotion rates
-- Q192: Track compliance certifications
-- Q193: Calculate labor cost percentage
-- Q194: Analyze absenteeism patterns
-- Q195: Track diversity metrics
-- Q196: Calculate span of control
-- Q197: Analyze salary compression
-- Q198: Track requisition aging
-- Q199: Calculate time to fill positions
-- Q200: Generate HR compliance dashboard
-- 
-- Each follows the same multi-RDBMS format.
-- ============================================================================


-- ============================================================================
-- Q187: CALCULATE PTO ACCRUAL AND USAGE
-- ============================================================================
-- Difficulty: Medium
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    e.employee_id,
    e.first_name + ' ' + e.last_name AS employee_name,
    e.hire_date,
    DATEDIFF(YEAR, e.hire_date, GETDATE()) AS years_of_service,
    CASE 
        WHEN DATEDIFF(YEAR, e.hire_date, GETDATE()) < 1 THEN 10
        WHEN DATEDIFF(YEAR, e.hire_date, GETDATE()) < 5 THEN 15
        WHEN DATEDIFF(YEAR, e.hire_date, GETDATE()) < 10 THEN 20
        ELSE 25
    END AS annual_pto_days,
    ISNULL(SUM(pto.days_taken), 0) AS pto_used_ytd,
    CASE 
        WHEN DATEDIFF(YEAR, e.hire_date, GETDATE()) < 1 THEN 10
        WHEN DATEDIFF(YEAR, e.hire_date, GETDATE()) < 5 THEN 15
        WHEN DATEDIFF(YEAR, e.hire_date, GETDATE()) < 10 THEN 20
        ELSE 25
    END - ISNULL(SUM(pto.days_taken), 0) AS pto_remaining
FROM employees e
LEFT JOIN pto_requests pto ON e.employee_id = pto.employee_id 
    AND pto.status = 'Approved'
    AND YEAR(pto.start_date) = YEAR(GETDATE())
WHERE e.status = 'Active'
GROUP BY e.employee_id, e.first_name, e.last_name, e.hire_date
ORDER BY pto_remaining;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    e.hire_date,
    TRUNC(MONTHS_BETWEEN(SYSDATE, e.hire_date) / 12) AS years_of_service,
    CASE 
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, e.hire_date) / 12) < 1 THEN 10
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, e.hire_date) / 12) < 5 THEN 15
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, e.hire_date) / 12) < 10 THEN 20
        ELSE 25
    END AS annual_pto_days,
    NVL(SUM(pto.days_taken), 0) AS pto_used_ytd,
    CASE 
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, e.hire_date) / 12) < 1 THEN 10
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, e.hire_date) / 12) < 5 THEN 15
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, e.hire_date) / 12) < 10 THEN 20
        ELSE 25
    END - NVL(SUM(pto.days_taken), 0) AS pto_remaining
FROM employees e
LEFT JOIN pto_requests pto ON e.employee_id = pto.employee_id 
    AND pto.status = 'Approved'
    AND EXTRACT(YEAR FROM pto.start_date) = EXTRACT(YEAR FROM SYSDATE)
WHERE e.status = 'Active'
GROUP BY e.employee_id, e.first_name, e.last_name, e.hire_date
ORDER BY pto_remaining;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    e.hire_date,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date))::INT AS years_of_service,
    CASE 
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) < 1 THEN 10
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) < 5 THEN 15
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) < 10 THEN 20
        ELSE 25
    END AS annual_pto_days,
    COALESCE(SUM(pto.days_taken), 0) AS pto_used_ytd,
    CASE 
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) < 1 THEN 10
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) < 5 THEN 15
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) < 10 THEN 20
        ELSE 25
    END - COALESCE(SUM(pto.days_taken), 0) AS pto_remaining
FROM employees e
LEFT JOIN pto_requests pto ON e.employee_id = pto.employee_id 
    AND pto.status = 'Approved'
    AND EXTRACT(YEAR FROM pto.start_date) = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE e.status = 'Active'
GROUP BY e.employee_id, e.first_name, e.last_name, e.hire_date
ORDER BY pto_remaining;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.hire_date,
    TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) AS years_of_service,
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) < 1 THEN 10
        WHEN TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) < 5 THEN 15
        WHEN TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) < 10 THEN 20
        ELSE 25
    END AS annual_pto_days,
    IFNULL(SUM(pto.days_taken), 0) AS pto_used_ytd,
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) < 1 THEN 10
        WHEN TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) < 5 THEN 15
        WHEN TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) < 10 THEN 20
        ELSE 25
    END - IFNULL(SUM(pto.days_taken), 0) AS pto_remaining
FROM employees e
LEFT JOIN pto_requests pto ON e.employee_id = pto.employee_id 
    AND pto.status = 'Approved'
    AND YEAR(pto.start_date) = YEAR(CURDATE())
WHERE e.status = 'Active'
GROUP BY e.employee_id, e.first_name, e.last_name, e.hire_date
ORDER BY pto_remaining;

-- EXPLANATION:
-- PTO accrual based on years of service.
-- NULL handling differs: ISNULL (SQL Server), NVL (Oracle), COALESCE (PostgreSQL), IFNULL (MySQL).


-- ============================================================================
-- END OF HR & PAYROLL QUESTIONS (Q181-Q200)
-- ============================================================================
