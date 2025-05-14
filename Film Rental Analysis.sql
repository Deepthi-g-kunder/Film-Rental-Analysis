-- Project Overview
-- Objective: To analyze and generate a report to uncover customer behavior, rental trends, film popularity and business insights to a film rental company.

use film_rental;

-- Know the defination of table
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    ORDINAL_POSITION,
    COLUMN_DEFAULT,
    IS_NULLABLE,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    COLUMN_TYPE,
    COLUMN_KEY,
    EXTRA
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_SCHEMA = 'film_rental'
;

-- Whats the total revenue generated from all rentals in the database
        select 'Total', sum(amount) as Revenue from payment
        UNION ALL 
        select rental_id, sum(amount) Revenue from payment 
        group by 1
        order by 2 desc
        ;
        
-- 	How many rentals and revenue were made in each month_name?
select date_format(rental_date, '%Y-%m') as "Year and Month"  ,count(a.rental_id) as "Rentals Sold",sum(amount)as Revenue  from  rental a
left join payment b 
on a.rental_id = b.rental_id
group by 1
order by 1 ;

--  Top Revenue-Generating Films
SELECT f.title, SUM(p.amount) AS 'Total Revenue '
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
GROUP BY f.film_id
ORDER BY 2 DESC
LIMIT 10;

 -- Top 3 Paying Customers
SELECT c.customer_id, c.first_name, c.last_name, SUM(p.amount) AS total_paid
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id
ORDER BY total_paid DESC
LIMIT 3;

-- Top Revenue Generating Category
select a.name , sum(amount) as Revenue
 from
 category a
left join film_category b
on a.category_id = b.category_id
left join inventory c
on b.film_id = c.film_id
left join rental d
on c.inventory_id = d.inventory_id
left join payment p
on d.rental_id = p.rental_id
group by 1
order by 2 desc;

-- 	Popular  category of films in terms of the number of rentals
select a.name , count(rental_id) as 'Rentals '  from category a
left join film_category b
on a.category_id = b.category_id
left join inventory c
on b.film_id = c.film_id
left join rental d
on c.inventory_id = d.inventory_id
group by 1
order by 2 desc;


-- 	What is the average rental rate for films that were taken from the last 30 days.
SELECT title ,round(avg(rental_rate),2) as average from film a
left join inventory b
on a.film_id = b.film_id
left join rental c
on b.inventory_id = c. inventory_id
WHERE rental_date >= DATE_SUB((select max(rental_date) from rental), INTERVAL 30 DAY)
group by title
order by 2 desc;

-- Films  which has not been rented by any customer
select f.title from film f
left join inventory i 
on f.film_id=i.film_id
left join rental as r
on i.inventory_id=r.inventory_id
where r.rental_id is null
order by f.length  desc
;

-- Customer with No Activity for past 3 month
SELECT CONCAT(first_name, " ", last_name) AS Name
FROM customer c
LEFT JOIN rental r 
  ON c.customer_id = r.customer_id 
  AND r.rental_date >= DATE_SUB((SELECT MAX(rental_date) FROM rental), INTERVAL 3 MONTH)
  -- AND r.rental_date >= ((SELECT MAX(rental_date) FROM rental)-INTERVAL 3 MONTH)
WHERE r.rental_id IS NULL;


 -- Customers Inactive for More Than 6 Months ( Different Approach)
SELECT c.customer_id, c.first_name, c.last_name, MAX(r.rental_date) AS last_rental
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id
HAVING MAX(r.rental_date) < DATE_SUB(CURDATE(), INTERVAL 6 MONTH);


-- Most Famous film  In Each Category
WITH famous_category AS (
  SELECT 
    c.name AS category_name,
    f.title,
    COUNT(*) AS rental_count
  FROM film f
  LEFT JOIN inventory i ON f.film_id = i.film_id
  LEFT JOIN rental r ON i.inventory_id = r.inventory_id
  LEFT JOIN film_category fc ON f.film_id = fc.film_id
  LEFT JOIN category c ON fc.category_id = c.category_id
  GROUP BY c.name, f.title
),
ranked_first AS (
  SELECT *, 
         ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY rental_count DESC) AS rk
  FROM famous_category
)
SELECT category_name, title, rental_count
FROM ranked_first
WHERE rk = 1;

-- Detect Category Performance Over Time
SELECT 
    c.name AS category,
    SUM(CASE WHEN DATE_FORMAT(p.payment_date, '%Y-%m') = '2005-05' THEN p.amount ELSE 0 END) AS '2005:05',
    SUM(CASE WHEN DATE_FORMAT(p.payment_date, '%Y-%m') = '2005-06' THEN p.amount ELSE 0 END) AS '2005:06',
    SUM(CASE WHEN DATE_FORMAT(p.payment_date, '%Y-%m') = '2005-07' THEN p.amount ELSE 0 END) AS '2005:07',
    SUM(CASE WHEN DATE_FORMAT(p.payment_date, '%Y-%m') = '2005-08' THEN p.amount ELSE 0 END) AS '2005:08',
    SUM(CASE WHEN DATE_FORMAT(p.payment_date, '%Y-%m') = '2006-02' THEN p.amount ELSE 0 END) AS '2006:02'
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY c.name;


-- Influnece of duration of film in Rentals Business ( Duration is divided to 3 part 45-90 short , 91-130 medium and 131-185 long )
SELECT 
  CASE 
    WHEN f.length BETWEEN 45 AND 90 THEN 'Short'
    WHEN f.length BETWEEN 91 AND 130 THEN 'Medium'
    WHEN f.length BETWEEN 131 AND 185 THEN 'Long'
  END AS Duration,
  SUM(CASE WHEN r.rental_id IS NOT NULL THEN 1 ELSE 0 END) AS Rented,
  SUM(CASE WHEN r.rental_id IS NULL THEN 1 ELSE 0 END) AS Not_Rented
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY Duration;

-- Influnece of rating of film in Rental Business
SELECT 
rating ,
  SUM(CASE WHEN r.rental_id IS NOT NULL THEN 1 ELSE 0 END) AS Rented,
  SUM(CASE WHEN r.rental_id IS NULL THEN 1 ELSE 0 END) AS Not_Rented

FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY rating;


-- 	What is the average rental rate and Average Movie Duration for Different Category
SELECT 
  c.name AS category,
  ROUND(AVG(ff.rental_rate), 2) AS 'Average Rental Rate',
  ROUND(AVG(ff.length), 2) AS 'Average Duration'
FROM category AS c
LEFT JOIN film_category f ON c.category_id = f.category_id
LEFT JOIN film ff ON f.film_id = ff.film_id
GROUP BY c.name, c.category_id;

--  total revenue generated from rentals for each actor
select concat(first_name ," ", last_name ) as Name
,sum(amount)
 as revenue from actor as a
left join film_actor as fa
on a.actor_id=fa.actor_id
left join inventory i
on fa.film_id =i.film_id
left join rental as r
on i.inventory_id=r.inventory_id
left join payment p
on r.rental_id=p.rental_id
group by Name
order by revenue desc;


-- 	Which customers have rented the same film more than once
SELECT 
  CONCAT(c.first_name, ' ', c.last_name) AS 'Customer Name',
  f.title AS 'Film Title',
  COUNT(*) AS 'Frequency Of Order'
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN customer c ON r.customer_id = c.customer_id
GROUP BY  c.first_name, c.last_name, f.title
HAVING COUNT(*) > 1
ORDER BY'Frequency Of Order' DESC;


-- 	How many films in the  category have a rental rate higher than the average rental rate and less than average rate
select c.name ,
sum(case when rental_rate > (select avg(rental_rate) from film) then 1 else 0 end) 'Category Higher than Avg Rate',
sum(case when rental_rate < (select avg(rental_rate) from film) then 1 else 0 end) 'Category Higher than Avg Rate'
from category as c
left join film_category fc
on c.category_id = fc.category_id
left join film i
on fc.film_id = i.film_id
group by c.name ;


-- 	Distribution of Business across different Cities
select city, count(rental_id) 'No of film Rented'
from city c
left join address a
on c.city_id = a.city_id
left join customer cu
on a.address_id = cu.address_id
left join rental r
on cu.customer_id = r.customer_id
where r.rental_id is not null
group by city
order by 1;

-- Customer Distribution Around dfferent country 
select  country , count(customer_id) as 'Number of Customer'
from country c
left join city cy
on c.country_id = cy.country_id
left join address a
on cy.city_id = a.city_id
left join customer cm
on a.address_id = cm.address_id
group by 1
order by 2 desc
;


-- 	Anlysis on customer Spending pattern on different Categories
select 
concat(first_name , " ", last_name ) as "Customer Name",
sum(case When c.name= 'Action' Then  amount else 0 end ) as Action,
sum(case When c.name= 'Animation' Then  amount else 0 end ) as Animation,
sum(case When c.name= 'Children' Then  amount else 0 end ) as Children,
sum(case When c.name= 'Classics' Then  amount else 0 end ) as Classics,
sum(case When c.name= 'Comedy' Then  amount else 0 end ) as Comedy,
sum(case When c.name= 'Documentary' Then  amount else 0 end ) as Documentary,
sum(case When c.name= 'Drama' Then  amount else 0 end ) as Drama,
sum(case When c.name= 'Family' Then  amount else 0 end ) as Family,
sum(case When c.name= 'Foreign' Then  amount else 0 end ) as 'Foreign',
sum(case When c.name= 'Games' Then  amount else 0 end ) as Games,
sum(case When c.name= 'Horror' Then  amount else 0 end ) as Horror,
sum(case When c.name= 'Music' Then  amount else 0 end ) as Music,
sum(case When c.name= 'New' Then  amount else 0 end ) as New,
sum(case When c.name= 'Sci-Fi' Then  amount else 0 end ) as 'Sci-Fi',
sum(case When c.name= 'Sports' Then  amount else 0 end ) as Sports,
sum(case When c.name= 'Travel' Then  amount else 0 end ) as Travel
 from category c
left join film_category fc
on c.category_id =fc.category_id
left join inventory i
on fc.film_id = i.film_id
left join rental r
on i.inventory_id = r.inventory_id
left join payment p
on r.rental_id = p.rental_id
left join customer ct
on p.customer_id = ct.customer_id
group by 1
order by 1 desc;


 -- Inventory Turnover Rate Per Store
SELECT s.store_id, COUNT(DISTINCT i.inventory_id) AS inventory_count, 
       COUNT(r.rental_id) AS total_rentals,
       ROUND(COUNT(r.rental_id) / COUNT(DISTINCT i.inventory_id), 2) AS turnover_rate
FROM store s
JOIN inventory i ON s.store_id = i.store_id
LEFT JOIN rental r ON r.inventory_id = i.inventory_id
GROUP BY s.store_id;
 

-- Display the fields which are having foreign key constraints related to the "rental" table
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM
    information_schema.KEY_COLUMN_USAGE
WHERE
    TABLE_SCHEMA = 'film_rental'
    AND REFERENCED_TABLE_NAME = 'rental';

-- Create a View for the total revenue generated by each staff member, broken down by store city with the country name.
create or replace
view staff_revenue as 
select sf.staff_id,sf.first_name,c.city_id,c.city,
cy.country,sum(p.amount) as Revenue
from staff as sf
left join store as s 
on sf.store_id=s.store_id
left join address as a
on s.address_id=a.address_id
left join city as c
on a.city_id=c.city_id
left join country as cy
on c.country_id=cy.country_id
left join payment p 
on sf.staff_id=p.staff_id
group by sf.staff_id,c.city_id,cy.country;

--  view
select * from staff_revenue;


-- 	Display the customers who paid 50% of their total rental costs within one day. 

WITH rental_details AS (
  SELECT  
    p.customer_id,
    SUM(amount) AS total_amount_of_each_customer,
    SUM(CASE 
          WHEN DATEDIFF(p.payment_date, r.rental_date) <= 1 
          THEN amount 
          ELSE 0 
        END) AS payment_made_within_a_day,
    ROUND(
      SUM(CASE 
            WHEN DATEDIFF(p.payment_date, r.rental_date) <= 1 
            THEN amount 
            ELSE 0 
          END) / SUM(amount) * 100, 
      2
    ) AS pct
  FROM payment p
  LEFT JOIN rental r ON p.rental_id = r.rental_id
  GROUP BY p.customer_id
)

SELECT * 
FROM rental_details
WHERE pct > 50;

-- Validation 
  select r.customer_id, rental_date,payment_date, amount
  from rental r
  left join payment p 
  on r.rental_id =p.rental_id
  where datediff(payment_date,rental_date) >1
  order by 1 ;
  -- There are no trnasaction which took more than one day of time to pay the rent
  
  
  
 
