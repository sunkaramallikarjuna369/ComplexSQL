-- ============================================
-- Normalization Examples
-- 1NF, 2NF, 3NF, BCNF, Denormalization
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- UNNORMALIZED DATA (Before 1NF)
-- ============================================

-- Problem: Repeating groups, multi-valued attributes
CREATE TABLE orders_unnormalized (
    order_id INT,
    customer_name VARCHAR(100),
    products VARCHAR(500),  -- "Laptop, Mouse, Keyboard"
    quantities VARCHAR(100), -- "1, 2, 1"
    prices VARCHAR(100)      -- "999.99, 29.99, 79.99"
);

INSERT INTO orders_unnormalized VALUES 
(1, 'John Doe', 'Laptop, Mouse, Keyboard', '1, 2, 1', '999.99, 29.99, 79.99');

-- ============================================
-- FIRST NORMAL FORM (1NF)
-- ============================================

-- Rules:
-- 1. Eliminate repeating groups
-- 2. Each cell contains atomic (single) values
-- 3. Each row is unique (has primary key)

-- 1NF Solution: Separate rows for each product
CREATE TABLE orders_1nf (
    order_id INT,
    customer_name VARCHAR(100),
    product_name VARCHAR(100),
    quantity INT,
    price DECIMAL(10,2),
    PRIMARY KEY (order_id, product_name)
);

INSERT INTO orders_1nf VALUES 
(1, 'John Doe', 'Laptop', 1, 999.99),
(1, 'John Doe', 'Mouse', 2, 29.99),
(1, 'John Doe', 'Keyboard', 1, 79.99);

-- ============================================
-- SECOND NORMAL FORM (2NF)
-- ============================================

-- Rules:
-- 1. Must be in 1NF
-- 2. No partial dependencies (non-key attributes depend on entire primary key)

-- Problem in 1NF: customer_name depends only on order_id, not on product_name

-- 2NF Solution: Separate tables
CREATE TABLE orders_2nf (
    order_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    order_date DATE
);

CREATE TABLE order_items_2nf (
    order_id INT,
    product_name VARCHAR(100),
    quantity INT,
    price DECIMAL(10,2),
    PRIMARY KEY (order_id, product_name),
    FOREIGN KEY (order_id) REFERENCES orders_2nf(order_id)
);

INSERT INTO orders_2nf VALUES (1, 'John Doe', '2024-01-15');
INSERT INTO order_items_2nf VALUES 
(1, 'Laptop', 1, 999.99),
(1, 'Mouse', 2, 29.99),
(1, 'Keyboard', 1, 79.99);

-- ============================================
-- THIRD NORMAL FORM (3NF)
-- ============================================

-- Rules:
-- 1. Must be in 2NF
-- 2. No transitive dependencies (non-key attributes depend only on primary key)

-- Problem: If we had customer_city depending on customer_name
CREATE TABLE orders_problem (
    order_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    customer_city VARCHAR(100),  -- Depends on customer_name, not order_id
    customer_state VARCHAR(50)   -- Depends on customer_city
);

-- 3NF Solution: Separate customer table
CREATE TABLE customers_3nf (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(50)
);

CREATE TABLE orders_3nf (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers_3nf(customer_id)
);

-- Even better: Separate city/state
CREATE TABLE states (
    state_id INT PRIMARY KEY,
    state_name VARCHAR(50)
);

CREATE TABLE cities (
    city_id INT PRIMARY KEY,
    city_name VARCHAR(100),
    state_id INT,
    FOREIGN KEY (state_id) REFERENCES states(state_id)
);

CREATE TABLE customers_normalized (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    city_id INT,
    FOREIGN KEY (city_id) REFERENCES cities(city_id)
);

-- ============================================
-- BOYCE-CODD NORMAL FORM (BCNF)
-- ============================================

-- Rules:
-- 1. Must be in 3NF
-- 2. For every functional dependency X -> Y, X must be a superkey

-- Problem scenario: Student-Subject-Teacher
-- A student can have only one teacher per subject
-- A teacher teaches only one subject
CREATE TABLE student_subject_teacher (
    student_id INT,
    subject VARCHAR(50),
    teacher VARCHAR(50),
    PRIMARY KEY (student_id, subject)
);

-- Functional dependencies:
-- (student_id, subject) -> teacher
-- teacher -> subject (violates BCNF because teacher is not a superkey)

-- BCNF Solution: Decompose
CREATE TABLE teachers (
    teacher_id INT PRIMARY KEY,
    teacher_name VARCHAR(100),
    subject VARCHAR(50)
);

CREATE TABLE student_teachers (
    student_id INT,
    teacher_id INT,
    PRIMARY KEY (student_id, teacher_id),
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id)
);

-- ============================================
-- DENORMALIZATION (For Performance)
-- ============================================

-- Sometimes we intentionally denormalize for read performance

-- Normalized (many joins needed)
SELECT 
    o.order_id,
    c.customer_name,
    ci.city_name,
    s.state_name,
    p.product_name,
    oi.quantity,
    oi.price
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN cities ci ON c.city_id = ci.city_id
JOIN states s ON ci.state_id = s.state_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;

-- Denormalized (faster reads, but data redundancy)
CREATE TABLE orders_denormalized (
    order_id INT PRIMARY KEY,
    order_date DATE,
    customer_id INT,
    customer_name VARCHAR(100),  -- Redundant
    customer_city VARCHAR(100),  -- Redundant
    customer_state VARCHAR(50),  -- Redundant
    total_amount DECIMAL(10,2)   -- Calculated/redundant
);

-- Materialized view for denormalization
CREATE MATERIALIZED VIEW mv_order_summary AS
SELECT 
    o.order_id,
    o.order_date,
    c.customer_name,
    ci.city_name,
    s.state_name,
    SUM(oi.quantity * oi.price) AS total_amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN cities ci ON c.city_id = ci.city_id
JOIN states s ON ci.state_id = s.state_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.order_date, c.customer_name, ci.city_name, s.state_name;

-- ============================================
-- Practical Normalization Example
-- ============================================

-- Start: Unnormalized employee data
CREATE TABLE emp_unnormalized (
    emp_id INT,
    emp_name VARCHAR(100),
    dept_name VARCHAR(100),
    dept_location VARCHAR(100),
    skills VARCHAR(500),  -- "Java, Python, SQL"
    projects VARCHAR(500) -- "Project A, Project B"
);

-- Final: Fully normalized structure
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL,
    location VARCHAR(100)
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE skills (
    skill_id INT PRIMARY KEY,
    skill_name VARCHAR(100) NOT NULL
);

CREATE TABLE employee_skills (
    emp_id INT,
    skill_id INT,
    proficiency_level VARCHAR(20),
    PRIMARY KEY (emp_id, skill_id),
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    FOREIGN KEY (skill_id) REFERENCES skills(skill_id)
);

CREATE TABLE projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    start_date DATE,
    end_date DATE
);

CREATE TABLE employee_projects (
    emp_id INT,
    project_id INT,
    role VARCHAR(50),
    hours_allocated INT,
    PRIMARY KEY (emp_id, project_id),
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    FOREIGN KEY (project_id) REFERENCES projects(project_id)
);

-- ============================================
-- When to Normalize vs Denormalize
-- ============================================

-- Normalize when:
-- 1. Data integrity is critical
-- 2. Write operations are frequent
-- 3. Storage space is a concern
-- 4. Data changes frequently

-- Denormalize when:
-- 1. Read performance is critical
-- 2. Data is mostly static
-- 3. Complex joins are hurting performance
-- 4. Reporting/analytics workloads
