-- ============================================
-- TCL (Transaction Control Language) Examples
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Basic Transaction Control
-- ============================================

-- SQL Server: Basic transaction
BEGIN TRANSACTION;

UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;

COMMIT TRANSACTION;

-- SQL Server: With rollback on error
BEGIN TRANSACTION;

BEGIN TRY
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- Oracle: Transaction (implicit start)
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
COMMIT;

-- Oracle: With exception handling
BEGIN
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

-- PostgreSQL: Basic transaction
BEGIN;

UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;

COMMIT;

-- PostgreSQL: With exception handling in function
CREATE OR REPLACE FUNCTION transfer_funds(
    from_account INT,
    to_account INT,
    amount DECIMAL
) RETURNS VOID AS $$
BEGIN
    UPDATE accounts SET balance = balance - amount WHERE account_id = from_account;
    UPDATE accounts SET balance = balance + amount WHERE account_id = to_account;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$ LANGUAGE plpgsql;

-- MySQL: Basic transaction
START TRANSACTION;

UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;

COMMIT;

-- MySQL: Disable autocommit
SET autocommit = 0;

UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;

COMMIT;

SET autocommit = 1;

-- ============================================
-- SAVEPOINT - Partial Rollback
-- ============================================

-- SQL Server: Savepoints
BEGIN TRANSACTION;

INSERT INTO orders (order_id, customer_id, total) VALUES (1, 100, 500);
SAVE TRANSACTION sp_after_order;

INSERT INTO order_items (order_id, product_id, qty) VALUES (1, 10, 2);
INSERT INTO order_items (order_id, product_id, qty) VALUES (1, 20, 1);
SAVE TRANSACTION sp_after_items;

-- Oops, need to undo items but keep order
ROLLBACK TRANSACTION sp_after_order;

-- Add correct items
INSERT INTO order_items (order_id, product_id, qty) VALUES (1, 30, 3);

COMMIT TRANSACTION;

-- Oracle: Savepoints
INSERT INTO orders (order_id, customer_id, total) VALUES (1, 100, 500);
SAVEPOINT sp_after_order;

INSERT INTO order_items (order_id, product_id, qty) VALUES (1, 10, 2);
SAVEPOINT sp_after_first_item;

INSERT INTO order_items (order_id, product_id, qty) VALUES (1, 20, 1);

-- Rollback to savepoint
ROLLBACK TO sp_after_first_item;

-- Continue with different item
INSERT INTO order_items (order_id, product_id, qty) VALUES (1, 30, 3);

COMMIT;

-- PostgreSQL: Savepoints
BEGIN;

INSERT INTO orders (order_id, customer_id, total) VALUES (1, 100, 500);
SAVEPOINT sp_after_order;

INSERT INTO order_items (order_id, product_id, qty) VALUES (1, 10, 2);
SAVEPOINT sp_after_first_item;

-- This might fail
INSERT INTO order_items (order_id, product_id, qty) VALUES (1, 999, 1);

-- If error, rollback to savepoint
ROLLBACK TO SAVEPOINT sp_after_first_item;

-- Continue
INSERT INTO order_items (order_id, product_id, qty) VALUES (1, 20, 1);

COMMIT;

-- MySQL: Savepoints
START TRANSACTION;

INSERT INTO orders (order_id, customer_id, total) VALUES (1, 100, 500);
SAVEPOINT sp_after_order;

INSERT INTO order_items (order_id, product_id, qty) VALUES (1, 10, 2);
SAVEPOINT sp_after_items;

-- Rollback to savepoint
ROLLBACK TO SAVEPOINT sp_after_order;

-- Release savepoint (optional)
RELEASE SAVEPOINT sp_after_order;

COMMIT;

-- ============================================
-- ISOLATION LEVELS
-- ============================================

-- SQL Server: Set isolation level
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

-- SQL Server: Per-query hint
SELECT * FROM employees WITH (NOLOCK);  -- READ UNCOMMITTED
SELECT * FROM employees WITH (READCOMMITTED);
SELECT * FROM employees WITH (REPEATABLEREAD);
SELECT * FROM employees WITH (SERIALIZABLE);

-- Oracle: Set isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Oracle: Read-only transaction
SET TRANSACTION READ ONLY;

-- PostgreSQL: Set isolation level
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- PostgreSQL: Set for session
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- MySQL: Set isolation level
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- MySQL: Set for session
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- MySQL: Set globally
SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- ============================================
-- Practical Transaction Examples
-- ============================================

-- Example 1: Bank Transfer (SQL Server)
CREATE PROCEDURE sp_transfer_funds
    @from_account INT,
    @to_account INT,
    @amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check sufficient balance
        DECLARE @balance DECIMAL(10,2);
        SELECT @balance = balance FROM accounts WHERE account_id = @from_account;
        
        IF @balance < @amount
        BEGIN
            RAISERROR('Insufficient funds', 16, 1);
            RETURN;
        END
        
        -- Perform transfer
        UPDATE accounts SET balance = balance - @amount WHERE account_id = @from_account;
        UPDATE accounts SET balance = balance + @amount WHERE account_id = @to_account;
        
        -- Log transaction
        INSERT INTO transaction_log (from_account, to_account, amount, transaction_date)
        VALUES (@from_account, @to_account, @amount, GETDATE());
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;

-- Example 2: Order Processing (PostgreSQL)
CREATE OR REPLACE FUNCTION process_order(
    p_customer_id INT,
    p_product_ids INT[],
    p_quantities INT[]
) RETURNS INT AS $$
DECLARE
    v_order_id INT;
    v_product_id INT;
    v_quantity INT;
    v_price DECIMAL(10,2);
    v_total DECIMAL(10,2) := 0;
    i INT;
BEGIN
    -- Create order
    INSERT INTO orders (customer_id, order_date, status)
    VALUES (p_customer_id, CURRENT_DATE, 'pending')
    RETURNING order_id INTO v_order_id;
    
    -- Process each item
    FOR i IN 1..array_length(p_product_ids, 1) LOOP
        v_product_id := p_product_ids[i];
        v_quantity := p_quantities[i];
        
        -- Get price and check stock
        SELECT price INTO v_price FROM products WHERE product_id = v_product_id;
        
        -- Update inventory
        UPDATE inventory 
        SET quantity = quantity - v_quantity 
        WHERE product_id = v_product_id AND quantity >= v_quantity;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Insufficient stock for product %', v_product_id;
        END IF;
        
        -- Add order item
        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES (v_order_id, v_product_id, v_quantity, v_price);
        
        v_total := v_total + (v_price * v_quantity);
    END LOOP;
    
    -- Update order total
    UPDATE orders SET total_amount = v_total WHERE order_id = v_order_id;
    
    RETURN v_order_id;
END;
$$ LANGUAGE plpgsql;

-- Example 3: Batch Update with Progress (MySQL)
DELIMITER //
CREATE PROCEDURE sp_batch_salary_update(
    IN p_department_id INT,
    IN p_increase_pct DECIMAL(5,2)
)
BEGIN
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_total INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Get count for logging
    SELECT COUNT(*) INTO v_total 
    FROM employees 
    WHERE department_id = p_department_id;
    
    -- Update salaries
    UPDATE employees 
    SET salary = salary * (1 + p_increase_pct / 100)
    WHERE department_id = p_department_id;
    
    SET v_count = ROW_COUNT();
    
    -- Log the batch update
    INSERT INTO salary_update_log (department_id, employees_updated, increase_pct, update_date)
    VALUES (p_department_id, v_count, p_increase_pct, NOW());
    
    COMMIT;
    
    SELECT CONCAT('Updated ', v_count, ' of ', v_total, ' employees') AS result;
END //
DELIMITER ;
