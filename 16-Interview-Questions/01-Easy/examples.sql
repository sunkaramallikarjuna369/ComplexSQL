-- ============================================
-- SQL Interview Questions - Easy Level
-- HackerRank / LeetCode Style
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Problem 1: Second Highest Salary
-- ============================================

-- Find the second highest salary from the employees table
-- Return NULL if there is no second highest salary

-- Solution 1: Using LIMIT/OFFSET
SELECT DISTINCT salary AS SecondHighestSalary
FROM employees
ORDER BY salary DESC
LIMIT 1 OFFSET 1;

-- Solution 2: Using subquery
SELECT MAX(salary) AS SecondHighestSalary
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- Solution 3: Using DENSE_RANK
SELECT salary AS SecondHighestSalary
FROM (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rank
    FROM employees
) ranked
WHERE rank = 2;

-- Solution 4: Handle NULL case
SELECT (
    SELECT DISTINCT salary
    FROM employees
    ORDER BY salary DESC
    LIMIT 1 OFFSET 1
) AS SecondHighestSalary;

-- ============================================
-- Problem 2: Duplicate Emails
-- ============================================

-- Find all duplicate emails in a table

CREATE TABLE Person (id INT, email VARCHAR(100));

-- Solution 1: Using GROUP BY and HAVING
SELECT email
FROM Person
GROUP BY email
HAVING COUNT(*) > 1;

-- Solution 2: Using self-join
SELECT DISTINCT p1.email
FROM Person p1
JOIN Person p2 ON p1.email = p2.email AND p1.id <> p2.id;

-- ============================================
-- Problem 3: Customers Who Never Order
-- ============================================

-- Find all customers who never placed an order

CREATE TABLE Customers (id INT, name VARCHAR(100));
CREATE TABLE Orders (id INT, customerId INT);

-- Solution 1: Using LEFT JOIN
SELECT c.name AS Customers
FROM Customers c
LEFT JOIN Orders o ON c.id = o.customerId
WHERE o.id IS NULL;

-- Solution 2: Using NOT IN
SELECT name AS Customers
FROM Customers
WHERE id NOT IN (SELECT customerId FROM Orders WHERE customerId IS NOT NULL);

-- Solution 3: Using NOT EXISTS
SELECT name AS Customers
FROM Customers c
WHERE NOT EXISTS (SELECT 1 FROM Orders o WHERE o.customerId = c.id);

-- ============================================
-- Problem 4: Delete Duplicate Emails
-- ============================================

-- Delete all duplicate emails, keeping only the one with smallest id

-- Solution 1: Using self-join
DELETE p1
FROM Person p1
JOIN Person p2 ON p1.email = p2.email AND p1.id > p2.id;

-- Solution 2: Using NOT IN with subquery
DELETE FROM Person
WHERE id NOT IN (
    SELECT * FROM (
        SELECT MIN(id) FROM Person GROUP BY email
    ) AS temp
);

-- Solution 3: Using ROW_NUMBER (SQL Server/PostgreSQL)
WITH duplicates AS (
    SELECT id, ROW_NUMBER() OVER (PARTITION BY email ORDER BY id) AS rn
    FROM Person
)
DELETE FROM Person WHERE id IN (SELECT id FROM duplicates WHERE rn > 1);

-- ============================================
-- Problem 5: Rising Temperature
-- ============================================

-- Find all dates' IDs with higher temperatures compared to previous dates

CREATE TABLE Weather (id INT, recordDate DATE, temperature INT);

-- Solution 1: Using self-join
SELECT w1.id
FROM Weather w1
JOIN Weather w2 ON w1.recordDate = w2.recordDate + INTERVAL '1 day'
WHERE w1.temperature > w2.temperature;

-- Solution 2: Using LAG
SELECT id
FROM (
    SELECT 
        id,
        temperature,
        LAG(temperature) OVER (ORDER BY recordDate) AS prev_temp
    FROM Weather
) w
WHERE temperature > prev_temp;

-- ============================================
-- Problem 6: Employees Earning More Than Managers
-- ============================================

-- Find employees who earn more than their managers

CREATE TABLE Employee (id INT, name VARCHAR(100), salary INT, managerId INT);

-- Solution: Self-join
SELECT e.name AS Employee
FROM Employee e
JOIN Employee m ON e.managerId = m.id
WHERE e.salary > m.salary;

-- ============================================
-- Problem 7: Combine Two Tables
-- ============================================

-- Report firstName, lastName, city, state for each person

CREATE TABLE Person2 (personId INT, firstName VARCHAR(100), lastName VARCHAR(100));
CREATE TABLE Address (addressId INT, personId INT, city VARCHAR(100), state VARCHAR(100));

-- Solution: LEFT JOIN
SELECT p.firstName, p.lastName, a.city, a.state
FROM Person2 p
LEFT JOIN Address a ON p.personId = a.personId;

-- ============================================
-- Problem 8: Big Countries
-- ============================================

-- Find countries with area >= 3000000 OR population >= 25000000

CREATE TABLE World (name VARCHAR(100), continent VARCHAR(100), area INT, population BIGINT, gdp BIGINT);

-- Solution 1: Using OR
SELECT name, population, area
FROM World
WHERE area >= 3000000 OR population >= 25000000;

-- Solution 2: Using UNION
SELECT name, population, area FROM World WHERE area >= 3000000
UNION
SELECT name, population, area FROM World WHERE population >= 25000000;

-- ============================================
-- Problem 9: Classes More Than 5 Students
-- ============================================

-- Find all classes with at least 5 students

CREATE TABLE Courses (student VARCHAR(100), class VARCHAR(100));

-- Solution
SELECT class
FROM Courses
GROUP BY class
HAVING COUNT(DISTINCT student) >= 5;

-- ============================================
-- Problem 10: Not Boring Movies
-- ============================================

-- Find movies with odd ID and description not "boring", ordered by rating DESC

CREATE TABLE Cinema (id INT, movie VARCHAR(100), description VARCHAR(100), rating DECIMAL(3,1));

-- Solution
SELECT *
FROM Cinema
WHERE id % 2 = 1 AND description <> 'boring'
ORDER BY rating DESC;

-- ============================================
-- Problem 11: Swap Salary
-- ============================================

-- Swap all 'f' and 'm' values in sex column with single UPDATE

CREATE TABLE Salary (id INT, name VARCHAR(100), sex CHAR(1), salary INT);

-- Solution 1: Using CASE
UPDATE Salary
SET sex = CASE sex WHEN 'm' THEN 'f' ELSE 'm' END;

-- Solution 2: Using IF (MySQL)
UPDATE Salary SET sex = IF(sex = 'm', 'f', 'm');

-- ============================================
-- Problem 12: Recyclable and Low Fat Products
-- ============================================

-- Find products that are both low fat and recyclable

CREATE TABLE Products (product_id INT, low_fats CHAR(1), recyclable CHAR(1));

-- Solution
SELECT product_id
FROM Products
WHERE low_fats = 'Y' AND recyclable = 'Y';

-- ============================================
-- Problem 13: Find Customer Referee
-- ============================================

-- Find customers not referred by customer with id = 2

CREATE TABLE Customer (id INT, name VARCHAR(100), referee_id INT);

-- Solution (handle NULL)
SELECT name
FROM Customer
WHERE referee_id <> 2 OR referee_id IS NULL;

-- ============================================
-- Problem 14: Article Views
-- ============================================

-- Find all authors that viewed at least one of their own articles

CREATE TABLE Views (article_id INT, author_id INT, viewer_id INT, view_date DATE);

-- Solution
SELECT DISTINCT author_id AS id
FROM Views
WHERE author_id = viewer_id
ORDER BY id;

-- ============================================
-- Problem 15: Invalid Tweets
-- ============================================

-- Find IDs of invalid tweets (content > 15 characters)

CREATE TABLE Tweets (tweet_id INT, content VARCHAR(500));

-- Solution
SELECT tweet_id
FROM Tweets
WHERE LENGTH(content) > 15;
