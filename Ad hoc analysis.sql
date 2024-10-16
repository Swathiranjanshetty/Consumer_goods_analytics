select * from fact_sales_monthly;

## 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select distinct market from dim_customer where region like "%APAC%" and customer like "%Atliq Exclusive%";

## 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,unique_products_2020unique_products_2021 percentage_chg
SELECT 
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_products_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_products_2021,
    CASE WHEN COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) = 0 THEN NULL
        ELSE round((COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) - 
              COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END)) * 100.0 / 
              COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END),2)
        END AS percentage_chg
FROM 
    fact_sales_monthly
WHERE 
    fiscal_year IN (2020, 2021);

## 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields, segment product_count
select segment, count(distinct product_code) as unique_products from dim_product 
group by segment order by unique_products desc;

## 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,segment product_count_2020 product_count_2021 difference
SELECT segment,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN f.product_code END) AS unique_products_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN f.product_code END) AS unique_products_2021,
    CASE WHEN COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN f.product_code END) = 0 THEN NULL
        ELSE (COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN f.product_code END) - 
              COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN f.product_code END)) END AS 2021VS2020 
              from dim_product p join fact_sales_monthly f on f.product_code=p.product_code 
              where fiscal_year in(2020,2021)
              group by segment order by 2021VS2020 desc;
              
## 5. Get the products that have the highest and lowest manufacturing costs.The final output should contain these fields,product_code,product,manufacturing_cost
SELECT f.manufacturing_cost, p.product_code, p.product
    FROM dim_product p
    JOIN fact_manufacturing_cost f  
    using (product_code) where f.manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)
    or f.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost)
    order by f.manufacturing_cost desc; 
    
## 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields,customer_code customer average_discount_percentage
select c.customer_code, customer, round(avg(pre_invoice_discount_pct)*100,2) as avg_pre_invoice_disc_pct
from dim_customer c join fact_pre_invoice_deductions p using 
(customer_code) where market = "india" and fiscal_year = "2021" group by c.customer_code,c.customer
order by avg_pre_invoice_disc_pct desc limit 5;

## 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions.The final report contains these columns: MonthYearGross sales Amount
select monthname(f.date) as month_name, f.fiscal_year, round(sum(gross_price*sold_quantity),2) as gross_sales_amt_mln 
from fact_sales_monthly f join fact_gross_price g
on f.product_code =g.product_code join dim_customer c on f.customer_code= c.customer_code 
where customer = "Atliq Exclusive" group by month_name,f.fiscal_year order by f.fiscal_year asc;     

## 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
## output contains these fields sorted by the total_sold_quantity, Quarter,total_sold_quantity 
 WITH cte1 AS (SELECT 
        get_quarter(date) AS quarter,  -- Aliasing for clarity
        fiscal_year,
        SUM(sold_quantity) AS total_sold_quantity  -- Aggregate sold_quantity for each quarter
    FROM fact_sales_monthly f 
    GROUP BY get_quarter(date), fiscal_year)
SELECT quarter, 
   total_sold_quantity 
FROM cte1 WHERE fiscal_year = '2020'
GROUP BY quarter order by total_sold_quantity desc;

## 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,channel
## gross_sales_mln
## percentage
WITH cte1 AS (
    SELECT 
        channel, 
        ROUND(SUM(sold_quantity * gross_price) / 100000, 2) AS gross_price_mln 
    FROM 
        dim_customer c 
    JOIN 
        fact_sales_monthly f ON c.customer_code = f.customer_code 
    JOIN 
        fact_gross_price g ON g.product_code = f.product_code
        where f.fiscal_year = "2021"
    GROUP BY 
        channel
)
    SELECT 
        channel,
        gross_price_mln,
        ROUND((gross_price_mln /(select SUM(gross_price_mln) from cte1)) * 100, 2) AS gross_price_mln_pct  -- Calculate percentage
    FROM 
        cte1 order by gross_price_mln desc;


    
## 10. Get the Top 3 products in each division that have a high
## total_sold_quantity in the fiscal_year 2021? The final output contains these
## fields,
## division
## product_code
WITH cte1 AS (
    SELECT 
        division, 
        p.product_code, 
        SUM(sold_quantity) AS total_qty, 
        fiscal_year
    FROM  
        fact_sales_monthly f 
    JOIN 
        dim_product p 
    ON
        f.product_code = p.product_code 
    GROUP BY 
        division, p.product_code, fiscal_year  -- Group by fiscal year to ensure accurate total_qty calculation
)
SELECT 
    division, 
    product_code, 
    total_qty
FROM (
    SELECT 
        division, 
        product_code, 
        total_qty,
        DENSE_RANK() OVER (PARTITION BY division ORDER BY total_qty DESC) AS ranks
    FROM 
        cte1 
    WHERE 
        fiscal_year = 2021
) ranked_data
WHERE 
    ranks <= 3  -- Get top 3 products within each division
ORDER BY 
    division, ranks;










    


    




