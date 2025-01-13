-- Zomato 20 Advaned Business Problems Solutions

SELECT * FROM customers;
SELECT * FROM restaurants;
SELECT * FROM orders;
SELECT * FROM riders;
SELECT * FROM deliveries;

-- Business Problems Solutions

-- Q.1
-- Write a query to find the top 5 most frequently ordered dishes by customer called "Arjun Mehta" .

SELECT 
		c.customer_name,
		o.order_item,
		count(*) as total_orders
FROM customers as c
JOIN
orders as o
on c.customer_id = o.customer_id
WHERE 
	c.customer_name = 'Arjun Mehta'
group by 1,2
ORDER by 3 DESC
limit 5

-- 2. Popular Time Slots
-- Question: Identify the time slots during which the most orders are placed. based on 2-hour intervals.

-- Approach 1

SELECT
    CASE
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00 - 00:00'
    END AS time_slot,
    COUNT(order_id) AS order_count
FROM Orders
GROUP BY time_slot
ORDER BY order_count DESC;

-- Approach 2

SELECT 
		floor(EXTRACT (HOUR FROM order_time)/2)*2 as start_time,
		floor(EXTRACT (HOUR FROM order_time)/2)*2+2 as end_time,
		count(*) as total_orders
from orders
GROUP BY 1,2
ORDER BY 3 DESC

-- 3. Order Value Analysis
-- Question: Find the average order value per customer who has placed more than 750 orders.
-- Return customer_name, and aov(average order value)

SELECT
		c.customer_name,
		round(
			avg(o.total_amount),2) as avg_order_value
from orders as o
JOIN
customers as c
on c.customer_id = o.customer_id
group by 1
having count(o.order_id)>750
ORDER by 2 DESC;


-- 4. High-Value Customers
-- Question: List the customers who have spent more than 100K in total on food orders.
-- return customer_name, and customer_id!

SELECT
		c.customer_name,
		o.customer_id,
		sum(o.total_amount) as total_amount_spent
FROM 
customers as c
JOIN
orders as o
on o.customer_id = c.customer_id
GROUP BY 1,2
HAVING sum(o.total_amount)>100000
ORDER BY 3 DESC

-- 5. Orders Without Delivery
-- Question: Write a query to find orders that were placed but not delivered. 
-- Return each restuarant name, city and number of not delivered orders 

select 
		r.restaurant_name,
		r.city,
		count(o.order_id) as not_delivered_orders
FROM orders as o
LEFT join
restaurants as r
on r.restaurant_id = o.restaurant_id
LEFT join
deliveries as d
on d.order_id = o.order_id
where d.delivery_id is null
GROUP BY 1,2
order by 3 DESC


-- Q. 6
-- Restaurant Revenue Ranking: 
-- Rank restaurants by their total revenue including their name, 
-- total revenue, and rank within their city.

WITH ranking
AS
(
	SELECT 
			r.city,
			r.restaurant_name,
			sum(o.total_amount) as total_revenue,
			rank() OVER( PARTITION BY r.city ORDER BY sum(o.total_amount)) as Rank_within_their_city
	FROM restaurants as r
	JOIN
		 orders as o
	ON r.restaurant_id = o.restaurant_id
	GROUP BY 1 ,2
)
SELECT * 
from ranking
where Rank_within_their_city=1
order by total_revenue DESC;



-- Q. 7
-- Most Popular Dish by City: 
-- Identify the most popular dish in each city based on the number of orders.

WITH 
ranking AS
(
	SELECT 
			r.city as city,
			o.order_item as dish,
			COUNT(o.order_id) as total_orders,
			RANK() OVER(PARTITION BY r.city ORDER BY COUNT(o.order_id)DESC) AS rank
	FROM orders as o
	JOIN
		 restaurants as r
	ON r.restaurant_id = o.restaurant_id
	GROUP BY 1,2
)
SELECT
		city,
		dish,
		total_orders
from ranking
where rank = 1;

-- Q.8 Customer Churn: 
-- Find customers who haven’t placed an order in 2024 but did in 2023.

SELECT 
		DISTINCT(customer_id)
FROM orders
WHERE 
		EXTRACT (YEAR FROM order_date) = 2023
AND customer_id NOT IN
		(SELECT 
			DISTINCT(customer_id)
		FROM orders
		WHERE 
			EXTRACT (YEAR FROM order_date) = 2024)


-- Q.9 Cancellation Rate Comparison: 
-- Calculate and compare the order cancellation rate for each restaurant between the 
-- current year and the previous year.

WITH cancel_ratio_2023
AS
(
	select 
			o.restaurant_id,
			count(o.order_id) as total_orders,
			count( CASE WHEN delivery_id IS NULL THEN 1 END) AS not_deleiverd_orders
	from orders as o
	LEFT JOIN
	deliveries AS d
	ON o.order_id=d.order_id
	WHERE EXTRACT( YEAR FROM o.order_date) = 2023
	GROUP BY 1
),
cancel_ratio_2024
AS
(
	select 
			o.restaurant_id,
			count(o.order_id) as total_orders,
			count( CASE WHEN delivery_id IS NULL THEN 1 END) AS not_deleiverd_orders
	from orders as o
	LEFT JOIN
	deliveries AS d
	ON o.order_id=d.order_id
	WHERE EXTRACT( YEAR FROM o.order_date) = 2024
	GROUP BY 1
),
last_year_ratio
AS(
	select 	
			restaurant_id,
			total_orders,
			not_deleiverd_orders,
			ROUND(not_deleiverd_orders::numeric/total_orders::numeric*100,2) as cancel_ratio
	from cancel_ratio_2023
),
current_year_ratio
AS(
	select 	
			restaurant_id,
			total_orders,
			not_deleiverd_orders,
			ROUND(not_deleiverd_orders::numeric/total_orders::numeric*100,2) as cancel_ratio
	from cancel_ratio_2024
)

SELECT 
		l.restaurant_id as restaurant_id,
		l.cancel_ratio as last_year_cancel_ratio,
		c.cancel_ratio as current_year_cancel_ratio
FROM
last_year_ratio AS l
JOIN
current_year_ratio AS c
ON l.restaurant_id = c.restaurant_id


-- Q.10 Rider Average Delivery Time: 
-- Determine each rider's average delivery time.

SELECT 
    o.order_id,
    o.order_time,
    d.delivery_time,
    d.rider_id,
    d.delivery_time - o.order_time AS time_difference,
	EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + 
	CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE
	INTERVAL '0 day' END))/60 as time_difference_insec
from orders AS o
join deliveries AS d
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered';


-- Q.11 Monthly Restaurant Growth Ratio: 
-- Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining

WITH growth_ratio
AS
(
SELECT 
	o.restaurant_id,
	EXTRACT(YEAR FROM o.order_date) as year,
	EXTRACT(MONTH FROM o.order_date) as month,
	COUNT(o.order_id) as cr_month_orders,
	LAG(COUNT(o.order_id), 1) OVER(PARTITION BY o.restaurant_id ORDER BY EXTRACT(YEAR FROM o.order_date),
    EXTRACT(MONTH FROM o.order_date)) as prev_month_orders
FROM orders as o
JOIN
deliveries as d
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered'
GROUP BY 1, 2, 3
ORDER BY 1, 2
)
SELECT
	restaurant_id,
	month,
	prev_month_orders,
	cr_month_orders,
	ROUND(
	(cr_month_orders::numeric-prev_month_orders::numeric)/prev_month_orders::numeric * 100
	,2)
	as growth_ratio
FROM growth_ratio;


-- Q.12 Customer Segmentation: 
-- Customer Segmentation: Segment customers into 'Gold' or 'Silver' groups based on their total spending 
-- compared to the average order value (AOV). If a customer's total spending exceeds the AOV, 
-- label them as 'Gold'; otherwise, label them as 'Silver'. Write an SQL query to determine each segment's 
-- total number of orders and total revenue
		
SELECT 
	customer_category,
	SUM(total_orders) as total_orders,
	SUM(total_spent) as total_revenue
FROM

	(SELECT 
		customer_id,
		SUM(total_amount) as total_spent,
		COUNT(order_id) as total_orders,
		CASE 
			WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold'
			ELSE 'silver'
		END as customer_category
	FROM orders
	group by 1
	) as t1
GROUP BY 1


-- Q.13 Rider Monthly Earnings: 
-- Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.

SELECT 
		r.rider_id,
		r.rider_name,
		TO_CHAR(o.order_date, 'mm-yy') as month,
		sum(o.total_amount) * 0.08 as rider_earning
FROM orders as o
LEFT JOIN
deliveries as d
on d.order_id = o.order_id
join 
riders as r
on d.rider_id = r.rider_id
GROUP BY 1,2,3
ORDER BY 1,3;

-- Q.14 Rider Ratings Analysis: 
-- Find the number of 5-star, 4-star, and 3-star ratings each rider has.
-- riders receive this rating based on delivery time.
-- If orders are delivered less than 15 minutes of order received time the rider get 5 star rating,
-- if they deliver 15 and 20 minute they get 4 star rating 
-- if they deliver after 20 minute they get 3 star rating.


SELECT 
	rider_id,
	stars,
	COUNT(*) as total_stars
FROM
(
	SELECT
		rider_id,
		delivery_took_time,
		CASE 
			WHEN delivery_took_time < 15 THEN '5 star'
			WHEN delivery_took_time BETWEEN 15 AND 20 THEN '4 star'
			ELSE '3 star'
		END as stars
		
	FROM
	(
		SELECT 
			o.order_id,
			o.order_time,
			d.delivery_time,
			EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + 
			CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' 
			ELSE INTERVAL '0 day' END
			))/60 as delivery_took_time,
			d.rider_id
		FROM orders as o
		JOIN deliveries as d
		ON o.order_id = d.order_id
		WHERE delivery_status = 'Delivered'
	) as t1
) as t2
GROUP BY 1, 2
ORDER BY 1, 3 DESC


-- Q.15 Order Frequency by Day: 
-- Analyze order frequency per day of the week and identify the peak day for each restaurant.

select 
		restaurant_name,
		day,
		total_orders
from(
	select 
			r.restaurant_name,
			TO_CHAR(o.order_date , 'Day') as day,
			count(o.order_id) total_orders,
			RANK() OVER (PARTITION BY r.restaurant_name ORDER BY count(o.order_id) DESC) AS rank
	FROM orders as o
	JOIN 
	restaurants as r
	ON o.restaurant_id = r.restaurant_id
	GROUP BY 1,2
	ORDER BY 1,3)
AS t1
where rank=1


-- Q.16 Customer Lifetime Value (CLV): 
-- Calculate the total revenue generated by each customer over all their orders.

SELECT 
 		c.customer_name,
		sum(o.total_amount) as total_spending
FROM orders as o
JOIN
customers as c
ON o.customer_id=c.customer_id
GROUP BY 1
ORDER BY 2 DESC


-- Q.17 Monthly Sales Trends: 
-- Identify sales trends by comparing each month's total sales to the previous month.

SELECT
		EXTRACT(YEAR FROM order_date) as year,
		EXTRACT(MONTH FROM order_date) as month,
		sum(total_amount) as total_sales,
		lag(sum(total_amount),1) OVER (ORDER BY EXTRACT(YEAR FROM order_date),EXTRACT(MONTH FROM order_date)) as previous_month_sale
FROM orders
GROUP BY 1,2

-- Q.18 Rider Efficiency: 
-- Evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest averages.


WITH new_table
AS
(
	SELECT 
		*,
		d.rider_id as riders_id,
		EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + 
		CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE
		INTERVAL '0 day' END))/60 as time_deliver
	FROM orders as o
	JOIN deliveries as d
	ON o.order_id = d.order_id
	WHERE d.delivery_status = 'Delivered'
),

riders_time
AS

(
	SELECT 
		riders_id,
		AVG(time_deliver) avg_time
	FROM new_table
	GROUP BY 1
)
SELECT 
		MIN(avg_time),
		MAX(avg_time)
FROM riders_time



-- Q.19 Order Item Popularity: 
-- Track the popularity of specific order items over time and identify seasonal demand spikes.


SELECT 
		order_item,
		seasons,
		count(order_id) AS total_orders
FROM
	(SELECT 
			*,
			EXTRACT(MONTH FROM order_date) as month,
			CASE 
				WHEN EXTRACT(MONTH FROM order_date) BETWEEN 4 AND 6 THEN 'Spring'
				WHEN EXTRACT(MONTH FROM order_date) > 6 AND 
				EXTRACT(MONTH FROM order_date) < 9 THEN 'Summer'
				ELSE 'Winter'
			END as seasons
		FROM orders)
GROUP BY 1,2
ORDER BY 1;


-- Q.20 Rank each city based on the total revenue for last year 2023 

SELECT 
		r.city,
		sum(o.total_amount) AS total_revenue,
		RANK() OVER (ORDER BY sum(o.total_amount) DESC) AS rank
FROM orders as o
JOIN
restaurants as r
ON r.restaurant_id = o.restaurant_id
WHERE EXTRACT(YEAR FROM order_date) = 2023
GROUP BY 1;



