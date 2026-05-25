/*
  Business context:
  Month-over-month revenue change is the first number a commercial director
  asks for in a weekly review. A drop of more than 10% MoM is usually the
  trigger for a deeper product-level investigation — is it a demand problem,
  a fulfilment issue, or just a short month? This query gives you the trend
  line with the percentage change already calculated so you're not doing
  mental math in the meeting.

  Returns are excluded here because this is gross/top-line revenue.
  For net revenue after returns, cross-reference with returns_analysis.sql.

  Table assumed: `retail.transactions` in BigQuery.
  Revenue = Quantity * Price (per line item).
*/

WITH monthly_totals AS (
  SELECT
    DATE_TRUNC(InvoiceDate, MONTH)          AS month,
    ROUND(SUM(Quantity * Price), 2)          AS gross_revenue,
    COUNT(DISTINCT Invoice)                  AS order_count,
    COUNT(DISTINCT Customer_ID)              AS active_customers
  FROM `retail.transactions`
  WHERE Quantity > 0   -- exclude returns/cancellations
    AND Price > 0      -- exclude zero-price adjustments and samples
  GROUP BY 1
)

SELECT
  month,
  gross_revenue,
  order_count,
  active_customers,
  LAG(gross_revenue) OVER (ORDER BY month)                         AS prev_month_revenue,
  ROUND(
    SAFE_DIVIDE(
      gross_revenue - LAG(gross_revenue) OVER (ORDER BY month),
      LAG(gross_revenue) OVER (ORDER BY month)
    ) * 100,
    2
  )                                                                 AS mom_pct_change
FROM monthly_totals
ORDER BY month;
