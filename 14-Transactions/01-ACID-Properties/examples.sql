-- ============================================
-- Transactions and ACID Properties Examples
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- ACID Properties
-- ============================================

-- A - Atomicity: All or nothing
-- C - Consistency: Valid state to valid state
-- I - Isolation: Transactions don't interfere
-- D - Durability: Committed changes are permanent

-- ============================================
-- Basic Transaction Control
-- ============================================

-- SQL Server
BEGIN TRANSACTION;
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
COMMIT TRANSACTION;

-- Oracle (implicit transaction start)
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
COMMIT;

-- PostgreSQL
BEGIN;
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
COMMIT;

-- MySQL
START TRANSACTION;
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
COMMIT;

-- ============================================
-- ROLLBACK
-- ============================================

-- SQL Server
BEGIN TRANSACTION;
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    -- Something went wrong
ROLLBACK TRANSACTION;

-- PostgreSQL
BEGIN;
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    -- Check condition
    IF (SELECT balance FROM accounts WHERE account_id = 1) < 0 THEN
        ROLLBACK;
    ELSE
        COMMIT;
    END IF;

-- ============================================
-- SAVEPOINT
-- ============================================

-- SQL Server
BEGIN TRANSACTION;
    INSERT INTO orders (order_id, customer_id) VALUES (1, 100);
    SAVE TRANSACTION sp_after_order;
    
    INSERT INTO order_items (order_id, product_id) VALUES (1, 10);
    INSERT INTO order_items (order_id, product_id) VALUES (1, 20);
    SAVE TRANSACTION sp_after_items;
    
    -- Oops, wrong items
    ROLLBACK TRANSACTION sp_after_order;
    
    -- Add correct items
    INSERT INTO order_items (order_id, product_id) VALUES (1, 30);
COMMIT TRANSACTION;

-- PostgreSQL
BEGIN;
    INSERT INTO orders (order_id, customer_id) VALUES (1, 100);
    SAVEPOINT sp_after_order;
    
    INSERT INTO order_items (order_id, product_id) VALUES (1, 10);
    SAVEPOINT sp_after_first_item;
    
    -- This might fail
    INSERT INTO order_items (order_id, product_id) VALUES (1, 999);
    
    -- Rollback to savepoint on error
    ROLLBACK TO SAVEPOINT sp_after_first_item;
    
    -- Continue with valid data
    INSERT INTO order_items (order_id, product_id) VALUES (1, 20);
COMMIT;

-- Oracle
INSERT INTO orders (order_id, customer_id) VALUES (1, 100);
SAVEPOINT sp_after_order;

INSERT INTO order_items (order_id, product_id) VALUES (1, 10);
SAVEPOINT sp_after_items;

-- Rollback to savepoint
ROLLBACK TO sp_after_order;

-- Continue
INSERT INTO order_items (order_id, product_id) VALUES (1, 30);
COMMIT;

-- MySQL
START TRANSACTION;
    INSERT INTO orders (order_id, customer_id) VALUES (1, 100);
    SAVEPOINT sp_after_order;
    
    INSERT INTO order_items (order_id, product_id) VALUES (1, 10);
    
    -- Rollback to savepoint
    ROLLBACK TO SAVEPOINT sp_after_order;
    
    -- Release savepoint (optional)
    RELEASE SAVEPOINT sp_after_order;
COMMIT;

-- ============================================
-- ISOLATION LEVELS
-- ============================================

-- READ UNCOMMITTED (Dirty reads allowed)
-- SQL Server
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM accounts;  -- Can see uncommitted changes
COMMIT;

-- READ COMMITTED (Default for most RDBMS)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM accounts;  -- Only sees committed data
COMMIT;

-- REPEATABLE READ (Same query returns same results)
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT * FROM accounts WHERE account_id = 1;  -- First read
    -- Other transactions can't modify this row
    SELECT * FROM accounts WHERE account_id = 1;  -- Same result
COMMIT;

-- SERIALIZABLE (Highest isolation, prevents phantom reads)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    SELECT * FROM accounts WHERE balance > 1000;
    -- Other transactions can't insert rows matching this condition
COMMIT;

-- PostgreSQL: Set isolation level
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    -- Transaction code
COMMIT;

-- MySQL: Set isolation level
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;
    -- Transaction code
COMMIT;

-- ============================================
-- Error Handling in Transactions
-- ============================================

-- SQL Server: TRY-CATCH
BEGIN TRY
    BEGIN TRANSACTION;
        UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
        
        -- Check for negative balance
        IF (SELECT balance FROM accounts WHERE account_id = 1) < 0
            THROW 50001, 'Insufficient funds', 1;
        
        UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    -- Log error
    INSERT INTO error_log (error_message, error_date)
    VALUES (ERROR_MESSAGE(), GETDATE());
    
    THROW;
END CATCH;

-- PostgreSQL: Exception handling
DO $$
BEGIN
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    
    IF (SELECT balance FROM accounts WHERE account_id = 1) < 0 THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;
    
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        INSERT INTO error_log (error_message, error_date)
        VALUES (SQLERRM, CURRENT_TIMESTAMP);
        RAISE;
END $$;

-- Oracle: Exception handling
BEGIN
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        INSERT INTO error_log (error_message, error_date)
        VALUES (SQLERRM, SYSDATE);
        RAISE;
END;

-- ============================================
-- Practical Transaction Examples
-- ============================================

-- Bank Transfer Procedure (SQL Server)
CREATE PROCEDURE sp_transfer_funds
    @from_account INT,
    @to_account INT,
    @amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Lock accounts in consistent order to prevent deadlocks
        DECLARE @from_balance DECIMAL(10,2), @to_balance DECIMAL(10,2);
        
        SELECT @from_balance = balance 
        FROM accounts WITH (UPDLOCK) 
        WHERE account_id = @from_account;
        
        IF @from_balance IS NULL
            THROW 50001, 'Source account not found', 1;
        
        IF @from_balance < @amount
            THROW 50002, 'Insufficient funds', 1;
        
        SELECT @to_balance = balance 
        FROM accounts WITH (UPDLOCK) 
        WHERE account_id = @to_account;
        
        IF @to_balance IS NULL
            THROW 50003, 'Destination account not found', 1;
        
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

-- Order Processing (PostgreSQL)
CREATE OR REPLACE FUNCTION process_order(
    p_customer_id INT,
    p_items JSONB
) RETURNS INT AS $$
DECLARE
    v_order_id INT;
    v_item JSONB;
    v_product_id INT;
    v_quantity INT;
    v_price DECIMAL(10,2);
    v_stock INT;
BEGIN
    -- Create order
    INSERT INTO orders (customer_id, order_date, status)
    VALUES (p_customer_id, CURRENT_DATE, 'pending')
    RETURNING order_id INTO v_order_id;
    
    -- Process each item
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::INT;
        v_quantity := (v_item->>'quantity')::INT;
        
        -- Check and update stock
        SELECT stock_quantity, price INTO v_stock, v_price
        FROM products
        WHERE product_id = v_product_id
        FOR UPDATE;
        
        IF v_stock < v_quantity THEN
            RAISE EXCEPTION 'Insufficient stock for product %', v_product_id;
        END IF;
        
        UPDATE products 
        SET stock_quantity = stock_quantity - v_quantity
        WHERE product_id = v_product_id;
        
        -- Add order item
        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES (v_order_id, v_product_id, v_quantity, v_price);
    END LOOP;
    
    -- Update order status
    UPDATE orders SET status = 'confirmed' WHERE order_id = v_order_id;
    
    RETURN v_order_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Deadlock Prevention
-- ============================================

-- Always access tables/rows in the same order
-- Use appropriate isolation levels
-- Keep transactions short
-- Use lock hints when necessary (SQL Server)

-- SQL Server: Lock hints
SELECT * FROM accounts WITH (NOLOCK);  -- Read uncommitted
SELECT * FROM accounts WITH (UPDLOCK); -- Update lock
SELECT * FROM accounts WITH (XLOCK);   -- Exclusive lock
SELECT * FROM accounts WITH (ROWLOCK); -- Row-level lock
SELECT * FROM accounts WITH (TABLOCK); -- Table-level lock
