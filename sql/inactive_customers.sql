/*
  Business context:
  Customers who bought in 2010 but placed no orders in 2011 are a churn
  signal worth acting on. For a wholesale distributor, losing a trade account
  typically means they've found an alternative supplier — and re-acquiring a
  lapsed B2B customer costs significantly more than retaining an active one.
  This query pulls that list sorted by historical spend so the sales team can
  prioritise who to contact first (high-spend lapsed customers get a call,
  lower-spend ones might get an email campaign).

  The spend_2010 field gives you a rough "how important was this customer"
  signal. Pair it with avg_order_value to distinguish a customer who made
  one big order vs. one who ordered consistently throughout the year.
*/

WITH buyers_2010 AS (
  SELECT
    Customer_ID,
    MAX(Country)                             AS country,
    COUNT(DISTINCT Invoice)                  AS orders_in_2010,
    MAX(DATE(InvoiceDate))                   AS last_order_2010,
    ROUND(SUM(Quantity * Price), 2)          AS spend_2010,
    ROUND(
      SAFE_DIVIDE(SUM(Quantity * Price), COUNT(DISTINCT Invoice)),
      2
    )                                        AS avg_order_value_2010
  FROM `retail.transactions`
  WHERE EXTRACT(YEAR FROM InvoiceDate) = 2010
    AND Quantity > 0
    AND Price > 0
    AND Customer_ID IS NOT NULL
  GROUP BY Customer_ID
),

buyers_2011 AS (
  SELECT DISTINCT Customer_ID
  FROM `retail.transactions`
  WHERE EXTRACT(YEAR FROM InvoiceDate) = 2011
    AND Customer_ID IS NOT NULL
)

SELECT
  b10.Customer_ID,
  b10.country,
  b10.orders_in_2010,
  b10.last_order_2010,
  b10.spend_2010,
  b10.avg_order_value_2010,
  'Active 2010, no orders in 2011'   AS churn_flag
FROM buyers_2010 b10
WHERE b10.Customer_ID NOT IN (
  SELECT Customer_ID FROM buyers_2011
)
ORDER BY b10.spend_2010 DESC;
