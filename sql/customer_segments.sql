/*
  Business context:
  The goal here is to answer a simple question the sales team asks constantly:
  "Which customers should we be protecting, and which ones are drifting?"
  We're not using RFM jargon — just splitting customers into four plain groups
  based on how often they buy and how much they spend, relative to the median
  customer in this dataset. Four groups come out naturally:

    - High Frequency, High Value  → your core accounts, protect these
    - High Frequency, Low Value   → loyal but price-sensitive, good for volume
    - Occasional, High Value      → worth a personal outreach, high upside
    - Low Frequency, Low Value    → likely one-off or exploratory buyers

  This feeds directly into inactive_customers.sql for churn prioritisation.
  Customer_ID nulls are excluded — those are unregistered/guest transactions
  that can't be tracked longitudinally.
*/

WITH customer_metrics AS (
  SELECT
    Customer_ID,
    MAX(Country)                            AS country,  -- most recent country for that customer
    COUNT(DISTINCT Invoice)                 AS total_orders,
    ROUND(SUM(Quantity * Price), 2)         AS lifetime_spend,
    ROUND(
      SAFE_DIVIDE(SUM(Quantity * Price), COUNT(DISTINCT Invoice)),
      2
    )                                       AS avg_order_value,
    MIN(DATE(InvoiceDate))                  AS first_order_date,
    MAX(DATE(InvoiceDate))                  AS last_order_date,
    DATE_DIFF(
      MAX(DATE(InvoiceDate)),
      MIN(DATE(InvoiceDate)),
      DAY
    )                                       AS customer_lifespan_days
  FROM `retail.transactions`
  WHERE Quantity > 0
    AND Price > 0
    AND Customer_ID IS NOT NULL
  GROUP BY Customer_ID
),

-- Using approximate quantiles to find the median thresholds for the split
percentiles AS (
  SELECT
    APPROX_QUANTILES(total_orders, 2)[OFFSET(1)]   AS median_orders,
    APPROX_QUANTILES(lifetime_spend, 2)[OFFSET(1)] AS median_spend
  FROM customer_metrics
)

SELECT
  cm.Customer_ID,
  cm.country,
  cm.total_orders,
  cm.lifetime_spend,
  cm.avg_order_value,
  cm.first_order_date,
  cm.last_order_date,
  cm.customer_lifespan_days,
  CASE
    WHEN cm.total_orders >= p.median_orders AND cm.lifetime_spend >= p.median_spend
      THEN 'High Frequency, High Value'
    WHEN cm.total_orders >= p.median_orders AND cm.lifetime_spend < p.median_spend
      THEN 'High Frequency, Low Value'
    WHEN cm.total_orders < p.median_orders AND cm.lifetime_spend >= p.median_spend
      THEN 'Occasional, High Value'
    ELSE
      'Low Frequency, Low Value'
  END                                               AS customer_segment
FROM customer_metrics cm
CROSS JOIN percentiles p
ORDER BY cm.lifetime_spend DESC;
