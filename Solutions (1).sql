-- Monday Coffee -- Data Analysis 

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports & Data Analysis


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
	ROUND(
	(population * 0.25)/1000000, 
	2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?


select c1.city_name,sum(s.total) as revenue
from sales s join customers c
on s.customer_id=c.customer_id join city c1
on c.city_id=c1.city_id
where extract(quarter from s.sale_date)=4 and
		extract(year from s.sale_date)=2023
group by 1
order by 2 desc;



SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)  = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC


-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

select * from products;
select * from sales;
use monday_coffee_db;
select count(p.product_id),p.product_name
from sales s left join products p
on s.product_id=p.product_id
group by 2
order by 1 desc;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city


select c1.city_name,sum(s.total) as revenue,
		count(distinct c.customer_id) as cust_per_city,
		round(sum(s.total)/count(distinct s.customer_id),2) as avg_sale_per_cust
from sales s join customers c
on s.customer_id=c.customer_id join city c1
on c.city_id=c1.city_id
group by 1
order by 2 desc;


-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

with city_table as 
(
select city_name,population,round((population*0.25)/1000000,2) as coffee_consumers_in_millions
from city) ,  customers_table as

(
select ci.city_name ,count(distinct cs.customer_id) as unique_cx
from sales s join customers cs
on s.customer_id = cs.customer_id join city ci
on ci.city_id =cs.city_id
group by 1
)
select city_table.city_name, city_table.coffee_consumers_in_millions,customers_table.unique_cx
from city_table  join customers_table 
on city_table.city_name= customers_table.city_name ;



-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

select * from
(
select ci.city_name,p.product_name,
count(s.sale_id) as total_orders,
dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc) as rank1
from sales s join products p
on s.product_id=p.product_id  join customers cs
on cs.customer_id =s.customer_id join city ci
on ci.city_id =cs.city_id 
group by 1,2
-- order by 1,3 desc
) as t1
where rank1 <=3;


-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

select c.city_name , count(distinct cs.customer_id ) as unique_cx
from city c left join customers cs 
on c.city_id = cs.city_id join  sales s 
on s.customer_id = cs.customer_id 
where s.product_id between 1 and 14
group by 1;


-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions

WITH city_table AS
(
    SELECT
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2
        ) AS avg_sale_per_cx
    FROM sales s
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN city ci
        ON c.city_id = ci.city_id
    GROUP BY ci.city_name
),

city_rent AS
(
    SELECT
        city_name,
        estimated_rent
    FROM city
)

SELECT
    cr.city_name,
    cr.estimated_rent,
    ct.total_revenue,
    ct.total_cx,
    ct.avg_sale_per_cx,
    ROUND(
        cr.estimated_rent / ct.total_cx,
        2
    ) AS avg_rent_per_cx
FROM city_rent cr
JOIN city_table ct
    ON cr.city_name = ct.city_name
ORDER BY avg_sale_per_cx DESC;



-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

with monthly_sales as
(
select ci.city_name,extract(month from sale_date) as month, extract(year from sale_date) as year,sum(s.total) as total_sale
from sales s join customers c 
on s.customer_id =c.customer_id join city ci
on c.city_id = ci.city_id 
group by 1,2,3
order by 1,3,2), growth_ratio as
(
select city_name,month,year ,total_sale as curr_month_sale,lag(total_sale,1) over(partition by city_name) as last_month_sale
from monthly_sales)
select city_name,month,year,curr_month_sale,last_month_sale
,round((curr_month_sale-last_month_sale)/last_month_sale*100,2) as growth_ratio
from growth_ratio;


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



WITH city_table AS
(
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2
        ) AS avg_sale_pr_cx

    FROM sales s
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN city ci
        ON ci.city_id = c.city_id

    GROUP BY ci.city_name
),

city_rent AS
(
    SELECT
        city_name,
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumer_in_millions
    FROM city
)

SELECT
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_cx,
    cr.estimated_coffee_consumer_in_millions,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent / ct.total_cx,
        2
    ) AS avg_rent_per_cx

FROM city_rent cr
JOIN city_table ct
    ON cr.city_name = ct.city_name

ORDER BY total_revenue DESC;

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.



