 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок

-- 1.1. Доля платящих пользователей по всем данным:
-- Высчитываем кол-во всех пользователей и кол-во покупателей
WITH unp AS (SELECT 
	count( id) AS all_users,
	(SELECT
		count(*) 
	FROM ( SELECT * FROM fantasy.users u2 ) AS cheta
	WHERE payer = 1)  AS all_payers
FROM fantasy.users AS u)
--Высчитываем долю платящих игроков
SELECT *,
		round(all_payers::numeric/all_users,2) AS payers_procent
FROM unp;
-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Находим число платящих игроков
WITH cheta2 AS (
SELECT 
		r.race_id, 
		r.race,
		count(*) AS all_payers
FROM fantasy.users AS cheta
JOIN fantasy.race as r ON cheta.race_id = r.race_id  
WHERE payer = 1
GROUP BY r.race_id, race)
--Находим число всех игроков и долю платящих в разрезе расы
SELECT
	c.race,
	c.all_payers,
	count(u.id) AS all_players,
	round( c.all_payers::NUMERIC/count(u.id),2) AS payers_procent
FROM cheta2 AS c
JOIN fantasy.users AS u ON c.race_id = u.race_id
GROUP BY c.race,c.all_payers
ORDER BY payers_procent DESC;
-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT 
	count(transaction_id) AS total_purchases,
	sum(amount) AS total_amount,
	min(amount) AS min_amount,
	max(amount) AS max_amount,
	avg(amount) AS avg_amount,
	percentile_disc(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount,
	stddev(amount) AS stand_dev 
FROM fantasy.events;
-- 2.2: Аномальные нулевые покупки:
WITH basic_static AS (SELECT 
	count(transaction_id) AS total_purchases,
	sum(amount) AS total_amount,
	min(amount) AS min_amount,
	max(amount) AS max_amount,
	avg(amount) AS avg_amount,
	percentile_disc(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount,
	stddev(amount) AS stand_dev 
FROM fantasy.events),
zero_amount_static AS (SELECT 
    (SELECT
	count(transaction_id)
FROM fantasy.events
WHERE amount = 0) AS all_zero_amount,
total_purchases
FROM basic_static)
SELECT
	all_zero_amount,
	all_zero_amount::NUMERIC/total_purchases AS zero_amount_proc
FROM zero_amount_static

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
SELECT 
	payer,
	count(DISTINCT e.id) AS total_players,
	count(transaction_id)/ count(DISTINCT e.id) AS avg_transac,
	round(sum(amount)::numeric /count(DISTINCT e.id),2) AS avg_amount 
FROM fantasy.users AS u 
JOIN fantasy.events as e using(id)
WHERE amount != 0
GROUP BY payer
