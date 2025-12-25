-- ============================================
-- EMPLOYEE MANAGEMENT DOMAIN
-- Database Schema and Sample Data
-- Compatible with: SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- TABLE DEFINITIONS
-- ============================================

-- DEPARTMENTS TABLE
-- Stores organizational department information
CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    manager_id INT,
    location_id INT,
    budget DECIMAL(15,2),
    created_date DATE
);

-- JOBS TABLE
-- Stores job position definitions with salary ranges
CREATE TABLE jobs (
    job_id VARCHAR(20) PRIMARY KEY,
    job_title VARCHAR(100) NOT NULL,
    min_salary DECIMAL(10,2),
    max_salary DECIMAL(10,2),
    job_category VARCHAR(50)
);

-- EMPLOYEES TABLE
-- Core employee information
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    job_id VARCHAR(20) REFERENCES jobs(job_id),
    salary DECIMAL(10,2),
    commission_pct DECIMAL(4,2),
    manager_id INT REFERENCES employees(employee_id),
    department_id INT REFERENCES departments(department_id),
    status VARCHAR(20) DEFAULT 'ACTIVE'
);

-- JOB_HISTORY TABLE
-- Tracks employee job changes over time
CREATE TABLE job_history (
    employee_id INT REFERENCES employees(employee_id),
    start_date DATE NOT NULL,
    end_date DATE,
    job_id VARCHAR(20) REFERENCES jobs(job_id),
    department_id INT REFERENCES departments(department_id),
    reason VARCHAR(100),
    PRIMARY KEY (employee_id, start_date)
);

-- ============================================
-- SAMPLE DATA - DEPARTMENTS
-- ============================================
INSERT INTO departments VALUES (10, 'Executive', NULL, 1, 500000.00, '2020-01-01');
INSERT INTO departments VALUES (20, 'IT', 201, 1, 800000.00, '2020-01-01');
INSERT INTO departments VALUES (30, 'Sales', 301, 2, 1200000.00, '2020-01-01');
INSERT INTO departments VALUES (40, 'Marketing', 401, 2, 600000.00, '2020-01-01');
INSERT INTO departments VALUES (50, 'HR', 501, 1, 400000.00, '2020-01-01');
INSERT INTO departments VALUES (60, 'Finance', 601, 1, 700000.00, '2020-01-01');
INSERT INTO departments VALUES (70, 'Operations', NULL, 3, 900000.00, '2020-06-01');
INSERT INTO departments VALUES (80, 'Research', NULL, 3, 550000.00, '2021-01-01');

-- ============================================
-- SAMPLE DATA - JOBS
-- ============================================
INSERT INTO jobs VALUES ('CEO', 'Chief Executive Officer', 200000, 400000, 'Executive');
INSERT INTO jobs VALUES ('VP', 'Vice President', 150000, 250000, 'Executive');
INSERT INTO jobs VALUES ('MGR', 'Manager', 80000, 150000, 'Management');
INSERT INTO jobs VALUES ('SR_DEV', 'Senior Developer', 90000, 140000, 'Technical');
INSERT INTO jobs VALUES ('DEV', 'Developer', 60000, 100000, 'Technical');
INSERT INTO jobs VALUES ('JR_DEV', 'Junior Developer', 45000, 70000, 'Technical');
INSERT INTO jobs VALUES ('SR_SALES', 'Senior Sales Representative', 70000, 120000, 'Sales');
INSERT INTO jobs VALUES ('SALES', 'Sales Representative', 50000, 90000, 'Sales');
INSERT INTO jobs VALUES ('ANALYST', 'Business Analyst', 65000, 110000, 'Analysis');
INSERT INTO jobs VALUES ('HR_MGR', 'HR Manager', 75000, 120000, 'HR');
INSERT INTO jobs VALUES ('HR_REP', 'HR Representative', 45000, 75000, 'HR');
INSERT INTO jobs VALUES ('FIN_MGR', 'Finance Manager', 85000, 140000, 'Finance');
INSERT INTO jobs VALUES ('ACCT', 'Accountant', 55000, 90000, 'Finance');

-- ============================================
-- SAMPLE DATA - EMPLOYEES
-- ============================================
-- Executive Level
INSERT INTO employees VALUES (100, 'Steven', 'King', 'sking@company.com', '515-123-4567', '2015-06-17', 'CEO', 350000, NULL, NULL, 10, 'ACTIVE');
INSERT INTO employees VALUES (101, 'Neena', 'Kochhar', 'nkochhar@company.com', '515-123-4568', '2016-09-21', 'VP', 200000, NULL, 100, 10, 'ACTIVE');
INSERT INTO employees VALUES (102, 'Lex', 'De Haan', 'ldehaan@company.com', '515-123-4569', '2016-01-13', 'VP', 195000, NULL, 100, 10, 'ACTIVE');

-- IT Department
INSERT INTO employees VALUES (201, 'Alexander', 'Hunold', 'ahunold@company.com', '590-423-4567', '2018-01-03', 'MGR', 120000, NULL, 102, 20, 'ACTIVE');
INSERT INTO employees VALUES (202, 'Bruce', 'Ernst', 'bernst@company.com', '590-423-4568', '2019-05-21', 'SR_DEV', 110000, NULL, 201, 20, 'ACTIVE');
INSERT INTO employees VALUES (203, 'David', 'Austin', 'daustin@company.com', '590-423-4569', '2020-06-25', 'DEV', 75000, NULL, 201, 20, 'ACTIVE');
INSERT INTO employees VALUES (204, 'Valli', 'Pataballa', 'vpataballa@company.com', '590-423-4560', '2021-02-05', 'DEV', 72000, NULL, 201, 20, 'ACTIVE');
INSERT INTO employees VALUES (205, 'Diana', 'Lorentz', 'dlorentz@company.com', '590-423-5567', '2023-02-07', 'JR_DEV', 52000, NULL, 202, 20, 'ACTIVE');
INSERT INTO employees VALUES (206, 'Kevin', 'Mourgos', 'kmourgos@company.com', '590-423-5568', '2024-08-15', 'JR_DEV', 48000, NULL, 202, 20, 'ACTIVE');
INSERT INTO employees VALUES (207, 'Sarah', 'Bell', 'sbell@company.com', '590-423-5569', '2025-10-01', 'JR_DEV', 46000, NULL, 202, 20, 'ACTIVE');

-- Sales Department
INSERT INTO employees VALUES (301, 'Alberto', 'Errazuriz', 'aerrazuriz@company.com', '590-423-5570', '2017-03-10', 'MGR', 130000, 0.10, 101, 30, 'ACTIVE');
INSERT INTO employees VALUES (302, 'Gerald', 'Cambrault', 'gcambrault@company.com', '590-423-5571', '2018-10-15', 'SR_SALES', 95000, 0.15, 301, 30, 'ACTIVE');
INSERT INTO employees VALUES (303, 'Eleni', 'Zlotkey', 'ezlotkey@company.com', '590-423-5572', '2019-01-29', 'SR_SALES', 92000, 0.12, 301, 30, 'ACTIVE');
INSERT INTO employees VALUES (304, 'Peter', 'Tucker', 'ptucker@company.com', '590-423-5573', '2020-01-30', 'SALES', 70000, 0.10, 302, 30, 'ACTIVE');
INSERT INTO employees VALUES (305, 'David', 'Bernstein', 'dbernstein@company.com', '590-423-5574', '2021-03-24', 'SALES', 68000, 0.08, 302, 30, 'ACTIVE');
INSERT INTO employees VALUES (306, 'Peter', 'Hall', 'phall@company.com', '590-423-5575', '2022-08-20', 'SALES', 65000, 0.08, 303, 30, 'ACTIVE');
INSERT INTO employees VALUES (307, 'Christopher', 'Olsen', 'colsen@company.com', '590-423-5576', '2025-11-15', 'SALES', 55000, NULL, 303, 30, 'ACTIVE');

-- Marketing Department
INSERT INTO employees VALUES (401, 'Michael', 'Hartstein', 'mhartstein@company.com', '515-123-5555', '2017-02-17', 'MGR', 115000, NULL, 101, 40, 'ACTIVE');
INSERT INTO employees VALUES (402, 'Pat', 'Fay', 'pfay@company.com', '603-123-6666', '2019-08-17', 'ANALYST', 85000, NULL, 401, 40, 'ACTIVE');
INSERT INTO employees VALUES (403, 'Jennifer', 'Whalen', 'jwhalen@company.com', '515-123-4444', '2020-09-17', 'ANALYST', 78000, NULL, 401, 40, 'ACTIVE');

-- HR Department
INSERT INTO employees VALUES (501, 'Susan', 'Mavris', 'smavris@company.com', '515-123-7777', '2018-06-07', 'HR_MGR', 95000, NULL, 101, 50, 'ACTIVE');
INSERT INTO employees VALUES (502, 'Hermann', 'Baer', 'hbaer@company.com', '515-123-8888', '2020-06-07', 'HR_REP', 58000, NULL, 501, 50, 'ACTIVE');
INSERT INTO employees VALUES (503, 'Shelley', 'Higgins', 'shiggins@company.com', '515-123-8080', '2022-06-07', 'HR_REP', 55000, NULL, 501, 50, 'ACTIVE');

-- Finance Department
INSERT INTO employees VALUES (601, 'William', 'Gietz', 'wgietz@company.com', '515-123-8181', '2018-06-07', 'FIN_MGR', 110000, NULL, 102, 60, 'ACTIVE');
INSERT INTO employees VALUES (602, 'Daniel', 'Faviet', 'dfaviet@company.com', '515-124-4169', '2019-08-16', 'ACCT', 75000, NULL, 601, 60, 'ACTIVE');
INSERT INTO employees VALUES (603, 'John', 'Chen', 'jchen@company.com', '515-124-4269', '2021-09-28', 'ACCT', 72000, NULL, 601, 60, 'ACTIVE');
INSERT INTO employees VALUES (604, 'Ismael', 'Sciarra', 'isciarra@company.com', '515-124-4369', '2023-09-30', 'ACCT', 68000, NULL, 601, 60, 'ACTIVE');

-- ============================================
-- SAMPLE DATA - JOB_HISTORY
-- ============================================
INSERT INTO job_history VALUES (201, '2015-01-01', '2017-12-31', 'DEV', 20, 'Promotion');
INSERT INTO job_history VALUES (201, '2018-01-01', NULL, 'MGR', 20, 'Current Position');
INSERT INTO job_history VALUES (202, '2017-03-01', '2019-05-20', 'DEV', 20, 'Promotion');
INSERT INTO job_history VALUES (301, '2015-01-01', '2016-12-31', 'SALES', 30, 'Promotion');
INSERT INTO job_history VALUES (301, '2017-01-01', '2017-03-09', 'SR_SALES', 30, 'Promotion');
INSERT INTO job_history VALUES (302, '2016-01-01', '2018-10-14', 'SALES', 30, 'Promotion');
INSERT INTO job_history VALUES (401, '2014-01-01', '2017-02-16', 'ANALYST', 40, 'Promotion');
INSERT INTO job_history VALUES (501, '2016-01-01', '2018-06-06', 'HR_REP', 50, 'Promotion');
INSERT INTO job_history VALUES (601, '2016-01-01', '2018-06-06', 'ACCT', 60, 'Promotion');

-- ============================================
-- DATA SUMMARY
-- ============================================
-- Total Employees: 28
-- Departments: 8 (2 without managers assigned)
-- Jobs: 13 different positions
-- Hierarchy: 4 levels (CEO -> VP -> Manager -> Staff)
-- Date Range: Hire dates from 2015 to 2025
-- New Hires (last 90 days): 2 employees (IDs 206, 207, 307)
