--Cafe Rewards Offers

--Data Cleaning

--Extracting the JSON column in the customers table

DROP TABLE IF EXISTS #NEW_EVENTS

CREATE TABLE #NEW_EVENTS(
CUSTOMER_ID varchar(100),
event varchar(100),
offer_id varchar(100),
amount float,
reward int,
time int
)

INSERT INTO #NEW_EVENTS

SELECT CUSTOMER_ID, EVENT,
	 JSON_VALUE(REPLACE(REPLACE(value, '''', '"'), 'offer id', 'offer_id'), '$.offer_id') AS offer_id,
	 JSON_VALUE(REPLACE(REPLACE(value, '''', '"'), 'offer id', 'offer_id'), '$.amount') AS amount,
	 JSON_VALUE(REPLACE(REPLACE(value, '''', '"'), 'offer id', 'offer_id'), '$.reward') AS reward,
	 TIME
FROM CAFE.DBO.events$;

DROP TABLE IF EXISTS #EVENTS2

CREATE TABLE #EVENTS2(
CUSTOMER_ID varchar(100),
event varchar(100),
offer_id varchar(100),
amount float,
reward int,
time int,
offer_type char(15),
difficulty int,
rewards int,
duration int,
channels nvarchar(100),
became_member_on int,
gender char(10),
age int,
income int
)

INSERT INTO #EVENTS2
SELECT A.CUSTOMER_ID, A.event, A.offer_id, A.amount, A.reward, A.time, B.offer_type, B.difficulty, (B.reward) AS rewards, B.duration, B.channels, became_member_on, gender, age, income
FROM #NEW_EVENTS A
LEFT JOIN Cafe.DBO.offers$ B
ON A.offer_id = B.offer_id
left join cafe.dbo.customers$ c
on a.CUSTOMER_ID= c.customer_id
--where c.gender is not null
ORDER BY a.TIME

select *
from #EVENTS2
order by time

--Data exploration

--1. How many Rewards offers were completed

select count(*)
from #EVENTS2
where event= 'offer completed'

--2. Which offers had the highest completion rate

SELECT 
  offer_type,
  COUNT(*) AS completed_count,
  ROUND((100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()), 2) AS percentage_completed
FROM #EVENTS2
WHERE event = 'offer completed'
GROUP BY offer_type;

--We could make it even more granular by breaking down each offer type

with tt1 as (
select offer_type, offer_id, event, 
		case
			when offer_id = 'ae264e3637204a6fb9bb56bc8210ddfd' then 'bogo1'
			when offer_id = '4d5c57ea9a6940dd891ad53e9dbe8da0' then 'bogo2'
			when offer_id = '9b98b8c7a33c4b65b9aebfe6a799e6d9' then 'bogo3'
			when offer_id = 'f19421c1d4aa40978ebb69ca19b0e20d' then 'bogo4'
			when offer_id = '0b1e1539f2cc45b7b9fa7c272da2e1d7' then 'discount1'
			when offer_id = '2298d6c36e964ae4a3e7e9706d1fb8c2' then 'discount2'
			when offer_id = 'fafdcd668e3743c1bb461111dcafc2a4' then 'discount3'
			when offer_id = '2906b810c7d4411798c6938adc9daaa5' then 'discount4'
			when offer_id = '3f207df678b143eea3cee63160fa8bed' then 'informational1'
			else 'informational2'
			end as specific_offer,
			channels
from #EVENTS2
)

SELECT 
  specific_offer,
  COUNT(*) AS completed_count,
  ROUND((100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()), 2) AS percentage_completed,
  channels
FROM tt1
WHERE event = 'offer completed'
GROUP BY specific_offer, channels
order by specific_offer;

--3. How many informational offers were followed by transactions

WITH ordered_events AS (
  SELECT
    customer_id,
    event,
    time,
	offer_type,
    LEAD(event) OVER (PARTITION BY customer_id ORDER BY time) AS next_event
  FROM #EVENTS2
  WHERE offer_type = 'informational' OR offer_type IS NULL

)

SELECT COUNT(*) AS transaction_count
FROM ordered_events
WHERE event = 'offer viewed'
  AND next_event = 'transaction';

--4. How are customer demographics distributed?

select coalesce(gender, 'Unknown') as gender, count(*) as count, ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
from #EVENTS2
group by gender

SELECT 
  CASE 
    WHEN age < 20 THEN 'Under 20'
    WHEN age BETWEEN 20 AND 35 THEN 'Young_adult'
    WHEN age BETWEEN 36 AND 50 THEN 'Middle_age'
    WHEN age BETWEEN 51 AND 65 THEN 'Advanced_age' -- :)
    ELSE 'Senior' -- :)
  END AS age_group,
  COUNT(*) AS count
FROM #EVENTS2
group by
  CASE 
    WHEN age < 20 THEN 'Under 20'
    WHEN age BETWEEN 20 AND 35 THEN 'Young_adult'
    WHEN age BETWEEN 36 AND 50 THEN 'Middle_age'
    WHEN age BETWEEN 51 AND 65 THEN 'Advanced_age' -- :)
    ELSE 'Senior' -- :)
  END;


SELECT 
  CASE 
    WHEN income BETWEEN 30000 AND 60000 THEN 'low_income'
    WHEN income BETWEEN 61000 AND 90000 THEN 'mid_income'
    ELSE 'high_income'
  END AS income_group,
  COUNT(*) AS count
FROM #EVENTS2
where income is not null
group by
  CASE 
    WHEN income BETWEEN 30000 AND 60000 THEN 'low_income'
    WHEN income BETWEEN 61000 AND 90000 THEN 'mid_income'
    ELSE 'high_income'
  END;
  
SELECT 
  CASE 
    WHEN income BETWEEN 30000 AND 60000 THEN 'low_income'
    WHEN income BETWEEN 61000 AND 90000 THEN 'mid_income'
    ELSE 'high_income'
  END AS income_group,
  COUNT(*) AS count
FROM #EVENTS2
where income is not null
group by
  CASE 
    WHEN income BETWEEN 30000 AND 60000 THEN 'low_income'
    WHEN income BETWEEN 61000 AND 90000 THEN 'mid_income'
    ELSE 'high_income'
  END;

  --5. Are there any demographic patterns in offer completion?

  select gender, count(*) as count,  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
  from #EVENTS2
  where event = 'offer completed' and gender is not null
  group by gender

  
  SELECT 
  CASE 
    WHEN income BETWEEN 30000 AND 60000 THEN 'low_income'
    WHEN income BETWEEN 61000 AND 90000 THEN 'mid_income'
    ELSE 'high_income'
  END AS income_group,
  COUNT(*) AS count,
   ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM #EVENTS2
where income is not null and event = 'offer completed'
group by
  CASE 
    WHEN income BETWEEN 30000 AND 60000 THEN 'low_income'
    WHEN income BETWEEN 61000 AND 90000 THEN 'mid_income'
    ELSE 'high_income'
  END;


SELECT 
  CASE 
    WHEN age < 20 THEN 'Under 20'
    WHEN age BETWEEN 20 AND 35 THEN 'Young_adult'
    WHEN age BETWEEN 36 AND 50 THEN 'Middle_age'
    WHEN age BETWEEN 51 AND 65 THEN 'Advanced_age' -- :)
    ELSE 'Senior' -- :)
  END AS age_group,
  COUNT(*) AS count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM #EVENTS2
where event = 'offer completed'
group by
  CASE 
    WHEN age < 20 THEN 'Under 20'
    WHEN age BETWEEN 20 AND 35 THEN 'Young_adult'
    WHEN age BETWEEN 36 AND 50 THEN 'Middle_age'
    WHEN age BETWEEN 51 AND 65 THEN 'Advanced_age' -- :)
    ELSE 'Senior' -- :)
  END;


--6. Are there reward patterns in offer completion

 select rewards, count(*) as count,  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
  from #EVENTS2
  where event = 'offer completed' and rewards is not null
  group by rewards
  order by percentage

--Difficulty

 select difficulty, count(*) as count,  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
  from #EVENTS2
  where event = 'offer completed' and difficulty is not null
  group by difficulty
  order by percentage;

--7. Trend between offer channels and offers viewed

with tt2 as (

select offer_type, offer_id, event, channels,
		case
			when offer_id = 'ae264e3637204a6fb9bb56bc8210ddfd' then 'bogo1'
			when offer_id = '4d5c57ea9a6940dd891ad53e9dbe8da0' then 'bogo2'
			when offer_id = '9b98b8c7a33c4b65b9aebfe6a799e6d9' then 'bogo3'
			when offer_id = 'f19421c1d4aa40978ebb69ca19b0e20d' then 'bogo4'
			when offer_id = '0b1e1539f2cc45b7b9fa7c272da2e1d7' then 'discount1'
			when offer_id = '2298d6c36e964ae4a3e7e9706d1fb8c2' then 'discount2'
			when offer_id = 'fafdcd668e3743c1bb461111dcafc2a4' then 'discount3'
			when offer_id = '2906b810c7d4411798c6938adc9daaa5' then 'discount4'
			when offer_id = '3f207df678b143eea3cee63160fa8bed' then 'informational1'
			when offer_id = '5a8bc65990b245e5a138643cd4eb9837' then 'informational2'
			else 'other'
			end as specific_offer
from #EVENTS2
)

SELECT 
	specific_offer,
  COUNT(*) AS viewed_count,
  ROUND((100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()), 2) AS percentage_viewed,
  channels
FROM tt2
WHERE event = 'offer viewed'
GROUP BY specific_offer, channels
order by 3 desc;

--8. Best performing offers in different demographics
--Gender

 select gender, offer_type, count(*) as count,  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
  from #EVENTS2
  where event = 'offer completed' and gender is not null
  group by gender, offer_type
  order by percentage desc;

--Age

SELECT 
  CASE 
    WHEN age < 20 THEN 'Under 20'
    WHEN age BETWEEN 20 AND 35 THEN 'Young_adult'
    WHEN age BETWEEN 36 AND 50 THEN 'Middle_age'
    WHEN age BETWEEN 51 AND 65 THEN 'Advanced_age' -- :)
    ELSE 'Senior' -- :)
  END AS age_group,
  offer_type,
  COUNT(*) AS count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM #EVENTS2
where event = 'offer completed'
group by
  CASE 
    WHEN age < 20 THEN 'Under 20'
    WHEN age BETWEEN 20 AND 35 THEN 'Young_adult'
    WHEN age BETWEEN 36 AND 50 THEN 'Middle_age'
    WHEN age BETWEEN 51 AND 65 THEN 'Advanced_age' -- :)
    ELSE 'Senior' -- :)
  END,
  offer_type
  order by percentage desc;

--Income

  SELECT 
  CASE 
    WHEN income BETWEEN 30000 AND 60000 THEN 'low_income'
    WHEN income BETWEEN 61000 AND 90000 THEN 'mid_income'
    ELSE 'high_income'
  END AS income_group,
  offer_type,
  COUNT(*) AS count,
   ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM #EVENTS2
where income is not null and event = 'offer completed'
group by
  CASE 
    WHEN income BETWEEN 30000 AND 60000 THEN 'low_income'
    WHEN income BETWEEN 61000 AND 90000 THEN 'mid_income'
    ELSE 'high_income'
  END,
  offer_type
  order by percentage;


--Offer linked purchases and revenue



WITH linked_purchases AS (
  SELECT
    customer_id,
    event,
	cast(isnull(amount, 0) as float) as amount,
    time,
	offer_type,
    Lag(event) OVER (PARTITION BY customer_id ORDER BY time) AS previous_event
  FROM #EVENTS2
  --WHERE offer_type IS not NULL

)


SELECT SUM(amount) AS amount, count(amount) as count
FROM linked_purchases
WHERE event = 'transaction'
  AND previous_event = 'offer viewed' --or previous_event= 'offer received';

--Total numbers

SELECT count(amount) AS total_count, sum(amount) as total_amount
FROM #EVENTS2
--WHERE event = 'transaction'
--  AND previous_event = 'offer viewed' --or previous_event= 'offer received';


SELECT 
	customer_id,
	event,
	offer_type,
	amount,
  CASE
    WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' AND Channels LIKE '%mobile%' AND Channels LIKE '%social%' THEN 'WEMS'
    WHEN Channels LIKE '%email%' AND Channels LIKE '%mobile%' AND Channels LIKE '%social%' THEN 'EMS'
    WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' AND Channels LIKE '%mobile%' THEN 'WEM'
	WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' THEN 'WE'
    ELSE 'OTHER'
  END AS channel_group
FROM #EVENTS2
--WHERE channels is not null
GROUP BY CASE
    WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' AND Channels LIKE '%mobile%' AND Channels LIKE '%social%' THEN 'WEMS'
    WHEN Channels LIKE '%email%' AND Channels LIKE '%mobile%' AND Channels LIKE '%social%' THEN 'EMS'
    WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' AND Channels LIKE '%mobile%' THEN 'WEM'
	WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' THEN 'WE'
    ELSE 'OTHER'
  END,
  CUSTOMER_ID,
  event,
  offer_type,
  amount

--CTR AND COMPLETION RATE PER CHANNELS

WITH TT5 as (
  SELECT 
    customer_id,
    event,
    offer_type,
    amount,
    Channels,
    CASE
    --  WHEN Channels IS NULL THEN 'UNKNOWN'
      WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' AND Channels LIKE '%mobile%' AND Channels LIKE '%social%' THEN 'WEMS'
      WHEN Channels LIKE '%email%' AND Channels LIKE '%mobile%' AND Channels LIKE '%social%' THEN 'EMS'
      WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' AND Channels LIKE '%mobile%' THEN 'WEM'
      WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' THEN 'WE'
      ELSE 'OTHER'
    END AS channel_group
  FROM #EVENTS2
  )

SELECT 
  channel_group,
  COUNT(*) AS completed_offer_count
FROM TT5
WHERE event = 'offer completed'
GROUP BY channel_group
ORDER BY completed_offer_count DESC;

WITH TT6 AS (
  SELECT 
    customer_id,
    event,
    offer_type,
    amount,
    Channels,
    CASE
    --  WHEN Channels IS NULL THEN 'UNKNOWN'
      WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' AND Channels LIKE '%mobile%' AND Channels LIKE '%social%' THEN 'WEMS'
      WHEN Channels LIKE '%email%' AND Channels LIKE '%mobile%' AND Channels LIKE '%social%' THEN 'EMS'
      WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' AND Channels LIKE '%mobile%' THEN 'WEM'
      WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' THEN 'WE'
      ELSE 'OTHER'
    END AS channel_group
  FROM #EVENTS2
)

SELECT 
  channel_group,
  COUNT(*) AS viewed_offer_count
FROM TT6
WHERE event = 'offer viewed'
GROUP BY channel_group
ORDER BY viewed_offer_count DESC;


WITH TT7 AS (
  SELECT 
    customer_id,
    event,
    offer_type,
    amount,
    Channels,
    CASE
    --  WHEN Channels IS NULL THEN 'UNKNOWN'
      WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' AND Channels LIKE '%mobile%' AND Channels LIKE '%social%' THEN 'WEMS'
      WHEN Channels LIKE '%email%' AND Channels LIKE '%mobile%' AND Channels LIKE '%social%' THEN 'EMS'
      WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' AND Channels LIKE '%mobile%' THEN 'WEM'
      WHEN Channels LIKE '%web%' AND Channels LIKE '%email%' THEN 'WE'
      ELSE 'OTHER'
    END AS channel_group
  FROM #EVENTS2
)

SELECT 
  channel_group,
  COUNT(*) AS received_offer_count
FROM TT7
WHERE event = 'offer received'
GROUP BY channel_group
ORDER BY received_offer_count DESC;

--PER OFFER TYPE


SELECT 
  OFFER_TYPE,
  COUNT(*) AS offer_type_count
FROM #EVENTS2
WHERE event = 'offer received'
GROUP BY offer_type
ORDER BY offer_type_count DESC;

SELECT 
  OFFER_TYPE,
  COUNT(*) AS viewed_count
FROM #EVENTS2
WHERE event = 'offer viewed'
GROUP BY offer_type
ORDER BY viewed_count DESC;

SELECT 
  OFFER_TYPE,
  COUNT(*) AS completed_count
FROM #EVENTS2
WHERE event = 'offer completed'
GROUP BY offer_type
ORDER BY completed_count DESC;



SELECT 
	offer_type,
  COUNT(*) AS viewed_count,
  ROUND((100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()), 2) AS percentage_viewed
FROM #EVENTS2
WHERE event = 'offer viewed'
GROUP BY offer_type
order by 3 desc;

SELECT 
	channels,
  COUNT(*) AS viewed_count,
  ROUND((100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()), 2) AS percentage_viewed
FROM #EVENTS2
WHERE event = 'offer viewed'
GROUP BY channels
order by 3 desc;

SELECT 
	offer_type,
  COUNT(*) AS received_count,
  ROUND((100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()), 2) AS percentage_viewed
FROM #EVENTS2
WHERE event = 'offer received'
GROUP BY offer_type
order by 3 desc;


