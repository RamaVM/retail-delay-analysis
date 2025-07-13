use project;

-- select total numbers 
select count(* ) from orders;

-- find the number of ordres delivered

select count(order_status) from orders
where order_status = 'delivered';

-- find the average delivery time in days 

select round(avg(DATEDIFF(orders.order_delivered_customer_date,orders.order_purchase_timestamp ))) as average_delivery_date from orders
where order_status='delivered';

-- delayed delivery counts

select count(*) as delayed_delivery_count
from orders where order_estimated_delivery_date > order_delivered_customer_date;

--  % of Orders  Delivered Late
select round(sum(case when order_estimated_delivery_date< order_delivered_customer_date then 1 else 0 end ) * 100 / count(*),2) as delayed_delivery_percent from orders 
where order_status='delivered' ;

-- Average Delivery Time by Product Category

select products.product_category_name,avg(datediff(orders.order_delivered_customer_date,orders.order_purchase_timestamp)) as average  
from orders join order_items on orders.order_id = order_items.order_id
join products on order_items.product_id=products.product_id
group by product_category_name order by average desc ;

-- Delivery Performance by State
select customers.customer_state, sum(case when order_delivered_customer_date < order_estimated_delivery_date then 1 else 0 end ) as on_time_delivery
,round((sum(case when order_delivered_customer_date < order_estimated_delivery_date then 1 else 0 end )/count(*))*100,2) as on_time_delivery_percent
from customers join orders 
on customers.customer_id=orders.customer_id
group by customer_state order by on_time_delivery desc ;

-- Top 5 Sellers with Most Delays
select order_items.seller_id ,count(*) as delayed_orders
from orders join order_items 
on orders.order_id=order_items.order_id
where order_estimated_delivery_date > order_delivered_customer_date
group by order_items.seller_id order by delayed_orders desc limit 5;

-- Monthly Trend of Delayed Deliveries
select count(*) as delayed_orders, date_format(order_delivered_customer_date,'%y-%m') as  order_month
from orders 
where order_estimated_delivery_date < order_delivered_customer_date
group by  order_month
order by delayed_orders desc;


-- Payment Method Impact on Delay
select order_payments.payment_type,count(*) as total_orders,
sum(case when  order_estimated_delivery_date < order_delivered_customer_date then 1 else 0 end  ) as delayed_orders,
round((sum(case when  order_estimated_delivery_date < order_delivered_customer_date then 1 else 0 end  ) / count(*) )*100 ,2)as delayed_orders_percent
from orders join order_payments 
on orders.order_id=order_payments.order_id
group by order_payments.payment_type
order by delayed_orders_percent desc;

-- Average Delay in Days (Only for Delayed Orders)
select  avg(datediff(order_delivered_customer_date,order_estimated_delivery_date)) as average_delivery_date
from orders
where order_delivered_customer_date>order_estimated_delivery_date;

-- Delivery Performance by City
select customers.customer_city,sum(case when order_delivered_customer_date>order_estimated_delivery_date then 1 else 0 end) as delyed_delivery,
 (sum(case when order_delivered_customer_date>order_estimated_delivery_date then 1 else 0 end) /count(*))* 100 as delivery_percentage
 from orders join customers 
 on orders.customer_id=customers.customer_id
 group by customers.customer_city
 order by delivery_percentage desc;
 
 -- Review Score vs Delivery Time
 select avg(datediff(order_delivered_customer_date,order_purchase_timestamp)) as average_delivery_time,
avg(review_score) as average_review_score
from orders join order_reviews
on orders.order_id=order_reviews.order_id
where order_status='delivered'
group by datediff(order_delivered_customer_date,order_purchase_timestamp)
order by average_delivery_time desc;

-- Top 5 Product Categories with Most Delays

select products.product_category_name,products.product_id,count(*),sum( case when order_delivered_customer_date>order_estimated_delivery_date then 1 else 0 end) as most_delays,
(sum( case when order_delivered_customer_date>order_estimated_delivery_date then 1 else 0 end)/count(*))*100 as delayed_percentage
from orders join order_items on 
orders.order_id=order_items.order_id
join products 
on products.product_id=order_items.product_id
where order_status='delivered'
group by products.product_category_name, products.product_id

order by most_delays desc limit 5;

--  Delay % by Seller State
select sellers.seller_state,count(*),
(sum(case when order_delivered_customer_date>order_estimated_delivery_date  then 1 else 0 end)/count(*))*100 as delay_percent
from orders join order_items
on orders.order_id=order_items.order_id
join sellers
on sellers.seller_id=order_items.seller_id
group by sellers.seller_state
order by delay_percent desc;

-- Weekend vs Weekday Order Delay
select count(*) ,case when dayofweek(order_purchase_timestamp) in (1,7) then 'weekend' else 'weekday'  end as oder_weeks,
sum(case when order_delivered_customer_date>order_estimated_delivery_date  then 1 else 0 end ) as delayed_order,
(sum(case when order_delivered_customer_date>order_estimated_delivery_date  then 1 else 0 end)/count(*))*100 as delayed_percent
from orders
where order_status='delivered'
group by oder_weeks;


-- Cancellation Rate by Product Category (if using order_status = 'canceled')
select products.product_category_name,count(*),sum(case when  order_status='canceled' then 1 else 0 end ) as canceled_order,
(sum(case when order_status='canceled' then 1 else 0 end )/count(*))*100 as canceled_percent
from orders join order_items
on orders.order_id=order_items.order_id
join products
on products.product_id=order_items.product_id
where order_status='canceled'
group by product_category_name
order by canceled_order desc;

-- merging all the required columns from every table based on kpi and queries for presentations

SELECT 
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    c.customer_city,
    c.customer_state,
    op.payment_type,
    orv.review_score,
    oi.product_id,
    pr.product_category_name,
    oi.seller_id,
    s.seller_state
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products pr ON oi.product_id = pr.product_id
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN order_payments op ON o.order_id = op.order_id
JOIN order_reviews orv ON o.order_id = orv.order_id
WHERE o.order_status IN ('delivered', 'canceled');  -- Keep only relevant statuses

