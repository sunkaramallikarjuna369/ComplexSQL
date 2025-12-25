-- ============================================
-- SCENARIO-BASED SQL QUESTIONS
-- Category: Education (Questions 121-140)
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- SAMPLE SCHEMA
-- ============================================
/*
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    enrollment_date DATE,
    major_id INT,
    gpa DECIMAL(3,2),
    status VARCHAR(20)
);

CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    course_code VARCHAR(20),
    course_name VARCHAR(100),
    credits INT,
    department_id INT,
    instructor_id INT
);

CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY,
    student_id INT,
    course_id INT,
    semester VARCHAR(20),
    grade VARCHAR(2),
    grade_points DECIMAL(3,2)
);

CREATE TABLE instructors (
    instructor_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department_id INT,
    hire_date DATE,
    tenure_status VARCHAR(20)
);

CREATE TABLE assignments (
    assignment_id INT PRIMARY KEY,
    course_id INT,
    title VARCHAR(100),
    due_date DATE,
    max_points INT
);

CREATE TABLE submissions (
    submission_id INT PRIMARY KEY,
    assignment_id INT,
    student_id INT,
    submission_date TIMESTAMP,
    score INT,
    feedback TEXT
);
*/

-- ============================================
-- QUESTION 121: Calculate student GPA by semester
-- ============================================
-- Scenario: Academic performance tracking

SELECT 
    s.student_id,
    s.first_name || ' ' || s.last_name AS student_name,
    e.semester,
    SUM(e.grade_points * c.credits) / SUM(c.credits) AS semester_gpa,
    SUM(c.credits) AS credits_attempted
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
JOIN courses c ON e.course_id = c.course_id
WHERE e.grade IS NOT NULL
GROUP BY s.student_id, s.first_name, s.last_name, e.semester
ORDER BY s.student_id, e.semester;

-- ============================================
-- QUESTION 122: Find students at risk of academic probation
-- ============================================
-- Scenario: Early intervention program

WITH semester_gpa AS (
    SELECT 
        s.student_id,
        s.first_name || ' ' || s.last_name AS student_name,
        e.semester,
        SUM(e.grade_points * c.credits) / SUM(c.credits) AS gpa
    FROM students s
    JOIN enrollments e ON s.student_id = e.student_id
    JOIN courses c ON e.course_id = c.course_id
    WHERE e.grade IS NOT NULL
    GROUP BY s.student_id, s.first_name, s.last_name, e.semester
)
SELECT 
    student_id,
    student_name,
    semester,
    gpa,
    LAG(gpa) OVER (PARTITION BY student_id ORDER BY semester) AS prev_semester_gpa,
    CASE 
        WHEN gpa < 2.0 THEN 'PROBATION'
        WHEN gpa < 2.5 AND LAG(gpa) OVER (PARTITION BY student_id ORDER BY semester) < 2.5 THEN 'WARNING'
        ELSE 'GOOD STANDING'
    END AS academic_status
FROM semester_gpa
ORDER BY gpa;

-- ============================================
-- QUESTION 123: Analyze course enrollment trends
-- ============================================
-- Scenario: Curriculum planning and resource allocation

WITH enrollment_counts AS (
    SELECT 
        c.course_id,
        c.course_code,
        c.course_name,
        e.semester,
        COUNT(*) AS enrollment_count
    FROM courses c
    JOIN enrollments e ON c.course_id = e.course_id
    GROUP BY c.course_id, c.course_code, c.course_name, e.semester
)
SELECT 
    course_code,
    course_name,
    semester,
    enrollment_count,
    LAG(enrollment_count) OVER (PARTITION BY course_id ORDER BY semester) AS prev_semester,
    ROUND(100.0 * (enrollment_count - LAG(enrollment_count) OVER (PARTITION BY course_id ORDER BY semester)) / 
          NULLIF(LAG(enrollment_count) OVER (PARTITION BY course_id ORDER BY semester), 0), 2) AS change_pct
FROM enrollment_counts
ORDER BY course_code, semester;

-- ============================================
-- QUESTION 124: Calculate instructor teaching load
-- ============================================
-- Scenario: Workload balancing

SELECT 
    i.instructor_id,
    i.first_name || ' ' || i.last_name AS instructor_name,
    d.department_name,
    COUNT(DISTINCT c.course_id) AS courses_taught,
    SUM(c.credits) AS total_credits,
    COUNT(DISTINCT e.student_id) AS total_students,
    ROUND(AVG(
        SELECT AVG(grade_points) FROM enrollments 
        WHERE course_id = c.course_id AND semester = 'Fall 2024'
    ), 2) AS avg_class_gpa
FROM instructors i
JOIN courses c ON i.instructor_id = c.instructor_id
JOIN departments d ON i.department_id = d.department_id
LEFT JOIN enrollments e ON c.course_id = e.course_id AND e.semester = 'Fall 2024'
GROUP BY i.instructor_id, i.first_name, i.last_name, d.department_name
ORDER BY total_credits DESC;

-- ============================================
-- QUESTION 125: Find prerequisite chain for courses
-- ============================================
-- Scenario: Degree planning assistance

WITH RECURSIVE prereq_chain AS (
    SELECT 
        course_id,
        course_code,
        course_name,
        prerequisite_id,
        1 AS level,
        CAST(course_code AS VARCHAR(500)) AS path
    FROM courses
    WHERE course_id = 301  -- Target course
    
    UNION ALL
    
    SELECT 
        c.course_id,
        c.course_code,
        c.course_name,
        c.prerequisite_id,
        pc.level + 1,
        CAST(c.course_code || ' -> ' || pc.path AS VARCHAR(500))
    FROM courses c
    JOIN prereq_chain pc ON c.course_id = pc.prerequisite_id
    WHERE pc.level < 10
)
SELECT course_code, course_name, level, path
FROM prereq_chain
ORDER BY level DESC;

-- ============================================
-- QUESTION 126: Calculate grade distribution by course
-- ============================================
-- Scenario: Course difficulty analysis

SELECT 
    c.course_code,
    c.course_name,
    i.first_name || ' ' || i.last_name AS instructor,
    COUNT(*) AS total_students,
    ROUND(100.0 * COUNT(CASE WHEN e.grade IN ('A', 'A-') THEN 1 END) / COUNT(*), 1) AS pct_a,
    ROUND(100.0 * COUNT(CASE WHEN e.grade IN ('B+', 'B', 'B-') THEN 1 END) / COUNT(*), 1) AS pct_b,
    ROUND(100.0 * COUNT(CASE WHEN e.grade IN ('C+', 'C', 'C-') THEN 1 END) / COUNT(*), 1) AS pct_c,
    ROUND(100.0 * COUNT(CASE WHEN e.grade IN ('D+', 'D', 'D-') THEN 1 END) / COUNT(*), 1) AS pct_d,
    ROUND(100.0 * COUNT(CASE WHEN e.grade = 'F' THEN 1 END) / COUNT(*), 1) AS pct_f,
    ROUND(AVG(e.grade_points), 2) AS avg_gpa
FROM courses c
JOIN instructors i ON c.instructor_id = i.instructor_id
JOIN enrollments e ON c.course_id = e.course_id
WHERE e.grade IS NOT NULL
GROUP BY c.course_code, c.course_name, i.first_name, i.last_name
ORDER BY avg_gpa;

-- ============================================
-- QUESTION 127: Identify students eligible for honors
-- ============================================
-- Scenario: Academic recognition program

WITH student_stats AS (
    SELECT 
        s.student_id,
        s.first_name || ' ' || s.last_name AS student_name,
        s.major_id,
        SUM(c.credits) AS total_credits,
        SUM(e.grade_points * c.credits) / SUM(c.credits) AS cumulative_gpa
    FROM students s
    JOIN enrollments e ON s.student_id = e.student_id
    JOIN courses c ON e.course_id = c.course_id
    WHERE e.grade IS NOT NULL
    GROUP BY s.student_id, s.first_name, s.last_name, s.major_id
)
SELECT 
    student_id,
    student_name,
    m.major_name,
    total_credits,
    cumulative_gpa,
    CASE 
        WHEN cumulative_gpa >= 3.9 THEN 'Summa Cum Laude'
        WHEN cumulative_gpa >= 3.7 THEN 'Magna Cum Laude'
        WHEN cumulative_gpa >= 3.5 THEN 'Cum Laude'
        ELSE 'No Honors'
    END AS honors_status
FROM student_stats ss
JOIN majors m ON ss.major_id = m.major_id
WHERE total_credits >= 90
ORDER BY cumulative_gpa DESC;

-- ============================================
-- QUESTION 128: Track assignment submission patterns
-- ============================================
-- Scenario: Student engagement analysis

SELECT 
    a.assignment_id,
    a.title,
    c.course_code,
    a.due_date,
    COUNT(sub.submission_id) AS total_submissions,
    COUNT(CASE WHEN sub.submission_date <= a.due_date THEN 1 END) AS on_time,
    COUNT(CASE WHEN sub.submission_date > a.due_date THEN 1 END) AS late,
    ROUND(100.0 * COUNT(CASE WHEN sub.submission_date <= a.due_date THEN 1 END) / 
          NULLIF(COUNT(sub.submission_id), 0), 2) AS on_time_pct,
    ROUND(AVG(sub.score), 2) AS avg_score,
    ROUND(AVG(sub.score)::DECIMAL / a.max_points * 100, 2) AS avg_pct_score
FROM assignments a
JOIN courses c ON a.course_id = c.course_id
LEFT JOIN submissions sub ON a.assignment_id = sub.assignment_id
GROUP BY a.assignment_id, a.title, c.course_code, a.due_date, a.max_points
ORDER BY on_time_pct;

-- ============================================
-- QUESTION 129: Calculate retention rate by cohort
-- ============================================
-- Scenario: Student success metrics

WITH enrollment_cohorts AS (
    SELECT 
        student_id,
        DATE_TRUNC('year', enrollment_date) AS cohort_year
    FROM students
),
yearly_enrollment AS (
    SELECT 
        ec.cohort_year,
        DATE_TRUNC('year', e.semester_start_date) AS academic_year,
        COUNT(DISTINCT e.student_id) AS enrolled_students
    FROM enrollment_cohorts ec
    JOIN enrollments e ON ec.student_id = e.student_id
    GROUP BY ec.cohort_year, DATE_TRUNC('year', e.semester_start_date)
)
SELECT 
    cohort_year,
    academic_year,
    enrolled_students,
    FIRST_VALUE(enrolled_students) OVER (PARTITION BY cohort_year ORDER BY academic_year) AS original_cohort_size,
    ROUND(100.0 * enrolled_students / FIRST_VALUE(enrolled_students) OVER (PARTITION BY cohort_year ORDER BY academic_year), 2) AS retention_rate
FROM yearly_enrollment
ORDER BY cohort_year, academic_year;

-- ============================================
-- QUESTION 130: Find course scheduling conflicts
-- ============================================
-- Scenario: Registration system validation

SELECT 
    s.student_id,
    s.first_name || ' ' || s.last_name AS student_name,
    c1.course_code AS course_1,
    c2.course_code AS course_2,
    cs1.day_of_week,
    cs1.start_time AS course1_start,
    cs1.end_time AS course1_end,
    cs2.start_time AS course2_start,
    cs2.end_time AS course2_end
FROM enrollments e1
JOIN enrollments e2 ON e1.student_id = e2.student_id 
    AND e1.course_id < e2.course_id 
    AND e1.semester = e2.semester
JOIN courses c1 ON e1.course_id = c1.course_id
JOIN courses c2 ON e2.course_id = c2.course_id
JOIN course_schedule cs1 ON c1.course_id = cs1.course_id
JOIN course_schedule cs2 ON c2.course_id = cs2.course_id
JOIN students s ON e1.student_id = s.student_id
WHERE cs1.day_of_week = cs2.day_of_week
AND cs1.start_time < cs2.end_time 
AND cs2.start_time < cs1.end_time;

-- ============================================
-- QUESTION 131: Calculate department performance metrics
-- ============================================
-- Scenario: Academic program review

SELECT 
    d.department_name,
    COUNT(DISTINCT c.course_id) AS courses_offered,
    COUNT(DISTINCT i.instructor_id) AS faculty_count,
    COUNT(DISTINCT e.student_id) AS students_enrolled,
    ROUND(AVG(e.grade_points), 2) AS avg_department_gpa,
    SUM(c.credits * (SELECT COUNT(*) FROM enrollments WHERE course_id = c.course_id)) AS total_credit_hours,
    ROUND(COUNT(DISTINCT e.student_id)::DECIMAL / COUNT(DISTINCT i.instructor_id), 1) AS student_faculty_ratio
FROM departments d
JOIN courses c ON d.department_id = c.department_id
JOIN instructors i ON d.department_id = i.department_id
LEFT JOIN enrollments e ON c.course_id = e.course_id
GROUP BY d.department_name
ORDER BY students_enrolled DESC;

-- ============================================
-- QUESTION 132: Identify students needing advising
-- ============================================
-- Scenario: Academic advising prioritization

WITH student_progress AS (
    SELECT 
        s.student_id,
        s.first_name || ' ' || s.last_name AS student_name,
        s.enrollment_date,
        m.major_name,
        m.required_credits,
        SUM(c.credits) AS completed_credits,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, s.enrollment_date)) AS years_enrolled
    FROM students s
    JOIN majors m ON s.major_id = m.major_id
    LEFT JOIN enrollments e ON s.student_id = e.student_id AND e.grade IS NOT NULL AND e.grade != 'F'
    LEFT JOIN courses c ON e.course_id = c.course_id
    GROUP BY s.student_id, s.first_name, s.last_name, s.enrollment_date, m.major_name, m.required_credits
)
SELECT 
    student_id,
    student_name,
    major_name,
    completed_credits,
    required_credits,
    required_credits - completed_credits AS credits_remaining,
    years_enrolled,
    ROUND(completed_credits::DECIMAL / years_enrolled, 1) AS credits_per_year,
    CASE 
        WHEN completed_credits::DECIMAL / years_enrolled < 25 THEN 'CRITICAL'
        WHEN completed_credits::DECIMAL / years_enrolled < 30 THEN 'BEHIND'
        ELSE 'ON TRACK'
    END AS progress_status
FROM student_progress
WHERE years_enrolled > 0
ORDER BY credits_per_year;

-- ============================================
-- QUESTION 133: Analyze course waitlist patterns
-- ============================================
-- Scenario: Course capacity planning

SELECT 
    c.course_code,
    c.course_name,
    c.max_enrollment,
    COUNT(DISTINCT e.student_id) AS enrolled,
    COUNT(DISTINCT w.student_id) AS waitlisted,
    c.max_enrollment - COUNT(DISTINCT e.student_id) AS available_seats,
    ROUND(100.0 * COUNT(DISTINCT e.student_id) / c.max_enrollment, 2) AS fill_rate,
    AVG(w.waitlist_position) AS avg_waitlist_position
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id AND e.semester = 'Spring 2025'
LEFT JOIN waitlist w ON c.course_id = w.course_id AND w.semester = 'Spring 2025'
GROUP BY c.course_code, c.course_name, c.max_enrollment
HAVING COUNT(DISTINCT w.student_id) > 0
ORDER BY COUNT(DISTINCT w.student_id) DESC;

-- ============================================
-- QUESTION 134: Calculate scholarship eligibility
-- ============================================
-- Scenario: Financial aid processing

WITH student_academics AS (
    SELECT 
        s.student_id,
        s.first_name || ' ' || s.last_name AS student_name,
        SUM(c.credits) AS total_credits,
        SUM(e.grade_points * c.credits) / SUM(c.credits) AS gpa,
        COUNT(DISTINCT e.semester) AS semesters_completed
    FROM students s
    JOIN enrollments e ON s.student_id = e.student_id
    JOIN courses c ON e.course_id = c.course_id
    WHERE e.grade IS NOT NULL
    GROUP BY s.student_id, s.first_name, s.last_name
)
SELECT 
    sa.student_id,
    sa.student_name,
    sa.gpa,
    sa.total_credits,
    sch.scholarship_name,
    sch.amount,
    CASE 
        WHEN sa.gpa >= sch.min_gpa AND sa.total_credits >= sch.min_credits THEN 'ELIGIBLE'
        ELSE 'NOT ELIGIBLE'
    END AS eligibility_status
FROM student_academics sa
CROSS JOIN scholarships sch
WHERE sa.gpa >= sch.min_gpa - 0.2  -- Show near-eligible too
ORDER BY sa.gpa DESC, sch.amount DESC;

-- ============================================
-- QUESTION 135: Track graduation progress
-- ============================================
-- Scenario: Degree audit system

WITH degree_requirements AS (
    SELECT 
        s.student_id,
        s.first_name || ' ' || s.last_name AS student_name,
        m.major_name,
        dr.requirement_type,
        dr.required_credits,
        COALESCE(SUM(CASE WHEN c.category = dr.requirement_type AND e.grade NOT IN ('F', 'W') THEN c.credits ELSE 0 END), 0) AS completed_credits
    FROM students s
    JOIN majors m ON s.major_id = m.major_id
    CROSS JOIN degree_requirements dr
    LEFT JOIN enrollments e ON s.student_id = e.student_id
    LEFT JOIN courses c ON e.course_id = c.course_id
    WHERE dr.major_id = s.major_id
    GROUP BY s.student_id, s.first_name, s.last_name, m.major_name, dr.requirement_type, dr.required_credits
)
SELECT 
    student_id,
    student_name,
    major_name,
    requirement_type,
    completed_credits,
    required_credits,
    GREATEST(required_credits - completed_credits, 0) AS credits_needed,
    ROUND(100.0 * LEAST(completed_credits, required_credits) / required_credits, 2) AS completion_pct
FROM degree_requirements
ORDER BY student_id, requirement_type;

-- ============================================
-- QUESTION 136: Analyze instructor evaluation scores
-- ============================================
-- Scenario: Faculty performance review

SELECT 
    i.instructor_id,
    i.first_name || ' ' || i.last_name AS instructor_name,
    d.department_name,
    COUNT(DISTINCT ev.evaluation_id) AS total_evaluations,
    ROUND(AVG(ev.teaching_quality), 2) AS avg_teaching,
    ROUND(AVG(ev.course_content), 2) AS avg_content,
    ROUND(AVG(ev.communication), 2) AS avg_communication,
    ROUND(AVG(ev.overall_rating), 2) AS avg_overall,
    ROUND(AVG(ev.overall_rating), 2) - AVG(AVG(ev.overall_rating)) OVER (PARTITION BY d.department_id) AS vs_dept_avg
FROM instructors i
JOIN departments d ON i.department_id = d.department_id
JOIN courses c ON i.instructor_id = c.instructor_id
JOIN evaluations ev ON c.course_id = ev.course_id
GROUP BY i.instructor_id, i.first_name, i.last_name, d.department_name, d.department_id
ORDER BY avg_overall DESC;

-- ============================================
-- QUESTION 137: Find popular course combinations
-- ============================================
-- Scenario: Academic pathway analysis

WITH course_pairs AS (
    SELECT 
        e1.course_id AS course_1,
        e2.course_id AS course_2,
        COUNT(DISTINCT e1.student_id) AS students_taking_both
    FROM enrollments e1
    JOIN enrollments e2 ON e1.student_id = e2.student_id 
        AND e1.course_id < e2.course_id
        AND e1.semester = e2.semester
    GROUP BY e1.course_id, e2.course_id
    HAVING COUNT(DISTINCT e1.student_id) >= 10
)
SELECT 
    c1.course_code AS course_1,
    c1.course_name AS course_1_name,
    c2.course_code AS course_2,
    c2.course_name AS course_2_name,
    cp.students_taking_both
FROM course_pairs cp
JOIN courses c1 ON cp.course_1 = c1.course_id
JOIN courses c2 ON cp.course_2 = c2.course_id
ORDER BY students_taking_both DESC
LIMIT 20;

-- ============================================
-- QUESTION 138: Calculate time to graduation
-- ============================================
-- Scenario: Student success metrics

SELECT 
    m.major_name,
    COUNT(*) AS graduates,
    ROUND(AVG(EXTRACT(YEAR FROM AGE(g.graduation_date, s.enrollment_date)) * 12 + 
              EXTRACT(MONTH FROM AGE(g.graduation_date, s.enrollment_date))), 1) AS avg_months_to_graduate,
    MIN(EXTRACT(YEAR FROM AGE(g.graduation_date, s.enrollment_date)) * 12 + 
        EXTRACT(MONTH FROM AGE(g.graduation_date, s.enrollment_date))) AS min_months,
    MAX(EXTRACT(YEAR FROM AGE(g.graduation_date, s.enrollment_date)) * 12 + 
        EXTRACT(MONTH FROM AGE(g.graduation_date, s.enrollment_date))) AS max_months,
    ROUND(100.0 * COUNT(CASE WHEN EXTRACT(YEAR FROM AGE(g.graduation_date, s.enrollment_date)) <= 4 THEN 1 END) / COUNT(*), 2) AS four_year_grad_rate
FROM students s
JOIN majors m ON s.major_id = m.major_id
JOIN graduates g ON s.student_id = g.student_id
GROUP BY m.major_name
ORDER BY avg_months_to_graduate;

-- ============================================
-- QUESTION 139: Identify at-risk first-year students
-- ============================================
-- Scenario: Early alert system

WITH first_year_performance AS (
    SELECT 
        s.student_id,
        s.first_name || ' ' || s.last_name AS student_name,
        COUNT(DISTINCT e.course_id) AS courses_enrolled,
        COUNT(DISTINCT CASE WHEN e.grade IS NOT NULL THEN e.course_id END) AS courses_completed,
        AVG(e.grade_points) AS current_gpa,
        COUNT(CASE WHEN sub.submission_date > a.due_date THEN 1 END) AS late_assignments,
        COUNT(CASE WHEN att.status = 'ABSENT' THEN 1 END) AS absences
    FROM students s
    JOIN enrollments e ON s.student_id = e.student_id
    LEFT JOIN submissions sub ON s.student_id = sub.student_id
    LEFT JOIN assignments a ON sub.assignment_id = a.assignment_id
    LEFT JOIN attendance att ON s.student_id = att.student_id
    WHERE s.enrollment_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY s.student_id, s.first_name, s.last_name
)
SELECT 
    student_id,
    student_name,
    courses_enrolled,
    courses_completed,
    current_gpa,
    late_assignments,
    absences,
    (CASE WHEN current_gpa < 2.0 THEN 3 ELSE 0 END +
     CASE WHEN late_assignments > 5 THEN 2 ELSE 0 END +
     CASE WHEN absences > 10 THEN 2 ELSE 0 END) AS risk_score,
    CASE 
        WHEN current_gpa < 2.0 OR late_assignments > 5 OR absences > 10 THEN 'HIGH RISK'
        WHEN current_gpa < 2.5 OR late_assignments > 3 OR absences > 5 THEN 'MODERATE RISK'
        ELSE 'LOW RISK'
    END AS risk_level
FROM first_year_performance
ORDER BY risk_score DESC;

-- ============================================
-- QUESTION 140: Generate class roster with statistics
-- ============================================
-- Scenario: Instructor dashboard

SELECT 
    c.course_code,
    c.course_name,
    i.first_name || ' ' || i.last_name AS instructor,
    e.semester,
    COUNT(DISTINCT e.student_id) AS enrolled_students,
    ROUND(AVG(s.gpa), 2) AS avg_incoming_gpa,
    COUNT(DISTINCT CASE WHEN s.status = 'FRESHMAN' THEN s.student_id END) AS freshmen,
    COUNT(DISTINCT CASE WHEN s.status = 'SOPHOMORE' THEN s.student_id END) AS sophomores,
    COUNT(DISTINCT CASE WHEN s.status = 'JUNIOR' THEN s.student_id END) AS juniors,
    COUNT(DISTINCT CASE WHEN s.status = 'SENIOR' THEN s.student_id END) AS seniors,
    STRING_AGG(DISTINCT m.major_name, ', ') AS majors_represented
FROM courses c
JOIN instructors i ON c.instructor_id = i.instructor_id
JOIN enrollments e ON c.course_id = e.course_id
JOIN students s ON e.student_id = s.student_id
JOIN majors m ON s.major_id = m.major_id
WHERE e.semester = 'Fall 2024'
GROUP BY c.course_code, c.course_name, i.first_name, i.last_name, e.semester
ORDER BY enrolled_students DESC;
