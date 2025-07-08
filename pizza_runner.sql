-- 🧠 Case Study #2 - Pizza Runner  
-- 📊 A. Pizza Metrics

-- Define helper function to replace null-like strings with a blank
CREATE TEMP FUNCTION nullOutcome(exclusions STRING)
RETURNS STRING
LANGUAGE js AS """
  if (exclusions === null || exclusions === 'null' || exclusions === 'NaN') {
    return ' ';
  } else {
    return exclusions;
  }
""";

-- Define helper function to extract digits unless it's a datetime
CREATE TEMP FUNCTION digitOutcome(exclusions STRING)
RETURNS STRING
LANGUAGE js AS """
  function nullOutcome(exclusions) {
    if (exclusions === null || exclusions === 'null' || exclusions === 'NaN') {
      return ' ';
    } else {
      return exclusions;
    }
  }

  function extractNumbers(input) {
    let datePattern = /^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}$/;
    if (datePattern.test(input)) {
      return input;
    } else {
      let matches = input.match(/\d+(\.\d+)?/g);
      return matches ? matches.join('') : input;
    }
  }

  let cleanedInput = nullOutcome(exclusions);
  return extractNumbers(cleanedInput);
""";

-- ✅ Prepared Data (Not executed yet — uncomment and use if needed)
-- Cleaned version of customer_orders
-- CREATE OR REPLACE TEMP TABLE customer_orders_prep AS
-- SELECT 
--   order_id,
--   customer_id,
--   pizza_order,
--   nullOutcome(exclusions) AS exclusions,
--   nullOutcome(extras) AS extras,
--   order_time
-- FROM `weekchallenges.pizza_runner.customer_orders`;

-- Cleaned version of runner_orders
-- CREATE OR REPLACE TEMP TABLE runner_orders_prep AS
-- SELECT 
--   *,
--   digitOutcome(pickup_time) AS exclusion_pickup_time,
--   digitOutcome(distance) AS exclusion_distance,
--   digitOutcome(duration) AS exclusion_duration,
--   digitOutcome(cancellation) AS exclusion_cancellation
-- FROM `weekchallenges.pizza_runner.runner_orders`;

-- 1️⃣ How many pizzas were ordered?
-- SELECT COUNT(*) AS pizza_orders FROM customer_orders_prep;

-- 2️⃣ How many unique customer orders were made?
-- SELECT COUNT(DISTINCT order_id) AS total_orders FROM customer_orders_prep;

-- 3️⃣ How many successful orders were delivered by each runner?
-- SELECT 
--   runner_id,
--   COUNT(*) AS delivered_orders
-- FROM runner_orders_prep
-- WHERE exclusion_cancellation = ' '
-- GROUP BY runner_id
-- ORDER BY runner_id;

-- 4️⃣ How many of each type of pizza was delivered?
-- WITH pizza_orders AS (
--   SELECT 
--     pn.pizza_name,
--     digitOutcome(ro.cancellation) AS exclusion_cancellation
--   FROM `weekchallenges.pizza_runner.pizza_names` pn
--   JOIN `weekchallenges.pizza_runner.customer_orders` co ON pn.pizza_order = co.pizza_order
--   JOIN `weekchallenges.pizza_runner.runner_orders` ro ON ro.order_id = co.order_id
--   WHERE digitOutcome(ro.cancellation) = ' '
-- )
-- SELECT pizza_name, COUNT(*) AS delivered_count
-- FROM pizza_orders
-- GROUP BY pizza_name;

-- 5️⃣ How many Vegetarian and Meatlovers were ordered by each customer?
-- WITH pizza_orders AS (
--   SELECT 
--     co.customer_id,
--     pn.pizza_name
--   FROM `weekchallenges.pizza_runner.pizza_names` pn
--   JOIN `weekchallenges.pizza_runner.customer_orders` co ON pn.pizza_order = co.pizza_order
--   JOIN `weekchallenges.pizza_runner.runner_orders` ro ON ro.order_id = co.order_id
-- )
-- SELECT customer_id, pizza_name, COUNT(*) AS orders
-- FROM pizza_orders
-- GROUP BY customer_id, pizza_name
-- ORDER BY customer_id;

-- 6️⃣ What was the maximum number of pizzas delivered in a single order?
-- WITH pizza_orders AS (
--   SELECT co.order_id
--   FROM `weekchallenges.pizza_runner.customer_orders` co
--   JOIN `weekchallenges.pizza_runner.runner_orders` ro ON ro.order_id = co.order_id
--   WHERE digitOutcome(ro.cancellation) = ' '
-- )
-- SELECT order_id, COUNT(*) AS pizzas_delivered
-- FROM pizza_orders
-- GROUP BY order_id
-- ORDER BY pizzas_delivered DESC
-- LIMIT 1;

-- 7️⃣ For each customer, how many delivered pizzas had changes vs no changes?
-- WITH pizza_orders AS (
--   SELECT 
--     co.customer_id,
--     nullOutcome(exclusions) AS exclusions,
--     nullOutcome(extras) AS extras,
--     digitOutcome(ro.distance) AS distance
--   FROM `weekchallenges.pizza_runner.customer_orders` co
--   JOIN `weekchallenges.pizza_runner.runner_orders` ro ON ro.order_id = co.order_id
-- )
-- SELECT 
--   customer_id,
--   COUNT(CASE WHEN exclusions <> ' ' OR extras <> ' ' THEN 1 END) AS changed,
--   COUNT(CASE WHEN exclusions = ' ' AND extras = ' ' THEN 1 END) AS unchanged
-- FROM pizza_orders
-- WHERE distance <> ' '
-- GROUP BY customer_id;

-- 8️⃣ How many pizzas had both exclusions and extras?
-- SELECT 
--   COUNT(*) AS pizzas_with_both
-- FROM (
--   SELECT 
--     nullOutcome(exclusions) AS exclusions,
--     nullOutcome(extras) AS extras,
--     digitOutcome(ro.distance) AS distance
--   FROM `weekchallenges.pizza_runner.customer_orders` co
--   JOIN `weekchallenges.pizza_runner.runner_orders` ro ON ro.order_id = co.order_id
-- )
-- WHERE exclusions <> ' ' AND extras <> ' ' AND distance <> ' ';

-- 9️⃣ Total volume of pizzas ordered per hour?
-- SELECT 
--   EXTRACT(HOUR FROM order_time) AS order_hour,
--   COUNT(*) AS pizza_count
-- FROM `weekchallenges.pizza_runner.customer_orders`
-- GROUP BY order_hour
-- ORDER BY order_hour;

-- 🔟 Orders per day of the week?
-- SELECT 
--   FORMAT_DATE('%A', order_time) AS weekday,
--   COUNT(*) AS orders
-- FROM `weekchallenges.pizza_runner.customer_orders`
-- GROUP BY weekday
-- ORDER BY weekday;

-- 🚴 B. Runner and Customer Experience

-- 1️⃣ How many runners signed up each week?
-- SELECT 
--   EXTRACT(WEEK FROM registration_date + 2) AS registration_week,
--   COUNT(*) AS runner_signups
-- FROM `weekchallenges.pizza_runner.runners`
-- GROUP BY registration_week
-- ORDER BY registration_week;

-- 2️⃣ Average time (minutes) from order to pickup
-- WITH base_table AS (
--   SELECT
--     ro.runner_id,
--     nullOutcome(CAST(ro.pickup_time AS STRING)) AS pickup_time,
--     nullOutcome(CAST(co.order_time AS STRING)) AS order_time
--   FROM `weekchallenges.pizza_runner.runner_orders` ro
--   JOIN `weekchallenges.pizza_runner.customer_orders` co ON ro.order_id = co.order_id
-- ),
-- pickup_order_times AS (
--   SELECT
--     CAST(DATETIME(CONCAT('2021-', FORMAT_DATETIME('%m-%d %H:%M:%S', CAST(pickup_time AS TIMESTAMP)))) AS TIMESTAMP) AS pickup_times,
--     CAST(order_time AS TIMESTAMP) AS order_times
--   FROM base_table
--   WHERE pickup_time != ' '
-- ),
-- avg_time_diff AS (
--   SELECT AVG(DATE_DIFF(pickup_times, order_times, MINUTE)) AS avg_time FROM pickup_order_times
-- )
-- SELECT
--   TIME(0, FLOOR(avg_time), FLOOR((avg_time - FLOOR(avg_time)) * 60)) AS order_time_diff
-- FROM avg_time_diff;

-- 3️⃣ Relation between number of pizzas and prep time?
-- Similar to #2 but grouped by pizza count per order

-- 4️⃣ Average distance per customer
-- SELECT
--   co.customer_id,
--   AVG(SAFE_CAST(digitOutcome(CAST(ro.distance AS STRING)) AS FLOAT64)) AS avg_distance
-- FROM `weekchallenges.pizza_runner.runner_orders` ro
-- JOIN `weekchallenges.pizza_runner.customer_orders` co ON ro.order_id = co.order_id
-- WHERE digitOutcome(CAST(ro.distance AS STRING)) != ' '
-- GROUP BY customer_id
-- ORDER BY customer_id;

-- 5️⃣ Difference between longest and shortest delivery time
-- SELECT 
--   MAX(SAFE_CAST(digitOutcome(CAST(duration AS STRING)) AS INT64)) - 
--   MIN(SAFE_CAST(digitOutcome(CAST(duration AS STRING)) AS INT64)) AS delivery_time_range
-- FROM `weekchallenges.pizza_runner.runner_orders`;

-- 6️⃣ Average speed per delivery per runner
-- SELECT 
--   runner_id,
--   order_id,
--   ROUND(SAFE_CAST(digitOutcome(CAST(distance AS STRING)) AS FLOAT64) /
--         (SAFE_CAST(digitOutcome(CAST(duration AS STRING)) AS FLOAT64)/60), 2) AS avg_speed
-- FROM `weekchallenges.pizza_runner.runner_orders`
-- WHERE digitOutcome(CAST(distance AS STRING)) != ' '
-- ORDER BY order_id;

-- 7️⃣ Successful delivery percentage per runner
-- WITH delivery_stats AS (
--   SELECT 
--     runner_id,
--     COUNT(*) AS total_deliveries,
--     COUNTIF(SAFE_CAST(digitOutcome(CAST(duration AS STRING)) AS FLOAT64) > 0) AS successful_deliveries
--   FROM `weekchallenges.pizza_runner.runner_orders`
--   GROUP BY runner_id
-- )
-- SELECT 
--   runner_id,
--   total_deliveries,
--   successful_deliveries,
--   ROUND((successful_deliveries / total_deliveries) * 100, 2) || '%' AS success_rate
-- FROM delivery_stats;