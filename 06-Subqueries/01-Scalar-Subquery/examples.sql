-- ============================================
-- Subqueries Examples
-- Scalar, Row, Table, Correlated, EXISTS
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Scalar Subqueries (Return single value)
-- ============================================

-- Scalar subquery in SELECT
SELECT 
    first_name,
    salary,
    (SELECT AVG(salary) FROM employees) AS company_avg,
    salary - (SELECT AVG(salary) FROM employees) AS diff_from_avg
FROM employees;

-- Scalar subquery in WHERE
SELECT first_name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Scalar subquery with MAX
SELECT first_name, salary
FROM employees
WHERE salary = (SELECT MAX(salary) FROM employees);

-- ============================================
-- Row Subqueries (Return single row)
-- ============================================

-- Compare multiple columns
SELECT first_name, department_id, salary
FROM employees
WHERE (department_id, salary) = (
    SELECT department_id, MAX(salary)
    FROM employees
    WHERE department_id = 60
    GROUP BY department_id
);

-- ============================================
-- Table Subqueries (Return multiple rows)
-- ============================================

-- IN with subquery
SELECT first_name, department_id
FROM employees
WHERE department_id IN (
    SELECT department_id
    FROM departments
    WHERE location_id = 1700
);

-- NOT IN with subquery
SELECT first_name, department_id
FROM employees
WHERE department_id NOT IN (
    SELECT department_id
    FROM departments
    WHERE manager_id IS NULL
    AND department_id IS NOT NULL  -- Important for NOT IN!
);

-- ANY/SOME with subquery
SELECT first_name, salary
FROM employees
WHERE salary > ANY (
    SELECT salary FROM employees WHERE department_id = 60
);

-- ALL with subquery
SELECT first_name, salary
FROM employees
WHERE salary > ALL (
    SELECT salary FROM employees WHERE department_id = 60
);

-- ============================================
-- Correlated Subqueries
-- ============================================

-- Find employees earning more than department average
SELECT 
    e.first_name,
    e.salary,
    e.department_id
FROM employees e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM employees e2
    WHERE e2.department_id = e.department_id
);

-- Find employees with highest salary in their department
SELECT 
    e.first_name,
    e.salary,
    e.department_id
FROM employees e
WHERE e.salary = (
    SELECT MAX(e2.salary)
    FROM employees e2
    WHERE e2.department_id = e.department_id
);

-- Correlated subquery in SELECT
SELECT 
    e.first_name,
    e.salary,
    e.department_id,
    (SELECT AVG(e2.salary) 
     FROM employees e2 
     WHERE e2.department_id = e.department_id) AS dept_avg
FROM employees e;

-- ============================================
-- EXISTS / NOT EXISTS
-- ============================================

-- EXISTS: Find departments with employees
SELECT d.department_name
FROM departments d
WHERE EXISTS (
    SELECT 1
    FROM employees e
    WHERE e.department_id = d.department_id
);

-- NOT EXISTS: Find departments without employees
SELECT d.department_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1
    FROM employees e
    WHERE e.department_id = d.department_id
);

-- EXISTS vs IN (EXISTS often faster for large datasets)
-- Using IN
SELECT * FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders);

-- Using EXISTS (equivalent, often faster)
SELECT * FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);

-- ============================================
-- Subquery in FROM (Derived Tables)
-- ============================================

-- Basic derived table
SELECT 
    dept_stats.department_id,
    dept_stats.emp_count,
    dept_stats.avg_salary
FROM (
    SELECT 
        department_id,
        COUNT(*) AS emp_count,
        AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
) dept_stats
WHERE dept_stats.emp_count > 5;

-- Join with derived table
SELECT 
    e.first_name,
    e.salary,
    dept_avg.avg_salary,
    e.salary - dept_avg.avg_salary AS diff
FROM employees e
JOIN (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
) dept_avg ON e.department_id = dept_avg.department_id;

-- ============================================
-- Nested Subqueries
-- ============================================

-- Three levels of nesting
SELECT first_name, salary
FROM employees
WHERE department_id IN (
    SELECT department_id
    FROM departments
    WHERE location_id IN (
        SELECT location_id
        FROM locations
        WHERE country_id = 'US'
    )
);

-- ============================================
-- Subquery with INSERT
-- ============================================

-- Insert from subquery
INSERT INTO high_earners (employee_id, first_name, salary)
SELECT employee_id, first_name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) * 2 FROM employees);

-- ============================================
-- Subquery with UPDATE
-- ============================================

-- Update using subquery
UPDATE employees
SET salary = salary * 1.10
WHERE department_id IN (
    SELECT department_id
    FROM departments
    WHERE department_name = 'IT'
);

-- Update with correlated subquery
UPDATE employees e
SET salary = (
    SELECT AVG(e2.salary) * 1.1
    FROM employees e2
    WHERE e2.department_id = e.department_id
)
WHERE e.salary < (
    SELECT AVG(e3.salary)
    FROM employees e3
    WHERE e3.department_id = e.department_id
);

-- ============================================
-- Subquery with DELETE
-- ============================================

-- Delete using subquery
DELETE FROM employees
WHERE department_id IN (
    SELECT department_id
    FROM departments
    WHERE location_id = 1700
);

-- Delete with NOT EXISTS
DELETE FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);

-- ============================================
-- Practical Subquery Examples
-- ============================================

-- Find second highest salary
SELECT MAX(salary) AS second_highest
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- Find Nth highest salary
SELECT DISTINCT salary
FROM employees e1
WHERE N = (
    SELECT COUNT(DISTINCT salary)
    FROM employees e2
    WHERE e2.salary >= e1.salary
);

-- Find employees with no direct reports
SELECT e.first_name, e.last_name
FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM employees m WHERE m.manager_id = e.employee_id
);

-- Find products never ordered
SELECT p.product_name
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM order_items oi WHERE oi.product_id = p.product_id
);

-- Running total using correlated subquery
SELECT 
    e.employee_id,
    e.first_name,
    e.salary,
    (SELECT SUM(e2.salary) 
     FROM employees e2 
     WHERE e2.employee_id <= e.employee_id) AS running_total
FROM employees e
ORDER BY e.employee_id;
