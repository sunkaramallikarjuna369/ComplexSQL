-- ============================================
-- SQL Interview Questions - Hard Level
-- HackerRank / LeetCode Style (FAANG Interview Questions)
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Problem 1: Trips and Users Cancellation Rate
-- ============================================

-- Calculate cancellation rate for unbanned users between dates

CREATE TABLE Trips (id INT, client_id INT, driver_id INT, city_id INT, status VARCHAR(50), request_at DATE);
CREATE TABLE Users (users_id INT, banned VARCHAR(10), role VARCHAR(20));

-- Solution
SELECT 
    t.request_at AS Day,
    ROUND(
        SUM(CASE WHEN t.status LIKE 'cancelled%' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS 'Cancellation Rate'
FROM Trips t
JOIN Users u1 ON t.client_id = u1.users_id AND u1.banned = 'No'
JOIN Users u2 ON t.driver_id = u2.users_id AND u2.banned = 'No'
WHERE t.request_at BETWEEN '2013-10-01' AND '2013-10-03'
GROUP BY t.request_at;

-- ============================================
-- Problem 2: Human Traffic of Stadium
-- ============================================

-- Find records with 3+ consecutive days of 100+ visitors

CREATE TABLE Stadium (id INT, visit_date DATE, people INT);

-- Solution using window functions
WITH numbered AS (
    SELECT 
        id, visit_date, people,
        id - ROW_NUMBER() OVER (ORDER BY id) AS grp
    FROM Stadium
    WHERE people >= 100
),
grouped AS (
    SELECT id, visit_date, people, grp, COUNT(*) OVER (PARTITION BY grp) AS cnt
    FROM numbered
)
SELECT id, visit_date, people
FROM grouped
WHERE cnt >= 3
ORDER BY visit_date;

-- ============================================
-- Problem 3: Median Employee Salary
-- ============================================

-- Find median salary for each company

CREATE TABLE Employee3 (id INT, company VARCHAR(100), salary INT);

-- Solution
WITH ranked AS (
    SELECT 
        id, company, salary,
        ROW_NUMBER() OVER (PARTITION BY company ORDER BY salary, id) AS rn,
        COUNT(*) OVER (PARTITION BY company) AS cnt
    FROM Employee3
)
SELECT id, company, salary
FROM ranked
WHERE rn BETWEEN cnt/2.0 AND cnt/2.0 + 1
ORDER BY company, salary;

-- ============================================
-- Problem 4: Department Budget Running Total
-- ============================================

-- Calculate running total of department budgets

CREATE TABLE DeptBudget (dept_id INT, dept_name VARCHAR(100), budget DECIMAL(15,2));

-- Solution
SELECT 
    dept_id,
    dept_name,
    budget,
    SUM(budget) OVER (ORDER BY dept_id) AS running_total,
    ROUND(100.0 * budget / SUM(budget) OVER (), 2) AS pct_of_total
FROM DeptBudget
ORDER BY dept_id;

-- ============================================
-- Problem 5: Find Gaps in Sequences
-- ============================================

-- Find missing numbers in a sequence

CREATE TABLE Sequence (num INT);

-- Solution
WITH RECURSIVE all_nums AS (
    SELECT MIN(num) AS num FROM Sequence
    UNION ALL
    SELECT num + 1 FROM all_nums WHERE num < (SELECT MAX(num) FROM Sequence)
)
SELECT num AS missing_number
FROM all_nums
WHERE num NOT IN (SELECT num FROM Sequence);

-- Alternative without recursive CTE
SELECT a.num + 1 AS gap_start, MIN(b.num) - 1 AS gap_end
FROM Sequence a
JOIN Sequence b ON a.num < b.num
WHERE NOT EXISTS (SELECT 1 FROM Sequence c WHERE c.num = a.num + 1)
GROUP BY a.num;

-- ============================================
-- Problem 6: Report Contiguous Dates
-- ============================================

-- Merge overlapping date ranges

CREATE TABLE Tasks (task_id INT, start_date DATE, end_date DATE);

-- Solution: Find contiguous date ranges
WITH date_groups AS (
    SELECT 
        task_id,
        start_date,
        end_date,
        SUM(CASE WHEN prev_end >= start_date - INTERVAL '1 day' THEN 0 ELSE 1 END) 
            OVER (ORDER BY start_date) AS grp
    FROM (
        SELECT 
            task_id,
            start_date,
            end_date,
            LAG(end_date) OVER (ORDER BY start_date) AS prev_end
        FROM Tasks
    ) t
)
SELECT 
    MIN(start_date) AS period_start,
    MAX(end_date) AS period_end
FROM date_groups
GROUP BY grp
ORDER BY period_start;

-- ============================================
-- Problem 7: Get Highest Answer Rate Question
-- ============================================

-- Find question with highest answer rate

CREATE TABLE SurveyLog (id INT, action VARCHAR(20), question_id INT, answer_id INT, q_num INT, timestamp INT);

-- Solution
SELECT question_id AS survey_log
FROM SurveyLog
GROUP BY question_id
ORDER BY 
    SUM(CASE WHEN action = 'answer' THEN 1 ELSE 0 END) / 
    NULLIF(SUM(CASE WHEN action = 'show' THEN 1 ELSE 0 END), 0) DESC,
    question_id ASC
LIMIT 1;

-- ============================================
-- Problem 8: Average Salary: Departments vs Company
-- ============================================

-- Compare department average to company average by month

CREATE TABLE Salary2 (id INT, employee_id INT, amount INT, pay_date DATE);
CREATE TABLE Employee4 (employee_id INT, department_id INT);

-- Solution
WITH monthly_avg AS (
    SELECT 
        DATE_FORMAT(s.pay_date, '%Y-%m') AS pay_month,
        e.department_id,
        AVG(s.amount) AS dept_avg
    FROM Salary2 s
    JOIN Employee4 e ON s.employee_id = e.employee_id
    GROUP BY DATE_FORMAT(s.pay_date, '%Y-%m'), e.department_id
),
company_avg AS (
    SELECT 
        DATE_FORMAT(pay_date, '%Y-%m') AS pay_month,
        AVG(amount) AS company_avg
    FROM Salary2
    GROUP BY DATE_FORMAT(pay_date, '%Y-%m')
)
SELECT 
    m.pay_month,
    m.department_id,
    CASE 
        WHEN m.dept_avg > c.company_avg THEN 'higher'
        WHEN m.dept_avg < c.company_avg THEN 'lower'
        ELSE 'same'
    END AS comparison
FROM monthly_avg m
JOIN company_avg c ON m.pay_month = c.pay_month;

-- ============================================
-- Problem 9: Students Report By Geography
-- ============================================

-- Pivot students by continent

CREATE TABLE Student2 (name VARCHAR(100), continent VARCHAR(100));

-- Solution (pivot)
SELECT 
    MAX(CASE WHEN continent = 'America' THEN name END) AS America,
    MAX(CASE WHEN continent = 'Asia' THEN name END) AS Asia,
    MAX(CASE WHEN continent = 'Europe' THEN name END) AS Europe
FROM (
    SELECT 
        name,
        continent,
        ROW_NUMBER() OVER (PARTITION BY continent ORDER BY name) AS rn
    FROM Student2
) t
GROUP BY rn;

-- ============================================
-- Problem 10: Market Analysis II
-- ============================================

-- Find if user's second item sold is their favorite brand

CREATE TABLE Users2 (user_id INT, join_date DATE, favorite_brand VARCHAR(100));
CREATE TABLE Orders3 (order_id INT, order_date DATE, item_id INT, buyer_id INT, seller_id INT);
CREATE TABLE Items (item_id INT, item_brand VARCHAR(100));

-- Solution
WITH seller_items AS (
    SELECT 
        o.seller_id,
        i.item_brand,
        ROW_NUMBER() OVER (PARTITION BY o.seller_id ORDER BY o.order_date) AS rn
    FROM Orders3 o
    JOIN Items i ON o.item_id = i.item_id
)
SELECT 
    u.user_id AS seller_id,
    CASE 
        WHEN s.item_brand = u.favorite_brand THEN 'yes'
        ELSE 'no'
    END AS 2nd_item_fav_brand
FROM Users2 u
LEFT JOIN seller_items s ON u.user_id = s.seller_id AND s.rn = 2;

-- ============================================
-- Problem 11: Find Cumulative Salary
-- ============================================

-- Calculate 3-month cumulative salary excluding most recent month

CREATE TABLE Employee5 (id INT, month INT, salary INT);

-- Solution
SELECT 
    e1.id,
    e1.month,
    SUM(e2.salary) AS Salary
FROM Employee5 e1
JOIN Employee5 e2 ON e1.id = e2.id AND e2.month BETWEEN e1.month - 2 AND e1.month
WHERE e1.month < (SELECT MAX(month) FROM Employee5 WHERE id = e1.id)
GROUP BY e1.id, e1.month
ORDER BY e1.id, e1.month DESC;

-- ============================================
-- Problem 12: Count Salary Categories
-- ============================================

-- Count accounts in Low, Average, High salary categories

CREATE TABLE Accounts (account_id INT, income INT);

-- Solution
SELECT 'Low Salary' AS category, COUNT(*) AS accounts_count
FROM Accounts WHERE income < 20000
UNION ALL
SELECT 'Average Salary', COUNT(*)
FROM Accounts WHERE income BETWEEN 20000 AND 50000
UNION ALL
SELECT 'High Salary', COUNT(*)
FROM Accounts WHERE income > 50000;

-- ============================================
-- Problem 13: Shortest Distance in a Plane
-- ============================================

-- Find shortest distance between any two points

CREATE TABLE Point2D (x INT, y INT);

-- Solution
SELECT ROUND(MIN(SQRT(POW(p1.x - p2.x, 2) + POW(p1.y - p2.y, 2))), 2) AS shortest
FROM Point2D p1
JOIN Point2D p2 ON (p1.x, p1.y) <> (p2.x, p2.y);

-- ============================================
-- Problem 14: Second Degree Follower
-- ============================================

-- Find users who are both followers and followees

CREATE TABLE Follow (followee VARCHAR(100), follower VARCHAR(100));

-- Solution
SELECT f1.follower, COUNT(DISTINCT f2.follower) AS num
FROM Follow f1
JOIN Follow f2 ON f1.follower = f2.followee
GROUP BY f1.follower
ORDER BY f1.follower;

-- ============================================
-- Problem 15: Active Businesses
-- ============================================

-- Find businesses with more than average occurrences for event types

CREATE TABLE Events (business_id INT, event_type VARCHAR(100), occurrences INT);

-- Solution
WITH avg_occurrences AS (
    SELECT event_type, AVG(occurrences) AS avg_occ
    FROM Events
    GROUP BY event_type
)
SELECT e.business_id
FROM Events e
JOIN avg_occurrences a ON e.event_type = a.event_type
WHERE e.occurrences > a.avg_occ
GROUP BY e.business_id
HAVING COUNT(*) > 1;
