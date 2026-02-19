
SELECT * FROM categories c 
SELECT * FROM orders o
SELECT * FROM order_details od
SELECT * FROM customers c
SELECT * FROM employees e

-- Products and categories that makes the most money
SELECT c.categoryName,
		COUNT(DISTINCT o.orderID) as total_orders,
		SUM(od.quantity) as total_units_sold,
		ROUND(SUM(od.unitPrice * od.quantity * (1-od.discount)), 2) as total_revenue_value,
        ROUND(AVG(od.unitPrice * od.quantity * (1-od.discount)), 2) as avg_order_line
FROM categories c
JOIN products p ON c.categoryID = p.categoryID
JOIN order_details od ON p.productID = od.productID
JOIN orders o ON od.orderID = o.orderID
GROUP BY c.categoryName
ORDER BY total_revenue_value;

-- Finding the top 10 customers by Value
WITH customer_revenue AS (
     SELECT 
          c.customerID,
          c.companyName,
          c.country,
          c.city,
          COUNT(DISTINCT o.orderID) as total_orders,
          SUM(od.quantity) as total_items_purchased,
          ROUND(SUM(od.unitPrice * od.quantity * (1-od.discount)), 2) as total_spent,
          ROUND(AVG(od.unitPrice * od.quantity * (1-od.discount)), 2) as avg_order_line,
          DENSE_RANK() OVER(ORDER BY SUM(od.unitPrice * od.quantity * (1-od.discount)) DESC) as revenue_rank
          
          FROM customers c
          JOIN orders o ON c.customerID = o.customerID 
          JOIN order_details od ON o.orderID = od.orderID 
          GROUP BY c.customerID, c.companyName, c.country, c.city
) 
      SELECT revenue_rank,
		      companyName,
		      country,
		      city,
		      total_orders,
		      total_items_purchased,
		      total_spent
		      avg_order_line_value,
		      ROUND(total_spent/total_orders, 2) as avg_order_value
      FROM customer_revenue 
      WHERE revenue_rank <= 10
      ORDER BY revenue_rank;
      
          
-- Employee Sales Ranking
WITH employees_rank AS(
		SELECT 
		    e.employeeID,
		    e.employeeName,
		    e.title,
		    e.city as employee_city,
		    COUNT(DISTINCT o.orderID) as orders_handled,
		    ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as total_sales,
		    ROUND(AVG(od.unitPrice * od.quantity * (1 - od.discount)), 2) as avg_sale_value,
		    COUNT(DISTINCT o.customerID) as unique_customers_served,
		    DENSE_RANK() OVER (ORDER BY SUM(od.unitPrice * od.quantity * (1 - od.discount)) DESC) as sales_rank
		FROM employees e
		JOIN orders o ON e.employeeID = o.employeeID
		JOIN order_details od ON o.orderID = od.orderID
		GROUP BY e.employeeID, e.employeeName, e.title, e.city
		
)
SELECT 
     sales_rank,
     employeeName,
     title,
     employee_city,
     orders_handled,
     total_sales,
     avg_sale_value
     FROM employees_rank
     WHERE sales_rank<=10
     ORDER BY sales_rank;

-- Monthly Trend Over Time
SELECT 
     STRFTIME('%Y', o.orderDate) as year,
     STRFTIME('%M', o.orderDate) as month,
     STRFTIME('%Y-%M', o.orderDate) as year_month,
     COUNT(DISTINCT o.orderID) as total_orders,
     SUM(od.quantity) as total_items_sold,
     ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as monthly_revenue,
	 ROUND(AVG(od.unitPrice * od.quantity * (1 - od.discount)), 2) as avg_order_line_revenue
FROM orders o
JOIN order_details od ON o.orderID = od.orderID
GROUP BY year, month, year_month
ORDER BY year_month;

--Or Advanced Analysis
WITH monthly_revenue AS (
    SELECT 
        strftime('%Y-%m', o.orderDate) as year_month,
        COUNT(DISTINCT o.orderID) as total_orders,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as revenue
    FROM orders o
    JOIN order_details od ON o.orderID = od.orderID
    GROUP BY year_month
)
SELECT 
    year_month,
    total_orders,
    revenue,
    LAG(revenue) OVER (ORDER BY year_month) as prev_month_revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY year_month), 2) as revenue_change,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY year_month)) / 
          NULLIF(LAG(revenue) OVER (ORDER BY year_month), 0), 2) as pct_change
FROM monthly_revenue
ORDER BY year_month;

-- Products that we should promote heavily
WITH product_performance AS (
    SELECT 
        p.productID,
        p.productName,
        c.categoryName,
        p.unitPrice as list_price,
        COUNT(DISTINCT od.orderID) as times_ordered,
        SUM(od.quantity) as total_quantity_sold,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as total_revenue,
        ROUND(AVG(od.discount), 4) as avg_discount_rate,
        DENSE_RANK() OVER (ORDER BY SUM(od.unitPrice * od.quantity * (1 - od.discount)) DESC) as revenue_rank
    FROM products p
    JOIN categories c ON p.categoryID = c.categoryID
    JOIN order_details od ON p.productID = od.productID
    GROUP BY p.productID, p.productName, c.categoryName, p.unitPrice
)
SELECT 
    revenue_rank,
    productName,
    categoryName,
    list_price,
    times_ordered,
    total_quantity_sold,
    total_revenue,
    avg_discount_rate,
    CASE 
        WHEN revenue_rank <= 10 THEN 'Top Performer'
        WHEN revenue_rank <= 30 THEN 'Strong Performer'
        WHEN revenue_rank <= 50 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END as performance_tier
FROM product_performance
ORDER BY revenue_rank
LIMIT 20;

-- Average Order Value By Customer
-- Which customers place large orders vs small orders? How does this affect our fulfillment strategy?
SELECT 
      c.companyName,
      c.country,
      COUNT(DISTINCT o.orderID) AS total_orders,
      ROUND(SUM(od.unitPrice * od.quantity * (1-od.discount)), 2) as total_spent,
      ROUND(SUM(od.unitPrice * od.quantity * (1-od.discount))/COUNT(DISTINCT o.orderID), 2) AS avg_order_value,
      MIN(o.orderDate) as first_order_date,
      MAX(o.orderDate) as last_order_date,
      ROUND(julianday(MAX(o.orderDate)) - julianday(MIN(o.orderDate)),0) as customer_tenure_days,
      CASE 
      	WHEN COUNT(DISTINCT o.orderID) >= 15 THEN 'Frequent Buyer'
      	WHEN COUNT(DISTINCT o.orderID) >= 8 THEN 'Regular Customer'
      	WHEN COUNT(DISTINCT o.orderID) >= 3 THEN 'Occasssional Buyer'
      	ELSE 'New/Frequent'
      END AS customer_segment
      FROM customers c
      JOIN orders o ON c.customerID = o.customerID
      JOIN order_details od ON o.orderID = od.orderID
      GROUP BY c.companyName, c.country 
      HAVING COUNT(DISTINCT o.orderID) >= 3
      ORDER BY avg_order_value DESC
      LIMIT 20;
      

--Revenue Per Country
--What countries are our biggest markets? Where should we expand? Where should we invest in Marketing?
WITH country_performance AS(
      SELECT 
            c.country,
            COUNT(DISTINCT c.customerID) as total_customers,
            COUNT(DISTINCT o.orderID) AS total_orders,
            SUM(od.quantity) as total_items_sold,
            ROUND(SUM(od.unitPrice * od.quantity * (1-od.discount)), 2) as total_revenue,
            ROUND(SUM(od.unitPrice * od.quantity * (1-od.discount))/COUNT(DISTINCT o.orderID), 2) AS total_revenue_per_customer,
            ROUND(SUM(od.unitPrice * od.quantity * (1-od.discount))/COUNT(DISTINCT o.orderID), 2) AS avg_order_value,
            DENSE_RANK() OVER(ORDER BY SUM(od.unitPrice * od.quantity * (1-od.discount))DESC) as country_rank
      FROM customers c
      JOIN orders o ON c.customerID = O.customerID
      JOIN order_details od ON o.orderID =  od.orderID
      GROUP BY c.country
      )
      SELECT 
            country_rank,
            country,
            total_customers,
            total_orders,
            total_items_sold,
            total_revenue,
            total_revenue_per_customer,
            avg_order_value,
            ROUND(100.0 * total_revenue/SUM(total_revenue) OVER(), 2) AS pct_of_total_revenue,
            CASE WHEN country_rank <= 5 THEN 'Primary Market'
                 WHEN country_rank <= 10 THEN 'Secondary Market'
                 ELSE 'Emerging Market'
            END AS marker_tier
      FROM country_performance
      ORDER BY country_rank;

-- Impacts of Discounts on Revenue
--Do discounts help or hurt us? Are we giving away too much margin? Whats the Optimal Strategy?
WITH discount_analysis AS (
           SELECT od.orderID,
                  od.productID,
                  p.productName,
                  c.categoryName,
                  od.quantity,
                  od.unitPrice,
                  od.discount,
                  ROUND(od.unitPrice * od.quantity,2) as revenue_without_discount,
                  ROUND(od.unitPrice * od.quantity*(1-od.discount),2) as revenue_with_discount,
                  ROUND(od.unitPrice * od.quantity, 2) as discount_amount,
                  CASE WHEN od.discount = 0  THEN 'No discount'
                       WHEN od.discount <= 0.05   THEN '(1-5)% Discount'   
                       WHEN od.discount <= 0.10   THEN '(6-10)% Discount' 
                       WHEN od.discount <= 0.15   THEN '(11-15)% Discount'
                       WHEN od.discount <= 0.2   THEN '(16-20)% Discount'
                       ELSE '>20% Discount'
                       
                  END AS discount_tier
                  FROM order_details od
                  JOIN products p ON od.productID = p.productID
                  JOIN categories c ON p.categoryID = c.categoryID 
                  
                  
)
    SELECT discount_tier
           count(*) as order_lines
           SUM(quantity) as total_units,
           ROUND(SUM(revenue_without_discount), 2) as potential_revenue
           ROUND(SUM(revenue_with_discount), 2) as actual_revenue  
           ROUND(SUM(discount_amount), 2) as total_discount_given
           ROUND(100 * SUM(discount_amount)/SUM(reveneu_without_discount),2) as pct_revenue_lost,
           ROUND(AVG(discount), 4) as  avg_discount_rate
    FROM  discount_analysis  
    GROUP BY discount_tier
    ORDER BY 
           CASE discount_tier
             WHEN 'No Discoutn' THEN 1
             WHEN '(1-5)% Discount' THEN 2
             WHEN '(6-10)% Discount' THEN 3
             WHEN '(11-15)% Discount' THEN 4
             WHEN '(16-20)% Discount' THEN 5
             ELSE 6
            END;

-- Order Fulfillment Time(Operational Efficiency)
-- How do we ship orders? Are we meeting Customer Expectations? Which Shippers are fastest?
SELECT o.orderID,
       o.orderDate,
       o.requiredDate,
       o.shippedDate,
       s.companyName as shipper,
       c.companyName as customer,
       c.country,
       julianday(o.shippedDate) - julianday(o.orderDate) as days_to_ship,
       julianday(o.requiredDate) - julianday(o.orderDate) as days_before_required,
       CASE 
	       	WHEN o.shippedDate IS NULL THEN 'Not Shipped'
	       	WHEN julianday(o.shippedDate) <= julianday(o.requiredDate) THEN 'On-Time'
	       	ELSE 'Late'
       END as delivery_status,
      ROUND(o.freight, 2) as freight_cost
FROM orders o
       	JOIN customers c ON o.customerID = c.customerID
       	LEFT JOIN shippers s ON o.shipperID = s.shipperID
       	WHERE o.shippedDate IS NOT NULL
       	ORDER BY days_to_ship DESC
       	LIMIT 20;
       	
-- Summary Shipper
SELECT 
     s.companyName as shipper,
     COUNT(o.orderID) as total_orders,
     ROUND(AVG(julianday(o.shippedDate) - julianday(o.orderDate)),2) as avg_days_to_ship,
     ROUND(MIN(julianday(o.shippedDate) - julianday(o.orderDate)),2) as fastest_shipment,
     ROUND(MAX(julianday(o.shippedDate) - julianday(o.orderDate)),2) as slowest_shipment,
     SUM(CASE WHEN julianday(o.shippedDate) <= julianday(o.requiredDate) THEN 1 ELSE 0 END) AS on_time_orders,
      ROUND(100.0 * SUM(CASE WHEN julianday(o.shippedDate) <= julianday(o.requiredDate) THEN 1 ELSE 0 END) / 
          COUNT(o.orderID), 2) as on_time_pct,
     ROUND(AVG(o.freight), 2) as avg_freight_cost,
     ROUND(SUM(o.freight), 2 ) as total_freight_cost
FROM orders o
JOIN shippers s ON o.shipperID = s.shipperID
WHERE o.shippedDate IS NOT NULL
GROUP BY s.companyName
ORDER BY avg_days_to_ship;

-- Product Category Profit Margins
-- Which Categories are Most Profitable? Where should we focus our efforts 
-- Since we don't have the actual cost of the data, we  will estimate based on patterns
WITH category_metrics AS (
      SELECT 
           c.categoryName,
           COUNT(DISTINCT p.productID) AS products_in_category,
           COUNT(DISTINCT od.orderID) AS total_orders,
           SUM(od.quantity) as total_units_sold,
           ROUND(SUM(od.unitPrice * od.quantity * (1-od.discount)),2) as total_revenue,
           ROUND(AVG(p.unitPrice), 2) as avg_product_price,
           ROUND(AVG(od.discount), 2) as discount_rate,
           ROUND(SUM(od.unitPrice * od.quantity* (1-od.discount))* 0.6,2) as estimated_gross_profit,
           ROUND(100.00 * 0.6, 2) as estimated_margin_pct
           
      FROM categories c
      JOIN products p ON c.categoryID  = p.categoryID
      JOIN order_details od ON p.productID = od.productID
      GROUP BY c.categoryName 
      )
      SELECT 
            categoryName,
            products_in_category,
            total_orders,
            total_units_sold,
            total_revenue,
            avg_product_price,
            discount_rate,
            estimated_gross_profit,
            estimated_margin_pct,
            ROUND(total_revenue/total_units_sold, 2) as revenue_per_unit,
			ROUND(estimated_gross_profit/total_units_sold, 2) as profit_per_unit,
			DENSE_RANK() OVER(ORDER BY total_revenue DESC) as revenue_rank,
			DENSE_RANK() OVER(ORDER BY estimated_gross_profit DESC) as profit_rank
	FROM category_metrics
	ORDER BY estimated_gross_profit DESC;
      


     


       