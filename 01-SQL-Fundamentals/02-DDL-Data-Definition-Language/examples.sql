-- ============================================
-- DDL (Data Definition Language) Examples
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- CREATE TABLE
-- ============================================

-- Basic table creation (All RDBMS)
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    hire_date DATE,
    salary DECIMAL(10,2),
    department_id INT
);

-- SQL Server: With IDENTITY
CREATE TABLE employees_sqlserver (
    employee_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    hire_date DATE DEFAULT GETDATE(),
    salary DECIMAL(10,2) CHECK (salary > 0),
    department_id INT
);

-- Oracle: With SEQUENCE (traditional)
CREATE SEQUENCE emp_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE employees_oracle (
    employee_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE,
    hire_date DATE DEFAULT SYSDATE,
    salary NUMBER(10,2) CHECK (salary > 0),
    department_id NUMBER
);

-- Oracle 12c+: With IDENTITY
CREATE TABLE employees_oracle_12c (
    employee_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE,
    hire_date DATE DEFAULT SYSDATE,
    salary NUMBER(10,2),
    department_id NUMBER
);

-- PostgreSQL: With SERIAL
CREATE TABLE employees_postgresql (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    hire_date DATE DEFAULT CURRENT_DATE,
    salary NUMERIC(10,2) CHECK (salary > 0),
    department_id INT
);

-- MySQL: With AUTO_INCREMENT
CREATE TABLE employees_mysql (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    hire_date DATE DEFAULT (CURRENT_DATE),
    salary DECIMAL(10,2) CHECK (salary > 0),
    department_id INT
) ENGINE=InnoDB;

-- ============================================
-- CREATE TABLE with Foreign Key
-- ============================================

CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    location_id INT
);

CREATE TABLE employees_with_fk (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department_id INT,
    CONSTRAINT fk_department 
        FOREIGN KEY (department_id) 
        REFERENCES departments(department_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- ============================================
-- ALTER TABLE
-- ============================================

-- Add column
ALTER TABLE employees ADD phone VARCHAR(20);

-- SQL Server
ALTER TABLE employees ADD phone VARCHAR(20) NULL;

-- Oracle
ALTER TABLE employees ADD (phone VARCHAR2(20));

-- PostgreSQL / MySQL
ALTER TABLE employees ADD COLUMN phone VARCHAR(20);

-- Modify column
-- SQL Server
ALTER TABLE employees ALTER COLUMN phone VARCHAR(30);

-- Oracle
ALTER TABLE employees MODIFY phone VARCHAR2(30);

-- PostgreSQL
ALTER TABLE employees ALTER COLUMN phone TYPE VARCHAR(30);

-- MySQL
ALTER TABLE employees MODIFY COLUMN phone VARCHAR(30);

-- Drop column
ALTER TABLE employees DROP COLUMN phone;

-- Oracle
ALTER TABLE employees DROP (phone);

-- Add constraint
ALTER TABLE employees 
ADD CONSTRAINT chk_salary CHECK (salary >= 0);

-- Drop constraint
ALTER TABLE employees DROP CONSTRAINT chk_salary;

-- Rename table
-- SQL Server
EXEC sp_rename 'employees', 'staff';

-- Oracle
ALTER TABLE employees RENAME TO staff;

-- PostgreSQL
ALTER TABLE employees RENAME TO staff;

-- MySQL
RENAME TABLE employees TO staff;

-- Rename column
-- SQL Server
EXEC sp_rename 'employees.first_name', 'fname', 'COLUMN';

-- Oracle
ALTER TABLE employees RENAME COLUMN first_name TO fname;

-- PostgreSQL
ALTER TABLE employees RENAME COLUMN first_name TO fname;

-- MySQL
ALTER TABLE employees CHANGE first_name fname VARCHAR(50);

-- ============================================
-- DROP TABLE
-- ============================================

-- Basic drop
DROP TABLE employees;

-- Drop if exists (PostgreSQL, MySQL, SQL Server 2016+)
DROP TABLE IF EXISTS employees;

-- Oracle
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE employees';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;

-- Drop with cascade (PostgreSQL)
DROP TABLE departments CASCADE;

-- Oracle: Drop with cascade constraints
DROP TABLE departments CASCADE CONSTRAINTS;

-- ============================================
-- TRUNCATE TABLE
-- ============================================

-- Remove all rows (faster than DELETE, cannot rollback in most RDBMS)
TRUNCATE TABLE employees;

-- PostgreSQL: With RESTART IDENTITY
TRUNCATE TABLE employees RESTART IDENTITY;

-- SQL Server: Reseed identity
TRUNCATE TABLE employees;
DBCC CHECKIDENT ('employees', RESEED, 0);

-- ============================================
-- CREATE INDEX
-- ============================================

-- Basic index
CREATE INDEX idx_emp_lastname ON employees(last_name);

-- Unique index
CREATE UNIQUE INDEX idx_emp_email ON employees(email);

-- Composite index
CREATE INDEX idx_emp_name ON employees(last_name, first_name);

-- SQL Server: Clustered index
CREATE CLUSTERED INDEX idx_emp_id ON employees(employee_id);

-- SQL Server: Non-clustered with included columns
CREATE NONCLUSTERED INDEX idx_emp_dept 
ON employees(department_id) 
INCLUDE (first_name, last_name, salary);

-- PostgreSQL: Partial index
CREATE INDEX idx_active_emp ON employees(employee_id) 
WHERE status = 'active';

-- PostgreSQL: Expression index
CREATE INDEX idx_emp_lower_email ON employees(LOWER(email));

-- Drop index
DROP INDEX idx_emp_lastname;

-- SQL Server
DROP INDEX idx_emp_lastname ON employees;

-- ============================================
-- CREATE VIEW
-- ============================================

CREATE VIEW v_employee_details AS
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    e.salary,
    d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id;

-- Create or replace view
-- Oracle, PostgreSQL, MySQL
CREATE OR REPLACE VIEW v_employee_details AS
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS full_name,
    e.salary,
    d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id;

-- SQL Server
ALTER VIEW v_employee_details AS
SELECT 
    e.employee_id,
    e.first_name + ' ' + e.last_name AS full_name,
    e.salary,
    d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id;

-- Drop view
DROP VIEW v_employee_details;

-- ============================================
-- CREATE SCHEMA (Database organization)
-- ============================================

-- SQL Server / PostgreSQL
CREATE SCHEMA hr;

CREATE TABLE hr.employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50)
);

-- Oracle: Create user/schema
CREATE USER hr IDENTIFIED BY password;
GRANT CREATE TABLE TO hr;

-- MySQL: Create database
CREATE DATABASE hr;
USE hr;
