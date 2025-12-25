-- ============================================
-- DML (Data Manipulation Language) Examples
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Sample Tables Setup
-- ============================================

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    salary DECIMAL(10,2),
    department_id INT,
    hire_date DATE
);

CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100),
    location_id INT
);

-- ============================================
-- INSERT - Adding Data
-- ============================================

-- Insert single row with all columns
INSERT INTO employees (employee_id, first_name, last_name, email, salary, department_id, hire_date)
VALUES (1, 'John', 'Doe', 'john.doe@email.com', 75000.00, 10, '2020-01-15');

-- Insert single row (shorthand - all columns in order)
INSERT INTO employees 
VALUES (2, 'Jane', 'Smith', 'jane.smith@email.com', 85000.00, 20, '2019-06-01');

-- Insert multiple rows (SQL Server, PostgreSQL, MySQL)
INSERT INTO employees (employee_id, first_name, last_name, email, salary, department_id, hire_date)
VALUES 
    (3, 'Bob', 'Johnson', 'bob.j@email.com', 65000.00, 10, '2021-03-20'),
    (4, 'Alice', 'Williams', 'alice.w@email.com', 90000.00, 30, '2018-11-10'),
    (5, 'Charlie', 'Brown', 'charlie.b@email.com', 55000.00, 20, '2022-07-05');

-- Oracle: Insert multiple rows using INSERT ALL
INSERT ALL
    INTO employees VALUES (3, 'Bob', 'Johnson', 'bob.j@email.com', 65000.00, 10, DATE '2021-03-20')
    INTO employees VALUES (4, 'Alice', 'Williams', 'alice.w@email.com', 90000.00, 30, DATE '2018-11-10')
    INTO employees VALUES (5, 'Charlie', 'Brown', 'charlie.b@email.com', 55000.00, 20, DATE '2022-07-05')
SELECT * FROM dual;

-- Insert from SELECT (All RDBMS)
INSERT INTO employees (employee_id, first_name, last_name, email, salary, department_id)
SELECT 
    employee_id + 100,
    first_name,
    last_name,
    'backup_' || email,
    salary,
    department_id
FROM employees
WHERE department_id = 10;

-- SQL Server: INSERT with OUTPUT
INSERT INTO employees (employee_id, first_name, last_name, salary)
OUTPUT inserted.employee_id, inserted.first_name
VALUES (6, 'David', 'Lee', 70000.00);

-- PostgreSQL: INSERT with RETURNING
INSERT INTO employees (employee_id, first_name, last_name, salary)
VALUES (6, 'David', 'Lee', 70000.00)
RETURNING employee_id, first_name;

-- MySQL: Get last inserted ID
INSERT INTO employees (first_name, last_name, salary)
VALUES ('David', 'Lee', 70000.00);
SELECT LAST_INSERT_ID();

-- Insert with DEFAULT values
INSERT INTO employees (employee_id, first_name, last_name)
VALUES (7, 'Eva', 'Martinez');

-- ============================================
-- UPDATE - Modifying Data
-- ============================================

-- Update single column
UPDATE employees 
SET salary = 80000.00 
WHERE employee_id = 1;

-- Update multiple columns
UPDATE employees 
SET 
    salary = 85000.00,
    department_id = 20,
    email = 'john.doe.updated@email.com'
WHERE employee_id = 1;

-- Update with calculation
UPDATE employees 
SET salary = salary * 1.10  -- 10% raise
WHERE department_id = 10;

-- Update all rows (be careful!)
UPDATE employees 
SET salary = salary * 1.05;  -- 5% raise for everyone

-- Update with subquery
UPDATE employees 
SET salary = (
    SELECT AVG(salary) 
    FROM employees 
    WHERE department_id = 10
)
WHERE employee_id = 5;

-- Update with JOIN (SQL Server)
UPDATE e
SET e.salary = e.salary * 1.15
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'IT';

-- Update with JOIN (MySQL)
UPDATE employees e
INNER JOIN departments d ON e.department_id = d.department_id
SET e.salary = e.salary * 1.15
WHERE d.department_name = 'IT';

-- Update with JOIN (PostgreSQL)
UPDATE employees e
SET salary = salary * 1.15
FROM departments d
WHERE e.department_id = d.department_id
AND d.department_name = 'IT';

-- Oracle: Update with JOIN using subquery
UPDATE employees e
SET salary = salary * 1.15
WHERE department_id IN (
    SELECT department_id 
    FROM departments 
    WHERE department_name = 'IT'
);

-- SQL Server: UPDATE with OUTPUT
UPDATE employees
SET salary = salary * 1.10
OUTPUT deleted.salary AS old_salary, inserted.salary AS new_salary
WHERE employee_id = 1;

-- PostgreSQL: UPDATE with RETURNING
UPDATE employees
SET salary = salary * 1.10
WHERE employee_id = 1
RETURNING employee_id, salary;

-- ============================================
-- DELETE - Removing Data
-- ============================================

-- Delete specific row
DELETE FROM employees 
WHERE employee_id = 5;

-- Delete with multiple conditions
DELETE FROM employees 
WHERE department_id = 10 
AND salary < 50000;

-- Delete all rows (be careful!)
DELETE FROM employees;

-- Delete with subquery
DELETE FROM employees 
WHERE department_id IN (
    SELECT department_id 
    FROM departments 
    WHERE location_id = 1700
);

-- Delete with JOIN (SQL Server)
DELETE e
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'Temp';

-- Delete with JOIN (MySQL)
DELETE e
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'Temp';

-- Delete with JOIN (PostgreSQL)
DELETE FROM employees e
USING departments d
WHERE e.department_id = d.department_id
AND d.department_name = 'Temp';

-- SQL Server: DELETE with OUTPUT
DELETE FROM employees
OUTPUT deleted.employee_id, deleted.first_name
WHERE employee_id = 5;

-- PostgreSQL: DELETE with RETURNING
DELETE FROM employees
WHERE employee_id = 5
RETURNING *;

-- Delete top N rows (SQL Server)
DELETE TOP (10) FROM employees
WHERE department_id = 10;

-- Delete with LIMIT (MySQL)
DELETE FROM employees
WHERE department_id = 10
LIMIT 10;

-- PostgreSQL: Delete with LIMIT using CTE
WITH to_delete AS (
    SELECT employee_id 
    FROM employees 
    WHERE department_id = 10 
    LIMIT 10
)
DELETE FROM employees 
WHERE employee_id IN (SELECT employee_id FROM to_delete);

-- ============================================
-- MERGE / UPSERT
-- ============================================

-- SQL Server / Oracle: MERGE statement
MERGE INTO employees AS target
USING (
    SELECT 1 AS employee_id, 'John' AS first_name, 'Doe' AS last_name, 80000 AS salary
) AS source
ON target.employee_id = source.employee_id
WHEN MATCHED THEN
    UPDATE SET 
        first_name = source.first_name,
        last_name = source.last_name,
        salary = source.salary
WHEN NOT MATCHED THEN
    INSERT (employee_id, first_name, last_name, salary)
    VALUES (source.employee_id, source.first_name, source.last_name, source.salary);

-- PostgreSQL: INSERT ON CONFLICT (UPSERT)
INSERT INTO employees (employee_id, first_name, last_name, salary)
VALUES (1, 'John', 'Doe', 80000)
ON CONFLICT (employee_id) 
DO UPDATE SET 
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    salary = EXCLUDED.salary;

-- MySQL: INSERT ON DUPLICATE KEY UPDATE
INSERT INTO employees (employee_id, first_name, last_name, salary)
VALUES (1, 'John', 'Doe', 80000)
ON DUPLICATE KEY UPDATE 
    first_name = VALUES(first_name),
    last_name = VALUES(last_name),
    salary = VALUES(salary);

-- MySQL 8.0+: Using alias
INSERT INTO employees (employee_id, first_name, last_name, salary)
VALUES (1, 'John', 'Doe', 80000) AS new_values
ON DUPLICATE KEY UPDATE 
    first_name = new_values.first_name,
    last_name = new_values.last_name,
    salary = new_values.salary;

-- ============================================
-- SELECT INTO / CREATE TABLE AS
-- ============================================

-- SQL Server: SELECT INTO (creates new table)
SELECT employee_id, first_name, last_name, salary
INTO employees_backup
FROM employees
WHERE department_id = 10;

-- Oracle / PostgreSQL / MySQL: CREATE TABLE AS
CREATE TABLE employees_backup AS
SELECT employee_id, first_name, last_name, salary
FROM employees
WHERE department_id = 10;

-- PostgreSQL: With no data (structure only)
CREATE TABLE employees_template AS
SELECT * FROM employees
WHERE 1 = 0;

-- SQL Server: Structure only
SELECT employee_id, first_name, last_name, salary
INTO employees_template
FROM employees
WHERE 1 = 0;
