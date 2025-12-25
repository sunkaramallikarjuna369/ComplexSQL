-- ============================================
-- Performance Optimization Examples
-- Indexes, Query Tuning, Execution Plans
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- INDEX TYPES
-- ============================================

-- B-Tree Index (Default, most common)
CREATE INDEX idx_emp_lastname ON employees(last_name);

-- Unique Index
CREATE UNIQUE INDEX idx_emp_email ON employees(email);

-- Composite Index (multiple columns)
CREATE INDEX idx_emp_dept_salary ON employees(department_id, salary);

-- Covering Index (includes additional columns)
-- SQL Server
CREATE NONCLUSTERED INDEX idx_emp_dept_cover 
ON employees(department_id) 
INCLUDE (first_name, last_name, salary);

-- PostgreSQL
CREATE INDEX idx_emp_dept_cover 
ON employees(department_id) 
INCLUDE (first_name, last_name, salary);

-- Clustered Index (SQL Server)
CREATE CLUSTERED INDEX idx_emp_id ON employees(employee_id);

-- Partial/Filtered Index
-- PostgreSQL
CREATE INDEX idx_active_employees 
ON employees(employee_id) 
WHERE status = 'active';

-- SQL Server
CREATE NONCLUSTERED INDEX idx_active_employees 
ON employees(employee_id) 
WHERE status = 'active';

-- Expression/Functional Index
-- PostgreSQL
CREATE INDEX idx_emp_lower_email ON employees(LOWER(email));

-- Oracle
CREATE INDEX idx_emp_lower_email ON employees(LOWER(email));

-- Hash Index (PostgreSQL)
CREATE INDEX idx_emp_id_hash ON employees USING HASH (employee_id);

-- GIN Index for full-text search (PostgreSQL)
CREATE INDEX idx_products_search ON products USING GIN (to_tsvector('english', description));

-- ============================================
-- WHEN TO CREATE INDEXES
-- ============================================

-- Good candidates for indexing:
-- 1. Columns in WHERE clauses
-- 2. Columns in JOIN conditions
-- 3. Columns in ORDER BY
-- 4. Columns with high selectivity (many unique values)

-- Avoid indexing:
-- 1. Small tables
-- 2. Columns with low selectivity (few unique values)
-- 3. Frequently updated columns
-- 4. Columns rarely used in queries

-- ============================================
-- EXECUTION PLANS
-- ============================================

-- SQL Server
SET SHOWPLAN_ALL ON;
SELECT * FROM employees WHERE department_id = 10;
SET SHOWPLAN_ALL OFF;

-- SQL Server: Actual execution plan
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT * FROM employees WHERE department_id = 10;

-- PostgreSQL
EXPLAIN SELECT * FROM employees WHERE department_id = 10;
EXPLAIN ANALYZE SELECT * FROM employees WHERE department_id = 10;
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT * FROM employees WHERE department_id = 10;

-- MySQL
EXPLAIN SELECT * FROM employees WHERE department_id = 10;
EXPLAIN ANALYZE SELECT * FROM employees WHERE department_id = 10;

-- Oracle
EXPLAIN PLAN FOR SELECT * FROM employees WHERE department_id = 10;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- ============================================
-- QUERY OPTIMIZATION TIPS
-- ============================================

-- 1. Avoid SELECT *
-- Bad
SELECT * FROM employees WHERE department_id = 10;
-- Good
SELECT employee_id, first_name, last_name FROM employees WHERE department_id = 10;

-- 2. Avoid functions on indexed columns
-- Bad (can't use index)
SELECT * FROM employees WHERE YEAR(hire_date) = 2024;
-- Good (can use index)
SELECT * FROM employees WHERE hire_date >= '2024-01-01' AND hire_date < '2025-01-01';

-- 3. Use EXISTS instead of IN for large subqueries
-- Less efficient
SELECT * FROM customers 
WHERE customer_id IN (SELECT customer_id FROM orders);
-- More efficient
SELECT * FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);

-- 4. Avoid leading wildcards in LIKE
-- Bad (full table scan)
SELECT * FROM employees WHERE last_name LIKE '%son';
-- Good (can use index)
SELECT * FROM employees WHERE last_name LIKE 'John%';

-- 5. Use UNION ALL instead of UNION when possible
-- Slower (removes duplicates)
SELECT customer_id FROM orders_2023
UNION
SELECT customer_id FROM orders_2024;
-- Faster (keeps duplicates)
SELECT customer_id FROM orders_2023
UNION ALL
SELECT customer_id FROM orders_2024;

-- 6. Limit result sets
SELECT * FROM employees ORDER BY hire_date DESC LIMIT 100;

-- 7. Use appropriate JOINs
-- Avoid implicit joins
SELECT * FROM employees e, departments d WHERE e.department_id = d.department_id;
-- Use explicit joins
SELECT * FROM employees e JOIN departments d ON e.department_id = d.department_id;

-- ============================================
-- INDEX MAINTENANCE
-- ============================================

-- SQL Server: Rebuild fragmented indexes
ALTER INDEX idx_emp_lastname ON employees REBUILD;
ALTER INDEX ALL ON employees REBUILD;

-- SQL Server: Reorganize index (less intensive)
ALTER INDEX idx_emp_lastname ON employees REORGANIZE;

-- PostgreSQL: Reindex
REINDEX INDEX idx_emp_lastname;
REINDEX TABLE employees;

-- PostgreSQL: Vacuum and analyze
VACUUM ANALYZE employees;

-- Oracle: Rebuild index
ALTER INDEX idx_emp_lastname REBUILD;

-- MySQL: Optimize table
OPTIMIZE TABLE employees;
ANALYZE TABLE employees;

-- ============================================
-- STATISTICS
-- ============================================

-- SQL Server: Update statistics
UPDATE STATISTICS employees;
UPDATE STATISTICS employees idx_emp_lastname;

-- PostgreSQL: Analyze
ANALYZE employees;

-- Oracle: Gather statistics
EXEC DBMS_STATS.GATHER_TABLE_STATS('HR', 'EMPLOYEES');

-- MySQL: Analyze
ANALYZE TABLE employees;

-- ============================================
-- QUERY HINTS
-- ============================================

-- SQL Server
SELECT * FROM employees WITH (INDEX(idx_emp_dept)) WHERE department_id = 10;
SELECT * FROM employees WITH (NOLOCK) WHERE department_id = 10;
SELECT * FROM employees OPTION (MAXDOP 4);

-- PostgreSQL
SET enable_seqscan = off;  -- Force index usage
SELECT * FROM employees WHERE department_id = 10;
SET enable_seqscan = on;

-- Oracle
SELECT /*+ INDEX(e idx_emp_dept) */ * FROM employees e WHERE department_id = 10;
SELECT /*+ FULL(e) */ * FROM employees e WHERE department_id = 10;
SELECT /*+ PARALLEL(e, 4) */ * FROM employees e;

-- MySQL
SELECT * FROM employees USE INDEX (idx_emp_dept) WHERE department_id = 10;
SELECT * FROM employees FORCE INDEX (idx_emp_dept) WHERE department_id = 10;
SELECT * FROM employees IGNORE INDEX (idx_emp_dept) WHERE department_id = 10;

-- ============================================
-- PARTITIONING
-- ============================================

-- PostgreSQL: Range partitioning
CREATE TABLE orders (
    order_id INT,
    order_date DATE,
    customer_id INT,
    total_amount DECIMAL(10,2)
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2023 PARTITION OF orders
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
CREATE TABLE orders_2024 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- SQL Server: Range partitioning
CREATE PARTITION FUNCTION pf_order_date (DATE)
AS RANGE RIGHT FOR VALUES ('2023-01-01', '2024-01-01', '2025-01-01');

CREATE PARTITION SCHEME ps_order_date
AS PARTITION pf_order_date ALL TO ([PRIMARY]);

CREATE TABLE orders (
    order_id INT,
    order_date DATE,
    customer_id INT,
    total_amount DECIMAL(10,2)
) ON ps_order_date(order_date);

-- Oracle: Range partitioning
CREATE TABLE orders (
    order_id NUMBER,
    order_date DATE,
    customer_id NUMBER,
    total_amount NUMBER(10,2)
)
PARTITION BY RANGE (order_date) (
    PARTITION p_2023 VALUES LESS THAN (DATE '2024-01-01'),
    PARTITION p_2024 VALUES LESS THAN (DATE '2025-01-01'),
    PARTITION p_future VALUES LESS THAN (MAXVALUE)
);

-- ============================================
-- MONITORING QUERIES
-- ============================================

-- SQL Server: Find slow queries
SELECT TOP 10
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time,
    qs.execution_count,
    SUBSTRING(qt.text, qs.statement_start_offset/2 + 1,
        (CASE WHEN qs.statement_end_offset = -1 
              THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
              ELSE qs.statement_end_offset END - qs.statement_start_offset)/2 + 1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY avg_elapsed_time DESC;

-- PostgreSQL: Find slow queries
SELECT 
    query,
    calls,
    total_exec_time / calls AS avg_time,
    rows / calls AS avg_rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- MySQL: Find slow queries
SELECT * FROM mysql.slow_log ORDER BY query_time DESC LIMIT 10;
