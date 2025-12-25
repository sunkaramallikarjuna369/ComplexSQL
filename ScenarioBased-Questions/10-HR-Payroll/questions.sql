-- ============================================
-- SCENARIO-BASED SQL QUESTIONS
-- Category: HR & Payroll (Questions 181-200)
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- SAMPLE SCHEMA
-- ============================================
/*
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    hire_date DATE,
    department_id INT,
    job_id INT,
    manager_id INT,
    salary DECIMAL(12,2),
    commission_pct DECIMAL(5,2),
    status VARCHAR(20)
);

CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100),
    manager_id INT,
    location_id INT,
    budget DECIMAL(15,2)
);

CREATE TABLE payroll (
    payroll_id INT PRIMARY KEY,
    employee_id INT,
    pay_period_start DATE,
    pay_period_end DATE,
    gross_pay DECIMAL(12,2),
    deductions DECIMAL(12,2),
    net_pay DECIMAL(12,2),
    pay_date DATE
);

CREATE TABLE benefits (
    benefit_id INT PRIMARY KEY,
    employee_id INT,
    benefit_type VARCHAR(50),
    coverage_level VARCHAR(30),
    employee_contribution DECIMAL(10,2),
    employer_contribution DECIMAL(10,2),
    effective_date DATE,
    end_date DATE
);

CREATE TABLE time_off (
    request_id INT PRIMARY KEY,
    employee_id INT,
    leave_type VARCHAR(30),
    start_date DATE,
    end_date DATE,
    hours_requested DECIMAL(6,2),
    status VARCHAR(20),
    approved_by INT
);

CREATE TABLE performance_reviews (
    review_id INT PRIMARY KEY,
    employee_id INT,
    reviewer_id INT,
    review_period_start DATE,
    review_period_end DATE,
    overall_rating DECIMAL(3,2),
    goals_met_pct DECIMAL(5,2),
    comments TEXT
);
*/

-- ============================================
-- QUESTION 181: Calculate total compensation by employee
-- ============================================
-- Scenario: Compensation analysis for budgeting

SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    d.department_name,
    e.salary AS base_salary,
    COALESCE(e.salary * e.commission_pct, 0) AS commission,
    COALESCE(SUM(b.employer_contribution * 12), 0) AS annual_benefits,
    e.salary + COALESCE(e.salary * e.commission_pct, 0) + COALESCE(SUM(b.employer_contribution * 12), 0) AS total_compensation
FROM employees e
JOIN departments d ON e.department_id = d.department_id
LEFT JOIN benefits b ON e.employee_id = b.employee_id AND b.end_date IS NULL
WHERE e.status = 'ACTIVE'
GROUP BY e.employee_id, e.first_name, e.last_name, d.department_name, e.salary, e.commission_pct
ORDER BY total_compensation DESC;

-- ============================================
-- QUESTION 182: Calculate payroll tax withholdings
-- ============================================
-- Scenario: Payroll processing

SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    p.gross_pay,
    ROUND(p.gross_pay * 0.062, 2) AS social_security,  -- 6.2%
    ROUND(p.gross_pay * 0.0145, 2) AS medicare,  -- 1.45%
    ROUND(CASE 
        WHEN p.gross_pay * 26 <= 11000 THEN p.gross_pay * 0.10
        WHEN p.gross_pay * 26 <= 44725 THEN p.gross_pay * 0.12
        WHEN p.gross_pay * 26 <= 95375 THEN p.gross_pay * 0.22
        ELSE p.gross_pay * 0.24
    END, 2) AS federal_tax,
    ROUND(p.gross_pay * 0.05, 2) AS state_tax,  -- Example 5%
    p.gross_pay - (p.gross_pay * 0.062) - (p.gross_pay * 0.0145) - 
        CASE WHEN p.gross_pay * 26 <= 11000 THEN p.gross_pay * 0.10
             WHEN p.gross_pay * 26 <= 44725 THEN p.gross_pay * 0.12
             WHEN p.gross_pay * 26 <= 95375 THEN p.gross_pay * 0.22
             ELSE p.gross_pay * 0.24 END - (p.gross_pay * 0.05) AS estimated_net
FROM employees e
JOIN payroll p ON e.employee_id = p.employee_id
WHERE p.pay_date = (SELECT MAX(pay_date) FROM payroll)
ORDER BY p.gross_pay DESC;

-- ============================================
-- QUESTION 183: Analyze time-off balances
-- ============================================
-- Scenario: Leave management

WITH leave_accrual AS (
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        e.hire_date,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) AS years_of_service,
        CASE 
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) < 2 THEN 80
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) < 5 THEN 120
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) < 10 THEN 160
            ELSE 200
        END AS annual_pto_hours,
        40 AS annual_sick_hours
    FROM employees e
    WHERE e.status = 'ACTIVE'
),
leave_used AS (
    SELECT 
        employee_id,
        SUM(CASE WHEN leave_type = 'PTO' AND status = 'APPROVED' THEN hours_requested ELSE 0 END) AS pto_used,
        SUM(CASE WHEN leave_type = 'SICK' AND status = 'APPROVED' THEN hours_requested ELSE 0 END) AS sick_used
    FROM time_off
    WHERE EXTRACT(YEAR FROM start_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY employee_id
)
SELECT 
    la.employee_id,
    la.employee_name,
    la.years_of_service,
    la.annual_pto_hours,
    COALESCE(lu.pto_used, 0) AS pto_used,
    la.annual_pto_hours - COALESCE(lu.pto_used, 0) AS pto_remaining,
    la.annual_sick_hours,
    COALESCE(lu.sick_used, 0) AS sick_used,
    la.annual_sick_hours - COALESCE(lu.sick_used, 0) AS sick_remaining
FROM leave_accrual la
LEFT JOIN leave_used lu ON la.employee_id = lu.employee_id
ORDER BY pto_remaining;

-- ============================================
-- QUESTION 184: Calculate department headcount and budget
-- ============================================
-- Scenario: Workforce planning

SELECT 
    d.department_id,
    d.department_name,
    COUNT(e.employee_id) AS headcount,
    COUNT(CASE WHEN e.status = 'ACTIVE' THEN 1 END) AS active_employees,
    COUNT(CASE WHEN e.hire_date >= CURRENT_DATE - INTERVAL '90 days' THEN 1 END) AS new_hires_90d,
    SUM(e.salary) AS total_salaries,
    d.budget,
    d.budget - SUM(e.salary) AS budget_remaining,
    ROUND(100.0 * SUM(e.salary) / d.budget, 2) AS budget_utilization_pct
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name, d.budget
ORDER BY headcount DESC;

-- ============================================
-- QUESTION 185: Identify salary compression issues
-- ============================================
-- Scenario: Compensation equity analysis

WITH salary_stats AS (
    SELECT 
        e.job_id,
        j.job_title,
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        e.hire_date,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) AS tenure_years,
        e.salary,
        AVG(e.salary) OVER (PARTITION BY e.job_id) AS avg_job_salary,
        MIN(e.salary) OVER (PARTITION BY e.job_id) AS min_job_salary,
        MAX(e.salary) OVER (PARTITION BY e.job_id) AS max_job_salary
    FROM employees e
    JOIN jobs j ON e.job_id = j.job_id
    WHERE e.status = 'ACTIVE'
)
SELECT 
    job_title,
    employee_name,
    tenure_years,
    salary,
    avg_job_salary,
    ROUND(100.0 * (salary - avg_job_salary) / avg_job_salary, 2) AS pct_from_avg,
    CASE 
        WHEN tenure_years > 5 AND salary < avg_job_salary THEN 'COMPRESSION RISK'
        WHEN tenure_years < 1 AND salary > avg_job_salary * 1.1 THEN 'ABOVE MARKET'
        ELSE 'NORMAL'
    END AS salary_status
FROM salary_stats
WHERE tenure_years > 5 AND salary < avg_job_salary
ORDER BY pct_from_avg;

-- ============================================
-- QUESTION 186: Calculate overtime costs
-- ============================================
-- Scenario: Labor cost management

SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    d.department_name,
    SUM(t.regular_hours) AS total_regular_hours,
    SUM(t.overtime_hours) AS total_overtime_hours,
    e.salary / 2080 AS hourly_rate,  -- Annual salary / 2080 work hours
    SUM(t.regular_hours) * (e.salary / 2080) AS regular_pay,
    SUM(t.overtime_hours) * (e.salary / 2080) * 1.5 AS overtime_pay,
    SUM(t.regular_hours) * (e.salary / 2080) + SUM(t.overtime_hours) * (e.salary / 2080) * 1.5 AS total_pay
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN timesheets t ON e.employee_id = t.employee_id
WHERE t.week_ending >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY e.employee_id, e.first_name, e.last_name, d.department_name, e.salary
HAVING SUM(t.overtime_hours) > 0
ORDER BY overtime_pay DESC;

-- ============================================
-- QUESTION 187: Track performance review completion
-- ============================================
-- Scenario: Performance management compliance

WITH review_status AS (
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        e.manager_id,
        m.first_name || ' ' || m.last_name AS manager_name,
        d.department_name,
        MAX(pr.review_period_end) AS last_review_date,
        CURRENT_DATE - MAX(pr.review_period_end) AS days_since_review
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    LEFT JOIN employees m ON e.manager_id = m.employee_id
    LEFT JOIN performance_reviews pr ON e.employee_id = pr.employee_id
    WHERE e.status = 'ACTIVE'
    GROUP BY e.employee_id, e.first_name, e.last_name, e.manager_id, m.first_name, m.last_name, d.department_name
)
SELECT 
    employee_id,
    employee_name,
    manager_name,
    department_name,
    last_review_date,
    days_since_review,
    CASE 
        WHEN last_review_date IS NULL THEN 'NEVER REVIEWED'
        WHEN days_since_review > 365 THEN 'OVERDUE'
        WHEN days_since_review > 300 THEN 'DUE SOON'
        ELSE 'CURRENT'
    END AS review_status
FROM review_status
ORDER BY days_since_review DESC NULLS FIRST;

-- ============================================
-- QUESTION 188: Calculate benefits enrollment summary
-- ============================================
-- Scenario: Benefits administration

SELECT 
    b.benefit_type,
    b.coverage_level,
    COUNT(DISTINCT b.employee_id) AS enrolled_employees,
    ROUND(100.0 * COUNT(DISTINCT b.employee_id) / (SELECT COUNT(*) FROM employees WHERE status = 'ACTIVE'), 2) AS enrollment_rate,
    SUM(b.employee_contribution) AS total_employee_contributions,
    SUM(b.employer_contribution) AS total_employer_contributions,
    AVG(b.employee_contribution) AS avg_employee_contribution,
    AVG(b.employer_contribution) AS avg_employer_contribution
FROM benefits b
JOIN employees e ON b.employee_id = e.employee_id
WHERE b.end_date IS NULL
AND e.status = 'ACTIVE'
GROUP BY b.benefit_type, b.coverage_level
ORDER BY b.benefit_type, enrolled_employees DESC;

-- ============================================
-- QUESTION 189: Analyze turnover by department
-- ============================================
-- Scenario: Retention analysis

WITH terminations AS (
    SELECT 
        department_id,
        COUNT(*) AS terminated_count
    FROM employees
    WHERE status = 'TERMINATED'
    AND termination_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY department_id
),
avg_headcount AS (
    SELECT 
        department_id,
        AVG(headcount) AS avg_headcount
    FROM (
        SELECT department_id, COUNT(*) AS headcount
        FROM employees
        GROUP BY department_id
    ) hc
    GROUP BY department_id
)
SELECT 
    d.department_name,
    COALESCE(t.terminated_count, 0) AS terminations,
    ah.avg_headcount,
    ROUND(100.0 * COALESCE(t.terminated_count, 0) / NULLIF(ah.avg_headcount, 0), 2) AS turnover_rate,
    CASE 
        WHEN 100.0 * COALESCE(t.terminated_count, 0) / NULLIF(ah.avg_headcount, 0) > 20 THEN 'HIGH'
        WHEN 100.0 * COALESCE(t.terminated_count, 0) / NULLIF(ah.avg_headcount, 0) > 10 THEN 'MODERATE'
        ELSE 'LOW'
    END AS turnover_risk
FROM departments d
LEFT JOIN terminations t ON d.department_id = t.department_id
LEFT JOIN avg_headcount ah ON d.department_id = ah.department_id
ORDER BY turnover_rate DESC;

-- ============================================
-- QUESTION 190: Calculate cost per hire
-- ============================================
-- Scenario: Recruiting efficiency

SELECT 
    DATE_TRUNC('quarter', r.hire_date) AS quarter,
    COUNT(*) AS hires,
    SUM(r.recruiting_cost) AS total_recruiting_cost,
    SUM(r.signing_bonus) AS total_signing_bonuses,
    SUM(r.relocation_cost) AS total_relocation,
    SUM(r.recruiting_cost + COALESCE(r.signing_bonus, 0) + COALESCE(r.relocation_cost, 0)) AS total_cost,
    ROUND(SUM(r.recruiting_cost + COALESCE(r.signing_bonus, 0) + COALESCE(r.relocation_cost, 0)) / COUNT(*), 2) AS cost_per_hire,
    AVG(r.days_to_fill) AS avg_days_to_fill
FROM recruiting r
WHERE r.hire_date >= CURRENT_DATE - INTERVAL '2 years'
AND r.status = 'HIRED'
GROUP BY DATE_TRUNC('quarter', r.hire_date)
ORDER BY quarter;

-- ============================================
-- QUESTION 191: Identify flight risk employees
-- ============================================
-- Scenario: Retention risk assessment

WITH employee_signals AS (
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        e.hire_date,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) AS tenure_years,
        e.salary,
        AVG(e.salary) OVER (PARTITION BY e.job_id) AS avg_job_salary,
        COALESCE(pr.overall_rating, 0) AS last_rating,
        COALESCE(pr.goals_met_pct, 0) AS goals_met,
        COUNT(DISTINCT to.request_id) FILTER (WHERE to.leave_type = 'PTO' AND to.start_date >= CURRENT_DATE - INTERVAL '90 days') AS recent_pto_requests
    FROM employees e
    LEFT JOIN performance_reviews pr ON e.employee_id = pr.employee_id
        AND pr.review_period_end = (SELECT MAX(review_period_end) FROM performance_reviews WHERE employee_id = e.employee_id)
    LEFT JOIN time_off to ON e.employee_id = to.employee_id
    WHERE e.status = 'ACTIVE'
    GROUP BY e.employee_id, e.first_name, e.last_name, e.hire_date, e.salary, e.job_id, pr.overall_rating, pr.goals_met_pct
)
SELECT 
    employee_id,
    employee_name,
    tenure_years,
    salary,
    avg_job_salary,
    ROUND(100.0 * (salary - avg_job_salary) / avg_job_salary, 2) AS salary_vs_avg_pct,
    last_rating,
    goals_met,
    recent_pto_requests,
    (CASE WHEN salary < avg_job_salary * 0.9 THEN 2 ELSE 0 END +
     CASE WHEN tenure_years BETWEEN 2 AND 4 THEN 1 ELSE 0 END +
     CASE WHEN last_rating >= 4 AND salary < avg_job_salary THEN 2 ELSE 0 END +
     CASE WHEN recent_pto_requests > 3 THEN 1 ELSE 0 END) AS flight_risk_score
FROM employee_signals
ORDER BY flight_risk_score DESC;

-- ============================================
-- QUESTION 192: Calculate payroll variance
-- ============================================
-- Scenario: Payroll audit

WITH payroll_comparison AS (
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        e.salary / 26 AS expected_gross,  -- Bi-weekly
        p.gross_pay AS actual_gross,
        p.pay_date
    FROM employees e
    JOIN payroll p ON e.employee_id = p.employee_id
    WHERE p.pay_date >= CURRENT_DATE - INTERVAL '3 months'
)
SELECT 
    employee_id,
    employee_name,
    pay_date,
    expected_gross,
    actual_gross,
    actual_gross - expected_gross AS variance,
    ROUND(100.0 * (actual_gross - expected_gross) / expected_gross, 2) AS variance_pct,
    CASE 
        WHEN ABS(actual_gross - expected_gross) > expected_gross * 0.1 THEN 'INVESTIGATE'
        WHEN ABS(actual_gross - expected_gross) > expected_gross * 0.05 THEN 'REVIEW'
        ELSE 'OK'
    END AS status
FROM payroll_comparison
WHERE ABS(actual_gross - expected_gross) > 0.01
ORDER BY ABS(variance) DESC;

-- ============================================
-- QUESTION 193: Analyze training completion
-- ============================================
-- Scenario: Learning and development tracking

SELECT 
    t.training_id,
    t.training_name,
    t.category,
    t.required,
    COUNT(DISTINCT te.employee_id) AS enrolled,
    COUNT(DISTINCT CASE WHEN te.status = 'COMPLETED' THEN te.employee_id END) AS completed,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN te.status = 'COMPLETED' THEN te.employee_id END) / 
          NULLIF(COUNT(DISTINCT te.employee_id), 0), 2) AS completion_rate,
    AVG(CASE WHEN te.status = 'COMPLETED' THEN te.score END) AS avg_score,
    AVG(CASE WHEN te.status = 'COMPLETED' THEN 
        EXTRACT(DAYS FROM (te.completion_date - te.enrollment_date)) END) AS avg_days_to_complete
FROM trainings t
LEFT JOIN training_enrollments te ON t.training_id = te.training_id
GROUP BY t.training_id, t.training_name, t.category, t.required
ORDER BY t.required DESC, completion_rate;

-- ============================================
-- QUESTION 194: Calculate span of control
-- ============================================
-- Scenario: Organizational structure analysis

WITH RECURSIVE org_hierarchy AS (
    SELECT 
        employee_id,
        first_name || ' ' || last_name AS employee_name,
        manager_id,
        1 AS level
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name,
        e.manager_id,
        oh.level + 1
    FROM employees e
    JOIN org_hierarchy oh ON e.manager_id = oh.employee_id
),
direct_reports AS (
    SELECT 
        manager_id,
        COUNT(*) AS direct_report_count
    FROM employees
    WHERE manager_id IS NOT NULL
    GROUP BY manager_id
)
SELECT 
    oh.employee_id,
    oh.employee_name,
    oh.level,
    COALESCE(dr.direct_report_count, 0) AS direct_reports,
    CASE 
        WHEN COALESCE(dr.direct_report_count, 0) > 10 THEN 'TOO WIDE'
        WHEN COALESCE(dr.direct_report_count, 0) < 3 AND oh.level < 4 THEN 'TOO NARROW'
        ELSE 'OPTIMAL'
    END AS span_assessment
FROM org_hierarchy oh
LEFT JOIN direct_reports dr ON oh.employee_id = dr.manager_id
ORDER BY oh.level, dr.direct_report_count DESC;

-- ============================================
-- QUESTION 195: Calculate diversity metrics
-- ============================================
-- Scenario: DEI reporting

SELECT 
    d.department_name,
    COUNT(*) AS total_employees,
    ROUND(100.0 * COUNT(CASE WHEN e.gender = 'F' THEN 1 END) / COUNT(*), 2) AS female_pct,
    ROUND(100.0 * COUNT(CASE WHEN e.gender = 'M' THEN 1 END) / COUNT(*), 2) AS male_pct,
    ROUND(100.0 * COUNT(CASE WHEN e.ethnicity = 'MINORITY' THEN 1 END) / COUNT(*), 2) AS minority_pct,
    ROUND(100.0 * COUNT(CASE WHEN e.veteran_status = TRUE THEN 1 END) / COUNT(*), 2) AS veteran_pct,
    ROUND(AVG(CASE WHEN e.gender = 'F' THEN e.salary END), 2) AS avg_female_salary,
    ROUND(AVG(CASE WHEN e.gender = 'M' THEN e.salary END), 2) AS avg_male_salary,
    ROUND(100.0 * (AVG(CASE WHEN e.gender = 'F' THEN e.salary END) - AVG(CASE WHEN e.gender = 'M' THEN e.salary END)) / 
          AVG(CASE WHEN e.gender = 'M' THEN e.salary END), 2) AS gender_pay_gap_pct
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE e.status = 'ACTIVE'
GROUP BY d.department_name
ORDER BY total_employees DESC;

-- ============================================
-- QUESTION 196: Analyze promotion patterns
-- ============================================
-- Scenario: Career progression analysis

WITH promotions AS (
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        e.hire_date,
        jh.effective_date AS promotion_date,
        jh.old_job_id,
        jh.new_job_id,
        jh.old_salary,
        jh.new_salary,
        ROW_NUMBER() OVER (PARTITION BY e.employee_id ORDER BY jh.effective_date) AS promotion_number
    FROM employees e
    JOIN job_history jh ON e.employee_id = jh.employee_id
    WHERE jh.change_type = 'PROMOTION'
)
SELECT 
    employee_id,
    employee_name,
    hire_date,
    promotion_date,
    EXTRACT(DAYS FROM (promotion_date - hire_date)) AS days_to_first_promotion,
    old_salary,
    new_salary,
    new_salary - old_salary AS salary_increase,
    ROUND(100.0 * (new_salary - old_salary) / old_salary, 2) AS increase_pct
FROM promotions
WHERE promotion_number = 1
ORDER BY days_to_first_promotion;

-- ============================================
-- QUESTION 197: Calculate absenteeism rate
-- ============================================
-- Scenario: Workforce productivity analysis

WITH absence_data AS (
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        d.department_name,
        SUM(CASE WHEN to.leave_type IN ('SICK', 'PERSONAL') THEN to.hours_requested ELSE 0 END) AS unplanned_absence_hours,
        SUM(to.hours_requested) AS total_absence_hours
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    LEFT JOIN time_off to ON e.employee_id = to.employee_id 
        AND to.status = 'APPROVED'
        AND to.start_date >= CURRENT_DATE - INTERVAL '1 year'
    WHERE e.status = 'ACTIVE'
    GROUP BY e.employee_id, e.first_name, e.last_name, d.department_name
)
SELECT 
    department_name,
    COUNT(*) AS employee_count,
    SUM(unplanned_absence_hours) AS total_unplanned_hours,
    SUM(total_absence_hours) AS total_absence_hours,
    ROUND(AVG(unplanned_absence_hours), 2) AS avg_unplanned_per_employee,
    ROUND(100.0 * SUM(unplanned_absence_hours) / (COUNT(*) * 2080), 2) AS absenteeism_rate
FROM absence_data
GROUP BY department_name
ORDER BY absenteeism_rate DESC;

-- ============================================
-- QUESTION 198: Generate payroll summary report
-- ============================================
-- Scenario: Executive payroll reporting

SELECT 
    DATE_TRUNC('month', p.pay_date) AS pay_month,
    COUNT(DISTINCT p.employee_id) AS employees_paid,
    SUM(p.gross_pay) AS total_gross,
    SUM(p.deductions) AS total_deductions,
    SUM(p.net_pay) AS total_net,
    SUM(p.gross_pay) * 0.0765 AS employer_fica,  -- 7.65% employer portion
    SUM(b.employer_contribution) AS employer_benefits,
    SUM(p.gross_pay) + SUM(p.gross_pay) * 0.0765 + COALESCE(SUM(b.employer_contribution), 0) AS total_labor_cost
FROM payroll p
LEFT JOIN benefits b ON p.employee_id = b.employee_id AND b.end_date IS NULL
WHERE p.pay_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', p.pay_date)
ORDER BY pay_month;

-- ============================================
-- QUESTION 199: Identify compliance gaps
-- ============================================
-- Scenario: HR compliance audit

SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    e.hire_date,
    CASE WHEN i9.verified_date IS NULL THEN 'MISSING' ELSE 'COMPLETE' END AS i9_status,
    CASE WHEN w4.submission_date IS NULL THEN 'MISSING' ELSE 'COMPLETE' END AS w4_status,
    CASE WHEN bg.completion_date IS NULL THEN 'MISSING' ELSE 'COMPLETE' END AS background_check,
    CASE WHEN dt.test_date IS NULL THEN 'MISSING' 
         WHEN dt.test_date < CURRENT_DATE - INTERVAL '1 year' THEN 'EXPIRED'
         ELSE 'CURRENT' END AS drug_test_status,
    CASE WHEN sh.completion_date IS NULL THEN 'MISSING'
         WHEN sh.completion_date < CURRENT_DATE - INTERVAL '1 year' THEN 'EXPIRED'
         ELSE 'CURRENT' END AS safety_training
FROM employees e
LEFT JOIN i9_forms i9 ON e.employee_id = i9.employee_id
LEFT JOIN w4_forms w4 ON e.employee_id = w4.employee_id
LEFT JOIN background_checks bg ON e.employee_id = bg.employee_id
LEFT JOIN drug_tests dt ON e.employee_id = dt.employee_id
LEFT JOIN safety_training sh ON e.employee_id = sh.employee_id
WHERE e.status = 'ACTIVE'
AND (i9.verified_date IS NULL 
     OR w4.submission_date IS NULL 
     OR bg.completion_date IS NULL
     OR dt.test_date IS NULL OR dt.test_date < CURRENT_DATE - INTERVAL '1 year'
     OR sh.completion_date IS NULL OR sh.completion_date < CURRENT_DATE - INTERVAL '1 year')
ORDER BY e.hire_date;

-- ============================================
-- QUESTION 200: Generate workforce analytics dashboard
-- ============================================
-- Scenario: Executive HR dashboard

SELECT 
    'Total Headcount' AS metric,
    COUNT(*)::TEXT AS value
FROM employees WHERE status = 'ACTIVE'

UNION ALL

SELECT 
    'Average Tenure (Years)',
    ROUND(AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date))), 1)::TEXT
FROM employees WHERE status = 'ACTIVE'

UNION ALL

SELECT 
    'Average Salary',
    '$' || TO_CHAR(ROUND(AVG(salary), 0), 'FM999,999,999')
FROM employees WHERE status = 'ACTIVE'

UNION ALL

SELECT 
    'New Hires (YTD)',
    COUNT(*)::TEXT
FROM employees 
WHERE hire_date >= DATE_TRUNC('year', CURRENT_DATE)

UNION ALL

SELECT 
    'Turnover Rate (12mo)',
    ROUND(100.0 * (SELECT COUNT(*) FROM employees WHERE status = 'TERMINATED' AND termination_date >= CURRENT_DATE - INTERVAL '1 year') / 
          (SELECT COUNT(*) FROM employees), 2)::TEXT || '%'

UNION ALL

SELECT 
    'Open Positions',
    COUNT(*)::TEXT
FROM job_postings WHERE status = 'OPEN'

UNION ALL

SELECT 
    'Avg Days to Fill',
    ROUND(AVG(days_to_fill), 0)::TEXT
FROM recruiting WHERE hire_date >= CURRENT_DATE - INTERVAL '1 year'

UNION ALL

SELECT 
    'Training Completion Rate',
    ROUND(100.0 * COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) / COUNT(*), 1)::TEXT || '%'
FROM training_enrollments
WHERE enrollment_date >= DATE_TRUNC('year', CURRENT_DATE);
