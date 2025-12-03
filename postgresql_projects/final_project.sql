/*
* Анализ данных с помощью SQL и создание дашборда в DataLens. Знакомство с данными
*/
SELECT 
	table_schema,
	table_name,
	column_name,
	constraint_name
FROM information_schema.key_column_usage
WHERE table_schema = 'afisha'

--- Знакомимься с данными ---
--Знакомство cо столбцами всех таблиц в схеме afisha
SELECT table_name,
	column_name, 
	data_type
FROM information_schema.columns
WHERE table_schema = 'afisha'
ORDER BY table_name 

---Посмотрим на данные таблицы purchases
SELECT * FROM  afisha.purchases LIMIT 5

---Посмотрим на данные таблицы city
SELECT region_id ,count(*) FROM afisha.city c  
GROUP BY region_id 
ORDER BY 2 DESC

---Посмотрим на данные таблицы events
SELECT * FROM afisha.events e 
LIMIT 10

---Посмотрим на данные таблицы regions
SELECT * FROM afisha.regions r 

---Посмотрим на данные таблицы venues
SELECT * FROM afisha.venues v 

--- Всего пользователей и заказов
SELECT count(DISTINCT user_id) AS all_users,
	count(DISTINCT order_id) AS all_orders 
FROM afisha.purchases p 

-- Проверяем количество дубликатов в столбце 
with cte AS(SELECT order_id,user_id
FROM afisha.purchases p 
GROUP BY 1
HAVING count(*) = 1)
SELECT count(*)
FROM cte

-- Проверяем популярное возрастное ограничение
SELECT age_limit ,
	count(*) popularity 
FROM afisha.purchases p 
GROUP BY 1
ORDER BY 2 DESC 

---Проверяем количество пропущенных значений в столбце tickets_count
SELECT count(*)
FROM afisha.purchases p 
WHERE tickets_count IS NULL

---Посмотри на максимальный и минимальный размер числовых столбцов
SELECT max(revenue) max_revenue,
	min(revenue) min_revenue,
	max(tickets_count) max_tickets,
	min(tickets_count) min_tickets,
	max(total) max_total,
	min(total) min_total
FROM afisha.purchases p 

---Проверим самые популярные типы мероприятий
SELECT event_type_main ,
	count(*) popularity 
FROM afisha.purchases p 
LEFT JOIN afisha.events e using(event_id)
GROUP BY 1
ORDER BY 2 DESC 
---Проверим популярные устройства
SELECT device_type_canonical ,
count(*) count
FROM afisha.purchases p 
GROUP BY 1
ORDER BY 2 DESC

---Проверим временной отрезок данных
SELECT DISTINCT date_trunc('month', created_dt_msk::timestamp) AS month 
FROM afisha.purchases p 
ORDER BY 1

---Проверим виды валют и количество заказов с ними
SELECT currency_code , count(*)  all_count FROM afisha.purchases p GROUP BY 1 ORDER BY 2 DESC

--- Проверим столбец revenue с помощью мер центральных тенденций
SELECT max(revenue) max,
	min(revenue) min,
	max(revenue) - min(revenue) AS scale,
	avg(revenue) as avg,
	stddev(revenue) std,
	percentile_disc(0.5) WITHIN GROUP (ORDER BY revenue) AS median
FROM afisha.purchases p 

--- Проверим столбец revenue с типом валюты KZT с помощью мер центральных тенденций
SELECT max(revenue) max,
	min(revenue) min,
	max(revenue) - min(revenue) AS scale,
	avg(revenue) as avg,
	stddev(revenue) std,
	percentile_disc(0.5) WITHIN GROUP (ORDER BY revenue) AS median
FROM afisha.purchases p 
WHERE currency_code = 'rub'

--- Проверим столбец revenue с типом валюты KZT с помощью мер центральных тенденций
SELECT max(revenue) max,
	min(revenue) min,
	max(revenue) - min(revenue) AS scale,
	avg(revenue) as avg,
	stddev(revenue) std,
	percentile_disc(0.5) WITHIN GROUP (ORDER BY revenue) AS median,
	count(revenue) AS all_count
FROM afisha.purchases p 
WHERE currency_code = 'kzt'

--- Проверим количество строк с пропущенными значениями в revenue
SELECT count(*)
FROM afisha.purchases p 
WHERE revenue IS NULL 

---Посмотрим на количество заказов у каждого оператора
SELECT service_name,
	count(order_id)
FROM afisha.purchases p 
GROUP BY 1
ORDER BY 2 DESC

---Проверим количество неявных дубликатов по названию операторов
SELECT order_id,
	user_id,
	service_name 
FROM afisha.purchases p
GROUP BY 1,2,3
HAVING count(*) > 1

--- Проверим количество уникальных индификаторов событий и уникальных кодировок названий
SELECT count(DISTINCT event_id) AS event_id_count,
count(DISTINCT event_name_code) AS event_name_code_count
FROM afisha.events e 

---Проверим количество уникальных городов и регионов
SELECT count(DISTINCT city_name) AS all_cities,
count(DISTINCT region_id) AS all_regions
FROM afisha.events e 
JOIN afisha.city c using(city_id)

SELECT count(DISTINCT city_name) AS all_cities,
count(DISTINCT region_id) AS all_regions
FROM afisha.city c 

---Обнаружен явный дубликат 
SELECT *
FROM afisha.city c 
WHERE city_name = 'Глинополье'

---
SELECT 
	DISTINCT currency_code ,
	sum(revenue) AS total_revenue,
	count(order_id) total_orders,
	avg(revenue) avg_revenue_per_order,
	count(DISTINCT user_id) total_users
FROM afisha.purchases p
GROUP BY 1
ORDER BY 2 DESC 


-- Настройка параметра synchronize_seqscans важна для проверки
WITH set_config_precode AS (
  SELECT set_config('synchronize_seqscans', 'off', true)
)

-- Напишите ваш запрос ниже
SELECT 
	DISTINCT device_type_canonical ,
	sum(revenue) AS total_revenue,
	count(order_id) total_orders,
	avg(revenue) avg_revenue_per_order,
	round(sum(revenue)::NUMERIC/(SELECT sum(revenue) FROM afisha.purchases p WHERE currency_code = 'rub')::NUMERIC,3) revenue_share
FROM afisha.purchases p 
WHERE currency_code = 'rub'
GROUP BY 1
ORDER BY revenue_share DESC 

---
SELECT DISTINCT event_type_main,
	sum(revenue) AS total_revenue,
	count(order_id) total_orders,
	avg(revenue) avg_revenue_per_order,
	count(DISTINCT event_name_code) total_event_name,
	avg(tickets_count) avg_tickets,
	sum(revenue)/sum(tickets_count) avg_ticket_revenue,
	round(sum(revenue)::NUMERIC/(SELECT sum(revenue) FROM afisha.purchases p WHERE currency_code = 'rub')::NUMERIC,3) revenue_share
FROM afisha.purchases p 
JOIN afisha.events e using(event_id)
WHERE currency_code ='rub'
GROUP BY 1
ORDER BY total_orders DESC 

---
SELECT 
	date_trunc('week', created_dt_msk)::date week,
	sum(revenue) AS total_revenue,
	count(order_id) total_orders,
	count(DISTINCT user_id) total_users,
	sum(revenue)/count(order_id) revenue_per_order
FROM afisha.purchases p 
WHERE currency_code ='rub'
GROUP BY 1
ORDER BY 1  
---
SELECT 
	DISTINCT region_name,
	sum(revenue) AS total_revenue,
	count(order_id) total_orders,
	count(DISTINCT user_id) total_users,
	sum(tickets_count) total_tickets,
	sum(revenue)/sum(tickets_count) one_ticket_cost
FROM afisha.purchases p 
JOIN afisha.events e using(event_id)
JOIN afisha.city c using(city_id)
JOIN afisha.regions r using(region_id)
WHERE currency_code ='rub'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 7
