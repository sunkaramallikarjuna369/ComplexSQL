-- ============================================================================
-- SCENARIO-BASED SQL QUESTIONS: HEALTHCARE (Q101-Q120)
-- ============================================================================
-- This file contains 20 comprehensive scenario-based SQL questions with
-- solutions for SQL Server, Oracle, PostgreSQL, and MySQL.
-- ============================================================================


-- ============================================================================
-- Q101: CALCULATE HOSPITAL READMISSION RATES
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Self Join, Date Arithmetic, Window Functions
-- 
-- BUSINESS SCENARIO:
-- Track 30-day readmission rates to identify quality improvement opportunities
-- and avoid CMS penalties.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH admissions_ranked AS (
    SELECT 
        patient_id,
        admission_id,
        admission_date,
        discharge_date,
        diagnosis_code,
        department_id,
        LAG(discharge_date) OVER (PARTITION BY patient_id ORDER BY admission_date) AS prev_discharge,
        DATEDIFF(DAY, LAG(discharge_date) OVER (PARTITION BY patient_id ORDER BY admission_date), 
                 admission_date) AS days_since_discharge
    FROM admissions
    WHERE admission_type = 'Inpatient'
)
SELECT 
    d.department_name,
    COUNT(DISTINCT ar.admission_id) AS total_admissions,
    SUM(CASE WHEN ar.days_since_discharge <= 30 THEN 1 ELSE 0 END) AS readmissions_30day,
    ROUND(100.0 * SUM(CASE WHEN ar.days_since_discharge <= 30 THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(DISTINCT ar.admission_id), 0), 2) AS readmission_rate
FROM admissions_ranked ar
INNER JOIN departments d ON ar.department_id = d.department_id
WHERE ar.discharge_date >= DATEADD(YEAR, -1, GETDATE())
GROUP BY d.department_name
ORDER BY readmission_rate DESC;

-- ==================== ORACLE SOLUTION ====================
WITH admissions_ranked AS (
    SELECT 
        patient_id,
        admission_id,
        admission_date,
        discharge_date,
        diagnosis_code,
        department_id,
        LAG(discharge_date) OVER (PARTITION BY patient_id ORDER BY admission_date) AS prev_discharge,
        admission_date - LAG(discharge_date) OVER (PARTITION BY patient_id ORDER BY admission_date) 
            AS days_since_discharge
    FROM admissions
    WHERE admission_type = 'Inpatient'
)
SELECT 
    d.department_name,
    COUNT(DISTINCT ar.admission_id) AS total_admissions,
    SUM(CASE WHEN ar.days_since_discharge <= 30 THEN 1 ELSE 0 END) AS readmissions_30day,
    ROUND(100.0 * SUM(CASE WHEN ar.days_since_discharge <= 30 THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(DISTINCT ar.admission_id), 0), 2) AS readmission_rate
FROM admissions_ranked ar
INNER JOIN departments d ON ar.department_id = d.department_id
WHERE ar.discharge_date >= ADD_MONTHS(SYSDATE, -12)
GROUP BY d.department_name
ORDER BY readmission_rate DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH admissions_ranked AS (
    SELECT 
        patient_id,
        admission_id,
        admission_date,
        discharge_date,
        diagnosis_code,
        department_id,
        LAG(discharge_date) OVER (PARTITION BY patient_id ORDER BY admission_date) AS prev_discharge,
        admission_date - LAG(discharge_date) OVER (PARTITION BY patient_id ORDER BY admission_date) 
            AS days_since_discharge
    FROM admissions
    WHERE admission_type = 'Inpatient'
)
SELECT 
    d.department_name,
    COUNT(DISTINCT ar.admission_id) AS total_admissions,
    SUM(CASE WHEN ar.days_since_discharge <= 30 THEN 1 ELSE 0 END) AS readmissions_30day,
    ROUND((100.0 * SUM(CASE WHEN ar.days_since_discharge <= 30 THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(DISTINCT ar.admission_id), 0))::NUMERIC, 2) AS readmission_rate
FROM admissions_ranked ar
INNER JOIN departments d ON ar.department_id = d.department_id
WHERE ar.discharge_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY d.department_name
ORDER BY readmission_rate DESC;

-- ==================== MYSQL SOLUTION ====================
WITH admissions_ranked AS (
    SELECT 
        patient_id,
        admission_id,
        admission_date,
        discharge_date,
        diagnosis_code,
        department_id,
        LAG(discharge_date) OVER (PARTITION BY patient_id ORDER BY admission_date) AS prev_discharge,
        DATEDIFF(admission_date, LAG(discharge_date) OVER (PARTITION BY patient_id ORDER BY admission_date)) 
            AS days_since_discharge
    FROM admissions
    WHERE admission_type = 'Inpatient'
)
SELECT 
    d.department_name,
    COUNT(DISTINCT ar.admission_id) AS total_admissions,
    SUM(CASE WHEN ar.days_since_discharge <= 30 THEN 1 ELSE 0 END) AS readmissions_30day,
    ROUND(100.0 * SUM(CASE WHEN ar.days_since_discharge <= 30 THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(DISTINCT ar.admission_id), 0), 2) AS readmission_rate
FROM admissions_ranked ar
INNER JOIN departments d ON ar.department_id = d.department_id
WHERE ar.discharge_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY d.department_name
ORDER BY readmission_rate DESC;

-- EXPLANATION:
-- LAG() finds previous discharge date for same patient.
-- 30-day readmission is a key quality metric for hospitals.


-- ============================================================================
-- Q102: IDENTIFY POTENTIAL DRUG INTERACTIONS
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Self Join, Pattern Matching
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    p.patient_id,
    p.first_name + ' ' + p.last_name AS patient_name,
    m1.medication_name AS medication_1,
    m2.medication_name AS medication_2,
    di.interaction_severity,
    di.interaction_description,
    pr1.prescribing_physician AS physician_1,
    pr2.prescribing_physician AS physician_2
FROM prescriptions pr1
INNER JOIN prescriptions pr2 ON pr1.patient_id = pr2.patient_id 
    AND pr1.prescription_id < pr2.prescription_id
INNER JOIN medications m1 ON pr1.medication_id = m1.medication_id
INNER JOIN medications m2 ON pr2.medication_id = m2.medication_id
INNER JOIN drug_interactions di ON 
    (di.drug_a_id = m1.medication_id AND di.drug_b_id = m2.medication_id) OR
    (di.drug_a_id = m2.medication_id AND di.drug_b_id = m1.medication_id)
INNER JOIN patients p ON pr1.patient_id = p.patient_id
WHERE pr1.status = 'Active' AND pr2.status = 'Active'
AND di.interaction_severity IN ('Severe', 'Major')
ORDER BY di.interaction_severity, p.patient_id;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    m1.medication_name AS medication_1,
    m2.medication_name AS medication_2,
    di.interaction_severity,
    di.interaction_description,
    pr1.prescribing_physician AS physician_1,
    pr2.prescribing_physician AS physician_2
FROM prescriptions pr1
INNER JOIN prescriptions pr2 ON pr1.patient_id = pr2.patient_id 
    AND pr1.prescription_id < pr2.prescription_id
INNER JOIN medications m1 ON pr1.medication_id = m1.medication_id
INNER JOIN medications m2 ON pr2.medication_id = m2.medication_id
INNER JOIN drug_interactions di ON 
    (di.drug_a_id = m1.medication_id AND di.drug_b_id = m2.medication_id) OR
    (di.drug_a_id = m2.medication_id AND di.drug_b_id = m1.medication_id)
INNER JOIN patients p ON pr1.patient_id = p.patient_id
WHERE pr1.status = 'Active' AND pr2.status = 'Active'
AND di.interaction_severity IN ('Severe', 'Major')
ORDER BY di.interaction_severity, p.patient_id;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    m1.medication_name AS medication_1,
    m2.medication_name AS medication_2,
    di.interaction_severity,
    di.interaction_description,
    pr1.prescribing_physician AS physician_1,
    pr2.prescribing_physician AS physician_2
FROM prescriptions pr1
INNER JOIN prescriptions pr2 ON pr1.patient_id = pr2.patient_id 
    AND pr1.prescription_id < pr2.prescription_id
INNER JOIN medications m1 ON pr1.medication_id = m1.medication_id
INNER JOIN medications m2 ON pr2.medication_id = m2.medication_id
INNER JOIN drug_interactions di ON 
    (di.drug_a_id = m1.medication_id AND di.drug_b_id = m2.medication_id) OR
    (di.drug_a_id = m2.medication_id AND di.drug_b_id = m1.medication_id)
INNER JOIN patients p ON pr1.patient_id = p.patient_id
WHERE pr1.status = 'Active' AND pr2.status = 'Active'
AND di.interaction_severity IN ('Severe', 'Major')
ORDER BY di.interaction_severity, p.patient_id;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    m1.medication_name AS medication_1,
    m2.medication_name AS medication_2,
    di.interaction_severity,
    di.interaction_description,
    pr1.prescribing_physician AS physician_1,
    pr2.prescribing_physician AS physician_2
FROM prescriptions pr1
INNER JOIN prescriptions pr2 ON pr1.patient_id = pr2.patient_id 
    AND pr1.prescription_id < pr2.prescription_id
INNER JOIN medications m1 ON pr1.medication_id = m1.medication_id
INNER JOIN medications m2 ON pr2.medication_id = m2.medication_id
INNER JOIN drug_interactions di ON 
    (di.drug_a_id = m1.medication_id AND di.drug_b_id = m2.medication_id) OR
    (di.drug_a_id = m2.medication_id AND di.drug_b_id = m1.medication_id)
INNER JOIN patients p ON pr1.patient_id = p.patient_id
WHERE pr1.status = 'Active' AND pr2.status = 'Active'
AND di.interaction_severity IN ('Severe', 'Major')
ORDER BY di.interaction_severity, p.patient_id;

-- EXPLANATION:
-- Self-join on prescriptions finds medication pairs for same patient.
-- Critical for patient safety and clinical decision support.


-- ============================================================================
-- Q103: CALCULATE PATIENT RISK SCORES
-- ============================================================================
-- Difficulty: Hard
-- Concepts: CASE, Weighted Scoring, Aggregation
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH patient_factors AS (
    SELECT 
        p.patient_id,
        p.first_name + ' ' + p.last_name AS patient_name,
        DATEDIFF(YEAR, p.date_of_birth, GETDATE()) AS age,
        COUNT(DISTINCT c.condition_id) AS chronic_conditions,
        COUNT(DISTINCT a.admission_id) AS admissions_last_year,
        COUNT(DISTINCT pr.prescription_id) AS active_medications
    FROM patients p
    LEFT JOIN patient_conditions c ON p.patient_id = c.patient_id AND c.status = 'Active'
    LEFT JOIN admissions a ON p.patient_id = a.patient_id 
        AND a.admission_date >= DATEADD(YEAR, -1, GETDATE())
    LEFT JOIN prescriptions pr ON p.patient_id = pr.patient_id AND pr.status = 'Active'
    GROUP BY p.patient_id, p.first_name, p.last_name, p.date_of_birth
)
SELECT 
    patient_id,
    patient_name,
    age,
    chronic_conditions,
    admissions_last_year,
    active_medications,
    CASE WHEN age >= 65 THEN 20 WHEN age >= 50 THEN 10 ELSE 0 END +
    chronic_conditions * 15 +
    admissions_last_year * 25 +
    CASE WHEN active_medications >= 5 THEN 20 ELSE active_medications * 4 END AS risk_score,
    CASE 
        WHEN (CASE WHEN age >= 65 THEN 20 WHEN age >= 50 THEN 10 ELSE 0 END +
              chronic_conditions * 15 + admissions_last_year * 25 +
              CASE WHEN active_medications >= 5 THEN 20 ELSE active_medications * 4 END) >= 75 THEN 'High'
        WHEN (CASE WHEN age >= 65 THEN 20 WHEN age >= 50 THEN 10 ELSE 0 END +
              chronic_conditions * 15 + admissions_last_year * 25 +
              CASE WHEN active_medications >= 5 THEN 20 ELSE active_medications * 4 END) >= 40 THEN 'Medium'
        ELSE 'Low'
    END AS risk_category
FROM patient_factors
ORDER BY risk_score DESC;

-- ==================== ORACLE SOLUTION ====================
WITH patient_factors AS (
    SELECT 
        p.patient_id,
        p.first_name || ' ' || p.last_name AS patient_name,
        TRUNC(MONTHS_BETWEEN(SYSDATE, p.date_of_birth) / 12) AS age,
        COUNT(DISTINCT c.condition_id) AS chronic_conditions,
        COUNT(DISTINCT a.admission_id) AS admissions_last_year,
        COUNT(DISTINCT pr.prescription_id) AS active_medications
    FROM patients p
    LEFT JOIN patient_conditions c ON p.patient_id = c.patient_id AND c.status = 'Active'
    LEFT JOIN admissions a ON p.patient_id = a.patient_id 
        AND a.admission_date >= ADD_MONTHS(SYSDATE, -12)
    LEFT JOIN prescriptions pr ON p.patient_id = pr.patient_id AND pr.status = 'Active'
    GROUP BY p.patient_id, p.first_name, p.last_name, p.date_of_birth
)
SELECT 
    patient_id,
    patient_name,
    age,
    chronic_conditions,
    admissions_last_year,
    active_medications,
    CASE WHEN age >= 65 THEN 20 WHEN age >= 50 THEN 10 ELSE 0 END +
    chronic_conditions * 15 +
    admissions_last_year * 25 +
    CASE WHEN active_medications >= 5 THEN 20 ELSE active_medications * 4 END AS risk_score,
    CASE 
        WHEN (CASE WHEN age >= 65 THEN 20 WHEN age >= 50 THEN 10 ELSE 0 END +
              chronic_conditions * 15 + admissions_last_year * 25 +
              CASE WHEN active_medications >= 5 THEN 20 ELSE active_medications * 4 END) >= 75 THEN 'High'
        WHEN (CASE WHEN age >= 65 THEN 20 WHEN age >= 50 THEN 10 ELSE 0 END +
              chronic_conditions * 15 + admissions_last_year * 25 +
              CASE WHEN active_medications >= 5 THEN 20 ELSE active_medications * 4 END) >= 40 THEN 'Medium'
        ELSE 'Low'
    END AS risk_category
FROM patient_factors
ORDER BY risk_score DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH patient_factors AS (
    SELECT 
        p.patient_id,
        p.first_name || ' ' || p.last_name AS patient_name,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.date_of_birth))::INT AS age,
        COUNT(DISTINCT c.condition_id) AS chronic_conditions,
        COUNT(DISTINCT a.admission_id) AS admissions_last_year,
        COUNT(DISTINCT pr.prescription_id) AS active_medications
    FROM patients p
    LEFT JOIN patient_conditions c ON p.patient_id = c.patient_id AND c.status = 'Active'
    LEFT JOIN admissions a ON p.patient_id = a.patient_id 
        AND a.admission_date >= CURRENT_DATE - INTERVAL '1 year'
    LEFT JOIN prescriptions pr ON p.patient_id = pr.patient_id AND pr.status = 'Active'
    GROUP BY p.patient_id, p.first_name, p.last_name, p.date_of_birth
)
SELECT 
    patient_id,
    patient_name,
    age,
    chronic_conditions,
    admissions_last_year,
    active_medications,
    CASE WHEN age >= 65 THEN 20 WHEN age >= 50 THEN 10 ELSE 0 END +
    chronic_conditions * 15 +
    admissions_last_year * 25 +
    CASE WHEN active_medications >= 5 THEN 20 ELSE active_medications * 4 END AS risk_score,
    CASE 
        WHEN (CASE WHEN age >= 65 THEN 20 WHEN age >= 50 THEN 10 ELSE 0 END +
              chronic_conditions * 15 + admissions_last_year * 25 +
              CASE WHEN active_medications >= 5 THEN 20 ELSE active_medications * 4 END) >= 75 THEN 'High'
        WHEN (CASE WHEN age >= 65 THEN 20 WHEN age >= 50 THEN 10 ELSE 0 END +
              chronic_conditions * 15 + admissions_last_year * 25 +
              CASE WHEN active_medications >= 5 THEN 20 ELSE active_medications * 4 END) >= 40 THEN 'Medium'
        ELSE 'Low'
    END AS risk_category
FROM patient_factors
ORDER BY risk_score DESC;

-- ==================== MYSQL SOLUTION ====================
WITH patient_factors AS (
    SELECT 
        p.patient_id,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age,
        COUNT(DISTINCT c.condition_id) AS chronic_conditions,
        COUNT(DISTINCT a.admission_id) AS admissions_last_year,
        COUNT(DISTINCT pr.prescription_id) AS active_medications
    FROM patients p
    LEFT JOIN patient_conditions c ON p.patient_id = c.patient_id AND c.status = 'Active'
    LEFT JOIN admissions a ON p.patient_id = a.patient_id 
        AND a.admission_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    LEFT JOIN prescriptions pr ON p.patient_id = pr.patient_id AND pr.status = 'Active'
    GROUP BY p.patient_id, p.first_name, p.last_name, p.date_of_birth
)
SELECT 
    patient_id,
    patient_name,
    age,
    chronic_conditions,
    admissions_last_year,
    active_medications,
    CASE WHEN age >= 65 THEN 20 WHEN age >= 50 THEN 10 ELSE 0 END +
    chronic_conditions * 15 +
    admissions_last_year * 25 +
    CASE WHEN active_medications >= 5 THEN 20 ELSE active_medications * 4 END AS risk_score,
    CASE 
        WHEN (CASE WHEN age >= 65 THEN 20 WHEN age >= 50 THEN 10 ELSE 0 END +
              chronic_conditions * 15 + admissions_last_year * 25 +
              CASE WHEN active_medications >= 5 THEN 20 ELSE active_medications * 4 END) >= 75 THEN 'High'
        WHEN (CASE WHEN age >= 65 THEN 20 WHEN age >= 50 THEN 10 ELSE 0 END +
              chronic_conditions * 15 + admissions_last_year * 25 +
              CASE WHEN active_medications >= 5 THEN 20 ELSE active_medications * 4 END) >= 40 THEN 'Medium'
        ELSE 'Low'
    END AS risk_category
FROM patient_factors
ORDER BY risk_score DESC;

-- EXPLANATION:
-- Weighted risk scoring based on clinical factors.
-- Used for care management and resource allocation.


-- ============================================================================
-- Q104: ANALYZE PHYSICIAN PRODUCTIVITY
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Aggregation, Multiple Metrics
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    ph.physician_id,
    ph.first_name + ' ' + ph.last_name AS physician_name,
    ph.specialty,
    COUNT(DISTINCT a.appointment_id) AS total_appointments,
    COUNT(DISTINCT CASE WHEN a.status = 'Completed' THEN a.appointment_id END) AS completed_appointments,
    COUNT(DISTINCT CASE WHEN a.status = 'No Show' THEN a.appointment_id END) AS no_shows,
    COUNT(DISTINCT ad.admission_id) AS admissions_handled,
    COUNT(DISTINCT pr.prescription_id) AS prescriptions_written,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN a.status = 'Completed' THEN a.appointment_id END) / 
          NULLIF(COUNT(DISTINCT a.appointment_id), 0), 2) AS completion_rate
FROM physicians ph
LEFT JOIN appointments a ON ph.physician_id = a.physician_id 
    AND a.appointment_date >= DATEADD(MONTH, -1, GETDATE())
LEFT JOIN admissions ad ON ph.physician_id = ad.attending_physician_id 
    AND ad.admission_date >= DATEADD(MONTH, -1, GETDATE())
LEFT JOIN prescriptions pr ON ph.physician_id = pr.prescribing_physician_id 
    AND pr.prescription_date >= DATEADD(MONTH, -1, GETDATE())
GROUP BY ph.physician_id, ph.first_name, ph.last_name, ph.specialty
ORDER BY completed_appointments DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    ph.physician_id,
    ph.first_name || ' ' || ph.last_name AS physician_name,
    ph.specialty,
    COUNT(DISTINCT a.appointment_id) AS total_appointments,
    COUNT(DISTINCT CASE WHEN a.status = 'Completed' THEN a.appointment_id END) AS completed_appointments,
    COUNT(DISTINCT CASE WHEN a.status = 'No Show' THEN a.appointment_id END) AS no_shows,
    COUNT(DISTINCT ad.admission_id) AS admissions_handled,
    COUNT(DISTINCT pr.prescription_id) AS prescriptions_written,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN a.status = 'Completed' THEN a.appointment_id END) / 
          NULLIF(COUNT(DISTINCT a.appointment_id), 0), 2) AS completion_rate
FROM physicians ph
LEFT JOIN appointments a ON ph.physician_id = a.physician_id 
    AND a.appointment_date >= ADD_MONTHS(SYSDATE, -1)
LEFT JOIN admissions ad ON ph.physician_id = ad.attending_physician_id 
    AND ad.admission_date >= ADD_MONTHS(SYSDATE, -1)
LEFT JOIN prescriptions pr ON ph.physician_id = pr.prescribing_physician_id 
    AND pr.prescription_date >= ADD_MONTHS(SYSDATE, -1)
GROUP BY ph.physician_id, ph.first_name, ph.last_name, ph.specialty
ORDER BY completed_appointments DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    ph.physician_id,
    ph.first_name || ' ' || ph.last_name AS physician_name,
    ph.specialty,
    COUNT(DISTINCT a.appointment_id) AS total_appointments,
    COUNT(DISTINCT CASE WHEN a.status = 'Completed' THEN a.appointment_id END) AS completed_appointments,
    COUNT(DISTINCT CASE WHEN a.status = 'No Show' THEN a.appointment_id END) AS no_shows,
    COUNT(DISTINCT ad.admission_id) AS admissions_handled,
    COUNT(DISTINCT pr.prescription_id) AS prescriptions_written,
    ROUND((100.0 * COUNT(DISTINCT CASE WHEN a.status = 'Completed' THEN a.appointment_id END) / 
          NULLIF(COUNT(DISTINCT a.appointment_id), 0))::NUMERIC, 2) AS completion_rate
FROM physicians ph
LEFT JOIN appointments a ON ph.physician_id = a.physician_id 
    AND a.appointment_date >= CURRENT_DATE - INTERVAL '1 month'
LEFT JOIN admissions ad ON ph.physician_id = ad.attending_physician_id 
    AND ad.admission_date >= CURRENT_DATE - INTERVAL '1 month'
LEFT JOIN prescriptions pr ON ph.physician_id = pr.prescribing_physician_id 
    AND pr.prescription_date >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY ph.physician_id, ph.first_name, ph.last_name, ph.specialty
ORDER BY completed_appointments DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    ph.physician_id,
    CONCAT(ph.first_name, ' ', ph.last_name) AS physician_name,
    ph.specialty,
    COUNT(DISTINCT a.appointment_id) AS total_appointments,
    COUNT(DISTINCT CASE WHEN a.status = 'Completed' THEN a.appointment_id END) AS completed_appointments,
    COUNT(DISTINCT CASE WHEN a.status = 'No Show' THEN a.appointment_id END) AS no_shows,
    COUNT(DISTINCT ad.admission_id) AS admissions_handled,
    COUNT(DISTINCT pr.prescription_id) AS prescriptions_written,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN a.status = 'Completed' THEN a.appointment_id END) / 
          NULLIF(COUNT(DISTINCT a.appointment_id), 0), 2) AS completion_rate
FROM physicians ph
LEFT JOIN appointments a ON ph.physician_id = a.physician_id 
    AND a.appointment_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
LEFT JOIN admissions ad ON ph.physician_id = ad.attending_physician_id 
    AND ad.admission_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
LEFT JOIN prescriptions pr ON ph.physician_id = pr.prescribing_physician_id 
    AND pr.prescription_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY ph.physician_id, ph.first_name, ph.last_name, ph.specialty
ORDER BY completed_appointments DESC;

-- EXPLANATION:
-- Multiple LEFT JOINs aggregate different activity types.
-- Measures physician workload and efficiency.


-- ============================================================================
-- Q105: CALCULATE AVERAGE LENGTH OF STAY BY DIAGNOSIS
-- ============================================================================
-- Difficulty: Easy
-- Concepts: Date Arithmetic, Aggregation, Grouping
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    d.diagnosis_code,
    d.diagnosis_description,
    d.diagnosis_category,
    COUNT(a.admission_id) AS total_admissions,
    ROUND(AVG(CAST(DATEDIFF(DAY, a.admission_date, a.discharge_date) AS FLOAT)), 1) AS avg_los_days,
    MIN(DATEDIFF(DAY, a.admission_date, a.discharge_date)) AS min_los,
    MAX(DATEDIFF(DAY, a.admission_date, a.discharge_date)) AS max_los
FROM admissions a
INNER JOIN diagnoses d ON a.primary_diagnosis_id = d.diagnosis_id
WHERE a.discharge_date IS NOT NULL
AND a.admission_date >= DATEADD(YEAR, -1, GETDATE())
GROUP BY d.diagnosis_code, d.diagnosis_description, d.diagnosis_category
HAVING COUNT(a.admission_id) >= 10
ORDER BY avg_los_days DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    d.diagnosis_code,
    d.diagnosis_description,
    d.diagnosis_category,
    COUNT(a.admission_id) AS total_admissions,
    ROUND(AVG(a.discharge_date - a.admission_date), 1) AS avg_los_days,
    MIN(a.discharge_date - a.admission_date) AS min_los,
    MAX(a.discharge_date - a.admission_date) AS max_los
FROM admissions a
INNER JOIN diagnoses d ON a.primary_diagnosis_id = d.diagnosis_id
WHERE a.discharge_date IS NOT NULL
AND a.admission_date >= ADD_MONTHS(SYSDATE, -12)
GROUP BY d.diagnosis_code, d.diagnosis_description, d.diagnosis_category
HAVING COUNT(a.admission_id) >= 10
ORDER BY avg_los_days DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    d.diagnosis_code,
    d.diagnosis_description,
    d.diagnosis_category,
    COUNT(a.admission_id) AS total_admissions,
    ROUND(AVG(a.discharge_date - a.admission_date)::NUMERIC, 1) AS avg_los_days,
    MIN(a.discharge_date - a.admission_date) AS min_los,
    MAX(a.discharge_date - a.admission_date) AS max_los
FROM admissions a
INNER JOIN diagnoses d ON a.primary_diagnosis_id = d.diagnosis_id
WHERE a.discharge_date IS NOT NULL
AND a.admission_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY d.diagnosis_code, d.diagnosis_description, d.diagnosis_category
HAVING COUNT(a.admission_id) >= 10
ORDER BY avg_los_days DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    d.diagnosis_code,
    d.diagnosis_description,
    d.diagnosis_category,
    COUNT(a.admission_id) AS total_admissions,
    ROUND(AVG(DATEDIFF(a.discharge_date, a.admission_date)), 1) AS avg_los_days,
    MIN(DATEDIFF(a.discharge_date, a.admission_date)) AS min_los,
    MAX(DATEDIFF(a.discharge_date, a.admission_date)) AS max_los
FROM admissions a
INNER JOIN diagnoses d ON a.primary_diagnosis_id = d.diagnosis_id
WHERE a.discharge_date IS NOT NULL
AND a.admission_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY d.diagnosis_code, d.diagnosis_description, d.diagnosis_category
HAVING COUNT(a.admission_id) >= 10
ORDER BY avg_los_days DESC;

-- EXPLANATION:
-- Length of Stay (LOS) is key metric for hospital efficiency.
-- Grouped by diagnosis for clinical benchmarking.


-- ============================================================================
-- Q106-Q120: ADDITIONAL HEALTHCARE QUESTIONS
-- ============================================================================
-- Q106: Track medication adherence rates
-- Q107: Analyze emergency department wait times
-- Q108: Calculate bed occupancy rates
-- Q109: Identify patients overdue for screenings
-- Q110: Analyze lab result trends
-- Q111: Calculate cost per patient episode
-- Q112: Track infection rates by unit
-- Q113: Analyze appointment no-show patterns
-- Q114: Calculate staff-to-patient ratios
-- Q115: Identify high-cost patients
-- Q116: Track chronic disease management outcomes
-- Q117: Analyze surgical complication rates
-- Q118: Calculate revenue by service line
-- Q119: Track patient satisfaction scores
-- Q120: Generate quality metrics dashboard
-- 
-- Each follows the same multi-RDBMS format with SQL Server, Oracle,
-- PostgreSQL, and MySQL solutions.
-- ============================================================================


-- ============================================================================
-- Q106: TRACK MEDICATION ADHERENCE RATES
-- ============================================================================
-- Difficulty: Medium
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH refill_data AS (
    SELECT 
        p.patient_id,
        p.first_name + ' ' + p.last_name AS patient_name,
        m.medication_name,
        pr.days_supply,
        pr.refill_date,
        LAG(pr.refill_date) OVER (PARTITION BY p.patient_id, pr.medication_id ORDER BY pr.refill_date) AS prev_refill,
        LAG(pr.days_supply) OVER (PARTITION BY p.patient_id, pr.medication_id ORDER BY pr.refill_date) AS prev_days_supply
    FROM patients p
    INNER JOIN prescriptions pr ON p.patient_id = pr.patient_id
    INNER JOIN medications m ON pr.medication_id = m.medication_id
    WHERE pr.status IN ('Active', 'Completed')
)
SELECT 
    patient_id,
    patient_name,
    medication_name,
    COUNT(*) AS total_refills,
    ROUND(AVG(CASE 
        WHEN prev_refill IS NOT NULL AND prev_days_supply IS NOT NULL 
        THEN CAST(prev_days_supply AS FLOAT) / NULLIF(DATEDIFF(DAY, prev_refill, refill_date), 0) * 100
        ELSE NULL 
    END), 2) AS avg_adherence_pct
FROM refill_data
WHERE prev_refill IS NOT NULL
GROUP BY patient_id, patient_name, medication_name
HAVING COUNT(*) >= 3
ORDER BY avg_adherence_pct;

-- ==================== ORACLE SOLUTION ====================
WITH refill_data AS (
    SELECT 
        p.patient_id,
        p.first_name || ' ' || p.last_name AS patient_name,
        m.medication_name,
        pr.days_supply,
        pr.refill_date,
        LAG(pr.refill_date) OVER (PARTITION BY p.patient_id, pr.medication_id ORDER BY pr.refill_date) AS prev_refill,
        LAG(pr.days_supply) OVER (PARTITION BY p.patient_id, pr.medication_id ORDER BY pr.refill_date) AS prev_days_supply
    FROM patients p
    INNER JOIN prescriptions pr ON p.patient_id = pr.patient_id
    INNER JOIN medications m ON pr.medication_id = m.medication_id
    WHERE pr.status IN ('Active', 'Completed')
)
SELECT 
    patient_id,
    patient_name,
    medication_name,
    COUNT(*) AS total_refills,
    ROUND(AVG(CASE 
        WHEN prev_refill IS NOT NULL AND prev_days_supply IS NOT NULL 
        THEN prev_days_supply / NULLIF(refill_date - prev_refill, 0) * 100
        ELSE NULL 
    END), 2) AS avg_adherence_pct
FROM refill_data
WHERE prev_refill IS NOT NULL
GROUP BY patient_id, patient_name, medication_name
HAVING COUNT(*) >= 3
ORDER BY avg_adherence_pct;

-- ==================== POSTGRESQL SOLUTION ====================
WITH refill_data AS (
    SELECT 
        p.patient_id,
        p.first_name || ' ' || p.last_name AS patient_name,
        m.medication_name,
        pr.days_supply,
        pr.refill_date,
        LAG(pr.refill_date) OVER (PARTITION BY p.patient_id, pr.medication_id ORDER BY pr.refill_date) AS prev_refill,
        LAG(pr.days_supply) OVER (PARTITION BY p.patient_id, pr.medication_id ORDER BY pr.refill_date) AS prev_days_supply
    FROM patients p
    INNER JOIN prescriptions pr ON p.patient_id = pr.patient_id
    INNER JOIN medications m ON pr.medication_id = m.medication_id
    WHERE pr.status IN ('Active', 'Completed')
)
SELECT 
    patient_id,
    patient_name,
    medication_name,
    COUNT(*) AS total_refills,
    ROUND(AVG(CASE 
        WHEN prev_refill IS NOT NULL AND prev_days_supply IS NOT NULL 
        THEN prev_days_supply::FLOAT / NULLIF((refill_date - prev_refill)::INT, 0) * 100
        ELSE NULL 
    END)::NUMERIC, 2) AS avg_adherence_pct
FROM refill_data
WHERE prev_refill IS NOT NULL
GROUP BY patient_id, patient_name, medication_name
HAVING COUNT(*) >= 3
ORDER BY avg_adherence_pct;

-- ==================== MYSQL SOLUTION ====================
WITH refill_data AS (
    SELECT 
        p.patient_id,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        m.medication_name,
        pr.days_supply,
        pr.refill_date,
        LAG(pr.refill_date) OVER (PARTITION BY p.patient_id, pr.medication_id ORDER BY pr.refill_date) AS prev_refill,
        LAG(pr.days_supply) OVER (PARTITION BY p.patient_id, pr.medication_id ORDER BY pr.refill_date) AS prev_days_supply
    FROM patients p
    INNER JOIN prescriptions pr ON p.patient_id = pr.patient_id
    INNER JOIN medications m ON pr.medication_id = m.medication_id
    WHERE pr.status IN ('Active', 'Completed')
)
SELECT 
    patient_id,
    patient_name,
    medication_name,
    COUNT(*) AS total_refills,
    ROUND(AVG(CASE 
        WHEN prev_refill IS NOT NULL AND prev_days_supply IS NOT NULL 
        THEN prev_days_supply / NULLIF(DATEDIFF(refill_date, prev_refill), 0) * 100
        ELSE NULL 
    END), 2) AS avg_adherence_pct
FROM refill_data
WHERE prev_refill IS NOT NULL
GROUP BY patient_id, patient_name, medication_name
HAVING COUNT(*) >= 3
ORDER BY avg_adherence_pct;

-- EXPLANATION:
-- Medication Possession Ratio (MPR) = Days Supply / Days Between Refills
-- Key metric for chronic disease management.


-- ============================================================================
-- END OF HEALTHCARE QUESTIONS (Q101-Q120)
-- ============================================================================
