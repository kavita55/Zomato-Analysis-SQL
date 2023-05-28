--  Create a new data base
Create database Zomato;

-- use the above created database for this case study
Use Zomato;

Drop table if exists goldusers_signup;
 
--  Creating the tables 
Create table goldusers_signup( userid integer, gold_signup_date date ); 

-- Insert the values 
Insert into goldusers_signup( userid, gold_signup_date )
values ( 1, '2017-09-22' ),
	   ( 3, '2017-04-21' );
       
drop table if exists users;
Create table users( userid integer, signup_date date ); -- Creating another table

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer, created_date date, product_id integer); 

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
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

show tables; 

-- 1. What is the total amount amount each customer spent on zomato
select s.userid, sum(p.price) Total_Amt_Spend
from sales as s
inner join product as p
on s.product_id = p.product_id
group by userid;

-- 2. How many days has customer visited zomato
select userid, count(distinct(created_date))
from sales 
group by userid;

-- 3. What was the first product purchased bhy the each customer
select * 
from (select *, rank() over ( partition by userid order by created_date ) rnk
from sales ) a 
where rnk = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers

select userid, count(product_id) cnt 
from sales
where product_id = (select product_id 
					from sales 
					group by product_id 
					order by count(product_id) desc limit 1)
group by userid;

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
   
select userid, count(created_date) Order_Purchased ,sum(price) Total_Amt_Spent
from ( select c.* , p.price from
(SELECT  s.userid, s.created_date, s.product_id, g.gold_signup_date
FROM sales s
INNER JOIN goldusers_signup g
ON s.userid = g.userid and created_date <= gold_signup_date)c 
inner join product p
on c. product_id = p.product_id ) d
group by userid ;
    
-- 9. If buying each product generates points E.g. 5Rs = 2 zomato points and each product has different purchasing point E.g For p1 5rs = 1 zomato pt, 
-- for p2 10rs = 5 zomato point and for p3 , 5rs = 1 zomato pt
-- Calculate pts collected by each customers and for which product most pts have been given till now
 
select userid, sum(Total_pts) from
(select e.* , amt/points Total_pts_earned from
(select d.* , case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from
(select c.userid , c.product_id, sum(price) amt
from (select a.* , b.price from sales a inner join product b 
on a.product_id = b.product_id) c
group by userid , product_id )d ) e) f 
group by userid;

-- as mentioned above 5Rs = 2 zomato points, so we can find out the cashback each customer gets
select userid, sum(Total_pts) * 2.5 Total_Cashbacks from
(select e.* , amt/points Total_pts from
(select d.* , case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from
(select c.userid , c.product_id, sum(price) amt
from (select a.* , b.price from sales a inner join product b 
on a.product_id = b.product_id) c
group by userid , product_id )d ) e) f 
group by userid;

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
-- for every 10 rs spent who earned more than 1 or 3 & what was there point earnings in their first year

