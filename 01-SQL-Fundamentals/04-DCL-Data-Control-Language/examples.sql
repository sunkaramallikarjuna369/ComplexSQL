-- ============================================
-- DCL (Data Control Language) Examples
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- GRANT - Giving Permissions
-- ============================================

-- Grant SELECT permission on a table
GRANT SELECT ON employees TO user1;

-- Grant multiple permissions
GRANT SELECT, INSERT, UPDATE ON employees TO user1;

-- Grant all permissions on a table
GRANT ALL PRIVILEGES ON employees TO user1;

-- Grant with ability to grant to others
GRANT SELECT ON employees TO user1 WITH GRANT OPTION;

-- Grant to multiple users
GRANT SELECT ON employees TO user1, user2, user3;

-- Grant to PUBLIC (all users)
GRANT SELECT ON employees TO PUBLIC;

-- ============================================
-- SQL Server Specific GRANT
-- ============================================

-- Grant on schema
GRANT SELECT ON SCHEMA::hr TO user1;

-- Grant execute on stored procedure
GRANT EXECUTE ON sp_GetEmployees TO user1;

-- Grant on database
USE master;
GRANT CREATE DATABASE TO user1;

-- Grant server-level permission
GRANT VIEW SERVER STATE TO user1;

-- Grant role membership
ALTER ROLE db_datareader ADD MEMBER user1;

-- ============================================
-- Oracle Specific GRANT
-- ============================================

-- Grant system privileges
GRANT CREATE SESSION TO user1;
GRANT CREATE TABLE TO user1;
GRANT CREATE VIEW TO user1;
GRANT CREATE PROCEDURE TO user1;

-- Grant with admin option (can grant to others)
GRANT CREATE SESSION TO user1 WITH ADMIN OPTION;

-- Grant role to user
GRANT dba TO user1;
GRANT connect, resource TO user1;

-- Grant on directory (for external tables)
GRANT READ, WRITE ON DIRECTORY data_dir TO user1;

-- Grant execute on package
GRANT EXECUTE ON hr.emp_pkg TO user1;

-- ============================================
-- PostgreSQL Specific GRANT
-- ============================================

-- Grant on schema
GRANT USAGE ON SCHEMA hr TO user1;
GRANT ALL ON SCHEMA hr TO user1;

-- Grant on all tables in schema
GRANT SELECT ON ALL TABLES IN SCHEMA hr TO user1;

-- Grant on sequence
GRANT USAGE, SELECT ON SEQUENCE emp_seq TO user1;

-- Grant on function
GRANT EXECUTE ON FUNCTION get_employee(INT) TO user1;

-- Grant role membership
GRANT role_readonly TO user1;

-- Default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA hr
GRANT SELECT ON TABLES TO user1;

-- ============================================
-- MySQL Specific GRANT
-- ============================================

-- Grant on database
GRANT ALL PRIVILEGES ON hr.* TO 'user1'@'localhost';

-- Grant on specific table
GRANT SELECT, INSERT ON hr.employees TO 'user1'@'%';

-- Grant with password (MySQL 5.7 and earlier)
GRANT ALL PRIVILEGES ON hr.* TO 'user1'@'localhost' IDENTIFIED BY 'password';

-- Grant execute on procedure
GRANT EXECUTE ON PROCEDURE hr.sp_get_employees TO 'user1'@'localhost';

-- Grant proxy user
GRANT PROXY ON 'admin'@'localhost' TO 'user1'@'localhost';

-- Show grants
SHOW GRANTS FOR 'user1'@'localhost';

-- ============================================
-- REVOKE - Removing Permissions
-- ============================================

-- Revoke SELECT permission
REVOKE SELECT ON employees FROM user1;

-- Revoke multiple permissions
REVOKE SELECT, INSERT, UPDATE ON employees FROM user1;

-- Revoke all permissions
REVOKE ALL PRIVILEGES ON employees FROM user1;

-- Revoke from PUBLIC
REVOKE SELECT ON employees FROM PUBLIC;

-- ============================================
-- SQL Server Specific REVOKE
-- ============================================

-- Revoke with CASCADE (also revokes from users who got it via WITH GRANT OPTION)
REVOKE SELECT ON employees FROM user1 CASCADE;

-- Revoke role membership
ALTER ROLE db_datareader DROP MEMBER user1;

-- Deny permission (stronger than revoke)
DENY SELECT ON employees TO user1;

-- ============================================
-- Oracle Specific REVOKE
-- ============================================

-- Revoke system privilege
REVOKE CREATE SESSION FROM user1;
REVOKE CREATE TABLE FROM user1;

-- Revoke role
REVOKE dba FROM user1;

-- Revoke with cascade (for object privileges granted with GRANT OPTION)
REVOKE SELECT ON employees FROM user1 CASCADE CONSTRAINTS;

-- ============================================
-- PostgreSQL Specific REVOKE
-- ============================================

-- Revoke on schema
REVOKE ALL ON SCHEMA hr FROM user1;

-- Revoke on all tables
REVOKE ALL ON ALL TABLES IN SCHEMA hr FROM user1;

-- Revoke role membership
REVOKE role_readonly FROM user1;

-- Revoke default privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA hr
REVOKE SELECT ON TABLES FROM user1;

-- ============================================
-- MySQL Specific REVOKE
-- ============================================

-- Revoke all privileges
REVOKE ALL PRIVILEGES ON hr.* FROM 'user1'@'localhost';

-- Revoke specific privileges
REVOKE INSERT, UPDATE ON hr.employees FROM 'user1'@'%';

-- Flush privileges (apply changes)
FLUSH PRIVILEGES;

-- ============================================
-- Creating Users and Roles
-- ============================================

-- SQL Server: Create login and user
CREATE LOGIN user1 WITH PASSWORD = 'SecurePassword123!';
CREATE USER user1 FOR LOGIN user1;

-- SQL Server: Create role
CREATE ROLE role_readonly;
GRANT SELECT ON SCHEMA::dbo TO role_readonly;
ALTER ROLE role_readonly ADD MEMBER user1;

-- Oracle: Create user
CREATE USER user1 IDENTIFIED BY password;
GRANT CREATE SESSION TO user1;

-- Oracle: Create role
CREATE ROLE role_readonly;
GRANT SELECT ON hr.employees TO role_readonly;
GRANT role_readonly TO user1;

-- PostgreSQL: Create user/role
CREATE USER user1 WITH PASSWORD 'password';
CREATE ROLE role_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO role_readonly;
GRANT role_readonly TO user1;

-- MySQL: Create user
CREATE USER 'user1'@'localhost' IDENTIFIED BY 'password';
CREATE USER 'user1'@'%' IDENTIFIED BY 'password';

-- MySQL: Create role (MySQL 8.0+)
CREATE ROLE 'role_readonly';
GRANT SELECT ON hr.* TO 'role_readonly';
GRANT 'role_readonly' TO 'user1'@'localhost';
SET DEFAULT ROLE 'role_readonly' TO 'user1'@'localhost';

-- ============================================
-- Dropping Users and Roles
-- ============================================

-- SQL Server
DROP USER user1;
DROP LOGIN user1;
DROP ROLE role_readonly;

-- Oracle
DROP USER user1 CASCADE;
DROP ROLE role_readonly;

-- PostgreSQL
DROP USER user1;
DROP ROLE role_readonly;

-- MySQL
DROP USER 'user1'@'localhost';
DROP ROLE 'role_readonly';
