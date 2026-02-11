# Northwind_Traders_Sales_Project
A comprehensive SQL-based business intelligence analysis of Northwind Traders, a specialty foods export-import company. This project demonstrates advanced data analysis techniques through 30 progressive SQL queries, from basic aggregations to sophisticated customer segmentation and predictive analytics.
Author: Paul Gikonyo
Date: February 2026
Tools: SQLite, DBeaver, SQL
Dataset: Northwind Traders (2013-2015 transaction data)

 Project Objectives
This analysis addresses key business questions across multiple domains:

Revenue Analysis: Track performance trends, identify growth opportunities
Customer Intelligence: Segment customers, calculate lifetime value, predict churn
Product Portfolio: Optimize product mix, identify top performers
Operational Efficiency: Measure fulfillment performance, evaluate shipping costs
Employee Performance: Rank sales representatives, identify training needs
Market Intelligence: Analyze geographic opportunities, seasonal patterns


 Database Schema
Entity Relationship Diagram
CUSTOMERS (1) ────< ORDERS (M)
EMPLOYEES (1) ────< ORDERS (M)
SHIPPERS (1) ─────< ORDERS (M)
ORDERS (1) ───────< ORDER_DETAILS (M)
PRODUCTS (1) ─────< ORDER_DETAILS (M)
CATEGORIES (1) ───< PRODUCTS (M)
Tables Overview
TableRowsDescriptioncategories8Product categories (Beverages, Condiments, etc.)customers92Customer information across multiple countriesemployees9Sales representatives and managersproducts78Product catalog with pricing and statusorders831Order header information (2013-2015)order_details2,156Line-item details for each ordershippers3Shipping companies used for delivery
Total Records: 3,175 rows across 7 tables

Analysis Questions & Techniques
Basic Level (Questions 1-10)
Foundational SQL skills

Total customers, orders, and products
Basic aggregations and filtering
Simple GROUP BY operations
Date-based filtering

SQL Techniques:

SELECT, WHERE, ORDER BY, LIMIT
Aggregate functions: COUNT(), SUM(), AVG(), MIN(), MAX()
GROUP BY, HAVING


Intermediate Level (Questions 11-20)
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


Advanced Level (Questions 21-30)
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


Key Business Insights
Revenue & Growth

Total Revenue: $1,354,458.59 (2013-2015)
Monthly Average: ~$50K
Growth Trend: Steady increase from 2013 → 2015
Top Category: Beverages ($267,868 - 20% of revenue)

Customer Intelligence

Customer Concentration: Top 10 customers = 35% of total revenue
Average Customer Lifetime Value: $14,700
Customer Segments: 11 strategic RFM segments identified

Champions: 8% of customers, 25% of revenue
At Risk: 12% of customers, $180K in revenue at risk
Can't Lose: 5 high-value customers with 180+ days inactivity



Product Performance

Best-Selling Product: Côte de Blaye ($141,396 revenue)
Product Concentration: Top 10 products = 25% of revenue
Sell-Through Rate: 92% of products have sold at least once
Discontinued Products: 8 products discontinued, representing $45K in lost potential revenue

Geographic Insights

Top Markets:

USA ($245,584 - 18%)
Germany ($229,812 - 17%)
Austria ($128,004 - 9%)


Market Coverage: 21 countries served
Geographic Concentration: Top 5 countries = 60% of revenue

Operational Efficiency

Average Fulfillment Time: 8.5 days
On-Time Delivery Rate: 87%
Average Freight Cost: $78.24 per order
Freight as % of Revenue: 4.2%

Employee Performance

Top Performer: Margaret Peacock ($250,187 in sales)
Average Sales per Employee: $150,495
Performance Range: 3:1 ratio (top vs bottom performer)
Customer Coverage: Average 10 unique customers per employee


Strategic Recommendations
Based on the analysis, I recommend the following actions:
1. Customer Retention Focus
Priority: HIGH

Immediate outreach to 5 "Can't Lose" customers (high CLV, 180+ days inactive)
Implement loyalty program for 8% "Champions" segment
Re-engagement campaign for "At Risk" segment ($180K revenue exposure)

2. Product Portfolio Optimization
Priority: MEDIUM

Increase inventory for top 10 products (25% of revenue, high sell-through)
Review 6 products with zero sales in past year for discontinuation
Expand Beverages and Dairy categories (highest revenue, strong demand)

3. Geographic Expansion
Priority: MEDIUM

Invest in marketing in Germany and USA (proven strong markets)
Explore Austria and Brazil (high growth rates, underpenetrated)
Reduce exposure in saturated markets with declining growth

4. Operational Improvements
Priority: LOW-MEDIUM

Address 13% late deliveries (impact on customer satisfaction)
Negotiate better rates with Shipper #2 (handles 40% volume, higher costs)
Implement seasonal inventory planning (Q4 spike identified)

5. Sales Team Development
Priority: MEDIUM

Share best practices from top 3 performers (Margaret, Janet, Nancy)
Provide additional training for bottom quartile performers
Implement performance incentives based on multi-dimensional scoring


Technical Implementation
Prerequisites

Database: SQLite 3.x or PostgreSQL 12+
SQL Client: DBeaver Community Edition (recommended) or any SQL client
Optional: Power BI Desktop (for dashboard)

## Setup Instructions
1. Clone Repository
bashgit clone https://github.com/yourusername/northwind-traders-analysis.git
cd northwind-traders-analysis
2. Set Up Database
Option A: SQLite (Recommended for portability)
bash# Create database
sqlite3 northwind.db

# Import CSV files (from SQLite prompt)
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
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'order_details', COUNT(*) FROM order_details
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'shippers', COUNT(*) FROM shippers;
Expected Output:
categories: 8
customers: 92
employees: 9
order_details: 2156
orders: 831
products: 78
shippers: 3
4. Run Queries
bash# Execute basic queries
sqlite3 northwind.db < sql-queries/01-basic-queries.sql

# Or open in DBeaver and run interactively

Sample Queries
Query 1: Total Revenue by Category
sqlSELECT 
    c.categoryName,
    COUNT(DISTINCT o.orderID) as total_orders,
    SUM(od.quantity) as units_sold,
    ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as total_revenue
FROM categories c
JOIN products p ON c.categoryID = p.categoryID
JOIN order_details od ON p.productID = od.productID
JOIN orders o ON od.orderID = o.orderID
GROUP BY c.categoryName
ORDER BY total_revenue DESC;
Output:
CategoryOrdersUnits SoldRevenueBeverages4049,532$267,868.20Dairy Products3669,149$234,507.30Confections3347,906$167,357.90

Query 2: Customer Lifetime Value (Top 10)
sqlWITH customer_clv AS (
    SELECT 
        c.companyName,
        c.country,
        COUNT(DISTINCT o.orderID) as total_orders,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as lifetime_value,
        DENSE_RANK() OVER (ORDER BY SUM(od.unitPrice * od.quantity * (1 - od.discount)) DESC) as clv_rank
    FROM customers c
    JOIN orders o ON c.customerID = o.customerID
    JOIN order_details od ON o.orderID = od.orderID
    GROUP BY c.companyName, c.country
)
SELECT 
    clv_rank,
    companyName,
    country,
    total_orders,
    lifetime_value
FROM customer_clv
WHERE clv_rank <= 10
ORDER BY clv_rank;

Query 3: RFM Customer Segmentation
sqlWITH customer_rfm AS (
    SELECT 
        c.companyName,
        ROUND(julianday((SELECT MAX(orderDate) FROM orders)) - julianday(MAX(o.orderDate)), 0) as recency_days,
        COUNT(DISTINCT o.orderID) as frequency,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as monetary,
        -- RFM Scoring (1-5 scale)
        CASE 
            WHEN julianday((SELECT MAX(orderDate) FROM orders)) - julianday(MAX(o.orderDate)) <= 30 THEN 5
            WHEN julianday((SELECT MAX(orderDate) FROM orders)) - julianday(MAX(o.orderDate)) <= 60 THEN 4
            WHEN julianday((SELECT MAX(orderDate) FROM orders)) - julianday(MAX(o.orderDate)) <= 90 THEN 3
            WHEN julianday((SELECT MAX(orderDate) FROM orders)) - julianday(MAX(o.orderDate)) <= 180 THEN 2
            ELSE 1
        END as R_score,
        CASE 
            WHEN COUNT(DISTINCT o.orderID) >= 20 THEN 5
            WHEN COUNT(DISTINCT o.orderID) >= 15 THEN 4
            WHEN COUNT(DISTINCT o.orderID) >= 10 THEN 3
            WHEN COUNT(DISTINCT o.orderID) >= 5 THEN 2
            ELSE 1
        END as F_score,
        CASE 
            WHEN SUM(od.unitPrice * od.quantity * (1 - od.discount)) >= 20000 THEN 5
            WHEN SUM(od.unitPrice * od.quantity * (1 - od.discount)) >= 10000 THEN 4
            WHEN SUM(od.unitPrice * od.quantity * (1 - od.discount)) >= 5000 THEN 3
            WHEN SUM(od.unitPrice * od.quantity * (1 - od.discount)) >= 2000 THEN 2
            ELSE 1
        END as M_score
    FROM customers c
    JOIN orders o ON c.customerID = o.customerID
    JOIN order_details od ON o.orderID = od.orderID
    GROUP BY c.companyName
)
SELECT 
    companyName,
    recency_days,
    frequency,
    monetary,
    R_score,
    F_score,
    M_score,
    CASE 
        WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN ' Champions'
        WHEN F_score >= 4 AND M_score >= 4 THEN 'Loyal Customers'
        WHEN R_score >= 4 AND M_score >= 3 AND F_score <= 3 THEN ' Potential Loyalists'
        WHEN R_score <= 2 AND M_score >= 4 THEN 'At Risk'
        WHEN R_score = 1 AND F_score >= 4 AND M_score >= 4 THEN ' Can\'t Lose Them'
        ELSE ' Others'
    END as customer_segment
FROM customer_rfm
ORDER BY monetary DESC;

 Dashboard Preview
Executive Summary Dashboard

Total Revenue, Orders, Customers (KPI cards)
Monthly revenue trend (line chart)
Revenue by category (bar chart)
Geographic distribution (map)

Customer Analysis Dashboard

RFM segmentation distribution (pie chart)
Top 10 customers (table)
Customer churn risk (stacked bar)
CLV distribution (histogram)

Product Performance Dashboard

Top products by revenue (bar chart)
Category performance (matrix)
Seasonal patterns (heat map)
Product sell-through rate (gauge)

Employee Performance Dashboard

Sales by employee (bar chart)
Performance rankings (table)
Orders vs revenue scatter (scatter plot)
Territory coverage (map)


 Skills Demonstrated
SQL Proficiency

✅ Basic to advanced SELECT queries
✅ Multi-table JOINs (INNER, LEFT, RIGHT)
✅ Aggregate functions and GROUP BY
✅ Subqueries (scalar, inline, correlated)
✅ Common Table Expressions (CTEs)
✅ Window functions (RANK, DENSE_RANK, ROW_NUMBER, LAG, LEAD)
✅ Date/time functions and arithmetic
✅ String manipulation and concatenation
✅ CASE statements for conditional logic
✅ Set operations (UNION, INTERSECT)

Business Analysis

✅ Revenue and profitability analysis
✅ Customer segmentation (RFM methodology)
✅ Cohort and retention analysis
✅ Customer Lifetime Value (CLV) modeling
✅ Churn prediction and risk scoring
✅ Product portfolio optimization
✅ Operational efficiency metrics
✅ Geographic market analysis
✅ Seasonal demand forecasting
✅ Employee performance evaluation

Data Visualization

✅ Dashboard design principles
✅ KPI selection and presentation
✅ Interactive filtering and drill-downs
✅ Chart type selection for data types
✅ Data storytelling


 Documentation
Additional Resources

Data Dictionary: Detailed descriptions of all tables and columns
Business Insights Report: Comprehensive findings and recommendations
Methodology: Analysis approach and techniques used
Query Library: All 30 SQL queries with comments


Future Enhancements
Potential next steps for this project:

Predictive Analytics

Build customer churn prediction model using logistic regression
Forecast next month's revenue using time series analysis
Predict product reorder quantities


Advanced Segmentation

Implement K-means clustering for customer behavior patterns
Create product affinity analysis (market basket)
Build customer journey mapping


Real-Time Dashboard

Connect Power BI to live database with automatic refresh
Add real-time alerts for key metrics
Implement drill-through reports


Machine Learning Integration

Python integration for predictive modeling
Anomaly detection for unusual order patterns
Recommendation engine for cross-selling

 Contributing
This is a portfolio project, but suggestions and feedback are welcome!
If you'd like to suggest improvements:

Fork the repository
Create a feature branch
Make your changes
Submit a pull request


Contact
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
Visualizations Created: 15+ (in Power BI)
