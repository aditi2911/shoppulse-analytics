-- ================================================
-- SECTION 1: REVENUE ANALYSIS
-- ================================================

-- Query 1: Monthly GMV trend
-- Business: Is revenue growing month over month?
SELECT
    order_year,
    order_month,
    COUNT(DISTINCT order_id)          AS total_orders,
    ROUND(SUM(total_payment)::numeric, 2) AS monthly_gmv,
    ROUND(AVG(total_payment)::numeric, 2) AS avg_order_value
FROM master
GROUP BY order_year, order_month
ORDER BY order_year, order_month;


-- Query 2: Revenue by product category
-- Business: Which categories drive the most revenue?
SELECT
    category,
    COUNT(DISTINCT order_id)              AS total_orders,
    ROUND(SUM(total_payment)::numeric, 2) AS total_revenue,
    ROUND(AVG(total_payment)::numeric, 2) AS avg_order_value,
    ROUND(AVG(review_score)::numeric, 2)  AS avg_review_score
FROM master
WHERE category IS NOT NULL
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 15;


-- Query 3: Month over month revenue growth rate
-- Business: Are we accelerating or decelerating?
WITH monthly_revenue AS (
    SELECT
        order_year,
        order_month,
        SUM(total_payment) AS gmv
    FROM master
    GROUP BY order_year, order_month
)
SELECT
    order_year,
    order_month,
    ROUND(gmv::numeric, 2) AS gmv,
    ROUND(LAG(gmv) OVER (ORDER BY order_year, order_month)::numeric, 2) AS prev_month_gmv,
    ROUND(
        ((gmv - LAG(gmv) OVER (ORDER BY order_year, order_month))
        / NULLIF(LAG(gmv) OVER (ORDER BY order_year, order_month), 0) * 100)::numeric
    , 2) AS growth_rate_pct
FROM monthly_revenue
ORDER BY order_year, order_month;


-- Query 4: Revenue by quarter
-- Business: Seasonal patterns — which quarter is strongest?
SELECT
    order_year,
    order_quarter,
    ROUND(SUM(total_payment)::numeric, 2) AS quarterly_revenue,
    COUNT(DISTINCT order_id)              AS total_orders
FROM master
GROUP BY order_year, order_quarter
ORDER BY order_year, order_quarter;


-- ================================================
-- SECTION 2: CUSTOMER ANALYSIS
-- ================================================

-- Query 5: Top 10 highest value customers
-- Business: Who are our VIP customers?
SELECT
    customer_id,
    customer_city,
    customer_state,
    COUNT(DISTINCT order_id)              AS total_orders,
    ROUND(SUM(total_payment)::numeric, 2) AS lifetime_value,
    ROUND(AVG(total_payment)::numeric, 2) AS avg_order_value,
    ROUND(AVG(review_score)::numeric, 2)  AS avg_satisfaction
FROM master
GROUP BY customer_id, customer_city, customer_state
ORDER BY lifetime_value DESC
LIMIT 10;


-- Query 6: Customer distribution by state
-- Business: Where are our customers geographically concentrated?
SELECT
    customer_state,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT order_id)    AS total_orders,
    ROUND(SUM(total_payment)::numeric, 2) AS state_revenue
FROM master
GROUP BY customer_state
ORDER BY unique_customers DESC;


-- Query 7: One-time vs repeat customers
-- Business: What % of customers ever buy again?
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM master
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time buyer'
        WHEN order_count BETWEEN 2 AND 3 THEN 'Occasional buyer'
        ELSE 'Loyal buyer'
    END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM customer_orders
GROUP BY customer_type
ORDER BY customer_count DESC;


-- ================================================
-- SECTION 3: RFM ANALYSIS IN SQL
-- ================================================

-- Query 8: RFM scores per customer
-- Business: Segment customers by value tier
WITH rfm_base AS (
    SELECT
        customer_id,
        MAX(order_purchase_timestamp::date) AS last_purchase,
        COUNT(DISTINCT order_id)            AS frequency,
        SUM(total_payment)                  AS monetary
    FROM master
    GROUP BY customer_id
),
rfm_scored AS (
    SELECT
        customer_id,
        CURRENT_DATE - last_purchase        AS recency_days,
        frequency,
        ROUND(monetary::numeric, 2)         AS monetary,
        NTILE(5) OVER (ORDER BY CURRENT_DATE - last_purchase ASC)  AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC)                     AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)                      AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    r_score + f_score + m_score AS rfm_total,
    CASE
        WHEN r_score + f_score + m_score >= 13 THEN 'Champion'
        WHEN r_score + f_score + m_score >= 10 THEN 'Loyal'
        WHEN r_score + f_score + m_score >= 7  THEN 'At Risk'
        ELSE 'Lost'
    END AS customer_segment
FROM rfm_scored
ORDER BY rfm_total DESC;


-- Query 9: RFM segment summary
-- Business: How many customers in each segment?
WITH rfm_base AS (
    SELECT
        customer_id,
        MAX(order_purchase_timestamp::date) AS last_purchase,
        COUNT(DISTINCT order_id)            AS frequency,
        SUM(total_payment)                  AS monetary
    FROM master
    GROUP BY customer_id
),
rfm_scored AS (
    SELECT
        customer_id,
        NTILE(5) OVER (ORDER BY CURRENT_DATE - last_purchase ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC)                    AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)                     AS m_score
    FROM rfm_base
)
SELECT
    CASE
        WHEN r_score + f_score + m_score >= 13 THEN 'Champion'
        WHEN r_score + f_score + m_score >= 10 THEN 'Loyal'
        WHEN r_score + f_score + m_score >= 7  THEN 'At Risk'
        ELSE 'Lost'
    END AS segment,
    COUNT(*)                                      AS customer_count,
    ROUND(AVG(m_score)::numeric, 2)               AS avg_monetary_score,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_customers
FROM rfm_scored
GROUP BY segment
ORDER BY customer_count DESC;


-- ================================================
-- SECTION 4: DELIVERY & OPERATIONS ANALYSIS
-- ================================================

-- Query 10: Average delivery time by state
-- Business: Which regions have the worst delivery SLA?
SELECT
    customer_state,
    COUNT(DISTINCT order_id)               AS total_orders,
    ROUND(AVG(delivery_days)::numeric, 1)  AS avg_delivery_days,
    ROUND(AVG(is_delayed)::numeric * 100, 1) AS delay_rate_pct,
    ROUND(AVG(review_score)::numeric, 2)   AS avg_review_score
FROM master
WHERE delivery_days IS NOT NULL
GROUP BY customer_state
ORDER BY avg_delivery_days DESC
LIMIT 15;


-- Query 11: Delayed orders impact on review scores
-- Business: Does delay actually hurt customer satisfaction?
SELECT
    is_delayed,
    COUNT(*)                              AS order_count,
    ROUND(AVG(review_score)::numeric, 2)  AS avg_review_score,
    ROUND(AVG(delivery_days)::numeric, 1) AS avg_delivery_days,
    ROUND(AVG(total_payment)::numeric, 2) AS avg_order_value
FROM master
WHERE is_delayed IS NOT NULL
GROUP BY is_delayed
ORDER BY is_delayed;


-- Query 12: Delivery performance by product category
-- Business: Which categories have the worst delivery times?
SELECT
    category,
    COUNT(DISTINCT order_id)               AS total_orders,
    ROUND(AVG(delivery_days)::numeric, 1)  AS avg_delivery_days,
    ROUND(AVG(is_delayed)::numeric * 100, 1) AS delay_rate_pct
FROM master
WHERE category IS NOT NULL
GROUP BY category
ORDER BY delay_rate_pct DESC
LIMIT 10;


-- ================================================
-- SECTION 5: PAYMENT ANALYSIS
-- ================================================

-- Query 13: Payment method breakdown
-- Business: How do customers prefer to pay?
SELECT
    payment_type,
    COUNT(*)                              AS order_count,
    ROUND(SUM(total_payment)::numeric, 2) AS total_revenue,
    ROUND(AVG(total_payment)::numeric, 2) AS avg_order_value,
    ROUND(AVG(payment_installments)::numeric, 1) AS avg_installments
FROM master
WHERE payment_type IS NOT NULL
GROUP BY payment_type
ORDER BY order_count DESC;


-- Query 14: High value orders analysis
-- Business: What drives our top 10% orders?
WITH order_percentiles AS (
    SELECT
        PERCENTILE_CONT(0.90) WITHIN GROUP
        (ORDER BY total_payment) AS p90_value
    FROM master
)
SELECT
    m.order_id,
    m.category,
    m.customer_state,
    m.payment_type,
    ROUND(m.total_payment::numeric, 2) AS order_value,
    m.delivery_days,
    m.review_score
FROM master m, order_percentiles op
WHERE m.total_payment >= op.p90_value
ORDER BY m.total_payment DESC
LIMIT 20;


-- ================================================
-- SECTION 6: REVIEW & SATISFACTION ANALYSIS
-- ================================================

-- Query 15: Review score distribution
-- Business: Overall customer satisfaction health
SELECT
    review_score,
    COUNT(*)  AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM master
WHERE review_score IS NOT NULL
GROUP BY review_score
ORDER BY review_score;


-- Query 16: Low review analysis — what goes wrong?
-- Business: What are the common factors in 1-star reviews?
SELECT
    review_score,
    ROUND(AVG(delivery_days)::numeric, 1)    AS avg_delivery_days,
    ROUND(AVG(is_delayed::numeric) * 100, 1) AS delay_rate_pct,
    ROUND(AVG(total_payment)::numeric, 2)    AS avg_order_value,
    COUNT(*)                                 AS order_count
FROM master
WHERE review_score IS NOT NULL
GROUP BY review_score
ORDER BY review_score;


-- ================================================
-- SECTION 7: ADVANCED — WINDOW FUNCTIONS
-- ================================================

-- Query 17: Running total revenue by month
-- Business: Cumulative GMV growth visualization
SELECT
    order_year,
    order_month,
    ROUND(SUM(total_payment)::numeric, 2) AS monthly_gmv,
    ROUND(SUM(SUM(total_payment)) OVER (
        ORDER BY order_year, order_month
    )::numeric, 2) AS cumulative_gmv
FROM master
GROUP BY order_year, order_month
ORDER BY order_year, order_month;


-- Query 18: Customer order ranking
-- Business: Rank each customer's orders by value
SELECT
    customer_id,
    order_id,
    ROUND(total_payment::numeric, 2) AS order_value,
    order_purchase_timestamp::date   AS order_date,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY total_payment DESC
    ) AS order_rank_by_value
FROM master
ORDER BY customer_id, order_rank_by_value
LIMIT 30;


-- Query 19: Category revenue rank with percentile
-- Business: Where does each category rank in revenue contribution?
-- Query 19: Category revenue rank with percentile
SELECT
    category,
    ROUND(CAST(SUM(total_payment) AS numeric), 2) AS total_revenue,
    RANK() OVER (ORDER BY SUM(total_payment) DESC) AS revenue_rank,
    ROUND(
        CAST(SUM(total_payment) * 100.0 / SUM(SUM(total_payment)) OVER() AS numeric)
    , 2) AS revenue_share_pct
FROM master
WHERE category IS NOT NULL
GROUP BY category
ORDER BY revenue_rank
LIMIT 20;


-- Query 20: Cohort — first purchase month per customer
-- Business: Foundation for retention/cohort analysis
WITH first_purchase AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_purchase_timestamp)) AS cohort_month
    FROM master
    GROUP BY customer_id
),
order_months AS (
    SELECT
        m.customer_id,
        DATE_TRUNC('month', m.order_purchase_timestamp) AS order_month,
        fp.cohort_month
    FROM master m
    JOIN first_purchase fp ON m.customer_id = fp.customer_id
)
SELECT
    cohort_month::date,
    order_month::date,
    COUNT(DISTINCT customer_id) AS active_customers,
    EXTRACT(MONTH FROM AGE(order_month, cohort_month)) AS months_since_first
FROM order_months
GROUP BY cohort_month, order_month
ORDER BY cohort_month, order_month
LIMIT 50;