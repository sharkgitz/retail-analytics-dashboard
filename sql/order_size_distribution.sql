/*
  Business context:
  Order size distribution tells you who you're actually selling to. A retailer
  dominated by sub-£50 orders is likely consumer-facing. One with a heavy
  concentration in £500+ orders is serving trade buyers or businesses. If this
  distribution shifts quarter-over-quarter, it usually means the customer mix
  is changing — and that has downstream implications for product mix, packaging,
  and credit terms.

  The bucket boundaries here were determined by looking at the actual
  distribution first, not arbitrary round numbers. The £150–299 band captures
  the median invoice range for this dataset.

  Note: invoice_total is calculated per Invoice (summing all line items), not
  per line item. A single invoice can have 30+ products.
*/

WITH invoice_totals AS (
  SELECT
    Invoice,
    Customer_ID,
    Country,
    DATE(MIN(InvoiceDate))           AS invoice_date,
    COUNT(*)                         AS line_items,
    ROUND(SUM(Quantity * Price), 2)  AS invoice_total
  FROM `retail.transactions`
  WHERE Quantity > 0
    AND Price > 0
  GROUP BY Invoice, Customer_ID, Country
),

bucketed AS (
  SELECT
    *,
    CASE
      WHEN invoice_total < 50      THEN 'Under £50'
      WHEN invoice_total < 150     THEN '£50 – £149'
      WHEN invoice_total < 300     THEN '£150 – £299'
      WHEN invoice_total < 500     THEN '£300 – £499'
      WHEN invoice_total < 1000    THEN '£500 – £999'
      ELSE                              '£1,000+'
    END AS order_size_band,
    CASE
      WHEN invoice_total < 50      THEN 1
      WHEN invoice_total < 150     THEN 2
      WHEN invoice_total < 300     THEN 3
      WHEN invoice_total < 500     THEN 4
      WHEN invoice_total < 1000    THEN 5
      ELSE                              6
    END AS band_sort
  FROM invoice_totals
)

SELECT
  order_size_band,
  COUNT(*)                                                        AS order_count,
  ROUND(AVG(invoice_total), 2)                                    AS avg_order_value,
  ROUND(SUM(invoice_total), 2)                                    AS total_revenue,
  ROUND(SUM(invoice_total) / SUM(SUM(invoice_total)) OVER () * 100, 2)  AS revenue_share_pct
FROM bucketed
GROUP BY order_size_band, band_sort
ORDER BY band_sort;
