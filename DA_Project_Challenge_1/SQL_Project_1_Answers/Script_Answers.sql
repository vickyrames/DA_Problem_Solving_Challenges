
-- Q1. Provide the list of markets in which customer  "Atliq  Exclusive"  operates its business in the  APAC  region. (1)
Select market from dim_customer where region = 'APAC' and customer = 'Atliq Exclusive'
Group by market order by market asc; 


-- Q2.  What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, 
-- unique_products_2020 
-- unique_products_2021 
-- percentage_chg  (0)

with cte as 
(
Select product_code, count( Distinct product_code) as unique_products_2020 from fact_sales_monthly where fiscal_year = '2020'
),
cte_a as
(
Select product_code, count( Distinct product_code) as unique_products_2021 from fact_sales_monthly where fiscal_year = '2021'
)
Select  a.product_code,a.unique_products_2020,b.unique_products_2021, 
concat( round(((b.unique_products_2021 - a.unique_products_2020) / a.unique_products_2020) * 100,2), '%') as 'percentage_chg'
from cte a cross join 
cte_a b on a.product_code = b.product_code;

-- Q3.  Provide a report with all the unique product counts for each  segment  and 
-- sort them in descending order of product counts. The final output contains 
-- 2 fields, 
-- segment 
-- product_count  (1)

Select Distinct segment, count(product_code) as product_count from dim_product 
Group by segment 
order by product_count desc;

-- Q4.  Follow-up: Which segment had the most increase in unique products in 
-- 2021 vs 2020? The final output contains these fields, 
-- segment 
-- product_count_2020 
-- product_count_2021 
-- difference (0.5)
with cte as
(
Select  a.segment, count( distinct a.product_code) as product_count_2020 
from dim_product a 
join fact_sales_monthly b
on a.product_code = b.product_code
where b.fiscal_year = 2020
Group by a.segment
order by product_count_2020 desc
),
cte_a as
(
Select distinct a.segment, count( distinct a.product_code) as product_count_2021
from dim_product a 
join fact_sales_monthly b
on a.product_code = b.product_code
where b.fiscal_year = 2021
Group by a.segment
order by product_count_2021 desc
)
Select cte.segment,cte.product_count_2020,cte_a.product_count_2021,
(cte_a.product_count_2021-cte.product_count_2020) as difference from cte
join cte_a on cte.segment = cte_a.segment order by cte.segment;

-- Q5.  Get the products that have the highest and lowest manufacturing costs. 
-- The final output should contain these fields, 
-- product_code 
-- product 
-- manufacturing_cost (1)

Select pd.product_code, pd.product,Max(mf_cost.manufacturing_cost) as manufacturing_cost from dim_product pd 
join fact_manufacturing_cost mf_cost 
on pd.product_code = mf_cost.product_code 
union all 
Select pd.product_code, pd.product,Min(mf_cost.manufacturing_cost) as manufacturing_cost from dim_product pd 
join fact_manufacturing_cost mf_cost 
on pd.product_code = mf_cost.product_code ;

-- Q6.  Generate a report which contains the top 5 customers who received an average high  pre_invoice_discount_pct  
-- for the  fiscal  year 2021  and in the Indian  market. The final output contains these fields, 
-- customer_code 
-- customer 
-- average_discount_percentage

Select customer.customer_code,customer.customer,
round(Avg(invoice_deductions.pre_invoice_discount_pct),4) as average_discount_percentage
 from dim_customer customer
join fact_pre_invoice_deductions invoice_deductions
where customer.market = 'India' and invoice_deductions.fiscal_year = 2021 
Group by customer.customer_code, customer.customer
order by average_discount_percentage desc Limit 5;


-- Q7.  Get the complete report of the Gross sales amount for the customer  “Atliq 
-- Exclusive”  for each month  .  This analysis helps to  get an idea of low and high-performing months and take strategic decisions. 
-- The final report contains these columns: 
-- Month 
-- Year 
-- Gross sales Amount (1)

Select monthly_sales.fiscal_year as 'Year',monthname(monthly_sales.date) as 'Month',
round(SUM(monthly_sales.sold_quantity * gross_price.gross_price),2) as 'gross_sales_amt'
 from dim_customer customer
join fact_sales_monthly monthly_sales
on customer.customer_code = monthly_sales.customer_code
join fact_gross_price gross_price
on monthly_sales.product_code = gross_price.product_code
where customer.customer = 'Atliq Exclusive'
Group by monthly_sales.fiscal_year,monthname(monthly_sales.date) order by Year,month(monthly_sales.date) ;


-- Q8. In which quarter of 2020, got the maximum total_sold_quantity? The final 
-- output contains these fields sorted by the total_sold_quantity, 
-- Quarter 
-- total_sold_quantity (0)

with cte as
(
Select quarter(date) as Quarter, SUM(sold_quantity) as total_sold_quantity from fact_sales_monthly 
where fiscal_year = 2020  and (month(date) >= 9 and month(date) <=12)
Group by quarter(date)
),
cte_a as
(
Select quarter(date) as Quarter, SUM(sold_quantity) as total_sold_quantity from fact_sales_monthly 
where fiscal_year = 2021  and (month(date) >= 1 and month(date) <=9)
Group by quarter(date)
)
select * from cte
union all
Select * from cte_a;

-- Q9.  Get the Top 3 products in each division that have a high 
-- total_sold_quantity in the fiscal_year 2021? The final output contains these fields, 
-- division 
-- product_code 
-- product 
-- total_sold_quantity 
-- rank_order (1)
with cte 
as
(
Select a.division,a.product_code,a.product, SUM(sold_quantity) as total_sold_quantity
from dim_product a 
inner join fact_sales_monthly b
on a.product_code = b.product_code
where b.fiscal_year = 2021
Group by a.division,a.product_code,a.product
order by total_sold_quantity desc
), cte_a as

(Select *,rank() over(partition by division order by total_sold_quantity desc) as 'rank_order'  from cte)
Select 
a.division,a.product_code,a.product,a.total_sold_quantity,b.rank_order
from 
cte a
join
cte_a b
on a.product_code = b.product_code where b.rank_order in (1,2,3);


-- Q10.  Which channel helped to bring more gross sales in the fiscal year 2021 
-- and the percentage of contribution?  The final output  contains these fields, 
-- channel 
-- gross_sales_mln 
-- percentage (1)
with cte as 
(
Select customer.channel,
round(SUM(monthly_sales.sold_quantity * gross_price.gross_price),2) as 'gross_sales_mln' 
 from dim_customer customer
join fact_sales_monthly monthly_sales
on customer.customer_code = monthly_sales.customer_code
join fact_gross_price gross_price
on monthly_sales.product_code = gross_price.product_code
where  monthly_sales.fiscal_year = 2021
Group by customer.channel
)
Select channel,gross_sales_mln, 
round(gross_sales_mln / (select SUM(gross_sales_mln) from cte),2) as percentage from cte order by percentage desc;
