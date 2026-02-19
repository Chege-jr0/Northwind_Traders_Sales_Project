-- Running Total Revenue by Month
-- Whats our cumulative revenue over time? When did we hit $500k, $1M

WITH monthly_revenue AS (
    SELECT 
        strftime('%Y-%m', o.orderDate) AS year_month,
        COUNT(DISTINCT o.orderID) AS order_counts,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) AS monthly_revenue
    FROM orders o
    JOIN order_details od 
        ON o.orderID = od.orderID
    GROUP BY year_month
)

SELECT 
    year_month,
    order_counts,
    monthly_revenue,

    -- Running Total Revenue
    SUM(monthly_revenue) OVER (ORDER BY year_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_revenue,

    -- 3-Month Moving Average
    ROUND(AVG(monthly_revenue) OVER (ORDER BY year_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS three_month_moving_average,

    -- Previous Month Revenue
    LAG(monthly_revenue) OVER (ORDER BY year_month) AS prev_month_revenue,

    -- Month-over-Month Change (Absolute)
    ROUND(monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY year_month), 2) AS mon_change,

    -- Month-over-Month Growth (%)
    ROUND(100.0 * (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY year_month)) / NULLIF(LAG(monthly_revenue) OVER (ORDER BY year_month), 0),2) AS mon_growth_pct

FROM monthly_revenue
ORDER BY year_month;

-- Top 3 Performers per category
-- What are the best-selling products in Each category
--(Not just in each overall products but category leaders)

WITH product_performance AS (
    SELECT
        p.productID,
        p.productName,
        c.categoryName,
        p.unitPrice AS list_price,
        COUNT(DISTINCT od.orderID) AS times_ordered,
        SUM(od.quantity) AS total_quantity_sold,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) AS total_revenue,
        ROUND(AVG(od.discount), 4) AS avg_discount,

        -- Rank Products within each category
        DENSE_RANK() OVER (PARTITION BY c.categoryName ORDER BY SUM(od.unitPrice * od.quantity * (1 - od.discount)) DESC) AS rank_in_category,

        -- Overall rank
        DENSE_RANK() OVER (ORDER BY SUM(od.unitPrice * od.quantity * (1 - od.discount)) DESC) AS overall_rank

    FROM products p
    JOIN categories c ON p.categoryID = c.categoryID
    JOIN order_details od ON p.productID = od.productID
    GROUP BY p.productID, p.productName, c.categoryName, p.unitPrice
)

SELECT 
    categoryName,
    rank_in_category,
    productName,
    list_price,
    times_ordered,
    total_quantity_sold,
    total_revenue,
    avg_discount,
    overall_rank,
    CASE
        WHEN rank_in_category = 1 THEN 'Category Leader'
        WHEN rank_in_category = 2 THEN 'Second Best'
        WHEN rank_in_category = 3 THEN 'Third Best'
    END AS category_position
FROM product_performance
WHERE rank_in_category <= 3
ORDER BY categoryName, rank_in_category;


                          
-- Customer Retention - Consecutive month Ordering
-- Which customer orders month after month?
-- What are our most loyal, repeat customer?

WITH customer_monthly_orders as (
       SELECT 
             c.customerID,
             c.companyName,
             c.country,
             strftime('%Y-%m', o.orderDate) as order_month,
             COUNT(DISTINCT o.orderID)    AS  orders_in_month
        FROM customers c
        JOIN orders o ON c.customerID = o.customerID
        GROUP BY c.customerID, c.companyName, c.country, order_month
                  
       ),
       customer_order_sequence AS (
       SELECT
            customerID,
            companyName, 
            country, 
            order_month,
            orders_in_month,
            LAG(order_month, 1) OVER (PARTITION BY customerID ORDER BY order_month) as prev_month,
        -- Checks if orders are in consecutive months
            CASE 
            	WHEN LAG(order_month, 1)OVER (PARTITION BY customerID ORDER BY order_month) IS NULL THEN 0
            	WHEN julianday(order_month || '-01') - julianday(LAG(order_month, 1) OVER (PARTITION BY customerID ORDER BY order_month) || '-01') <= 31 THEN 1
            	ELSE 0
            END AS is_consecutive
            
         FROM customer_monthly_orders
                       
       )
       
SELECT  
      companyName,
      country,
      COUNT(DISTINCT order_month) as total_months_ordered,
      MIN(order_month) as first_order_month,
      MAX(order_month) as last_order_month,
      SUM(orders_in_month) as total_orders,
      SUM(is_consecutive) as consecutive_month_count,
      ROUND(100.0 * SUM(is_consecutive)/COUNT(*),2) as pct_consecutive_months,
      CASE 
      	WHEN SUM(is_consecutive) >= 10 THEN 'Highly Consistent'
      	WHEN SUM(is_consecutive) >= 5 THEN 'Regular Customer'
      	WHEN SUM(is_consecutive) >=0 THEN 'Occassional Repeat'
      	ELSE 'Sprodic Buyer'
      END as loyalty_segment
      
FROM customer_order_sequence
GROUP BY companyName, country
HAVING COUNT(DISTINCT order_month) >= 3
ORDER BY consecutive_month_count DESC, total_months_ordered DESC
LIMIT 20;
      
-- Year over year Revenue
-- Which categories are growing? Declining? Whats our YoY growth rate?
WITH yearly_category_revenue AS (
    SELECT 
        c.categoryName,
        strftime('%Y', o.orderDate) as year,
        COUNT(DISTINCT o.orderID) as orders,
        SUM(od.quantity) as units_sold,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as revenue
    FROM categories c
    JOIN products p ON c.categoryID = p.categoryID
    JOIN order_details od ON p.productID = od.productID
    JOIN orders o ON od.orderID = o.orderID
    GROUP BY c.categoryName, year
),
category_growth AS (
    SELECT 
        categoryName,
        year,
        orders,
        units_sold,
        revenue,
        LAG(revenue, 1) OVER (PARTITION BY categoryName ORDER BY year) as prev_year_revenue,
        ROUND(revenue - LAG(revenue, 1) OVER (PARTITION BY categoryName ORDER BY year), 2) as yoy_revenue_change,
        ROUND(100.0 * (revenue - LAG(revenue, 1) OVER (PARTITION BY categoryName ORDER BY year)) / 
              NULLIF(LAG(revenue, 1) OVER (PARTITION BY categoryName ORDER BY year), 0), 2) as yoy_growth_pct,
        -- Calculate 2-year CAGR (Compound Annual Growth Rate)
        CASE 
            WHEN LAG(revenue, 2) OVER (PARTITION BY categoryName ORDER BY year) IS NOT NULL 
            THEN ROUND(100.0 * (POWER(revenue / LAG(revenue, 2) OVER (PARTITION BY categoryName ORDER BY year), 1.0/2.0) - 1), 2)
            ELSE NULL
        END as two_year_cagr
    FROM yearly_category_revenue
)
SELECT 
    categoryName,
    year,
    orders,
    units_sold,
    revenue,
    prev_year_revenue,
    yoy_revenue_change,
    yoy_growth_pct,
    two_year_cagr,
    CASE 
        WHEN yoy_growth_pct > 20 THEN '🚀 High Growth'
        WHEN yoy_growth_pct > 10 THEN '📈 Growing'
        WHEN yoy_growth_pct > 0 THEN '➡️ Stable'
        WHEN yoy_growth_pct > -10 THEN '📉 Declining'
        ELSE '⚠️ Significant Decline'
    END as growth_status
FROM category_growth
WHERE prev_year_revenue IS NOT NULL
ORDER BY categoryName, year;

-- Cutomer Churn Identification
-- Which customers havent ordered recently? Who,s at risk of churning?
-- Where should retention efforts focus?
WITH customer_last_order AS (
    SELECT 
        c.customerID,
        c.companyName,
        c.contactName,
        c.country,
        c.city,
        MAX(o.orderDate) as last_order_date,
        COUNT(DISTINCT o.orderID) as total_orders,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as lifetime_value,
        MIN(o.orderDate) as first_order_date,
        ROUND(julianday(MAX(o.orderDate)) - julianday(MIN(o.orderDate)), 0) as customer_tenure_days,
        -- Days since last order (using latest date in database as reference)
        ROUND(julianday((SELECT MAX(orderDate) FROM orders)) - julianday(MAX(o.orderDate)), 0) as days_since_last_order
    FROM customers c
    LEFT JOIN orders o ON c.customerID = o.customerID
    LEFT JOIN order_details od ON o.orderID = od.orderID
    GROUP BY c.customerID, c.companyName, c.contactName, c.country, c.city
)
SELECT 
    companyName,
    contactName,
    country,
    city,
    last_order_date,
    days_since_last_order,
    total_orders,
    lifetime_value,
    customer_tenure_days,
    ROUND(lifetime_value / NULLIF(total_orders, 0), 2) as avg_order_value,
    CASE 
        WHEN days_since_last_order IS NULL THEN '❌ Never Ordered'
        WHEN days_since_last_order > 180 THEN '🔴 High Churn Risk (6+ months)'
        WHEN days_since_last_order > 120 THEN '🟠 Moderate Churn Risk (4-6 months)'
        WHEN days_since_last_order > 60 THEN '🟡 Low Churn Risk (2-4 months)'
        ELSE '🟢 Active Customer'
    END as churn_risk_category,
    CASE 
        WHEN lifetime_value > 10000 AND days_since_last_order > 120 THEN 'URGENT: High-Value At Risk'
        WHEN lifetime_value > 10000 AND days_since_last_order <= 120 THEN 'Monitor: High-Value Active'
        WHEN lifetime_value > 5000 AND days_since_last_order > 120 THEN 'Important: Mid-Value At Risk'
        WHEN days_since_last_order > 180 THEN 'Standard: Long Inactive'
        ELSE 'Standard: Active/Recent'
    END as retention_priority
FROM customer_last_order
WHERE total_orders >= 1
ORDER BY 
    CASE 
        WHEN retention_priority LIKE 'URGENT%' THEN 1
        WHEN retention_priority LIKE 'Important%' THEN 2
        WHEN retention_priority LIKE 'Monitor%' THEN 3
        ELSE 4
    END,
    lifetime_value DESC;


-- Customer Life Time Value
-- Whats the value of our customer relationships
-- How should prioritize acquisition over retention Investments?

WITH customer_metrics AS (
    SELECT 
        c.customerID,
        c.companyName,
        c.country,
        MIN(o.orderDate) as first_order_date,
        MAX(o.orderDate) as last_order_date,
        COUNT(DISTINCT o.orderID) as total_orders,
        COUNT(DISTINCT strftime('%Y-%m', o.orderDate)) as active_months,
        ROUND(julianday(MAX(o.orderDate)) - julianday(MIN(o.orderDate)), 0) as customer_lifespan_days,
        SUM(od.quantity) as total_items_purchased,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as total_revenue,
        ROUND(AVG(od.unitPrice * od.quantity * (1 - od.discount)), 2) as avg_transaction_value,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)) / 
              NULLIF(COUNT(DISTINCT o.orderID), 0), 2) as avg_order_value
    FROM customers c
    JOIN orders o ON c.customerID = o.customerID
    JOIN order_details od ON o.orderID = od.orderID
    GROUP BY c.customerID, c.companyName, c.country
),
customer_clv AS (
    SELECT 
        *,
        -- Order frequency (orders per month active)
        ROUND(CAST(total_orders AS FLOAT) / NULLIF(active_months, 0), 2) as orders_per_active_month,
        -- Monthly revenue rate
        ROUND(total_revenue / NULLIF(active_months, 0), 2) as avg_monthly_revenue,
        -- Historical CLV
        ROUND(total_revenue, 2) as historical_clv,
        -- Projected CLV (assuming 12 more months at current rate)
        ROUND(total_revenue + (total_revenue / NULLIF(active_months, 0) * 12), 2) as projected_clv_12mo,
        -- Revenue per 30 days
        ROUND(total_revenue / NULLIF(customer_lifespan_days, 0) * 30, 2) as revenue_per_30_days
    FROM customer_metrics
)
SELECT 
    companyName,
    country,
    first_order_date,
    last_order_date,
    customer_lifespan_days,
    active_months,
    total_orders,
    orders_per_active_month,
    avg_order_value,
    avg_monthly_revenue,
    historical_clv,
    projected_clv_12mo,
    revenue_per_30_days,
    DENSE_RANK() OVER (ORDER BY historical_clv DESC) as clv_rank,
    CASE 
        WHEN historical_clv >= 20000 THEN '💎 Diamond (Top Tier)'
        WHEN historical_clv >= 10000 THEN '🥇 Platinum'
        WHEN historical_clv >= 5000 THEN '🥈 Gold'
        WHEN historical_clv >= 2000 THEN '🥉 Silver'
        ELSE '🔵 Bronze'
    END as customer_tier,
    CASE 
        WHEN orders_per_active_month >= 2.0 THEN 'Very High Frequency'
        WHEN orders_per_active_month >= 1.0 THEN 'High Frequency'
        WHEN orders_per_active_month >= 0.5 THEN 'Moderate Frequency'
        ELSE 'Low Frequency'
    END as purchase_frequency_segment
FROM customer_clv
ORDER BY historical_clv DESC
LIMIT 30;

-- Employee Performance Ranking
-- How do employers rank across mutiple performance dimensions?
-- Where are our all-stars?
 WITH employee_performance AS (
    SELECT 
        e.employeeID,
        e.employeeName as employee_name,
        e.title,
        e.city,
        COUNT(DISTINCT o.orderID) as orders_handled,
        COUNT(DISTINCT o.customerID) as unique_customers,
        SUM(od.quantity) as total_units_sold,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as total_sales,
        ROUND(AVG(od.unitPrice * od.quantity * (1 - od.discount)), 2) as avg_transaction_value,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)) / 
              NULLIF(COUNT(DISTINCT o.orderID), 0), 2) as avg_order_value,
        ROUND(AVG(od.discount), 4) as avg_discount_rate
    FROM employees e
    JOIN orders o ON e.employeeID = o.employeeID
    JOIN order_details od ON o.orderID = od.orderID
    GROUP BY e.employeeID, e.employeeName, e.title, e.city
),
employee_rankings AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) as sales_rank,
        DENSE_RANK() OVER (ORDER BY orders_handled DESC) as volume_rank,
        DENSE_RANK() OVER (ORDER BY avg_order_value DESC) as aov_rank,
        DENSE_RANK() OVER (ORDER BY unique_customers DESC) as customer_reach_rank,
        -- Composite score (lower is better - sum of ranks)
        DENSE_RANK() OVER (ORDER BY total_sales DESC) +
        DENSE_RANK() OVER (ORDER BY orders_handled DESC) +
        DENSE_RANK() OVER (ORDER BY avg_order_value DESC) as composite_score
    FROM employee_performance
)
SELECT 
    DENSE_RANK() OVER (ORDER BY composite_score) as overall_rank,
    employee_name,
    title,
    city,
    orders_handled,
    unique_customers,
    total_units_sold,
    total_sales,
    avg_order_value,
    avg_discount_rate,
    sales_rank,
    volume_rank,
    aov_rank,
    customer_reach_rank,
    composite_score,
    CASE 
        WHEN DENSE_RANK() OVER (ORDER BY composite_score) = 1 THEN '🏆 Top Performer'
        WHEN DENSE_RANK() OVER (ORDER BY composite_score) <= 3 THEN '⭐ High Performer'
        WHEN DENSE_RANK() OVER (ORDER BY composite_score) <= 6 THEN '✅ Solid Performer'
        ELSE '📊 Developing'
    END as performance_category,
    CASE 
        WHEN sales_rank = 1 THEN 'Sales Leader'
        WHEN volume_rank = 1 THEN 'Volume Champion'
        WHEN aov_rank = 1 THEN 'Premium Seller'
        WHEN customer_reach_rank = 1 THEN 'Relationship Builder'
        ELSE NULL
    END as specialty
FROM employee_rankings
ORDER BY overall_rank, total_sales DESC;


-- Product Sell Through Rate Analysis
-- What percentage of products actually sell? Should we keep or discontinue

WITH product_status AS (
    SELECT 
        p.productID,
        p.productName,
        c.categoryName,
        p.unitPrice,
        p.discontinued,
        CASE WHEN p.discontinued = 1 THEN 'Discontinued' ELSE 'Active' END as product_status,
        COUNT(DISTINCT od.orderID) as times_ordered,
        COALESCE(SUM(od.quantity), 0) as total_quantity_sold,
        COALESCE(ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2), 0) as total_revenue
    FROM products p
    JOIN categories c ON p.categoryID = c.categoryID
    LEFT JOIN order_details od ON p.productID = od.productID
    GROUP BY p.productID, p.productName, c.categoryName, p.unitPrice, p.discontinued
)
SELECT 
    productName,
    categoryName,
    unitPrice,
    product_status,
    times_ordered,
    total_quantity_sold,
    total_revenue,
    CASE 
        WHEN times_ordered = 0 THEN 'Never Sold'
        WHEN times_ordered <= 5 THEN 'Rarely Sold (≤5 orders)'
        WHEN times_ordered <= 15 THEN 'Occasionally Sold (6-15)'
        WHEN times_ordered <= 30 THEN 'Regularly Sold (16-30)'
        ELSE 'Frequently Sold (30+)'
    END as sales_frequency,
    CASE 
        WHEN product_status = 'Discontinued' AND total_revenue > 10000 THEN '⚠️ High Revenue - Reconsider Discontinuation'
        WHEN product_status = 'Discontinued' AND total_revenue < 1000 THEN '✅ Low Revenue - Discontinuation Justified'
        WHEN product_status = 'Active' AND times_ordered = 0 THEN '❌ Active But Never Sold - Consider Discontinuing'
        WHEN product_status = 'Active' AND times_ordered <= 5 THEN '⚠️ Poor Performance - Monitor'
        WHEN product_status = 'Active' AND total_revenue > 50000 THEN '🌟 Star Product - Maintain'
        ELSE '➡️ Standard Product'
    END as recommendation,
    DENSE_RANK() OVER (PARTITION BY categoryName ORDER BY total_revenue DESC) as rank_in_category
FROM product_status
ORDER BY total_revenue DESC;

-- Seasonal Patterns in Product sales?
-- When do different categories sell best?
-- How should we plan inventory and promotions?

WITH monthly_category_sales AS (
    SELECT 
        c.categoryName,
        strftime('%m', o.orderDate) as month_num,
        CASE CAST(strftime('%m', o.orderDate) AS INTEGER)
            WHEN 1 THEN 'January'
            WHEN 2 THEN 'February'
            WHEN 3 THEN 'March'
            WHEN 4 THEN 'April'
            WHEN 5 THEN 'May'
            WHEN 6 THEN 'June'
            WHEN 7 THEN 'July'
            WHEN 8 THEN 'August'
            WHEN 9 THEN 'September'
            WHEN 10 THEN 'October'
            WHEN 11 THEN 'November'
            WHEN 12 THEN 'December'
        END as month_name,
        COUNT(DISTINCT o.orderID) as orders,
        SUM(od.quantity) as units_sold,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as revenue
    FROM categories c
    JOIN products p ON c.categoryID = p.categoryID
    JOIN order_details od ON p.productID = od.productID
    JOIN orders o ON od.orderID = o.orderID
    GROUP BY c.categoryName, month_num, month_name
),



category_monthly_avg AS (
    SELECT 
        categoryName,
        AVG(revenue) as avg_monthly_revenue
    FROM monthly_category_sales
    GROUP BY categoryName
)
SELECT 
    mcs.categoryName,
    mcs.month_name,
    mcs.month_num,
    mcs.orders,
    mcs.units_sold,
    mcs.revenue,
    cma.avg_monthly_revenue,
    ROUND(mcs.revenue - cma.avg_monthly_revenue, 2) as variance_from_avg,
    ROUND(100.0 * (mcs.revenue - cma.avg_monthly_revenue) / cma.avg_monthly_revenue, 2) as pct_variance,
    DENSE_RANK() OVER (PARTITION BY mcs.categoryName ORDER BY mcs.revenue DESC) as revenue_rank_in_category,
    CASE 
        WHEN mcs.revenue > cma.avg_monthly_revenue * 1.2 THEN '🔥 Peak Season (+20%)'
        WHEN mcs.revenue > cma.avg_monthly_revenue * 1.1 THEN '📈 High Season (+10%)'
        WHEN mcs.revenue > cma.avg_monthly_revenue * 0.9 THEN '➡️ Normal Season'
        WHEN mcs.revenue > cma.avg_monthly_revenue * 0.8 THEN '📉 Slow Season (-10%)'
        ELSE '❄️ Low Season (-20%)'
    END as seasonality_indicator
FROM monthly_category_sales mcs
JOIN category_monthly_avg cma ON mcs.categoryName = cma.categoryName
ORDER BY mcs.categoryName, CAST(mcs.month_num AS INTEGER);

-- RFM Customer Segmentation
-- How do we segement customers by Recency, Frequency and Monetary Value for targeted marketing?
WITH customer_rfm_raw AS (
    SELECT 
        c.customerID,
        c.companyName,
        c.country,
        c.city,
        -- Recency: Days since last order
        ROUND(julianday((SELECT MAX(orderDate) FROM orders)) - julianday(MAX(o.orderDate)), 0) as recency_days,
        -- Frequency: Number of orders
        COUNT(DISTINCT o.orderID) as frequency_orders,
        -- Monetary: Total spend
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as monetary_value
    FROM customers c
    JOIN orders o ON c.customerID = o.customerID
    JOIN order_details od ON o.orderID = od.orderID
    GROUP BY c.customerID, c.companyName, c.country, c.city
),
customer_rfm_scores AS (
    SELECT 
        *,
        -- RFM Scoring (1-5 scale, 5 = best)
        CASE 
            WHEN recency_days <= 30 THEN 5
            WHEN recency_days <= 60 THEN 4
            WHEN recency_days <= 90 THEN 3
            WHEN recency_days <= 180 THEN 2
            ELSE 1
        END as R_score,
        CASE 
            WHEN frequency_orders >= 20 THEN 5
            WHEN frequency_orders >= 15 THEN 4
            WHEN frequency_orders >= 10 THEN 3
            WHEN frequency_orders >= 5 THEN 2
            ELSE 1
        END as F_score,
        CASE 
            WHEN monetary_value >= 20000 THEN 5
            WHEN monetary_value >= 10000 THEN 4
            WHEN monetary_value >= 5000 THEN 3
            WHEN monetary_value >= 2000 THEN 2
            ELSE 1
        END as M_score
    FROM customer_rfm_raw
),
customer_segments AS (
    SELECT 
        *,
        (R_score + F_score + M_score) as RFM_total_score,
        CAST(R_score AS TEXT) || CAST(F_score AS TEXT) || CAST(M_score AS TEXT) as RFM_segment_code,
        -- Strategic segmentation (11 segments)
        CASE 
            -- Champions: High RFM across board
            WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN '🏆 Champions'
            -- Loyal Customers: High F & M, decent R
            WHEN F_score >= 4 AND M_score >= 4 THEN '💎 Loyal Customers'
            -- Potential Loyalists: Recent & high value, lower frequency
            WHEN R_score >= 4 AND M_score >= 3 AND F_score <= 3 THEN '⭐ Potential Loyalists'
            -- New Customers: Recent but low F & M
            WHEN R_score >= 4 AND F_score <= 2 AND M_score <= 2 THEN '🆕 New Customers'
            -- Promising: Decent RFM
            WHEN R_score >= 3 AND F_score >= 3 AND M_score >= 3 THEN '📈 Promising'
            -- Need Attention: Good M but declining R
            WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 3 THEN '⚠️ Need Attention'
            -- About to Sleep: Moderate but declining
            WHEN R_score <= 3 AND F_score <= 3 THEN '😴 About To Sleep'
            -- At Risk: Were valuable, now inactive
            WHEN R_score <= 2 AND M_score >= 4 THEN '🚨 At Risk'
            -- Can't Lose: High value, very inactive
            WHEN R_score = 1 AND F_score >= 4 AND M_score >= 4 THEN '🔴 Cant Lose Them'
            -- Hibernating: Low recent activity
            WHEN R_score <= 2 AND F_score <= 2 THEN '🧊 Hibernating'
            -- Lost: Completely inactive
            WHEN R_score = 1 AND F_score <= 2 AND M_score <= 2 THEN '❌ Lost'
            ELSE '📊 Others'
        END as customer_segment,
        -- Marketing actions (strategic recommendations)
        CASE 
            WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Reward them. They are your best customers!'
            WHEN F_score >= 4 AND M_score >= 4 THEN 'Upsell higher value products. Engage them.'
            WHEN R_score >= 4 AND M_score >= 3 AND F_score <= 3 THEN 'Offer membership / loyalty program.'
            WHEN R_score >= 4 AND F_score <= 2 AND M_score <= 2 THEN 'Provide onboarding support, build relationship.'
            WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 3 THEN 'Make limited time offers. Recommend products. Reactivate them.'
            WHEN R_score <= 3 AND F_score <= 3 THEN 'Share valuable resources. Recommend popular products.'
            WHEN R_score <= 2 AND M_score >= 4 THEN 'Send personalized emails. Dont lose them!'
            WHEN R_score = 1 AND F_score >= 4 AND M_score >= 4 THEN 'Win them back via renewals or newer products!'
            WHEN R_score = 1 AND F_score <= 2 AND M_score <= 2 THEN 'Dont spend too much trying to re-acquire.'
            ELSE 'Standard marketing approach.'
        END as recommended_action
    FROM customer_rfm_scores
)
SELECT 
    companyName,
    country,
    city,
    recency_days,
    frequency_orders,
    monetary_value,
    R_score,
    F_score,
    M_score,
    RFM_total_score,
    RFM_segment_code,
    customer_segment,
    recommended_action
FROM customer_segments
ORDER BY RFM_total_score DESC, monetary_value DESC;


SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(recency_days), 0) as avg_recency,
    ROUND(AVG(frequency_orders), 1) as avg_frequency,
    ROUND(SUM(monetary_value), 2) as total_value,
    ROUND(AVG(monetary_value), 2) as avg_value,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as pct_customers,
    ROUND(100.0 * SUM(monetary_value) / SUM(SUM(monetary_value)) OVER (), 2) as pct_total_value
FROM customer_segments
GROUP BY customer_segment
ORDER BY total_value DESC;

