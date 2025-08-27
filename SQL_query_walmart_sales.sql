-- Walmart Data Analysis

--Create database
CREATE DATABASE WalmartSales;

-- Create table
DROP TABLE IF EXISTS walmart_sales;
CREATE TABLE sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT,
    gross_income DECIMAL(12, 4),
    rating FLOAT
);

-- DATA CLEANING
Select * from sales;

Select count(*) from sales;

-- Add time_of_the_day
select 
	time,
	(CASE
		WHEN extract(hour from time) between 10 and 12 then 'Morning'
		WHEN extract(hour from time) between 12 and 16 then 'Afternoon'
		ELSE 'Evening'
	END) AS time_of_day
	from sales;

--Add column to the sales table
ALTER TABLE sales ADD COLUMN time_of_day varchar(10);

select * from sales;

-- add column values to table
Update sales
	set time_of_day=(
			case
				WHEN extract(hour from time) between 10 and 12 then 'Morning'
				WHEN extract(hour from time) between 12 and 16 then 'Afternoon'
				ELSE 'Evening'
			end
	);

-- Add month_name column

ALTER TABLE sales add column month_name varchar(10);

update sales 
	set month_name=to_char(date,'Month');

--Add day_name column
ALTER TABLE sales add column day_name varchar(10);

update sales
	set day_name=to_char(date,'DAY');

--Business Questions To Answer

--- Generic Question

-- How many unique cities does the data have?
select 
	distinct city 
from sales;

--In which city is each branch?
select 
	distinct city,
	branch
from sales;

-- Product Questions 

--How many unique product lines does the data have?
select 
	count(distinct product_line) as number_of_unique_product_lines
from sales;

--What is the most common payment method?
select 
	payment,
	count(*) as count
from sales
group by payment
order by count desc
limit 1;

-- 3. What is the most selling product line?
select 
	product_line,
	sum(Quantity) as total_quantity
from sales
group by product_line
order by total_quantity desc
limit 1;

-- 4. What is the total revenue by month?
select 
	month_name,
	sum(total) as total_revenue
from sales
group by month_name
order by month_name;

-- 5. What month had the largest COGS?
select 
	month_name,
	sum(cogs) as total_cogs
from sales
group by month_name
order by total_cogs desc
limit 1;

-- 6. What product line had the largest revenue?
select 
	product_line,
	sum(total) as total_revenue
from sales
group by product_line
order by total_revenue desc
limit 1;

-- 7. What is the city with the largest revenue?
select 
	city,
	sum(total) as total_revenue
from sales
group by city
order by total_revenue desc
limit 1;

-- 8. What product line had the largest VAT?
select 
	product_line,
	sum(tax_pct) as total_vat
from sales
group by product_line
order by total_vat desc
limit 1;

-- 9. Fetch each product line and add a column showing "Good", "Bad". Good if its greater than average sales
select 
	product_line,
	sum(total) as total_sales,
	case
		when sum(total)>( select avg(total_sales) from (select sum(total) as total_sales from sales group by product_line) as avg_sales)
		then 'Good'
		else 'Bad'
	end as performance
from sales 
group by product_line;

-- 10. Which branch sold more products than average product sold?
SELECT 
	branch, 
    SUM(quantity) AS total_quantity
FROM sales
GROUP BY branch
HAVING SUM(quantity) > (SELECT AVG(quantity) FROM sales);

--11. What is the most common product line by gender?
with ranked_products AS (
    SELECT 
        gender,
        product_line,
         count(*) as total_count,
        ROW_NUMBER() OVER (PARTITION BY gender ORDER BY count(*) DESC) as rn
    FROM sales
	group by gender,product_line
)
SELECT 
    gender,
    product_line,
    total_count
FROM ranked_products
WHERE rn = 1;

--12. What is the average rating of each product line?
select 
	product_line,
	avg(rating) as average_rating
from sales
group by product_line
order by average_rating desc;


----CUSTOMERS

--1. How many unique customer types does the data have?
select
	distinct customer_type as unique_customer
from sales;

-- 2. How many unique payment methods does the data have?
select
	distinct payment as unique_payment_method
from sales;

-- 3. What is the most common customer type?
select
	customer_type,
	count(*) as count
from sales
group by customer_type
order by count desc
limit 1;

-- 4. Which customer type buys the most?
select
	customer_type,
	sum(total) as total_spend
from sales
group by customer_type
order by total_spend desc
limit 1;

-- 5. What is the gender of most of the customers?
select
	 gender,
	 count(*) as customer_count
from sales
group by gender 
order by customer_count desc
limit 1;

-- 6. What is the gender distribution per branch?
select 
	branch,
	gender,
	count(*) as count
from sales
group by branch,gender
order by branch,count desc;

-- 7. Which time of the day do customers give most ratings?
select
	time_of_day,
	count(rating) as rating_count
from sales
group by time_of_day
order by rating_count desc
limit 1;

-- 8. Which time of the day do customers give most ratings per branch?
with ranked_time as (
	select branch,
		time_of_day,
		count(rating) as rating_count,
		row_number() over(partition by branch order by count(rating) desc) as rn
		from sales
		group by branch,time_of_day
)
select
	branch,
	time_of_day,
	rating_count
from ranked_time
where rn=1;

-- 9. Which day of the week has the best avg ratings?
select
	day_name,
	avg(rating) as avg_rating
from sales
group by day_name
order by avg_rating desc
limit 1;

-- 10. Which day of the week has the best average ratings per branch?
with branch_rating as (
	select 
		branch,
		day_name,
		avg(rating) as avg_rating,
		row_number() over (partition by branch order by avg(rating) desc ) as rn
		from sales
		group by branch,day_name
)
select 
	branch,
	day_name,
	avg_rating
from branch_rating
where rn=1;

---- SALES

-- 1. Number of sales made in each time of the day per weekday
select
	time_of_day,
	count(*) as sales_count
from sales
group by time_of_day
order by sales_count,time_of_day;

-- 2. Which of the customer types brings the most revenue?
select
	customer_type,
	sum(total)  as total_revenue
from sales
group by customer_type
order by total_revenue desc
limit 1;

-- 3. Which city has the largest tax percent/ VAT (Value Added Tax)?
select 
	city,
	sum(tax_pct) as total_vat,
	(sum(tax_pct)/sum(total)*100) as vat_percentage
from sales
group by city
order by vat_percentage desc
limit 1;

-- 4. Which customer type pays the most in VAT?
select
	customer_type,
	sum(tax_pct) as total_vat_paid
from sales
group by customer_type
order by total_vat_paid desc
limit 1;