## Northwind_Traders_Sales_Project
A comprehensive SQL-based business intelligence analysis of Northwind Traders, a specialty foods export-import company. This project demonstrates advanced data analysis techniques through 30 progressive SQL queries, from basic aggregations to sophisticated customer segmentation and predictive analytics.


 # Project Objectives
This analysis addresses key business questions across multiple domains:

Product Portfolio: Optimize product mix, identify top performers
Revenue Analysis: Track performance trends, identify growth opportunities
Customer Intelligence: Segment customers, calculate lifetime value, predict churn
Operational Efficiency: Measure fulfillment performance, evaluate shipping costs
Employee Performance: Rank sales representatives, identify training needs
Market Intelligence: Analyze geographic opportunities, seasonal patterns

# Analysis Questions & Techniques
Basic Level (Questions 1-10)
Foundational SQL skills

Total customers, orders, and products
Basic aggregations and filtering
Simple GROUP BY operations
Date-based filtering

# SQL Techniques:
 # Basic Queries
SELECT, WHERE, ORDER BY, LIMIT
Aggregate functions: COUNT(), SUM(), AVG(), MIN(), MAX()
GROUP BY, HAVING


# Intermediate Level
Multi-table analysis and business metrics
Key Questions:

Revenue by product category
Top 10 customers by order value
Employee sales performance rankings
Monthly revenue trends
Geographic revenue distribution
Discount impact analysis
Order fulfillment efficiency
Average order value by customer segment

SQL Techniques:

Multi-table INNER JOIN and LEFT JOIN
Subqueries in SELECT, WHERE, and FROM clauses
Date arithmetic with julianday()
String concatenation
Conditional aggregations with CASE
DENSE_RANK() window function
Percentage calculations


# Advanced Level 
Sophisticated business intelligence
Key Questions:

Running total revenue by month (financial modeling)
Top 3 products per category (partitioned rankings)
Customer retention and consecutive ordering
Year-over-year revenue growth by category
Customer churn identification (6-month inactivity)
Customer Lifetime Value (CLV) calculation
Multi-dimensional employee performance ranking
Product sell-through rate analysis
Seasonal demand patterns
RFM Customer Segmentation (Recency, Frequency, Monetary)

SQL Techniques:

Common Table Expressions (CTEs) with WITH clause
Window functions:

SUM() OVER() with ROWS BETWEEN for running totals
AVG() OVER() for moving averages
RANK(), DENSE_RANK(), ROW_NUMBER()
LAG(), LEAD() for period-over-period comparisons
PARTITION BY for grouped calculations


Complex CASE statements for segmentation
Compound Annual Growth Rate (CAGR) calculations
Multi-level categorization frameworks
NULL handling with COALESCE() and NULLIF()

## Setup Instructions
1. Clone Repository
bashgit clone https://github.com/yourusername/northwind-traders-analysis.git
cd northwind-traders-analysis

2. Set Up Database
Option A: SQLite 
bash# Create database
sqlite3 northwind.db

 Import CSV files (from SQLite prompt)
.mode csv
.import data/categories.csv categories
.import data/customers.csv customers
.import data/employees.csv employees
.import data/products.csv products
.import data/shippers.csv shippers
.import data/orders.csv orders
.import data/order_details.csv order_details
Option B: Using DBeaver

Open DBeaver
Create new SQLite connection
Right-click "Tables" → "Import Data"
Select CSV files and import one by one

3. Verify Setup
sql-- Check all tables loaded correctly
SELECT 'categories' as table_name, COUNT(*) as row_count FROM categories


SELECT 'customers', COUNT(*) FROM customers

SELECT 'employees', COUNT(*) FROM employees

SELECT 'order_details', COUNT(*) FROM order_details

SELECT 'orders', COUNT(*) FROM orders

SELECT 'products', COUNT(*) FROM products

SELECT 'shippers', COUNT(*) FROM shippers;

4. Run Queries
bash# Execute basic queries
sqlite3 northwind.db < sql-queries/01-basic-queries.sql
sqlite3 northwind.db < sql-queries/01-intermediate-queries.sql
sqlite3 northwind.db < sql-queries/01-advanced-queries.sql

# Or open in DBeaver and run interactively

# Contact
Paul Gikonyo
Data Analyst | SQL | Power BI | Python

Email: paulgikonyo100@gmail.com
LinkedIn: linkedin.com/in/paul-gikonyo-15389418b/
GitHub: github.com/Chege-jr0
Portfolio: View other projects →


Acknowledgments

Dataset Source: Northwind Traders sample database (adapted from Microsoft Northwind)
Tools: DBeaver Community, SQLite, Power BI Desktop
Training: Zindua School of Coding - Data Analytics Program
Inspiration: Maven Analytics community


📄 License
This project is open source and available under the MIT License.

Project Stats

Total Queries: 30
Lines of SQL Code: ~2,000+
Analysis Time: 40+ hours
Data Records Analyzed: 3,175
Business Insights Generated: 50+
Customer Segments Identified: 11
Visualizations Created: 10+ (in Power BI)
