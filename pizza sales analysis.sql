-- the total revenue generated from pizza sales
select 
round(sum((order_details.quantity * pizzas.price)),2)as total_sales 
from order_details join pizzas
on pizzas.pizza_id=order_details.pizza_id 

-- Identify the highest-priced pizza.
select 
	pizza_types.name,
	pizzas.price
from pizza_types
join pizzas
on 
	pizza_types.pizza_type_id=pizzas.pizza_type_id
order by price desc limit 1;

--identify the most common pizza size sold
select
	pizzas.size,
	count(order_details.order_details_id) as order_count
from pizzas
join order_details
on pizzas.pizza_id=order_details.pizza_id
group by pizzas.size
order by order_count desc limit 1;


/*list the top 5 most ordered pizza
types along with their quantities*/
select 
	pizza_types.name,
	sum(order_details.quantity) as quantity_ordered
from pizza_types
join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details
on order_details.pizza_id=pizzas.pizza_id
group by pizza_types.name
order by quantity_ordered desc limit 5;

-- intermediate
-- Join the necessary tables to find the total quantity of each pizza category ordered.
select
	pizza_types.category,
	sum(order_details.quantity) as total_quantity
from pizza_types
join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details
on pizzas.pizza_id=order_details.pizza_id
group by pizza_types.category
order by total_quantity desc;

-- Determine the distribution of orders by hour of the day.
select 
	EXTRACT(HOUR FROM time) as hour_of_day,
	count(order_id)
from orders
group by hour_of_day
order by hour_of_day;


--Join relevant tables to find the category-wise distribution of pizzas.
select
	pizza_types.category,
	count(orders.order_id)
from orders
join order_details
on orders.order_id=order_details.order_id
join pizzas
on order_details.pizza_id=pizzas.pizza_id
join pizza_types
on pizzas.pizza_type_id=pizza_types.pizza_type_id
group by pizza_types.category;

-- Group the orders by date and calculate the average number of pizzas ordered per day.
select
	round(avg(quantity),3)
from(
	select
		orders.date as order_date,
		sum(order_details.quantity) as quantity
	from orders
	join order_details
	on orders.order_id=order_details.order_id
	group by order_date
) as quantity

-- Determine the top 3 most ordered pizza types based on revenue.
select
	pizza_types.name,
	sum(order_details.quantity * pizzas.price) as revenue
from pizza_types
join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details
on pizzas.pizza_id=order_details.pizza_id
group by pizza_types.name
order by revenue desc limit 3;

-- Calculate the percentage contribution of each pizza type to total revenue
--without using cte
select
	pizza_types.category,
	round((sum(order_details.quantity * pizzas.price)/ (select round(sum((order_details.quantity * pizzas.price)),2)as total_sales from order_details join pizzas
on pizzas.pizza_id=order_details.pizza_id )) * 100,2) as revenue_percent
from pizza_types
join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details
on pizzas.pizza_id=order_details.pizza_id
group by pizza_types.category 
order by revenue_percent desc;

--using CTE
 with total_sales_cte as(
select
	round(sum(order_details.quantity * pizzas.price),2) as total_sales
	from order_details
	join pizzas
	on order_details.pizza_id=pizzas.pizza_id
 )

select
	pizza_types.category,
	round((sum(order_details.quantity * pizzas.price) / total_sales_cte.total_sales)*100,2) as revenue_percent
from pizza_types
join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details
on pizzas.pizza_id=order_details.pizza_id,
total_sales_cte
group by pizza_types.category, total_sales_cte.total_sales
order by revenue_percent desc;

-- Analyze the cumulative revenue generated over time.
select date,
sum(revenue) over(order by date ) as cum_revenue
from
(select
	orders.date,
	sum(order_details.quantity * pizzas.price) as revenue
from orders
join order_details
on orders.order_id=order_details.order_id
join pizzas
on order_details.pizza_id=pizzas.pizza_id
group by orders.date
order by orders.date ) as sales;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
select category, name, revenue from
(select category,name,revenue,
rank() over(partition by category order by revenue desc) as rn
from
(select 
	pizza_types.category,
	pizza_types.name,
	sum(order_details.quantity *pizzas.price) as revenue
from pizza_types
join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details
on pizzas.pizza_id=order_details.pizza_id
group by pizza_types.category, pizza_types.name) as a) as b
where rn<=3