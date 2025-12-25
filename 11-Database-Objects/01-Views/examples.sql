-- ============================================
-- Database Objects Examples
-- Views, Stored Procedures, Functions, Triggers
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- VIEWS
-- ============================================

-- Basic View
CREATE VIEW v_employee_details AS
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    e.email,
    e.salary,
    d.department_name,
    l.city
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
LEFT JOIN locations l ON d.location_id = l.location_id;

-- Query the view
SELECT * FROM v_employee_details WHERE department_name = 'IT';

-- View with aggregation
CREATE VIEW v_department_stats AS
SELECT 
    d.department_id,
    d.department_name,
    COUNT(e.employee_id) AS employee_count,
    AVG(e.salary) AS avg_salary,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name;

-- Updatable View (simple views)
CREATE VIEW v_it_employees AS
SELECT employee_id, first_name, last_name, salary
FROM employees
WHERE department_id = 60;

-- WITH CHECK OPTION (prevents updates that would remove row from view)
CREATE VIEW v_high_earners AS
SELECT employee_id, first_name, salary
FROM employees
WHERE salary > 100000
WITH CHECK OPTION;

-- Materialized View (Oracle, PostgreSQL)
-- PostgreSQL
CREATE MATERIALIZED VIEW mv_sales_summary AS
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    SUM(total_amount) AS total_sales,
    COUNT(*) AS order_count
FROM orders
GROUP BY DATE_TRUNC('month', order_date);

-- Refresh materialized view
REFRESH MATERIALIZED VIEW mv_sales_summary;

-- Oracle Materialized View
CREATE MATERIALIZED VIEW mv_sales_summary
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT 
    TRUNC(order_date, 'MM') AS month,
    SUM(total_amount) AS total_sales,
    COUNT(*) AS order_count
FROM orders
GROUP BY TRUNC(order_date, 'MM');

-- Drop View
DROP VIEW v_employee_details;

-- ============================================
-- STORED PROCEDURES
-- ============================================

-- SQL Server Stored Procedure
CREATE PROCEDURE sp_GetEmployeesByDept
    @DepartmentId INT,
    @MinSalary DECIMAL(10,2) = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        employee_id,
        first_name,
        last_name,
        salary
    FROM employees
    WHERE department_id = @DepartmentId
    AND salary >= @MinSalary
    ORDER BY salary DESC;
END;

-- Execute SQL Server procedure
EXEC sp_GetEmployeesByDept @DepartmentId = 60, @MinSalary = 50000;

-- Oracle Stored Procedure
CREATE OR REPLACE PROCEDURE sp_get_employees_by_dept(
    p_department_id IN NUMBER,
    p_min_salary IN NUMBER DEFAULT 0,
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT 
        employee_id,
        first_name,
        last_name,
        salary
    FROM employees
    WHERE department_id = p_department_id
    AND salary >= p_min_salary
    ORDER BY salary DESC;
END;

-- PostgreSQL Stored Procedure
CREATE OR REPLACE PROCEDURE sp_transfer_funds(
    p_from_account INT,
    p_to_account INT,
    p_amount DECIMAL(10,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Deduct from source
    UPDATE accounts SET balance = balance - p_amount
    WHERE account_id = p_from_account;
    
    -- Add to destination
    UPDATE accounts SET balance = balance + p_amount
    WHERE account_id = p_to_account;
    
    COMMIT;
END;
$$;

-- Call PostgreSQL procedure
CALL sp_transfer_funds(1, 2, 100.00);

-- MySQL Stored Procedure
DELIMITER //
CREATE PROCEDURE sp_get_employees_by_dept(
    IN p_department_id INT,
    IN p_min_salary DECIMAL(10,2)
)
BEGIN
    SELECT 
        employee_id,
        first_name,
        last_name,
        salary
    FROM employees
    WHERE department_id = p_department_id
    AND salary >= COALESCE(p_min_salary, 0)
    ORDER BY salary DESC;
END //
DELIMITER ;

-- Call MySQL procedure
CALL sp_get_employees_by_dept(60, 50000);

-- ============================================
-- USER-DEFINED FUNCTIONS
-- ============================================

-- SQL Server Scalar Function
CREATE FUNCTION fn_CalculateBonus(@Salary DECIMAL(10,2), @PerformanceRating INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Bonus DECIMAL(10,2);
    SET @Bonus = @Salary * 
        CASE @PerformanceRating
            WHEN 5 THEN 0.20
            WHEN 4 THEN 0.15
            WHEN 3 THEN 0.10
            WHEN 2 THEN 0.05
            ELSE 0
        END;
    RETURN @Bonus;
END;

-- Use SQL Server function
SELECT first_name, salary, dbo.fn_CalculateBonus(salary, 4) AS bonus FROM employees;

-- SQL Server Table-Valued Function
CREATE FUNCTION fn_GetEmployeesByDept(@DeptId INT)
RETURNS TABLE
AS
RETURN (
    SELECT employee_id, first_name, last_name, salary
    FROM employees
    WHERE department_id = @DeptId
);

-- Use table-valued function
SELECT * FROM fn_GetEmployeesByDept(60);

-- PostgreSQL Function
CREATE OR REPLACE FUNCTION fn_calculate_bonus(
    p_salary DECIMAL(10,2),
    p_rating INT
)
RETURNS DECIMAL(10,2)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p_salary * 
        CASE p_rating
            WHEN 5 THEN 0.20
            WHEN 4 THEN 0.15
            WHEN 3 THEN 0.10
            WHEN 2 THEN 0.05
            ELSE 0
        END;
END;
$$;

-- MySQL Function
DELIMITER //
CREATE FUNCTION fn_calculate_bonus(
    p_salary DECIMAL(10,2),
    p_rating INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_bonus DECIMAL(10,2);
    SET v_bonus = p_salary * 
        CASE p_rating
            WHEN 5 THEN 0.20
            WHEN 4 THEN 0.15
            WHEN 3 THEN 0.10
            WHEN 2 THEN 0.05
            ELSE 0
        END;
    RETURN v_bonus;
END //
DELIMITER ;

-- ============================================
-- TRIGGERS
-- ============================================

-- SQL Server Trigger
CREATE TRIGGER tr_employee_audit
ON employees
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO employee_audit (
        action_type,
        employee_id,
        old_salary,
        new_salary,
        changed_date,
        changed_by
    )
    SELECT 
        CASE 
            WHEN EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE'
            WHEN EXISTS(SELECT 1 FROM inserted) THEN 'INSERT'
            ELSE 'DELETE'
        END,
        COALESCE(i.employee_id, d.employee_id),
        d.salary,
        i.salary,
        GETDATE(),
        SYSTEM_USER
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.employee_id = d.employee_id;
END;

-- PostgreSQL Trigger
CREATE OR REPLACE FUNCTION fn_employee_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO employee_audit (
        action_type,
        employee_id,
        old_salary,
        new_salary,
        changed_date
    )
    VALUES (
        TG_OP,
        COALESCE(NEW.employee_id, OLD.employee_id),
        OLD.salary,
        NEW.salary,
        CURRENT_TIMESTAMP
    );
    RETURN NEW;
END;
$$;

CREATE TRIGGER tr_employee_audit
AFTER INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW
EXECUTE FUNCTION fn_employee_audit();

-- MySQL Trigger
DELIMITER //
CREATE TRIGGER tr_employee_audit_insert
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
    INSERT INTO employee_audit (action_type, employee_id, new_salary, changed_date)
    VALUES ('INSERT', NEW.employee_id, NEW.salary, NOW());
END //

CREATE TRIGGER tr_employee_audit_update
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    INSERT INTO employee_audit (action_type, employee_id, old_salary, new_salary, changed_date)
    VALUES ('UPDATE', NEW.employee_id, OLD.salary, NEW.salary, NOW());
END //

CREATE TRIGGER tr_employee_audit_delete
AFTER DELETE ON employees
FOR EACH ROW
BEGIN
    INSERT INTO employee_audit (action_type, employee_id, old_salary, changed_date)
    VALUES ('DELETE', OLD.employee_id, OLD.salary, NOW());
END //
DELIMITER ;

-- Drop objects
DROP PROCEDURE sp_GetEmployeesByDept;
DROP FUNCTION fn_CalculateBonus;
DROP TRIGGER tr_employee_audit;
