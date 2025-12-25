-- ============================================
-- SCENARIO-BASED SQL QUESTIONS
-- Category: Healthcare (Questions 101-120)
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- SAMPLE SCHEMA
-- ============================================
/*
CREATE TABLE patients (
    patient_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    date_of_birth DATE,
    gender VARCHAR(10),
    blood_type VARCHAR(5),
    insurance_id INT,
    registration_date DATE
);

CREATE TABLE doctors (
    doctor_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    specialization VARCHAR(100),
    department_id INT,
    hire_date DATE
);

CREATE TABLE appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT,
    doctor_id INT,
    appointment_date TIMESTAMP,
    status VARCHAR(20),
    type VARCHAR(30),
    notes TEXT
);

CREATE TABLE diagnoses (
    diagnosis_id INT PRIMARY KEY,
    patient_id INT,
    doctor_id INT,
    diagnosis_code VARCHAR(20),
    diagnosis_description VARCHAR(200),
    diagnosis_date DATE,
    severity VARCHAR(20)
);

CREATE TABLE prescriptions (
    prescription_id INT PRIMARY KEY,
    patient_id INT,
    doctor_id INT,
    medication_id INT,
    dosage VARCHAR(50),
    frequency VARCHAR(50),
    start_date DATE,
    end_date DATE
);

CREATE TABLE lab_results (
    result_id INT PRIMARY KEY,
    patient_id INT,
    test_type VARCHAR(100),
    test_date DATE,
    result_value DECIMAL(10,2),
    unit VARCHAR(20),
    reference_min DECIMAL(10,2),
    reference_max DECIMAL(10,2),
    status VARCHAR(20)
);
*/

-- ============================================
-- QUESTION 101: Find patients with multiple chronic conditions
-- ============================================
-- Scenario: Care coordination for complex patients

SELECT 
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    COUNT(DISTINCT d.diagnosis_code) AS condition_count,
    STRING_AGG(DISTINCT d.diagnosis_description, ', ') AS conditions
FROM patients p
JOIN diagnoses d ON p.patient_id = d.patient_id
WHERE d.diagnosis_code IN (
    SELECT diagnosis_code FROM chronic_conditions
)
GROUP BY p.patient_id, p.first_name, p.last_name
HAVING COUNT(DISTINCT d.diagnosis_code) >= 3
ORDER BY condition_count DESC;

-- ============================================
-- QUESTION 102: Calculate patient readmission rate
-- ============================================
-- Scenario: Quality metric for hospital performance

WITH admissions AS (
    SELECT 
        patient_id,
        admission_date,
        discharge_date,
        LEAD(admission_date) OVER (PARTITION BY patient_id ORDER BY admission_date) AS next_admission
    FROM hospital_admissions
    WHERE discharge_date IS NOT NULL
)
SELECT 
    DATE_TRUNC('month', discharge_date) AS month,
    COUNT(*) AS total_discharges,
    COUNT(CASE WHEN next_admission <= discharge_date + INTERVAL '30 days' THEN 1 END) AS readmissions_30d,
    ROUND(100.0 * COUNT(CASE WHEN next_admission <= discharge_date + INTERVAL '30 days' THEN 1 END) / COUNT(*), 2) AS readmission_rate_pct
FROM admissions
GROUP BY DATE_TRUNC('month', discharge_date)
ORDER BY month;

-- ============================================
-- QUESTION 103: Identify patients overdue for checkups
-- ============================================
-- Scenario: Preventive care outreach

SELECT 
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.date_of_birth,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.date_of_birth)) AS age,
    MAX(a.appointment_date) AS last_visit,
    CURRENT_DATE - MAX(a.appointment_date)::DATE AS days_since_visit
FROM patients p
LEFT JOIN appointments a ON p.patient_id = a.patient_id AND a.status = 'COMPLETED'
GROUP BY p.patient_id, p.first_name, p.last_name, p.date_of_birth
HAVING MAX(a.appointment_date) < CURRENT_DATE - INTERVAL '1 year'
    OR MAX(a.appointment_date) IS NULL
ORDER BY days_since_visit DESC NULLS FIRST;

-- ============================================
-- QUESTION 104: Calculate doctor utilization rate
-- ============================================
-- Scenario: Resource planning and scheduling optimization

WITH doctor_slots AS (
    SELECT 
        doctor_id,
        DATE(appointment_date) AS work_date,
        COUNT(*) AS scheduled_appointments,
        COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) AS completed_appointments,
        COUNT(CASE WHEN status = 'NO_SHOW' THEN 1 END) AS no_shows
    FROM appointments
    WHERE appointment_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY doctor_id, DATE(appointment_date)
)
SELECT 
    d.doctor_id,
    d.first_name || ' ' || d.last_name AS doctor_name,
    d.specialization,
    SUM(ds.scheduled_appointments) AS total_scheduled,
    SUM(ds.completed_appointments) AS total_completed,
    SUM(ds.no_shows) AS total_no_shows,
    ROUND(100.0 * SUM(ds.completed_appointments) / NULLIF(SUM(ds.scheduled_appointments), 0), 2) AS utilization_rate,
    ROUND(100.0 * SUM(ds.no_shows) / NULLIF(SUM(ds.scheduled_appointments), 0), 2) AS no_show_rate
FROM doctors d
JOIN doctor_slots ds ON d.doctor_id = ds.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name, d.specialization
ORDER BY utilization_rate DESC;

-- ============================================
-- QUESTION 105: Find abnormal lab results requiring follow-up
-- ============================================
-- Scenario: Critical value alerts

SELECT 
    lr.result_id,
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    lr.test_type,
    lr.test_date,
    lr.result_value,
    lr.unit,
    lr.reference_min,
    lr.reference_max,
    CASE 
        WHEN lr.result_value < lr.reference_min THEN 'LOW'
        WHEN lr.result_value > lr.reference_max THEN 'HIGH'
        ELSE 'NORMAL'
    END AS status,
    ABS(lr.result_value - (lr.reference_min + lr.reference_max) / 2) / 
        ((lr.reference_max - lr.reference_min) / 2) AS deviation_factor
FROM lab_results lr
JOIN patients p ON lr.patient_id = p.patient_id
WHERE lr.result_value < lr.reference_min OR lr.result_value > lr.reference_max
ORDER BY deviation_factor DESC;

-- ============================================
-- QUESTION 106: Calculate medication adherence rate
-- ============================================
-- Scenario: Patient compliance monitoring

WITH prescription_days AS (
    SELECT 
        patient_id,
        medication_id,
        start_date,
        end_date,
        end_date - start_date AS prescribed_days
    FROM prescriptions
    WHERE end_date IS NOT NULL
),
refill_data AS (
    SELECT 
        patient_id,
        medication_id,
        COUNT(*) AS refill_count,
        SUM(quantity) AS total_dispensed
    FROM pharmacy_refills
    GROUP BY patient_id, medication_id
)
SELECT 
    p.patient_id,
    pt.first_name || ' ' || pt.last_name AS patient_name,
    m.medication_name,
    pd.prescribed_days,
    COALESCE(rd.total_dispensed, 0) AS days_supply_dispensed,
    ROUND(100.0 * COALESCE(rd.total_dispensed, 0) / NULLIF(pd.prescribed_days, 0), 2) AS adherence_rate
FROM prescription_days pd
JOIN patients pt ON pd.patient_id = pt.patient_id
JOIN medications m ON pd.medication_id = m.medication_id
LEFT JOIN refill_data rd ON pd.patient_id = rd.patient_id AND pd.medication_id = rd.medication_id
WHERE pd.prescribed_days > 30
ORDER BY adherence_rate;

-- ============================================
-- QUESTION 107: Identify high-risk patients for intervention
-- ============================================
-- Scenario: Population health management

WITH patient_risk AS (
    SELECT 
        p.patient_id,
        p.first_name || ' ' || p.last_name AS patient_name,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.date_of_birth)) AS age,
        COUNT(DISTINCT d.diagnosis_code) AS diagnosis_count,
        COUNT(DISTINCT pr.prescription_id) AS medication_count,
        COUNT(DISTINCT CASE WHEN a.status = 'NO_SHOW' THEN a.appointment_id END) AS missed_appointments,
        COUNT(DISTINCT CASE WHEN lr.status = 'ABNORMAL' THEN lr.result_id END) AS abnormal_labs
    FROM patients p
    LEFT JOIN diagnoses d ON p.patient_id = d.patient_id
    LEFT JOIN prescriptions pr ON p.patient_id = pr.patient_id
    LEFT JOIN appointments a ON p.patient_id = a.patient_id
    LEFT JOIN lab_results lr ON p.patient_id = lr.patient_id
    GROUP BY p.patient_id, p.first_name, p.last_name, p.date_of_birth
)
SELECT 
    patient_id,
    patient_name,
    age,
    diagnosis_count,
    medication_count,
    missed_appointments,
    abnormal_labs,
    -- Simple risk score calculation
    (CASE WHEN age > 65 THEN 2 ELSE 0 END +
     CASE WHEN diagnosis_count > 5 THEN 3 ELSE diagnosis_count * 0.5 END +
     CASE WHEN medication_count > 5 THEN 2 ELSE 0 END +
     missed_appointments +
     abnormal_labs * 0.5) AS risk_score
FROM patient_risk
ORDER BY risk_score DESC
LIMIT 100;

-- ============================================
-- QUESTION 108: Calculate average wait time by department
-- ============================================
-- Scenario: Patient experience improvement

SELECT 
    dept.department_name,
    COUNT(a.appointment_id) AS total_appointments,
    AVG(EXTRACT(EPOCH FROM (a.actual_start_time - a.appointment_date)) / 60) AS avg_wait_minutes,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (a.actual_start_time - a.appointment_date)) / 60) AS median_wait_minutes,
    MAX(EXTRACT(EPOCH FROM (a.actual_start_time - a.appointment_date)) / 60) AS max_wait_minutes
FROM appointments a
JOIN doctors d ON a.doctor_id = d.doctor_id
JOIN departments dept ON d.department_id = dept.department_id
WHERE a.status = 'COMPLETED'
AND a.actual_start_time IS NOT NULL
AND a.appointment_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY dept.department_name
ORDER BY avg_wait_minutes DESC;

-- ============================================
-- QUESTION 109: Find drug interactions in patient prescriptions
-- ============================================
-- Scenario: Medication safety alert

SELECT 
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    m1.medication_name AS medication_1,
    m2.medication_name AS medication_2,
    di.interaction_severity,
    di.interaction_description
FROM prescriptions pr1
JOIN prescriptions pr2 ON pr1.patient_id = pr2.patient_id 
    AND pr1.medication_id < pr2.medication_id
    AND pr1.end_date >= pr2.start_date 
    AND pr1.start_date <= pr2.end_date
JOIN drug_interactions di ON 
    (di.drug_1_id = pr1.medication_id AND di.drug_2_id = pr2.medication_id)
    OR (di.drug_1_id = pr2.medication_id AND di.drug_2_id = pr1.medication_id)
JOIN patients p ON pr1.patient_id = p.patient_id
JOIN medications m1 ON pr1.medication_id = m1.medication_id
JOIN medications m2 ON pr2.medication_id = m2.medication_id
WHERE di.interaction_severity IN ('SEVERE', 'MAJOR')
ORDER BY di.interaction_severity, p.patient_id;

-- ============================================
-- QUESTION 110: Calculate diagnosis trends over time
-- ============================================
-- Scenario: Epidemiological analysis

WITH monthly_diagnoses AS (
    SELECT 
        DATE_TRUNC('month', diagnosis_date) AS month,
        diagnosis_code,
        diagnosis_description,
        COUNT(*) AS diagnosis_count
    FROM diagnoses
    WHERE diagnosis_date >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY DATE_TRUNC('month', diagnosis_date), diagnosis_code, diagnosis_description
)
SELECT 
    month,
    diagnosis_code,
    diagnosis_description,
    diagnosis_count,
    LAG(diagnosis_count) OVER (PARTITION BY diagnosis_code ORDER BY month) AS prev_month_count,
    ROUND(100.0 * (diagnosis_count - LAG(diagnosis_count) OVER (PARTITION BY diagnosis_code ORDER BY month)) / 
          NULLIF(LAG(diagnosis_count) OVER (PARTITION BY diagnosis_code ORDER BY month), 0), 2) AS mom_change_pct,
    AVG(diagnosis_count) OVER (PARTITION BY diagnosis_code ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3m
FROM monthly_diagnoses
ORDER BY diagnosis_code, month;

-- ============================================
-- QUESTION 111: Find patients with gaps in care
-- ============================================
-- Scenario: Care continuity monitoring

WITH patient_visits AS (
    SELECT 
        patient_id,
        appointment_date,
        LAG(appointment_date) OVER (PARTITION BY patient_id ORDER BY appointment_date) AS prev_visit,
        appointment_date - LAG(appointment_date) OVER (PARTITION BY patient_id ORDER BY appointment_date) AS days_between
    FROM appointments
    WHERE status = 'COMPLETED'
)
SELECT 
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    pv.prev_visit,
    pv.appointment_date AS current_visit,
    pv.days_between,
    d.diagnosis_description AS primary_condition
FROM patient_visits pv
JOIN patients p ON pv.patient_id = p.patient_id
LEFT JOIN diagnoses d ON p.patient_id = d.patient_id
WHERE pv.days_between > 180
ORDER BY pv.days_between DESC;

-- ============================================
-- QUESTION 112: Calculate insurance claim statistics
-- ============================================
-- Scenario: Revenue cycle management

SELECT 
    i.insurance_name,
    COUNT(c.claim_id) AS total_claims,
    SUM(c.billed_amount) AS total_billed,
    SUM(c.paid_amount) AS total_paid,
    SUM(c.billed_amount - c.paid_amount) AS total_adjustments,
    ROUND(100.0 * SUM(c.paid_amount) / NULLIF(SUM(c.billed_amount), 0), 2) AS collection_rate,
    AVG(c.payment_date - c.submission_date) AS avg_days_to_payment,
    COUNT(CASE WHEN c.status = 'DENIED' THEN 1 END) AS denied_claims,
    ROUND(100.0 * COUNT(CASE WHEN c.status = 'DENIED' THEN 1 END) / COUNT(*), 2) AS denial_rate
FROM claims c
JOIN insurance i ON c.insurance_id = i.insurance_id
WHERE c.submission_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY i.insurance_name
ORDER BY total_billed DESC;

-- ============================================
-- QUESTION 113: Identify patients needing vaccinations
-- ============================================
-- Scenario: Immunization compliance tracking

WITH vaccination_schedule AS (
    SELECT 
        p.patient_id,
        p.first_name || ' ' || p.last_name AS patient_name,
        p.date_of_birth,
        v.vaccine_name,
        v.recommended_age_months,
        v.booster_interval_months
    FROM patients p
    CROSS JOIN vaccines v
    WHERE v.is_required = TRUE
),
vaccination_history AS (
    SELECT 
        patient_id,
        vaccine_id,
        MAX(vaccination_date) AS last_vaccination
    FROM patient_vaccinations
    GROUP BY patient_id, vaccine_id
)
SELECT 
    vs.patient_id,
    vs.patient_name,
    vs.vaccine_name,
    vh.last_vaccination,
    CASE 
        WHEN vh.last_vaccination IS NULL THEN 'NEVER VACCINATED'
        WHEN vh.last_vaccination + (vs.booster_interval_months || ' months')::INTERVAL < CURRENT_DATE THEN 'OVERDUE'
        ELSE 'UP TO DATE'
    END AS vaccination_status
FROM vaccination_schedule vs
LEFT JOIN vaccination_history vh ON vs.patient_id = vh.patient_id
WHERE vh.last_vaccination IS NULL 
   OR vh.last_vaccination + (vs.booster_interval_months || ' months')::INTERVAL < CURRENT_DATE
ORDER BY vs.patient_id, vs.vaccine_name;

-- ============================================
-- QUESTION 114: Calculate bed occupancy rate
-- ============================================
-- Scenario: Hospital capacity planning

WITH daily_census AS (
    SELECT 
        d.date AS census_date,
        dept.department_name,
        COUNT(DISTINCT CASE 
            WHEN ha.admission_date <= d.date AND (ha.discharge_date IS NULL OR ha.discharge_date >= d.date) 
            THEN ha.admission_id 
        END) AS occupied_beds
    FROM generate_series(CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE, '1 day') d(date)
    CROSS JOIN departments dept
    LEFT JOIN hospital_admissions ha ON ha.department_id = dept.department_id
    GROUP BY d.date, dept.department_name, dept.bed_capacity
)
SELECT 
    department_name,
    AVG(occupied_beds) AS avg_daily_census,
    MAX(occupied_beds) AS peak_census,
    MIN(occupied_beds) AS min_census,
    ROUND(100.0 * AVG(occupied_beds) / bed_capacity, 2) AS avg_occupancy_rate
FROM daily_census dc
JOIN departments d ON dc.department_name = d.department_name
GROUP BY department_name, bed_capacity
ORDER BY avg_occupancy_rate DESC;

-- ============================================
-- QUESTION 115: Find patients with similar conditions for clinical trials
-- ============================================
-- Scenario: Research patient recruitment

SELECT 
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.date_of_birth,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.date_of_birth)) AS age,
    p.gender,
    STRING_AGG(DISTINCT d.diagnosis_code, ', ') AS diagnosis_codes,
    COUNT(DISTINCT d.diagnosis_code) AS condition_count
FROM patients p
JOIN diagnoses d ON p.patient_id = d.patient_id
WHERE d.diagnosis_code IN ('E11', 'E11.9')  -- Type 2 Diabetes
AND EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.date_of_birth)) BETWEEN 40 AND 65
AND NOT EXISTS (
    SELECT 1 FROM diagnoses d2 
    WHERE d2.patient_id = p.patient_id 
    AND d2.diagnosis_code IN ('C00-C97')  -- Exclude cancer patients
)
GROUP BY p.patient_id, p.first_name, p.last_name, p.date_of_birth, p.gender
ORDER BY condition_count;

-- ============================================
-- QUESTION 116: Calculate procedure success rates
-- ============================================
-- Scenario: Quality assurance and surgeon performance

SELECT 
    d.doctor_id,
    d.first_name || ' ' || d.last_name AS surgeon_name,
    proc.procedure_name,
    COUNT(*) AS total_procedures,
    COUNT(CASE WHEN p.outcome = 'SUCCESS' THEN 1 END) AS successful,
    COUNT(CASE WHEN p.outcome = 'COMPLICATION' THEN 1 END) AS complications,
    ROUND(100.0 * COUNT(CASE WHEN p.outcome = 'SUCCESS' THEN 1 END) / COUNT(*), 2) AS success_rate,
    AVG(p.procedure_duration_minutes) AS avg_duration
FROM procedures p
JOIN doctors d ON p.surgeon_id = d.doctor_id
JOIN procedure_types proc ON p.procedure_type_id = proc.procedure_type_id
WHERE p.procedure_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY d.doctor_id, d.first_name, d.last_name, proc.procedure_name
HAVING COUNT(*) >= 10
ORDER BY success_rate DESC;

-- ============================================
-- QUESTION 117: Analyze emergency department patterns
-- ============================================
-- Scenario: Staffing optimization

SELECT 
    EXTRACT(DOW FROM arrival_time) AS day_of_week,
    EXTRACT(HOUR FROM arrival_time) AS hour_of_day,
    COUNT(*) AS visit_count,
    AVG(EXTRACT(EPOCH FROM (discharge_time - arrival_time)) / 60) AS avg_los_minutes,
    COUNT(CASE WHEN triage_level = 1 THEN 1 END) AS critical_cases,
    COUNT(CASE WHEN disposition = 'ADMITTED' THEN 1 END) AS admissions
FROM ed_visits
WHERE arrival_time >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY EXTRACT(DOW FROM arrival_time), EXTRACT(HOUR FROM arrival_time)
ORDER BY day_of_week, hour_of_day;

-- ============================================
-- QUESTION 118: Calculate cost per patient by diagnosis
-- ============================================
-- Scenario: Financial analysis and budgeting

SELECT 
    d.diagnosis_code,
    d.diagnosis_description,
    COUNT(DISTINCT d.patient_id) AS patient_count,
    SUM(c.total_charges) AS total_charges,
    AVG(c.total_charges) AS avg_cost_per_patient,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY c.total_charges) AS median_cost,
    MIN(c.total_charges) AS min_cost,
    MAX(c.total_charges) AS max_cost
FROM diagnoses d
JOIN patient_charges c ON d.patient_id = c.patient_id 
    AND d.diagnosis_date BETWEEN c.service_date_start AND c.service_date_end
GROUP BY d.diagnosis_code, d.diagnosis_description
HAVING COUNT(DISTINCT d.patient_id) >= 10
ORDER BY avg_cost_per_patient DESC;

-- ============================================
-- QUESTION 119: Find duplicate patient records
-- ============================================
-- Scenario: Data quality and master patient index

SELECT 
    p1.patient_id AS patient_id_1,
    p2.patient_id AS patient_id_2,
    p1.first_name,
    p1.last_name,
    p1.date_of_birth,
    p1.gender,
    CASE 
        WHEN p1.first_name = p2.first_name AND p1.last_name = p2.last_name AND p1.date_of_birth = p2.date_of_birth THEN 'EXACT MATCH'
        WHEN SOUNDEX(p1.last_name) = SOUNDEX(p2.last_name) AND p1.date_of_birth = p2.date_of_birth THEN 'PROBABLE MATCH'
        ELSE 'POSSIBLE MATCH'
    END AS match_type
FROM patients p1
JOIN patients p2 ON p1.patient_id < p2.patient_id
WHERE (p1.first_name = p2.first_name AND p1.last_name = p2.last_name AND p1.date_of_birth = p2.date_of_birth)
   OR (SOUNDEX(p1.last_name) = SOUNDEX(p2.last_name) AND p1.date_of_birth = p2.date_of_birth)
   OR (p1.first_name = p2.first_name AND p1.last_name = p2.last_name AND ABS(p1.date_of_birth - p2.date_of_birth) <= 1)
ORDER BY match_type, p1.last_name;

-- ============================================
-- QUESTION 120: Generate patient health summary
-- ============================================
-- Scenario: Comprehensive patient overview for care team

SELECT 
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.date_of_birth)) AS age,
    p.gender,
    p.blood_type,
    (SELECT STRING_AGG(DISTINCT diagnosis_description, '; ') 
     FROM diagnoses WHERE patient_id = p.patient_id) AS active_conditions,
    (SELECT COUNT(*) FROM prescriptions 
     WHERE patient_id = p.patient_id AND end_date >= CURRENT_DATE) AS active_medications,
    (SELECT MAX(appointment_date) FROM appointments 
     WHERE patient_id = p.patient_id AND status = 'COMPLETED') AS last_visit,
    (SELECT COUNT(*) FROM appointments 
     WHERE patient_id = p.patient_id AND status = 'NO_SHOW') AS missed_appointments,
    (SELECT COUNT(*) FROM lab_results 
     WHERE patient_id = p.patient_id AND status = 'ABNORMAL' 
     AND test_date >= CURRENT_DATE - INTERVAL '90 days') AS recent_abnormal_labs
FROM patients p
ORDER BY p.last_name, p.first_name;
