--  Create a new data base
CREATE DATABASE Zomato;

-- use the above created database for this case study
USE Zomato;

DROP TABLE IF EXISTS goldusers_signup;
 
--  Creating the tables 
CREATE TABLE goldusers_signup (
    userid INTEGER,
    gold_signup_date DATE
); 

-- Insert the values 
Insert into goldusers_signup( userid, gold_signup_date )
values ( 1, '2017-09-22' ),
	   ( 3, '2017-04-21' );
       
drop table if exists users;
CREATE TABLE users (
    userid INTEGER,
    signup_date DATE
); -- Creating another table

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales (
    userid INTEGER,
    created_date DATE,
    product_id INTEGER
); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product (
    product_id INTEGER,
    product_name TEXT,
    price INTEGER
); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

show tables;

-- 1. What is the total amount amount each customer spent on zomato
SELECT 
    s.userid, SUM(p.price) Total_Amt_Spend
FROM
    sales AS s
        INNER JOIN
    product AS p ON s.product_id = p.product_id
GROUP BY userid;

-- 2. How many days has customer visited zomato
SELECT 
    userid, COUNT(DISTINCT (created_date))
FROM
    sales
GROUP BY userid;

-- 3. What was the first product purchased bhy the each customer
select * 
from (select *, rank() over ( partition by userid order by created_date ) rnk
from sales ) a 
where rnk = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers

SELECT 
    userid, COUNT(product_id) cnt
FROM
    sales
WHERE
    product_id = (SELECT 
            product_id
        FROM
            sales
        GROUP BY product_id
        ORDER BY COUNT(product_id) DESC
        LIMIT 1)
GROUP BY userid;

-- 5. Which item was most popular for each customer
select * from ( select *, rank() over( partition by userid order by cnt desc) rnk from 
	  (select userid,product_id, count(product_id) cnt	
	  from sales
	  group by userid,product_id) a ) b
where rnk = 1;

-- 6. Which item was purchased first by the cutomer after they became a member
select * from
(select c.*, rank() over (partition by userid order by created_date) rnk from
(SELECT 
    s.userid, s.created_date, s.product_id, g.gold_signup_date
FROM
    sales s
        INNER JOIN
    goldusers_signup g ON s.userid = g.userid
    and created_date >= gold_signup_date) c)d
    where rnk =1;
    
    
    -- 7. Which item was just purchased before the customer become a member
    
    select * from (select c.*, rank() over (partition by userid order by created_date desc) rnk
    from (select s.userid, s.created_date,s.product_id, g.gold_signup_date
    from sales s inner join goldusers_signup g
    on s.userid = g.userid and s.created_date < g.gold_signup_date) c) d
    where rnk = 1;
    
    -- 8. What is the total orders and amount  spent for each member before they became a member
   
SELECT 
    userid,
    COUNT(created_date) Order_Purchased,
    SUM(price) Total_Amt_Spent
FROM
    (SELECT 
        c.*, p.price
    FROM
        (SELECT 
        s.userid, s.created_date, s.product_id, g.gold_signup_date
    FROM
        sales s
    INNER JOIN goldusers_signup g ON s.userid = g.userid
        AND created_date <= gold_signup_date) c
    INNER JOIN product p ON c.product_id = p.product_id) d
GROUP BY userid;
    
-- 9. If buying each product generates points E.g. 5Rs = 2 zomato points and each product has different purchasing point E.g For p1 5rs = 1 zomato pt, 
-- for p2 10rs = 5 zomato point and for p3 , 5rs = 1 zomato pt
-- Calculate pts collected by each customers and for which product most pts have been given till now
 
SELECT 
    userid, SUM(Total_pts)
FROM
    (SELECT 
        e.*, amt / points Total_pts_earned
    FROM
        (SELECT 
        d.*,
            CASE
                WHEN product_id = 1 THEN 5
                WHEN product_id = 2 THEN 2
                WHEN product_id = 3 THEN 5
                ELSE 0
            END AS points
    FROM
        (SELECT 
        c.userid, c.product_id, SUM(price) amt
    FROM
        (SELECT 
        a.*, b.price
    FROM
        sales a
    INNER JOIN product b ON a.product_id = b.product_id) c
    GROUP BY userid , product_id) d) e) f
GROUP BY userid;

-- as mentioned above 5Rs = 2 zomato points, so we can find out the cashback each customer gets
SELECT 
    userid, SUM(Total_pts) * 2.5 Total_Cashbacks
FROM
    (SELECT 
        e.*, amt / points Total_pts
    FROM
        (SELECT 
        d.*,
            CASE
                WHEN product_id = 1 THEN 5
                WHEN product_id = 2 THEN 2
                WHEN product_id = 3 THEN 5
                ELSE 0
            END AS points
    FROM
        (SELECT 
        c.userid, c.product_id, SUM(price) amt
    FROM
        (SELECT 
        a.*, b.price
    FROM
        sales a
    INNER JOIN product b ON a.product_id = b.product_id) c
    GROUP BY userid , product_id) d) e) f
GROUP BY userid;

-- for which product most pts have been given till now
select * from 
(select *, rank() over( order by Total_pts desc) rnk from
(select product_id, sum(Total_pts) Total_pts from
(select e.* , amt/points Total_pts from
(select d.* , case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from
(select c.userid , c.product_id, sum(price) amt
from (select a.* , b.price from sales a inner join product b 
on a.product_id = b.product_id) c
group by userid , product_id )d ) e) f 
group by product_id) f) g where rnk =1;

-- 10. In the first 1 year after a customer joins the gold program (including their join date) irrespective of what the customer has purchased they earn 5 zomato points 
-- for every 10 rs spent who earned more, user 1 or 3 & what was there point earnings in their first year
-- which means 2rs = 1 zomato pt

SELECT 
    c.*, p.price * 0.5 Total_pts_earned
FROM
    (SELECT 
        s.userid, s.created_date, s.product_id, g.gold_signup_date
    FROM
        sales s
    INNER JOIN goldusers_signup g ON s.userid = g.userid
        AND (created_date >= gold_signup_date)
        AND (created_date <= DATE_ADD(gold_signup_date, INTERVAL 1 YEAR))) c
        INNER JOIN
    product p ON c.product_id = p.product_id;
-- Answer: User 3 had maximum points within first year after golde membership


-- 11. Rank all the transaction of the customers
select *, rank() over (partition by userid order by created_date) rnk from sales;
    

-- 12. rank all the transactions for each member whenever they are a zomato gold member for every non gold member mark as NA
select c.* , case when gold_signup_date is null then 'NA' else rank() over (partition by userid order by created_date desc ) end as rnk from
(SELECT  s.userid, s.created_date, s.product_id, g.gold_signup_date
FROM sales s
left JOIN goldusers_signup g 
ON s.userid = g.userid and created_date >= gold_signup_date) c ;	