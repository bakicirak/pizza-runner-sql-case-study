# Pizza Runner: Delivery Operations & Unit Economics (SQL)

**Business question:** Where does the delivery business lose orders, time and margin, and what should the founder fix first?

**Stack:** PostgreSQL · data cleaning with `REGEXP_REPLACE`/`NULLIF` · CTEs · `FILTER` aggregates · array functions
**Source:** [8 Week SQL Challenge, Case Study #2](https://8weeksqlchallenge.com/case-study-2/). Small sample (10 orders, 14 pizzas, 4 runners). The goal is to show the method; the numbers are too small for strong conclusions.

---

## Workflow

1. **Data quality first** ([`01_data_cleaning.sql`](01_data_cleaning.sql)). The raw tables store `'null'` as text, put units inside numeric fields (`'20km'`, `'15 minute'`) and keep timestamps as strings. All of this is cleaned once into `*_clean` tables, so every KPI uses the same definitions.
2. **Analysis** ([`02_analysis.sql`](02_analysis.sql)), in four parts: order metrics, runner & customer experience, ingredient optimisation, pricing & profitability.

## Key results

| Area | KPI | Value |
|---|---|---|
| Demand | Pizzas / orders | 14 pizzas in 10 orders (1.4 per order) |
| Reliability | Orders cancelled | **2 of 10 (20 %)**: 1 by the restaurant, 1 by the customer |
| Reliability | Delivery success by runner | Runner 1: 100 % · Runner 2: 75 % · Runner 3: 50 % |
| Mix | Delivered Meatlovers vs. Vegetarian | 9 vs. 3 |
| Customisation | Delivered pizzas with changes | 6 of 12. Most added: **Bacon** (4x). Most excluded: **Cheese** (4x) |
| Kitchen | Prep time by order size | 1 pizza: 12 min · 2: 18 min · 3: 29 min (**~10 min per pizza**, no batching gain) |
| Peak times | Busiest hours | 13:00, 18:00, 21:00, 23:00 (3 pizzas each). Wednesday has 5 of 10 orders |
| Economics | Revenue (delivered, base prices) | **$138** ($142 with $1 extras) |
| Economics | Runner cost at $0.30/km | $43.56 → **profit $94.44, 68 % margin** |

## Recommendations

1. **Cut cancellations first.** One in five orders is lost. Restaurant-side cancellations should be logged with a reason, and a cancellation rate KPI per runner and per restaurant should be tracked weekly.
2. **Plan kitchen capacity per pizza, not per order.** Prep time grows linearly (~10 min/pizza). Multi-pizza orders at peak hours need a parallel prep slot.
3. **Make Bacon a paid add-on and offer a "no cheese" option.** These are the most requested changes. Today extras earn $1 each ($4 total in this sample).
4. **Add data validation at input.** Runner 2's speeds range from **35 to 94 km/h**, which is not realistic for city delivery and points to wrong distance or duration entries. Delivery KPIs are only reliable once these fields are validated when they are recorded.

## Files

| File | Content |
|---|---|
| [`schema.sql`](schema.sql) | Raw schema and sample data (from the challenge) |
| [`01_data_cleaning.sql`](01_data_cleaning.sql) | Cleaning layer: typed, null-safe `*_clean` tables |
| [`02_analysis.sql`](02_analysis.sql) | 21 queries across sections A–D |

**Run order:** `schema.sql` → `01_data_cleaning.sql` → `02_analysis.sql` (PostgreSQL 13+, or paste into [DB Fiddle](https://www.db-fiddle.com/)).
