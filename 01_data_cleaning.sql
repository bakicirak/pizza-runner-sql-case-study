-- ============================================================================
-- 01 Data cleaning (PostgreSQL)
-- Data-quality issues found in the raw tables:
--   * 'null' / 'NaN' stored as text, mixed with real NULLs and ''
--   * units inside numeric fields: '20km', '23.4 km', '32 minutes', '15 minute'
--   * pickup_time stored as text
-- The cleaned tables below are the single source for all later queries, so
-- every metric uses the same definitions.
-- ============================================================================
SET search_path = pizza_runner;

DROP TABLE IF EXISTS customer_orders_clean;
CREATE TABLE customer_orders_clean AS
SELECT
  ROW_NUMBER() OVER (ORDER BY order_id, pizza_id)                         AS pizza_line_id, -- one row = one pizza
  order_id,
  customer_id,
  pizza_id,
  NULLIF(NULLIF(NULLIF(TRIM(exclusions), ''), 'null'), 'NaN')             AS exclusions,
  NULLIF(NULLIF(NULLIF(TRIM(extras), ''), 'null'), 'NaN')                 AS extras,
  order_time
FROM customer_orders;

DROP TABLE IF EXISTS runner_orders_clean;
CREATE TABLE runner_orders_clean AS
SELECT
  order_id,
  runner_id,
  CAST(NULLIF(pickup_time, 'null') AS TIMESTAMP)                          AS pickup_time,
  CAST(NULLIF(REGEXP_REPLACE(distance, '[^0-9.]', '', 'g'), '') AS NUMERIC) AS distance_km,
  CAST(NULLIF(REGEXP_REPLACE(duration, '[^0-9.]', '', 'g'), '') AS NUMERIC) AS duration_min,
  NULLIF(NULLIF(NULLIF(TRIM(cancellation), ''), 'null'), 'NaN')          AS cancellation,
  NULLIF(NULLIF(NULLIF(TRIM(cancellation), ''), 'null'), 'NaN') IS NULL  AS is_delivered
FROM runner_orders;
