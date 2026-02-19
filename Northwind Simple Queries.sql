-- 1. Total customers
SELECT COUNT(*) as total_customers FROM customers;


-- Calculatng the total revenue
SELECT SUM(unitPrice * quantity * (1 - discount)) as revenue
FROM order_details;

-- List all the categories and the number of products reagardless of any category having 0 products
SELECT c.categoryName, COUNT(p.productID) as products
FROM categories c
LEFT JOIN products p ON c.categoryID = p.categoryID
GROUP BY c.categoryName;

--Top 5 customers 
SELECT c.companyName, c.country,
       ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as total_spent
FROM customers c
JOIN orders o ON c.customerID = o.customerID
JOIN order_details od ON o.orderID = od.orderID
GROUP BY c.companyName, c.country
ORDER BY total_spent DESC
LIMIT 5;

-- Top 5 customers using the window  function
WITH customer_spend AS (
    SELECT
        c.customerID,
        c.companyName,
        c.country,
        SUM(od.unitPrice * od.quantity * (1 - od.discount)) AS total_spent
    FROM customers c
    JOIN orders o ON c.customerID = o.customerID
    JOIN order_details od ON o.orderID = od.orderID
    GROUP BY c.customerID, c.companyName, c.country
)
SELECT
    companyName,
    country,
    ROUND(total_spent, 2) AS total_spent
FROM (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS rnk
    FROM customer_spend
) ranked
WHERE rnk <= 5
ORDER BY total_spent DESC;


-- Another One to handle the ties
-- Top 5 customers handling ties with DENSE_RANK
WITH customer_revenue AS (
    SELECT 
        c.companyName,
        c.country,
        COUNT(DISTINCT o.orderID) as total_orders,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) as total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(od.unitPrice * od.quantity * (1 - od.discount)) DESC) as rank
    FROM customers c
    JOIN orders o ON c.customerID = o.customerID
    JOIN order_details od ON o.orderID = od.orderID
    GROUP BY c.companyName, c.country
)
SELECT companyName, country, total_orders, total_spent, rank
FROM customer_revenue
WHERE rank <= 5;

-- Get the monthly orders
SELECT strftime('%Y-%m', orderDate) as month, 
       COUNT(*) as orders
FROM orders
GROUP BY month
ORDER BY month