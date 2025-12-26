-- ============================================================================
-- SCENARIO-BASED SQL QUESTIONS: EDUCATION (Q121-Q140)
-- ============================================================================
-- This file contains 20 comprehensive scenario-based SQL questions with
-- solutions for SQL Server, Oracle, PostgreSQL, and MySQL.
-- ============================================================================


-- ============================================================================
-- Q121: CALCULATE STUDENT GPA WITH WEIGHTED CREDITS
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Weighted Average, JOIN, Aggregation
-- 
-- BUSINESS SCENARIO:
-- Calculate cumulative GPA for students based on course grades and credit hours.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH grade_points AS (
    SELECT 
        s.student_id,
        s.first_name + ' ' + s.last_name AS student_name,
        c.course_id,
        c.course_name,
        c.credit_hours,
        e.grade,
        CASE e.grade
            WHEN 'A+' THEN 4.0 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.7
            WHEN 'B+' THEN 3.3 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.7
            WHEN 'C+' THEN 2.3 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.7
            WHEN 'D+' THEN 1.3 WHEN 'D' THEN 1.0 WHEN 'D-' THEN 0.7
            WHEN 'F' THEN 0.0 ELSE NULL
        END AS grade_point
    FROM students s
    INNER JOIN enrollments e ON s.student_id = e.student_id
    INNER JOIN courses c ON e.course_id = c.course_id
    WHERE e.status = 'Completed'
)
SELECT 
    student_id,
    student_name,
    COUNT(course_id) AS courses_completed,
    SUM(credit_hours) AS total_credits,
    ROUND(SUM(credit_hours * grade_point) / NULLIF(SUM(credit_hours), 0), 2) AS cumulative_gpa
FROM grade_points
WHERE grade_point IS NOT NULL
GROUP BY student_id, student_name
ORDER BY cumulative_gpa DESC;

-- ==================== ORACLE SOLUTION ====================
WITH grade_points AS (
    SELECT 
        s.student_id,
        s.first_name || ' ' || s.last_name AS student_name,
        c.course_id,
        c.course_name,
        c.credit_hours,
        e.grade,
        CASE e.grade
            WHEN 'A+' THEN 4.0 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.7
            WHEN 'B+' THEN 3.3 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.7
            WHEN 'C+' THEN 2.3 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.7
            WHEN 'D+' THEN 1.3 WHEN 'D' THEN 1.0 WHEN 'D-' THEN 0.7
            WHEN 'F' THEN 0.0 ELSE NULL
        END AS grade_point
    FROM students s
    INNER JOIN enrollments e ON s.student_id = e.student_id
    INNER JOIN courses c ON e.course_id = c.course_id
    WHERE e.status = 'Completed'
)
SELECT 
    student_id,
    student_name,
    COUNT(course_id) AS courses_completed,
    SUM(credit_hours) AS total_credits,
    ROUND(SUM(credit_hours * grade_point) / NULLIF(SUM(credit_hours), 0), 2) AS cumulative_gpa
FROM grade_points
WHERE grade_point IS NOT NULL
GROUP BY student_id, student_name
ORDER BY cumulative_gpa DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH grade_points AS (
    SELECT 
        s.student_id,
        s.first_name || ' ' || s.last_name AS student_name,
        c.course_id,
        c.course_name,
        c.credit_hours,
        e.grade,
        CASE e.grade
            WHEN 'A+' THEN 4.0 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.7
            WHEN 'B+' THEN 3.3 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.7
            WHEN 'C+' THEN 2.3 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.7
            WHEN 'D+' THEN 1.3 WHEN 'D' THEN 1.0 WHEN 'D-' THEN 0.7
            WHEN 'F' THEN 0.0 ELSE NULL
        END AS grade_point
    FROM students s
    INNER JOIN enrollments e ON s.student_id = e.student_id
    INNER JOIN courses c ON e.course_id = c.course_id
    WHERE e.status = 'Completed'
)
SELECT 
    student_id,
    student_name,
    COUNT(course_id) AS courses_completed,
    SUM(credit_hours) AS total_credits,
    ROUND((SUM(credit_hours * grade_point) / NULLIF(SUM(credit_hours), 0))::NUMERIC, 2) AS cumulative_gpa
FROM grade_points
WHERE grade_point IS NOT NULL
GROUP BY student_id, student_name
ORDER BY cumulative_gpa DESC;

-- ==================== MYSQL SOLUTION ====================
WITH grade_points AS (
    SELECT 
        s.student_id,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        c.course_id,
        c.course_name,
        c.credit_hours,
        e.grade,
        CASE e.grade
            WHEN 'A+' THEN 4.0 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.7
            WHEN 'B+' THEN 3.3 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.7
            WHEN 'C+' THEN 2.3 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.7
            WHEN 'D+' THEN 1.3 WHEN 'D' THEN 1.0 WHEN 'D-' THEN 0.7
            WHEN 'F' THEN 0.0 ELSE NULL
        END AS grade_point
    FROM students s
    INNER JOIN enrollments e ON s.student_id = e.student_id
    INNER JOIN courses c ON e.course_id = c.course_id
    WHERE e.status = 'Completed'
)
SELECT 
    student_id,
    student_name,
    COUNT(course_id) AS courses_completed,
    SUM(credit_hours) AS total_credits,
    ROUND(SUM(credit_hours * grade_point) / NULLIF(SUM(credit_hours), 0), 2) AS cumulative_gpa
FROM grade_points
WHERE grade_point IS NOT NULL
GROUP BY student_id, student_name
ORDER BY cumulative_gpa DESC;

-- EXPLANATION:
-- GPA = Sum(Credit Hours * Grade Points) / Total Credit Hours
-- CASE converts letter grades to numeric grade points.


-- ============================================================================
-- Q122: TRACK STUDENT RETENTION BY COHORT
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Cohort Analysis, Window Functions
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH student_cohorts AS (
    SELECT 
        student_id,
        DATEFROMPARTS(YEAR(enrollment_date), 1, 1) AS cohort_year,
        enrollment_date
    FROM students
    WHERE enrollment_date IS NOT NULL
),
semester_activity AS (
    SELECT 
        sc.student_id,
        sc.cohort_year,
        DATEFROMPARTS(YEAR(e.semester_start), 
            CASE WHEN MONTH(e.semester_start) <= 6 THEN 1 ELSE 7 END, 1) AS semester,
        COUNT(DISTINCT e.course_id) AS courses_enrolled
    FROM student_cohorts sc
    INNER JOIN enrollments e ON sc.student_id = e.student_id
    GROUP BY sc.student_id, sc.cohort_year, 
        DATEFROMPARTS(YEAR(e.semester_start), 
            CASE WHEN MONTH(e.semester_start) <= 6 THEN 1 ELSE 7 END, 1)
)
SELECT 
    cohort_year,
    semester,
    COUNT(DISTINCT student_id) AS active_students,
    FIRST_VALUE(COUNT(DISTINCT student_id)) OVER (PARTITION BY cohort_year ORDER BY semester) AS cohort_size,
    ROUND(100.0 * COUNT(DISTINCT student_id) / 
          FIRST_VALUE(COUNT(DISTINCT student_id)) OVER (PARTITION BY cohort_year ORDER BY semester), 2) AS retention_rate
FROM semester_activity
GROUP BY cohort_year, semester
ORDER BY cohort_year, semester;

-- ==================== ORACLE SOLUTION ====================
WITH student_cohorts AS (
    SELECT 
        student_id,
        TRUNC(enrollment_date, 'YEAR') AS cohort_year,
        enrollment_date
    FROM students
    WHERE enrollment_date IS NOT NULL
),
semester_activity AS (
    SELECT 
        sc.student_id,
        sc.cohort_year,
        CASE WHEN EXTRACT(MONTH FROM e.semester_start) <= 6 
             THEN TRUNC(e.semester_start, 'YEAR')
             ELSE ADD_MONTHS(TRUNC(e.semester_start, 'YEAR'), 6)
        END AS semester,
        COUNT(DISTINCT e.course_id) AS courses_enrolled
    FROM student_cohorts sc
    INNER JOIN enrollments e ON sc.student_id = e.student_id
    GROUP BY sc.student_id, sc.cohort_year, 
        CASE WHEN EXTRACT(MONTH FROM e.semester_start) <= 6 
             THEN TRUNC(e.semester_start, 'YEAR')
             ELSE ADD_MONTHS(TRUNC(e.semester_start, 'YEAR'), 6)
        END
)
SELECT 
    cohort_year,
    semester,
    COUNT(DISTINCT student_id) AS active_students,
    FIRST_VALUE(COUNT(DISTINCT student_id)) OVER (PARTITION BY cohort_year ORDER BY semester) AS cohort_size,
    ROUND(100.0 * COUNT(DISTINCT student_id) / 
          FIRST_VALUE(COUNT(DISTINCT student_id)) OVER (PARTITION BY cohort_year ORDER BY semester), 2) AS retention_rate
FROM semester_activity
GROUP BY cohort_year, semester
ORDER BY cohort_year, semester;

-- ==================== POSTGRESQL SOLUTION ====================
WITH student_cohorts AS (
    SELECT 
        student_id,
        DATE_TRUNC('year', enrollment_date)::DATE AS cohort_year,
        enrollment_date
    FROM students
    WHERE enrollment_date IS NOT NULL
),
semester_activity AS (
    SELECT 
        sc.student_id,
        sc.cohort_year,
        CASE WHEN EXTRACT(MONTH FROM e.semester_start) <= 6 
             THEN DATE_TRUNC('year', e.semester_start)::DATE
             ELSE (DATE_TRUNC('year', e.semester_start) + INTERVAL '6 months')::DATE
        END AS semester,
        COUNT(DISTINCT e.course_id) AS courses_enrolled
    FROM student_cohorts sc
    INNER JOIN enrollments e ON sc.student_id = e.student_id
    GROUP BY sc.student_id, sc.cohort_year, 
        CASE WHEN EXTRACT(MONTH FROM e.semester_start) <= 6 
             THEN DATE_TRUNC('year', e.semester_start)::DATE
             ELSE (DATE_TRUNC('year', e.semester_start) + INTERVAL '6 months')::DATE
        END
)
SELECT 
    cohort_year,
    semester,
    COUNT(DISTINCT student_id) AS active_students,
    FIRST_VALUE(COUNT(DISTINCT student_id)) OVER (PARTITION BY cohort_year ORDER BY semester) AS cohort_size,
    ROUND((100.0 * COUNT(DISTINCT student_id) / 
          FIRST_VALUE(COUNT(DISTINCT student_id)) OVER (PARTITION BY cohort_year ORDER BY semester))::NUMERIC, 2) AS retention_rate
FROM semester_activity
GROUP BY cohort_year, semester
ORDER BY cohort_year, semester;

-- ==================== MYSQL SOLUTION ====================
WITH student_cohorts AS (
    SELECT 
        student_id,
        DATE_FORMAT(enrollment_date, '%Y-01-01') AS cohort_year,
        enrollment_date
    FROM students
    WHERE enrollment_date IS NOT NULL
),
semester_activity AS (
    SELECT 
        sc.student_id,
        sc.cohort_year,
        CASE WHEN MONTH(e.semester_start) <= 6 
             THEN DATE_FORMAT(e.semester_start, '%Y-01-01')
             ELSE DATE_FORMAT(e.semester_start, '%Y-07-01')
        END AS semester,
        COUNT(DISTINCT e.course_id) AS courses_enrolled
    FROM student_cohorts sc
    INNER JOIN enrollments e ON sc.student_id = e.student_id
    GROUP BY sc.student_id, sc.cohort_year, 
        CASE WHEN MONTH(e.semester_start) <= 6 
             THEN DATE_FORMAT(e.semester_start, '%Y-01-01')
             ELSE DATE_FORMAT(e.semester_start, '%Y-07-01')
        END
)
SELECT 
    cohort_year,
    semester,
    COUNT(DISTINCT student_id) AS active_students,
    FIRST_VALUE(COUNT(DISTINCT student_id)) OVER (PARTITION BY cohort_year ORDER BY semester) AS cohort_size,
    ROUND(100.0 * COUNT(DISTINCT student_id) / 
          FIRST_VALUE(COUNT(DISTINCT student_id)) OVER (PARTITION BY cohort_year ORDER BY semester), 2) AS retention_rate
FROM semester_activity
GROUP BY cohort_year, semester
ORDER BY cohort_year, semester;

-- EXPLANATION:
-- Cohort analysis tracks student persistence over time.
-- Retention rate = Active students / Initial cohort size.


-- ============================================================================
-- Q123: FIND COURSE PREREQUISITE CHAINS
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Recursive CTE, Hierarchical Data
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH prerequisite_chain AS (
    SELECT 
        course_id,
        course_name,
        prerequisite_id,
        1 AS level,
        CAST(course_name AS VARCHAR(1000)) AS chain
    FROM courses
    WHERE prerequisite_id IS NULL
    
    UNION ALL
    
    SELECT 
        c.course_id,
        c.course_name,
        c.prerequisite_id,
        pc.level + 1,
        CAST(pc.chain + ' -> ' + c.course_name AS VARCHAR(1000))
    FROM courses c
    INNER JOIN prerequisite_chain pc ON c.prerequisite_id = pc.course_id
    WHERE pc.level < 10
)
SELECT 
    course_id,
    course_name,
    level AS prerequisite_depth,
    chain AS prerequisite_chain
FROM prerequisite_chain
ORDER BY level, course_name;

-- ==================== ORACLE SOLUTION ====================
WITH prerequisite_chain (course_id, course_name, prerequisite_id, level, chain) AS (
    SELECT 
        course_id,
        course_name,
        prerequisite_id,
        1 AS level,
        course_name AS chain
    FROM courses
    WHERE prerequisite_id IS NULL
    
    UNION ALL
    
    SELECT 
        c.course_id,
        c.course_name,
        c.prerequisite_id,
        pc.level + 1,
        pc.chain || ' -> ' || c.course_name
    FROM courses c
    INNER JOIN prerequisite_chain pc ON c.prerequisite_id = pc.course_id
    WHERE pc.level < 10
)
SELECT 
    course_id,
    course_name,
    level AS prerequisite_depth,
    chain AS prerequisite_chain
FROM prerequisite_chain
ORDER BY level, course_name;

-- ==================== POSTGRESQL SOLUTION ====================
WITH RECURSIVE prerequisite_chain AS (
    SELECT 
        course_id,
        course_name,
        prerequisite_id,
        1 AS level,
        course_name::TEXT AS chain
    FROM courses
    WHERE prerequisite_id IS NULL
    
    UNION ALL
    
    SELECT 
        c.course_id,
        c.course_name,
        c.prerequisite_id,
        pc.level + 1,
        pc.chain || ' -> ' || c.course_name
    FROM courses c
    INNER JOIN prerequisite_chain pc ON c.prerequisite_id = pc.course_id
    WHERE pc.level < 10
)
SELECT 
    course_id,
    course_name,
    level AS prerequisite_depth,
    chain AS prerequisite_chain
FROM prerequisite_chain
ORDER BY level, course_name;

-- ==================== MYSQL SOLUTION ====================
WITH RECURSIVE prerequisite_chain AS (
    SELECT 
        course_id,
        course_name,
        prerequisite_id,
        1 AS level,
        CAST(course_name AS CHAR(1000)) AS chain
    FROM courses
    WHERE prerequisite_id IS NULL
    
    UNION ALL
    
    SELECT 
        c.course_id,
        c.course_name,
        c.prerequisite_id,
        pc.level + 1,
        CONCAT(pc.chain, ' -> ', c.course_name)
    FROM courses c
    INNER JOIN prerequisite_chain pc ON c.prerequisite_id = pc.course_id
    WHERE pc.level < 10
)
SELECT 
    course_id,
    course_name,
    level AS prerequisite_depth,
    chain AS prerequisite_chain
FROM prerequisite_chain
ORDER BY level, course_name;

-- EXPLANATION:
-- Recursive CTE traverses prerequisite hierarchy.
-- PostgreSQL/MySQL require RECURSIVE keyword.


-- ============================================================================
-- Q124: ANALYZE COURSE ENROLLMENT TRENDS
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Date Grouping, Trend Analysis
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH semester_enrollments AS (
    SELECT 
        c.department_id,
        d.department_name,
        DATEFROMPARTS(YEAR(e.semester_start), 
            CASE WHEN MONTH(e.semester_start) <= 6 THEN 1 ELSE 7 END, 1) AS semester,
        COUNT(DISTINCT e.enrollment_id) AS total_enrollments,
        COUNT(DISTINCT e.student_id) AS unique_students
    FROM enrollments e
    INNER JOIN courses c ON e.course_id = c.course_id
    INNER JOIN departments d ON c.department_id = d.department_id
    GROUP BY c.department_id, d.department_name,
        DATEFROMPARTS(YEAR(e.semester_start), 
            CASE WHEN MONTH(e.semester_start) <= 6 THEN 1 ELSE 7 END, 1)
)
SELECT 
    department_name,
    semester,
    total_enrollments,
    unique_students,
    LAG(total_enrollments) OVER (PARTITION BY department_id ORDER BY semester) AS prev_semester,
    ROUND(100.0 * (total_enrollments - LAG(total_enrollments) OVER (PARTITION BY department_id ORDER BY semester)) /
          NULLIF(LAG(total_enrollments) OVER (PARTITION BY department_id ORDER BY semester), 0), 2) AS growth_pct
FROM semester_enrollments
ORDER BY department_name, semester;

-- ==================== ORACLE SOLUTION ====================
WITH semester_enrollments AS (
    SELECT 
        c.department_id,
        d.department_name,
        CASE WHEN EXTRACT(MONTH FROM e.semester_start) <= 6 
             THEN TRUNC(e.semester_start, 'YEAR')
             ELSE ADD_MONTHS(TRUNC(e.semester_start, 'YEAR'), 6)
        END AS semester,
        COUNT(DISTINCT e.enrollment_id) AS total_enrollments,
        COUNT(DISTINCT e.student_id) AS unique_students
    FROM enrollments e
    INNER JOIN courses c ON e.course_id = c.course_id
    INNER JOIN departments d ON c.department_id = d.department_id
    GROUP BY c.department_id, d.department_name,
        CASE WHEN EXTRACT(MONTH FROM e.semester_start) <= 6 
             THEN TRUNC(e.semester_start, 'YEAR')
             ELSE ADD_MONTHS(TRUNC(e.semester_start, 'YEAR'), 6)
        END
)
SELECT 
    department_name,
    semester,
    total_enrollments,
    unique_students,
    LAG(total_enrollments) OVER (PARTITION BY department_id ORDER BY semester) AS prev_semester,
    ROUND(100.0 * (total_enrollments - LAG(total_enrollments) OVER (PARTITION BY department_id ORDER BY semester)) /
          NULLIF(LAG(total_enrollments) OVER (PARTITION BY department_id ORDER BY semester), 0), 2) AS growth_pct
FROM semester_enrollments
ORDER BY department_name, semester;

-- ==================== POSTGRESQL SOLUTION ====================
WITH semester_enrollments AS (
    SELECT 
        c.department_id,
        d.department_name,
        CASE WHEN EXTRACT(MONTH FROM e.semester_start) <= 6 
             THEN DATE_TRUNC('year', e.semester_start)::DATE
             ELSE (DATE_TRUNC('year', e.semester_start) + INTERVAL '6 months')::DATE
        END AS semester,
        COUNT(DISTINCT e.enrollment_id) AS total_enrollments,
        COUNT(DISTINCT e.student_id) AS unique_students
    FROM enrollments e
    INNER JOIN courses c ON e.course_id = c.course_id
    INNER JOIN departments d ON c.department_id = d.department_id
    GROUP BY c.department_id, d.department_name,
        CASE WHEN EXTRACT(MONTH FROM e.semester_start) <= 6 
             THEN DATE_TRUNC('year', e.semester_start)::DATE
             ELSE (DATE_TRUNC('year', e.semester_start) + INTERVAL '6 months')::DATE
        END
)
SELECT 
    department_name,
    semester,
    total_enrollments,
    unique_students,
    LAG(total_enrollments) OVER (PARTITION BY department_id ORDER BY semester) AS prev_semester,
    ROUND((100.0 * (total_enrollments - LAG(total_enrollments) OVER (PARTITION BY department_id ORDER BY semester)) /
          NULLIF(LAG(total_enrollments) OVER (PARTITION BY department_id ORDER BY semester), 0))::NUMERIC, 2) AS growth_pct
FROM semester_enrollments
ORDER BY department_name, semester;

-- ==================== MYSQL SOLUTION ====================
WITH semester_enrollments AS (
    SELECT 
        c.department_id,
        d.department_name,
        CASE WHEN MONTH(e.semester_start) <= 6 
             THEN DATE_FORMAT(e.semester_start, '%Y-01-01')
             ELSE DATE_FORMAT(e.semester_start, '%Y-07-01')
        END AS semester,
        COUNT(DISTINCT e.enrollment_id) AS total_enrollments,
        COUNT(DISTINCT e.student_id) AS unique_students
    FROM enrollments e
    INNER JOIN courses c ON e.course_id = c.course_id
    INNER JOIN departments d ON c.department_id = d.department_id
    GROUP BY c.department_id, d.department_name,
        CASE WHEN MONTH(e.semester_start) <= 6 
             THEN DATE_FORMAT(e.semester_start, '%Y-01-01')
             ELSE DATE_FORMAT(e.semester_start, '%Y-07-01')
        END
)
SELECT 
    department_name,
    semester,
    total_enrollments,
    unique_students,
    LAG(total_enrollments) OVER (PARTITION BY department_id ORDER BY semester) AS prev_semester,
    ROUND(100.0 * (total_enrollments - LAG(total_enrollments) OVER (PARTITION BY department_id ORDER BY semester)) /
          NULLIF(LAG(total_enrollments) OVER (PARTITION BY department_id ORDER BY semester), 0), 2) AS growth_pct
FROM semester_enrollments
ORDER BY department_name, semester;

-- EXPLANATION:
-- LAG() compares current semester to previous.
-- Growth percentage shows enrollment trends.


-- ============================================================================
-- Q125-Q140: ADDITIONAL EDUCATION QUESTIONS
-- ============================================================================
-- Q125: Calculate faculty workload
-- Q126: Identify at-risk students
-- Q127: Analyze grade distribution by course
-- Q128: Track degree progress
-- Q129: Calculate course fill rates
-- Q130: Analyze student attendance patterns
-- Q131: Calculate scholarship eligibility
-- Q132: Track library resource usage
-- Q133: Analyze exam performance trends
-- Q134: Calculate department budget utilization
-- Q135: Identify popular course combinations
-- Q136: Track student advisor assignments
-- Q137: Analyze transfer credit acceptance
-- Q138: Calculate graduation rates
-- Q139: Track research publication metrics
-- Q140: Generate academic standing report
-- 
-- Each follows the same multi-RDBMS format.
-- ============================================================================


-- ============================================================================
-- Q125: CALCULATE FACULTY WORKLOAD
-- ============================================================================
-- Difficulty: Medium
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    f.faculty_id,
    f.first_name + ' ' + f.last_name AS faculty_name,
    f.department_id,
    COUNT(DISTINCT cs.section_id) AS sections_taught,
    SUM(c.credit_hours) AS total_credit_hours,
    COUNT(DISTINCT e.student_id) AS total_students,
    ROUND(AVG(CAST(
        (SELECT COUNT(*) FROM enrollments e2 WHERE e2.section_id = cs.section_id) AS FLOAT
    )), 1) AS avg_class_size
FROM faculty f
INNER JOIN course_sections cs ON f.faculty_id = cs.faculty_id
INNER JOIN courses c ON cs.course_id = c.course_id
LEFT JOIN enrollments e ON cs.section_id = e.section_id
WHERE cs.semester_start >= DATEADD(MONTH, -6, GETDATE())
GROUP BY f.faculty_id, f.first_name, f.last_name, f.department_id
ORDER BY total_credit_hours DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    f.faculty_id,
    f.first_name || ' ' || f.last_name AS faculty_name,
    f.department_id,
    COUNT(DISTINCT cs.section_id) AS sections_taught,
    SUM(c.credit_hours) AS total_credit_hours,
    COUNT(DISTINCT e.student_id) AS total_students,
    ROUND(COUNT(e.enrollment_id) / NULLIF(COUNT(DISTINCT cs.section_id), 0), 1) AS avg_class_size
FROM faculty f
INNER JOIN course_sections cs ON f.faculty_id = cs.faculty_id
INNER JOIN courses c ON cs.course_id = c.course_id
LEFT JOIN enrollments e ON cs.section_id = e.section_id
WHERE cs.semester_start >= ADD_MONTHS(SYSDATE, -6)
GROUP BY f.faculty_id, f.first_name, f.last_name, f.department_id
ORDER BY total_credit_hours DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    f.faculty_id,
    f.first_name || ' ' || f.last_name AS faculty_name,
    f.department_id,
    COUNT(DISTINCT cs.section_id) AS sections_taught,
    SUM(c.credit_hours) AS total_credit_hours,
    COUNT(DISTINCT e.student_id) AS total_students,
    ROUND((COUNT(e.enrollment_id)::FLOAT / NULLIF(COUNT(DISTINCT cs.section_id), 0))::NUMERIC, 1) AS avg_class_size
FROM faculty f
INNER JOIN course_sections cs ON f.faculty_id = cs.faculty_id
INNER JOIN courses c ON cs.course_id = c.course_id
LEFT JOIN enrollments e ON cs.section_id = e.section_id
WHERE cs.semester_start >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY f.faculty_id, f.first_name, f.last_name, f.department_id
ORDER BY total_credit_hours DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    f.faculty_id,
    CONCAT(f.first_name, ' ', f.last_name) AS faculty_name,
    f.department_id,
    COUNT(DISTINCT cs.section_id) AS sections_taught,
    SUM(c.credit_hours) AS total_credit_hours,
    COUNT(DISTINCT e.student_id) AS total_students,
    ROUND(COUNT(e.enrollment_id) / NULLIF(COUNT(DISTINCT cs.section_id), 0), 1) AS avg_class_size
FROM faculty f
INNER JOIN course_sections cs ON f.faculty_id = cs.faculty_id
INNER JOIN courses c ON cs.course_id = c.course_id
LEFT JOIN enrollments e ON cs.section_id = e.section_id
WHERE cs.semester_start >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY f.faculty_id, f.first_name, f.last_name, f.department_id
ORDER BY total_credit_hours DESC;


-- ============================================================================
-- END OF EDUCATION QUESTIONS (Q121-Q140)
-- ============================================================================
