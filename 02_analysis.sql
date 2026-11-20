-- ============================================================================
-- 02 Analysis (PostgreSQL). Run 01_data_cleaning.sql first.
-- Sections: A. Order metrics · B. Runner & customer experience
--           C. Ingredient optimisation · D. Pricing & profitability
-- ============================================================================
SET search_path = pizza_runner;

-- ---------------------------------------------------------------------------
-- A. ORDER METRICS
-- ---------------------------------------------------------------------------

-- A1. How many pizzas were ordered?
SELECT COUNT(*) AS pizzas_ordered
FROM customer_orders_clean;

-- A2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS orders
FROM customer_orders_clean;

-- A3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(*) AS delivered_orders
FROM runner_orders_clean
WHERE is_delivered
GROUP BY runner_id
ORDER BY runner_id;

-- A4. How many of each type of pizza was delivered?
SELECT pn.pizza_name, COUNT(*) AS pizzas_delivered
FROM customer_orders_clean co
JOIN runner_orders_clean ro ON ro.order_id = co.order_id
JOIN pizza_names pn         ON pn.pizza_id = co.pizza_id
WHERE ro.is_delivered
GROUP BY pn.pizza_name
ORDER BY pn.pizza_name;

-- A5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
  co.customer_id,
  COUNT(*) FILTER (WHERE pn.pizza_name = 'Meatlovers') AS meatlovers,
  COUNT(*) FILTER (WHERE pn.pizza_name = 'Vegetarian') AS vegetarian
FROM customer_orders_clean co
JOIN pizza_names pn ON pn.pizza_id = co.pizza_id
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- A6. Maximum number of pizzas delivered in a single order
SELECT co.order_id, COUNT(*) AS pizzas_in_order
FROM customer_orders_clean co
JOIN runner_orders_clean ro ON ro.order_id = co.order_id
WHERE ro.is_delivered
GROUP BY co.order_id
ORDER BY pizzas_in_order DESC
LIMIT 1;

-- A7. For each customer, how many delivered pizzas had at least one change vs. no changes?
SELECT
  co.customer_id,
  COUNT(*) FILTER (WHERE co.exclusions IS NOT NULL OR co.extras IS NOT NULL) AS with_changes,
  COUNT(*) FILTER (WHERE co.exclusions IS NULL AND co.extras IS NULL)         AS no_changes
FROM customer_orders_clean co
JOIN runner_orders_clean ro ON ro.order_id = co.order_id
WHERE ro.is_delivered
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- A8. How many delivered pizzas had both exclusions and extras?
SELECT COUNT(*) AS pizzas_with_exclusions_and_extras
FROM customer_orders_clean co
JOIN runner_orders_clean ro ON ro.order_id = co.order_id
WHERE ro.is_delivered
  AND co.exclusions IS NOT NULL
  AND co.extras IS NOT NULL;

-- A9. Pizza volume by hour of day
SELECT EXTRACT(HOUR FROM order_time) AS order_hour, COUNT(*) AS pizzas
FROM customer_orders_clean
GROUP BY order_hour
ORDER BY order_hour;

-- A10. Order volume by day of week (ordered Monday -> Sunday, not alphabetically)
SELECT
  EXTRACT(ISODOW FROM order_time) AS iso_dow,
  TRIM(TO_CHAR(order_time, 'Day')) AS weekday,
  COUNT(DISTINCT order_id)         AS orders
FROM customer_orders_clean
GROUP BY iso_dow, weekday
ORDER BY iso_dow;

-- ---------------------------------------------------------------------------
-- B. RUNNER & CUSTOMER EXPERIENCE
-- ---------------------------------------------------------------------------

-- B1. Runner sign-ups per week (weeks start on 2021-01-01)
SELECT
  FLOOR((registration_date - DATE '2021-01-01') / 7.0) + 1 AS signup_week,
  COUNT(*)                                          AS runners
FROM runners
GROUP BY signup_week
ORDER BY signup_week;

-- B2. Average minutes from order to pickup, per runner (one value per order, not per pizza)
WITH order_level AS (
  SELECT DISTINCT co.order_id, ro.runner_id, co.order_time, ro.pickup_time
  FROM customer_orders_clean co
  JOIN runner_orders_clean ro ON ro.order_id = co.order_id
  WHERE ro.is_delivered
)
SELECT
  runner_id,
  ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60), 1) AS avg_minutes_to_pickup
FROM order_level
GROUP BY runner_id
ORDER BY runner_id;

-- B3. Does the number of pizzas per order relate to preparation time?
WITH order_level AS (
  SELECT
    co.order_id,
    COUNT(*)                                                        AS pizzas,
    MAX(EXTRACT(EPOCH FROM (ro.pickup_time - co.order_time)) / 60)  AS prep_minutes
  FROM customer_orders_clean co
  JOIN runner_orders_clean ro ON ro.order_id = co.order_id
  WHERE ro.is_delivered
  GROUP BY co.order_id
)
SELECT
  pizzas,
  COUNT(*)                                       AS orders,
  ROUND(AVG(prep_minutes), 1)                    AS avg_prep_minutes,
  ROUND(AVG(prep_minutes) / pizzas, 1)           AS avg_prep_minutes_per_pizza
FROM order_level
GROUP BY pizzas
ORDER BY pizzas;

-- B4. Average delivery distance per customer
SELECT co.customer_id, ROUND(AVG(ro.distance_km), 1) AS avg_distance_km
FROM (SELECT DISTINCT order_id, customer_id FROM customer_orders_clean) co
JOIN runner_orders_clean ro ON ro.order_id = co.order_id
WHERE ro.is_delivered
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- B5. Difference between the longest and shortest delivery duration
SELECT MAX(duration_min) - MIN(duration_min) AS delivery_minutes_range
FROM runner_orders_clean
WHERE is_delivered;

-- B6. Average speed (km/h) per runner per delivery
SELECT
  runner_id,
  order_id,
  distance_km,
  duration_min,
  ROUND(distance_km / (duration_min / 60), 1) AS speed_kmh
FROM runner_orders_clean
WHERE is_delivered
ORDER BY runner_id, order_id;

-- B7. Successful delivery rate per runner
SELECT
  runner_id,
  COUNT(*)                                                       AS assigned_orders,
  COUNT(*) FILTER (WHERE is_delivered)                           AS delivered_orders,
  ROUND(100.0 * COUNT(*) FILTER (WHERE is_delivered) / COUNT(*)) AS success_rate_pct
FROM runner_orders_clean
GROUP BY runner_id
ORDER BY runner_id;

-- ---------------------------------------------------------------------------
-- C. INGREDIENT OPTIMISATION
-- ---------------------------------------------------------------------------

-- C1. Most frequently added extra
WITH extras AS (
  SELECT CAST(TRIM(UNNEST(STRING_TO_ARRAY(extras, ','))) AS INTEGER) AS topping_id
  FROM customer_orders_clean
  WHERE extras IS NOT NULL
)
SELECT pt.topping_name, COUNT(*) AS times_added
FROM extras e
JOIN pizza_toppings pt ON pt.topping_id = e.topping_id
GROUP BY pt.topping_name
ORDER BY times_added DESC, pt.topping_name;

-- C2. Most frequently excluded ingredient
WITH exclusions AS (
  SELECT CAST(TRIM(UNNEST(STRING_TO_ARRAY(exclusions, ','))) AS INTEGER) AS topping_id
  FROM customer_orders_clean
  WHERE exclusions IS NOT NULL
)
SELECT pt.topping_name, COUNT(*) AS times_excluded
FROM exclusions e
JOIN pizza_toppings pt ON pt.topping_id = e.topping_id
GROUP BY pt.topping_name
ORDER BY times_excluded DESC, pt.topping_name;

-- ---------------------------------------------------------------------------
-- D. PRICING & PROFITABILITY
-- Meatlovers $12, Vegetarian $10, each extra +$1, runners paid $0.30 per km.
-- ---------------------------------------------------------------------------

-- D1. Revenue from delivered pizzas, without and with extra charges
WITH delivered AS (
  SELECT
    co.pizza_id,
    COALESCE(ARRAY_LENGTH(STRING_TO_ARRAY(co.extras, ','), 1), 0) AS n_extras
  FROM customer_orders_clean co
  JOIN runner_orders_clean ro ON ro.order_id = co.order_id
  WHERE ro.is_delivered
)
SELECT
  SUM(CASE pizza_id WHEN 1 THEN 12 ELSE 10 END)            AS revenue_base,
  SUM(CASE pizza_id WHEN 1 THEN 12 ELSE 10 END + n_extras) AS revenue_with_extras
FROM delivered;

-- D2. Profit after paying runners $0.30/km (fixed prices, no extras)
WITH revenue AS (
  SELECT SUM(CASE co.pizza_id WHEN 1 THEN 12 ELSE 10 END) AS revenue
  FROM customer_orders_clean co
  JOIN runner_orders_clean ro ON ro.order_id = co.order_id
  WHERE ro.is_delivered
),
runner_cost AS (
  SELECT SUM(distance_km * 0.30) AS cost
  FROM runner_orders_clean
  WHERE is_delivered
)
SELECT
  r.revenue,
  ROUND(c.cost, 2)                               AS runner_cost,
  ROUND(r.revenue - c.cost, 2)                   AS profit,
  ROUND(100 * (r.revenue - c.cost) / r.revenue, 1) AS margin_pct
FROM revenue r CROSS JOIN runner_cost c;
