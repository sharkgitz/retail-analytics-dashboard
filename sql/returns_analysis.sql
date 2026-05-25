-- Returns are a direct margin hit, and the pattern matters as much as the rate.
-- A 15% return rate in January on holiday-season products is expected — gift
-- buyers changed their minds. The same rate spread evenly across the year
-- probably signals a quality or product-description mismatch, which means
-- a supplier conversation, not just a finance adjustment.
--
-- This query gives you return rate by month and country so you can separate
-- "seasonal behaviour" from "structural problem". Flag anything above 12%
-- outside of Jan-Feb for immediate review.

WITH all_lines AS (
  SELECT
    DATE_TRUNC(InvoiceDate, MONTH)              AS txn_month,
    Country,
    Quantity,
    Price,
    ABS(Quantity * Price)                       AS line_value,
    CASE WHEN Quantity < 0 THEN 1 ELSE 0 END    AS is_return
  FROM `retail.transactions`
  WHERE Price > 0
    AND Description IS NOT NULL
),

monthly_by_country AS (
  SELECT
    txn_month,
    Country,
    SUM(CASE WHEN is_return = 0 THEN line_value ELSE 0 END)  AS gross_sales,
    SUM(CASE WHEN is_return = 1 THEN line_value ELSE 0 END)  AS return_value,
    COUNT(CASE WHEN is_return = 0 THEN 1 END)                AS sale_line_count,
    COUNT(CASE WHEN is_return = 1 THEN 1 END)                AS return_line_count
  FROM all_lines
  GROUP BY txn_month, Country
)

SELECT
  txn_month,
  Country,
  ROUND(gross_sales, 2)                                       AS gross_sales,
  ROUND(return_value, 2)                                      AS return_value,
  ROUND(gross_sales - return_value, 2)                        AS net_sales,
  ROUND(SAFE_DIVIDE(return_value, gross_sales) * 100, 2)      AS return_rate_pct,
  sale_line_count,
  return_line_count
FROM monthly_by_country
WHERE gross_sales > 0
ORDER BY txn_month, return_rate_pct DESC;
