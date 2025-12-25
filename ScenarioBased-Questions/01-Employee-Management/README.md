# Employee Management - Scenario-Based SQL Questions

## Overview
This folder contains 20 comprehensive scenario-based SQL questions (Q1-Q20) focused on Employee Management scenarios. Each question includes multi-RDBMS solutions, detailed explanations, sample data, and expected results.

## Database Schema
The `schema.sql` file contains the complete database structure with sample data for:
- **employees** (28 records) - Core employee information
- **departments** (8 records) - Organizational departments
- **jobs** (13 records) - Job position definitions
- **job_history** (9 records) - Employee job change history

## How to Use

### Setup Instructions

**SQL Server:**
```sql
-- Run schema.sql to create tables and insert sample data
-- Then execute queries from questions.sql
```

**Oracle:**
```sql
-- Run schema.sql to create tables and insert sample data
-- Then execute queries from questions.sql
```

**PostgreSQL:**
```sql
-- Run schema.sql to create tables and insert sample data
-- Then execute queries from questions.sql
```

**MySQL:**
```sql
-- Run schema.sql to create tables and insert sample data
-- Then execute queries from questions.sql
```

## Question Index

| # | Question | Difficulty | Key Concepts |
|---|----------|-----------|--------------|
| Q1 | Find employees hired in the last 90 days | Easy | Date Functions, Filtering |
| Q2 | Calculate years of service for each employee | Easy | Date Arithmetic, DATEDIFF |
| Q3 | Find employees earning above department average | Medium | Subqueries, Window Functions, Aggregates |
| Q4 | Find the reporting hierarchy for an employee | Hard | Recursive CTEs, Hierarchical Queries |
| Q5 | Find employees with same job title in different departments | Medium | Self Joins, Filtering |
| Q6 | Calculate salary percentile for each employee | Medium | Window Functions, PERCENT_RANK, NTILE |
| Q7 | Find departments with no employees | Easy | LEFT JOIN, NOT EXISTS |
| Q8 | Find employees who changed jobs more than twice | Medium | Joins, GROUP BY, HAVING |
| Q9 | Calculate the salary gap between employee and manager | Medium | Self Joins, Calculations |
| Q10 | Find the second highest salary in each department | Medium | Window Functions, DENSE_RANK |
| Q11 | Find employees hired on weekends | Easy | Date Functions, Day of Week |
| Q12 | Calculate cumulative salary by hire date | Medium | Window Functions, Running Totals |
| Q13 | Find employees with duplicate email domains | Medium | String Functions, GROUP BY, HAVING |
| Q14 | Find the longest tenure employee in each department | Medium | Window Functions, ROW_NUMBER |
| Q15 | Calculate month-over-month hiring trend | Hard | Date Truncation, LAG, Trend Analysis |
| Q16 | Find employees whose salary is outside job salary range | Medium | Joins, CASE Statements, Range Checks |
| Q17 | Find managers with more than 5 direct reports | Easy | Self Joins, GROUP BY, HAVING |
| Q18 | Calculate average tenure by department | Medium | Aggregates, Date Functions, LEFT JOIN |
| Q19 | Find employees with no commission who should have one | Easy | Joins, NULL Handling, LIKE |
| Q20 | Generate employee directory with full details | Medium | Multiple Joins, COALESCE, String Concatenation |

## Difficulty Levels
- **Easy (7 questions):** Basic SQL concepts, simple joins, basic filtering
- **Medium (11 questions):** Window functions, subqueries, complex joins, aggregations
- **Hard (2 questions):** Recursive CTEs, complex analytics, trend analysis

## Key SQL Concepts Covered
- Date and Time Functions
- Joins (INNER, LEFT, Self)
- Subqueries and CTEs
- Window Functions (ROW_NUMBER, RANK, DENSE_RANK, PERCENT_RANK, NTILE, LAG, SUM OVER)
- Aggregate Functions (COUNT, AVG, SUM)
- String Functions
- Recursive Queries
- NULL Handling
- CASE Statements
- GROUP BY and HAVING

## RDBMS-Specific Syntax
Each question includes solutions for:
- **SQL Server** - T-SQL syntax with DATEADD, DATEDIFF, GETDATE()
- **Oracle** - PL/SQL syntax with SYSDATE, MONTHS_BETWEEN, CONNECT BY
- **PostgreSQL** - PostgreSQL syntax with INTERVAL, AGE, EXTRACT
- **MySQL** - MySQL syntax with DATE_SUB, TIMESTAMPDIFF, CURDATE()

## Interview Preparation Tips
1. Understand the business context of each scenario
2. Practice explaining your query logic step-by-step
3. Consider edge cases (NULL values, empty results, ties)
4. Know multiple approaches to solve the same problem
5. Understand performance implications (indexes, query plans)
6. Be familiar with RDBMS-specific syntax differences

## Additional Resources
- `visualization.html` - Interactive visual representation of database schema and sample queries
- `questions.sql` - All 20 questions with multi-RDBMS solutions
- `schema.sql` - Complete database schema with sample data
