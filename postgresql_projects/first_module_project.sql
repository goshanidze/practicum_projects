/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
*/

-- Пример фильтрации данных от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    )
-- Выведем объявления без выбросов:
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id);


-- Задача 1: Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?
-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    )
SELECT 	case 
		when city_id = '6X8I' then 'Санкт-Петербург'
		else 'ЛенОбл'
	end as "Регион",
	case 
		when days_exposition <= 30 then 'месяц'
		when days_exposition between 31 and 90 then 'квартал'
		when days_exposition between 91 and 180 then 'полгода'
		when days_exposition >= 181 then 'больше полугода'
		when days_exposition is null then 'публикация активна'
	end as "Период активности",
	*
FROM real_estate.flats
left join real_estate.advertisement a using(id)
left join real_estate.city c using(city_id)
left join real_estate."type" t using(type_id)
WHERE id IN (SELECT * FROM filtered_id) AND TYPE = 'город'

/*SELECT 
	"Регион",
	type,
	avg(days_exposition)
FROM cte
GROUP BY "Регион",type*/
select
	"Регион",
	"Период активности",
	count(distinct id) as all_id,
	round(count(distinct id)*100::numeric/(select count(*) from cte),2) as share_id,
	round(avg(last_price / total_area)::numeric,2) as avg_m2_price,
	round(avg(total_area)::numeric,2) as avg_total_area,
	percentile_disc(0.5) within group(order by rooms) as rooms_median,
	percentile_disc(0.5) within group(order by balcony) as balcony_median,
	percentile_disc(0.5) within group(order by floor) as floor_median,
	round(COALESCE(avg(days_exposition)::numeric,0),2) AS avg_exp
from cte
group by "Регион", "Период активности"
order by Регион desc


-- Задача 2: Сезонность объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
--    А в какие — по снятию? Это показывает динамику активности покупателей.
-- 2. Совпадают ли периоды активной публикации объявлений и периоды, 
--    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
-- 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
--    Что можно сказать о зависимости этих параметров от месяца?

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
-- Выведем объявления без выбросов:
SELECT
	id,
	first_day_exposition,
	EXTRACT(MONTH FROM first_day_exposition) AS month_exposition,
	CAST((first_day_exposition + INTERVAL'1'DAY *(EXTRACT(DAY FROM first_day_exposition ) + days_exposition)) AS date) AS date_selling,
	EXTRACT(MONTH FROM CAST((first_day_exposition + INTERVAL'1'DAY *(EXTRACT(DAY FROM first_day_exposition ) + days_exposition)) AS date)) AS month_selling,
	total_area,
	last_price
	--EXTRACT(DAY FROM first_day_exposition) AS day_exposition,
	--CAST((EXTRACT(DAY FROM first_day_exposition ) + days_exposition) AS numeric) AS day_selling,
FROM real_estate.flats
left join real_estate.advertisement a using(id)
left join real_estate.city c using(city_id)
left join real_estate."type" t using(type_id)
WHERE id IN (SELECT * FROM filtered_id)


SELECT
	*
FROM (SELECT month_exposition, 
	count(id) AS count_exp,
	rank()over(ORDER BY count(id)desc) AS rank_exp,
	round(avg(total_area)::NUMERIC,2) AS avg_exp_area,
	round(avg(last_price/total_area)::numeric,2) AS avg_m3_exp 
FROM cte1 group BY month_exposition) AS m_exp
JOIN (SELECT month_selling, 
	count(id) AS count_sell, 
	rank()over(ORDER BY count(id)desc) AS rank_sell,
	round(avg(total_area)::numeric,2) AS avg_sell_area,
	round(avg(last_price/total_area)::NUMERIC,2) AS  avg_m3_sell
FROM cte1
WHERE month_selling IS NOT null
group BY month_selling) AS m_sell ON month_exposition = month_selling
ORDER BY 1

-- Задача 3: Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    ),
cte as (
select
	*
FROM real_estate.flats
left join real_estate.advertisement a using(id)
left join real_estate.city c using(city_id)
left join real_estate."type" t using(type_id)
WHERE id IN (SELECT * FROM filtered_id) and  city_id != '6X8I' )
SELECT
	city,
	type,
	count(distinct id) as all_id,
	round(count(distinct id)*100::numeric/(select count(*) from cte),2) as share_id,
	round(avg(last_price / total_area)::numeric,2) as avg_m3_price,
	round(avg(total_area)::numeric,2) as avg_total_area,
	round(sum(CASE WHEN days_exposition IS NOT NULL THEN 1 ELSE 0 end)*100::numeric/count(first_day_exposition),3) AS sell_share,
	round(avg(COALESCE(days_exposition,0))::numeric,2) as avg_days_exp
from cte
group by city,type
ORDER BY all_id desc,sell_share DESC ,avg_days_exp
LIMIT 15 
