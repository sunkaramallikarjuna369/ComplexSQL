-- ============================================
-- SQL Interview Questions - Medium Level
-- HackerRank / LeetCode Style
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Problem 1: Nth Highest Salary
-- ============================================

-- Write a function to get the Nth highest salary

-- Solution 1: Using DENSE_RANK
CREATE FUNCTION getNthHighestSalary(N INT) RETURNS INT
BEGIN
    RETURN (
        SELECT DISTINCT salary
        FROM (
            SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rank
            FROM Employee
        ) ranked
        WHERE rank = N
    );
END;

-- Solution 2: Using LIMIT/OFFSET
SELECT DISTINCT salary AS NthHighestSalary
FROM Employee
ORDER BY salary DESC
LIMIT 1 OFFSET N-1;

-- Solution 3: Using subquery
SELECT DISTINCT salary AS NthHighestSalary
FROM Employee e1
WHERE N-1 = (
    SELECT COUNT(DISTINCT salary)
    FROM Employee e2
    WHERE e2.salary > e1.salary
);

-- ============================================
-- Problem 2: Department Top Three Salaries
-- ============================================

-- Find employees who earn top 3 salaries in each department

CREATE TABLE Employee2 (id INT, name VARCHAR(100), salary INT, departmentId INT);
CREATE TABLE Department (id INT, name VARCHAR(100));

-- Solution using DENSE_RANK
SELECT d.name AS Department, e.name AS Employee, e.salary AS Salary
FROM (
    SELECT 
        name, 
        salary, 
        departmentId,
        DENSE_RANK() OVER (PARTITION BY departmentId ORDER BY salary DESC) AS rank
    FROM Employee2
) e
JOIN Department d ON e.departmentId = d.id
WHERE e.rank <= 3;

-- ============================================
-- Problem 3: Consecutive Numbers
-- ============================================

-- Find all numbers that appear at least 3 times consecutively

CREATE TABLE Logs (id INT, num INT);

-- Solution 1: Using self-join
SELECT DISTINCT l1.num AS ConsecutiveNums
FROM Logs l1
JOIN Logs l2 ON l1.id = l2.id - 1
JOIN Logs l3 ON l2.id = l3.id - 1
WHERE l1.num = l2.num AND l2.num = l3.num;

-- Solution 2: Using LAG/LEAD
SELECT DISTINCT num AS ConsecutiveNums
FROM (
    SELECT 
        num,
        LAG(num, 1) OVER (ORDER BY id) AS prev1,
        LAG(num, 2) OVER (ORDER BY id) AS prev2
    FROM Logs
) t
WHERE num = prev1 AND num = prev2;

-- ============================================
-- Problem 4: Rank Scores
-- ============================================

-- Rank scores with no gaps in ranking

CREATE TABLE Scores (id INT, score DECIMAL(5,2));

-- Solution
SELECT 
    score,
    DENSE_RANK() OVER (ORDER BY score DESC) AS rank
FROM Scores
ORDER BY score DESC;

-- ============================================
-- Problem 5: Department Highest Salary
-- ============================================

-- Find employees with highest salary in each department

-- Solution 1: Using window function
SELECT Department, Employee, Salary
FROM (
    SELECT 
        d.name AS Department,
        e.name AS Employee,
        e.salary AS Salary,
        RANK() OVER (PARTITION BY e.departmentId ORDER BY e.salary DESC) AS rk
    FROM Employee2 e
    JOIN Department d ON e.departmentId = d.id
) ranked
WHERE rk = 1;

-- Solution 2: Using subquery
SELECT d.name AS Department, e.name AS Employee, e.salary AS Salary
FROM Employee2 e
JOIN Department d ON e.departmentId = d.id
WHERE (e.departmentId, e.salary) IN (
    SELECT departmentId, MAX(salary)
    FROM Employee2
    GROUP BY departmentId
);

-- ============================================
-- Problem 6: Exchange Seats
-- ============================================

-- Swap adjacent students' seats (1<->2, 3<->4, etc.)

CREATE TABLE Seat (id INT, student VARCHAR(100));

-- Solution
SELECT 
    CASE 
        WHEN id % 2 = 1 AND id = (SELECT MAX(id) FROM Seat) THEN id
        WHEN id % 2 = 1 THEN id + 1
        ELSE id - 1
    END AS id,
    student
FROM Seat
ORDER BY id;

-- ============================================
-- Problem 7: Tree Node
-- ============================================

-- Identify node type: Root, Inner, or Leaf

CREATE TABLE Tree (id INT, p_id INT);

-- Solution
SELECT 
    id,
    CASE 
        WHEN p_id IS NULL THEN 'Root'
        WHEN id IN (SELECT DISTINCT p_id FROM Tree WHERE p_id IS NOT NULL) THEN 'Inner'
        ELSE 'Leaf'
    END AS type
FROM Tree
ORDER BY id;

-- ============================================
-- Problem 8: Managers with 5+ Direct Reports
-- ============================================

-- Find managers with at least 5 direct reports

-- Solution
SELECT e.name
FROM Employee2 e
WHERE e.id IN (
    SELECT managerId
    FROM Employee2
    GROUP BY managerId
    HAVING COUNT(*) >= 5
);

-- ============================================
-- Problem 9: Winning Candidate
-- ============================================

-- Find the candidate who won the election

CREATE TABLE Candidate (id INT, name VARCHAR(100));
CREATE TABLE Vote (id INT, candidateId INT);

-- Solution
SELECT c.name
FROM Candidate c
WHERE c.id = (
    SELECT candidateId
    FROM Vote
    GROUP BY candidateId
    ORDER BY COUNT(*) DESC
    LIMIT 1
);

-- ============================================
-- Problem 10: Count Student Number in Departments
-- ============================================

-- Count students in each department, including departments with 0 students

CREATE TABLE Student (student_id INT, student_name VARCHAR(100), dept_id INT);
CREATE TABLE Department2 (dept_id INT, dept_name VARCHAR(100));

-- Solution
SELECT d.dept_name, COUNT(s.student_id) AS student_number
FROM Department2 d
LEFT JOIN Student s ON d.dept_id = s.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY student_number DESC, d.dept_name;

-- ============================================
-- Problem 11: Investments in 2016
-- ============================================

-- Find sum of TIV_2016 for policyholders who:
-- 1. Have same TIV_2015 as at least one other policyholder
-- 2. Are in a unique city (lat, lon)

CREATE TABLE Insurance (pid INT, tiv_2015 DECIMAL(10,2), tiv_2016 DECIMAL(10,2), lat DECIMAL(10,2), lon DECIMAL(10,2));

-- Solution
SELECT ROUND(SUM(tiv_2016), 2) AS tiv_2016
FROM Insurance
WHERE tiv_2015 IN (
    SELECT tiv_2015 FROM Insurance GROUP BY tiv_2015 HAVING COUNT(*) > 1
)
AND (lat, lon) IN (
    SELECT lat, lon FROM Insurance GROUP BY lat, lon HAVING COUNT(*) = 1
);

-- ============================================
-- Problem 12: Friend Requests: Acceptance Rate
-- ============================================

-- Calculate the acceptance rate of friend requests

CREATE TABLE FriendRequest (sender_id INT, send_to_id INT, request_date DATE);
CREATE TABLE RequestAccepted (requester_id INT, accepter_id INT, accept_date DATE);

-- Solution
SELECT ROUND(
    COALESCE(
        (SELECT COUNT(DISTINCT requester_id, accepter_id) FROM RequestAccepted) /
        NULLIF((SELECT COUNT(DISTINCT sender_id, send_to_id) FROM FriendRequest), 0),
        0
    ), 2
) AS accept_rate;

-- ============================================
-- Problem 13: Consecutive Available Seats
-- ============================================

-- Find all consecutive available seats

CREATE TABLE Cinema2 (seat_id INT, free INT);

-- Solution
SELECT DISTINCT c1.seat_id
FROM Cinema2 c1
JOIN Cinema2 c2 ON ABS(c1.seat_id - c2.seat_id) = 1
WHERE c1.free = 1 AND c2.free = 1
ORDER BY c1.seat_id;

-- ============================================
-- Problem 14: Sales Person
-- ============================================

-- Find salespeople who didn't sell to company 'RED'

CREATE TABLE SalesPerson (sales_id INT, name VARCHAR(100));
CREATE TABLE Company (com_id INT, name VARCHAR(100));
CREATE TABLE Orders2 (order_id INT, com_id INT, sales_id INT, amount INT);

-- Solution
SELECT s.name
FROM SalesPerson s
WHERE s.sales_id NOT IN (
    SELECT o.sales_id
    FROM Orders2 o
    JOIN Company c ON o.com_id = c.com_id
    WHERE c.name = 'RED'
);

-- ============================================
-- Problem 15: Product Sales Analysis
-- ============================================

-- Find first year of sale for each product

CREATE TABLE Sales (sale_id INT, product_id INT, year INT, quantity INT, price INT);
CREATE TABLE Product (product_id INT, product_name VARCHAR(100));

-- Solution
SELECT p.product_name, s.year AS first_year, s.quantity, s.price
FROM Sales s
JOIN Product p ON s.product_id = p.product_id
WHERE (s.product_id, s.year) IN (
    SELECT product_id, MIN(year)
    FROM Sales
    GROUP BY product_id
);
