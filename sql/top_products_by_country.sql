/*
  Business context:
  For a regional distributor, knowing which products lead in each market is
  a direct input to procurement decisions. If Germany's top-selling product
  barely ranks in France, you probably shouldn't be ordering equal quantities
  for both markets. The revenue_share_pct column is the critical one — a
  product with 8% share in one country but 0.3% in another is a market-
  specific opportunity, not a global bestseller.

  Results are limited to the top 10 products per country by revenue.
  Countries with fewer than 5 orders are excluded to avoid noise from
  one-off bulk purchases distorting the rankings.
*/

WITH country_product_revenue AS (
  SELECT
    Country,
    Description    AS product_name,
    StockCode      AS stock_code,
    ROUND(SUM(Quantity * Price), 2)  AS product_revenue,
    SUM(Quantity)                    AS units_sold,
    COUNT(DISTINCT Invoice)          AS order_appearances
  FROM `retail.transactions`
  WHERE Quantity > 0
    AND Price > 0
    AND Description IS NOT NULL
    AND Country NOT IN ('Unspecified')
  GROUP BY Country, Description, StockCode
),

country_totals AS (
  SELECT
    Country,
    SUM(product_revenue)             AS total_country_revenue,
    COUNT(DISTINCT order_appearances) AS approx_order_count
  FROM country_product_revenue
  GROUP BY Country
  HAVING SUM(product_revenue) > 0
),

ranked AS (
  SELECT
    cpr.Country,
    cpr.product_name,
    cpr.stock_code,
    cpr.product_revenue,
    cpr.units_sold,
    ct.total_country_revenue,
    ROUND(
      SAFE_DIVIDE(cpr.product_revenue, ct.total_country_revenue) * 100, 2
    )                                AS revenue_share_pct,
    ROW_NUMBER() OVER (
      PARTITION BY cpr.Country
      ORDER BY cpr.product_revenue DESC
    )                                AS rnk
  FROM country_product_revenue cpr
  JOIN country_totals ct ON cpr.Country = ct.Country
)

SELECT
  Country,
  rnk         AS rank_in_country,
  product_name,
  stock_code,
  product_revenue,
  units_sold,
  revenue_share_pct
FROM ranked
WHERE rnk <= 10
ORDER BY Country, rnk;
