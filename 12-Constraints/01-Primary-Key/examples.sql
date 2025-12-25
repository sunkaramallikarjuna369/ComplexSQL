-- ============================================
-- Constraints Examples
-- PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, DEFAULT, NOT NULL
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- PRIMARY KEY Constraint
-- ============================================

-- Primary key at column level
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50)
);

-- Primary key at table level
CREATE TABLE employees (
    employee_id INT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    CONSTRAINT pk_employees PRIMARY KEY (employee_id)
);

-- Composite primary key
CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    CONSTRAINT pk_order_items PRIMARY KEY (order_id, product_id)
);

-- Add primary key to existing table
ALTER TABLE employees ADD CONSTRAINT pk_employees PRIMARY KEY (employee_id);

-- Drop primary key
ALTER TABLE employees DROP CONSTRAINT pk_employees;

-- ============================================
-- FOREIGN KEY Constraint
-- ============================================

-- Foreign key at column level
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    department_id INT REFERENCES departments(department_id)
);

-- Foreign key at table level
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    department_id INT,
    CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) 
        REFERENCES departments(department_id)
);

-- Foreign key with ON DELETE/UPDATE actions
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    department_id INT,
    CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) 
        REFERENCES departments(department_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- Foreign key actions:
-- CASCADE: Delete/update child rows
-- SET NULL: Set foreign key to NULL
-- SET DEFAULT: Set to default value
-- RESTRICT/NO ACTION: Prevent delete/update

-- Self-referencing foreign key
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    manager_id INT,
    CONSTRAINT fk_emp_manager FOREIGN KEY (manager_id) 
        REFERENCES employees(employee_id)
);

-- Add foreign key to existing table
ALTER TABLE employees 
ADD CONSTRAINT fk_emp_dept 
FOREIGN KEY (department_id) REFERENCES departments(department_id);

-- Drop foreign key
ALTER TABLE employees DROP CONSTRAINT fk_emp_dept;

-- ============================================
-- UNIQUE Constraint
-- ============================================

-- Unique at column level
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    email VARCHAR(100) UNIQUE,
    ssn VARCHAR(11) UNIQUE
);

-- Unique at table level
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    email VARCHAR(100),
    CONSTRAINT uq_emp_email UNIQUE (email)
);

-- Composite unique constraint
CREATE TABLE employee_assignments (
    employee_id INT,
    project_id INT,
    role VARCHAR(50),
    CONSTRAINT uq_emp_project UNIQUE (employee_id, project_id)
);

-- Add unique constraint
ALTER TABLE employees ADD CONSTRAINT uq_emp_email UNIQUE (email);

-- Drop unique constraint
ALTER TABLE employees DROP CONSTRAINT uq_emp_email;

-- ============================================
-- CHECK Constraint
-- ============================================

-- Check at column level
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    salary DECIMAL(10,2) CHECK (salary > 0),
    age INT CHECK (age >= 18 AND age <= 100)
);

-- Check at table level
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    salary DECIMAL(10,2),
    min_salary DECIMAL(10,2),
    max_salary DECIMAL(10,2),
    CONSTRAINT chk_salary_range CHECK (salary BETWEEN min_salary AND max_salary)
);

-- Named check constraint
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    hire_date DATE,
    termination_date DATE,
    CONSTRAINT chk_dates CHECK (termination_date IS NULL OR termination_date > hire_date)
);

-- Check with IN list
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    status VARCHAR(20),
    CONSTRAINT chk_status CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

-- Add check constraint
ALTER TABLE employees ADD CONSTRAINT chk_salary CHECK (salary > 0);

-- Drop check constraint
ALTER TABLE employees DROP CONSTRAINT chk_salary;

-- ============================================
-- DEFAULT Constraint
-- ============================================

-- Default at column level
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    hire_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- SQL Server defaults
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    hire_date DATE DEFAULT GETDATE(),
    created_at DATETIME DEFAULT GETDATE()
);

-- Oracle defaults
CREATE TABLE employees (
    employee_id NUMBER PRIMARY KEY,
    hire_date DATE DEFAULT SYSDATE,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Named default constraint (SQL Server)
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    status VARCHAR(20),
    CONSTRAINT df_emp_status DEFAULT 'active' FOR status
);

-- Add default constraint
ALTER TABLE employees ADD CONSTRAINT df_status DEFAULT 'active' FOR status;

-- Drop default constraint (SQL Server)
ALTER TABLE employees DROP CONSTRAINT df_status;

-- ============================================
-- NOT NULL Constraint
-- ============================================

-- NOT NULL at column level
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100)
);

-- Add NOT NULL (SQL Server)
ALTER TABLE employees ALTER COLUMN first_name VARCHAR(50) NOT NULL;

-- Add NOT NULL (PostgreSQL)
ALTER TABLE employees ALTER COLUMN first_name SET NOT NULL;

-- Add NOT NULL (Oracle)
ALTER TABLE employees MODIFY first_name NOT NULL;

-- Add NOT NULL (MySQL)
ALTER TABLE employees MODIFY first_name VARCHAR(50) NOT NULL;

-- Remove NOT NULL (PostgreSQL)
ALTER TABLE employees ALTER COLUMN first_name DROP NOT NULL;

-- ============================================
-- Complete Example with All Constraints
-- ============================================

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    hire_date DATE NOT NULL DEFAULT CURRENT_DATE,
    salary DECIMAL(10,2) NOT NULL CHECK (salary > 0),
    department_id INT,
    manager_id INT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'terminated')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) 
        REFERENCES departments(department_id) ON DELETE SET NULL,
    CONSTRAINT fk_emp_manager FOREIGN KEY (manager_id) 
        REFERENCES employees(employee_id) ON DELETE SET NULL
);

-- ============================================
-- Viewing Constraints
-- ============================================

-- SQL Server
SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_NAME = 'employees';
SELECT * FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME = 'employees';

-- PostgreSQL
SELECT * FROM information_schema.table_constraints WHERE table_name = 'employees';
SELECT * FROM pg_constraint WHERE conrelid = 'employees'::regclass;

-- Oracle
SELECT * FROM user_constraints WHERE table_name = 'EMPLOYEES';
SELECT * FROM user_cons_columns WHERE table_name = 'EMPLOYEES';

-- MySQL
SELECT * FROM information_schema.table_constraints WHERE table_name = 'employees';
SHOW CREATE TABLE employees;
