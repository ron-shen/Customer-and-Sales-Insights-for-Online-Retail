USE retail_sales;

SET NAMES utf8mb4;

DROP VIEW IF EXISTS vw_cohort_retention;
DROP VIEW IF EXISTS vw_customer_rfm_segments;
DROP VIEW IF EXISTS vw_customer_order_segments;
DROP VIEW IF EXISTS vw_customer_purchase_metrics;
DROP VIEW IF EXISTS vw_positive_invoice_totals;
DROP VIEW IF EXISTS vw_product_performance;
DROP VIEW IF EXISTS vw_market_performance;
DROP VIEW IF EXISTS vw_monthly_sales_seasonality;
DROP VIEW IF EXISTS vw_monthly_sales_trend;
DROP VIEW IF EXISTS vw_sales_line_enriched;

/** 
Create enriched sales line view by joining invoice lines with invoices, products, and customers.
Calculate additional fields for analysis, including sales amount, cancellation flags, and time-based attributes.
**/
CREATE VIEW vw_sales_line_enriched AS
SELECT
  il.invoice_line_id,
  il.invoice,
  il.line_no,
  i.customer_id,
  c.country AS customer_country,
  i.country AS invoice_country,
  i.invoice_date,
  DATE(i.invoice_date) AS invoice_day,
  DATE_ADD(DATE(i.invoice_date), INTERVAL 1 - DAYOFMONTH(i.invoice_date) DAY) AS month_start,
  YEAR(i.invoice_date) AS sales_year,
  QUARTER(i.invoice_date) AS sales_quarter,
  MONTH(i.invoice_date) AS sales_month_num,
  MONTHNAME(i.invoice_date) AS sales_month_name,
  il.stock_code,
  p.description,
  il.quantity,
  il.price,
  il.quantity * il.price AS line_amount,
  ABS(il.quantity * il.price) AS abs_line_amount,
  CASE WHEN i.invoice LIKE 'C%' THEN 1 ELSE 0 END AS is_c_invoice,
  CASE WHEN il.quantity < 0 THEN 1 ELSE 0 END AS is_negative_quantity,
  CASE
    WHEN i.invoice LIKE 'C%' OR il.quantity < 0 THEN 1
    ELSE 0
  END AS is_cancellation,
  CASE
    WHEN i.invoice NOT LIKE 'C%' AND il.quantity > 0 THEN 1
    ELSE 0
  END AS is_positive_sale
FROM invoice_lines il
JOIN invoices i
  ON i.invoice = il.invoice
LEFT JOIN products p
  ON p.stock_code = il.stock_code
LEFT JOIN customers c
  ON c.customer_id = i.customer_id;

/* 
Calculate monthly sales trends, including gross sales, return value, net sales, and completed invoices
*/
CREATE VIEW vw_monthly_sales_trend AS
SELECT
  month_start,
  ROUND(SUM(CASE WHEN is_cancellation = 0 THEN line_amount ELSE 0 END), 2) AS gross_sales,
  ROUND(ABS(SUM(CASE WHEN is_cancellation = 1 THEN line_amount ELSE 0 END)), 2) AS return_value,
  ROUND(SUM(line_amount), 2) AS net_sales,
  COUNT(DISTINCT CASE WHEN is_cancellation = 0 THEN invoice END) AS completed_invoices
FROM vw_sales_line_enriched
GROUP BY month_start;

CREATE VIEW vw_monthly_sales_seasonality AS
SELECT
  MONTH(month_start) AS sales_month_num,
  MONTHNAME(month_start) AS sales_month_name,
  ROUND(AVG(net_sales), 2) AS avg_monthly_net_sales,
  ROUND(MIN(net_sales), 2) AS min_monthly_net_sales,
  ROUND(MAX(net_sales), 2) AS max_monthly_net_sales
FROM vw_monthly_sales_trend
GROUP BY MONTH(month_start), MONTHNAME(month_start);


/* 
Assign markets as UK vs Rest of World, and calculate performance metrics by market
*/
CREATE VIEW vw_market_performance AS
SELECT
  CASE
    WHEN invoice_country = 'United Kingdom' THEN 'United Kingdom'
    ELSE 'Rest of World'
  END AS market,
  COUNT(DISTINCT customer_id) AS customers,
  COUNT(DISTINCT CASE WHEN is_cancellation = 0 THEN invoice END) AS completed_invoices,
  ROUND(SUM(CASE WHEN is_cancellation = 0 THEN line_amount ELSE 0 END), 2) AS gross_sales,
  ROUND(ABS(SUM(CASE WHEN is_cancellation = 1 THEN line_amount ELSE 0 END)), 2) AS return_value,
  ROUND(SUM(line_amount), 2) AS net_sales
FROM vw_sales_line_enriched
GROUP BY
  CASE
    WHEN invoice_country = 'United Kingdom' THEN 'United Kingdom'
    ELSE 'Rest of World'
  END;


/* 
Calculate product performance metrics, including return rate.
*/
CREATE VIEW vw_product_performance AS
SELECT
  pp.stock_code,
  pp.description,
  pp.positive_units,
  pp.returned_units,
  ROUND(pp.gross_sales, 2) AS gross_sales,
  ROUND(pp.return_value, 2) AS return_value,
  ROUND(pp.net_revenue, 2) AS net_revenue,
  ROUND(pp.return_value / NULLIF(pp.gross_sales, 0), 4) AS return_rate
FROM (
  SELECT
    stock_code,
    description,
    SUM(CASE WHEN is_positive_sale = 1 THEN quantity ELSE 0 END) AS positive_units,
    ABS(SUM(CASE WHEN is_cancellation = 1 THEN quantity ELSE 0 END)) AS returned_units,
    SUM(CASE WHEN is_positive_sale = 1 THEN line_amount ELSE 0 END) AS gross_sales,
    ABS(SUM(CASE WHEN is_cancellation = 1 THEN line_amount ELSE 0 END)) AS return_value,
    SUM(line_amount) AS net_revenue
  FROM vw_sales_line_enriched
  GROUP BY stock_code, description
) pp;

CREATE VIEW vw_positive_invoice_totals AS
SELECT
  customer_id,
  customer_country,
  invoice,
  invoice_country,
  DATE(invoice_date) AS invoice_date,
  month_start,
  ROUND(SUM(line_amount), 2) AS invoice_amount
FROM vw_sales_line_enriched
WHERE is_positive_sale = 1
GROUP BY
  customer_id,
  customer_country,
  invoice,
  invoice_country,
  DATE(invoice_date),
  month_start;

CREATE VIEW vw_customer_purchase_metrics AS
SELECT
  pit.customer_id,
  MAX(pit.customer_country) AS customer_country,
  MIN(pit.invoice_date) AS first_purchase_date,
  MAX(pit.invoice_date) AS last_purchase_date,
  DATEDIFF(
    (SELECT MAX(invoice_date) FROM vw_positive_invoice_totals),
    MAX(pit.invoice_date)
  ) AS recency_days,
  COUNT(*) AS order_count,
  ROUND(SUM(pit.invoice_amount), 2) AS lifetime_value
FROM vw_positive_invoice_totals pit
GROUP BY pit.customer_id;

/* 
Assign customers who are one-time purchasers vs repeat purchasers, and assign segments based on purchase frequency.
*/
CREATE VIEW vw_customer_order_segments AS
SELECT
  customer_id,
  customer_country,
  first_purchase_date,
  last_purchase_date,
  recency_days,
  order_count,
  lifetime_value,
  CASE
    WHEN order_count = 1 THEN 'One-time'
    ELSE 'Repeat'
  END AS customer_segment
FROM vw_customer_purchase_metrics;


/* 
Assign customers with the rfm scores, and assign segments based on RFM thresholds
*/
CREATE VIEW vw_customer_rfm_segments AS
SELECT
  scored.customer_id,
  scored.customer_country,
  scored.first_purchase_date,
  scored.last_purchase_date,
  scored.recency_days,
  scored.order_count AS frequency,
  scored.lifetime_value AS monetary,
  scored.r_score,
  scored.f_score,
  scored.m_score,
  CASE
    WHEN scored.r_score >= 4 AND scored.f_score >= 4 AND scored.m_score >= 4 THEN 'Champions'
    WHEN scored.r_score >= 3 AND scored.f_score >= 3 AND scored.m_score >= 3 THEN 'Loyal'
    WHEN scored.r_score >= 4 AND scored.order_count <= 2 THEN 'Recent'
    WHEN scored.r_score <= 2 AND scored.f_score >= 3 THEN 'At Risk'
    ELSE 'Needs Attention'
  END AS rfm_segment
FROM (
  SELECT
    customer_id,
    customer_country,
    first_purchase_date,
    last_purchase_date,
    recency_days,
    order_count,
    lifetime_value,
    6 - NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,
    NTILE(5) OVER (ORDER BY order_count ASC) AS f_score,
    NTILE(5) OVER (ORDER BY lifetime_value ASC) AS m_score
  FROM vw_customer_purchase_metrics
) scored;


/* Find pct of retention customers
   cohort_month: month of first purchase
   activity_month: month of subsequent purchase activity
  */
CREATE VIEW vw_cohort_retention AS
SELECT
  cohort_activity.cohort_month,
  cohort_activity.activity_month,
  cohort_activity.months_since_first_purchase,
  cohort_size.cohort_customers,
  cohort_activity.active_customers,
  ROUND(cohort_activity.active_customers / cohort_size.cohort_customers * 100, 2) AS retention_rate_pct
FROM (
  SELECT
    first_purchase.cohort_month,
    purchase_months.order_month AS activity_month,
    TIMESTAMPDIFF(MONTH, first_purchase.cohort_month, purchase_months.order_month) AS months_since_first_purchase,
    COUNT(DISTINCT purchase_months.customer_id) AS active_customers
  FROM (
    SELECT
      customer_id,
      MIN(order_month) AS cohort_month
    FROM (
      SELECT DISTINCT
        customer_id,
        month_start AS order_month
      FROM vw_positive_invoice_totals
    ) distinct_purchase_months
    GROUP BY customer_id
  ) first_purchase
  JOIN (
    SELECT DISTINCT
      customer_id,
      month_start AS order_month
    FROM vw_positive_invoice_totals
  ) purchase_months
    ON purchase_months.customer_id = first_purchase.customer_id
  GROUP BY
    first_purchase.cohort_month,
    purchase_months.order_month,
    TIMESTAMPDIFF(MONTH, first_purchase.cohort_month, purchase_months.order_month)
) cohort_activity
JOIN (
  SELECT
    cohort_month,
    COUNT(*) AS cohort_customers
  FROM (
    SELECT
      customer_id,
      MIN(order_month) AS cohort_month
    FROM (
      SELECT DISTINCT
        customer_id,
        month_start AS order_month
      FROM vw_positive_invoice_totals
    ) distinct_purchase_months
    GROUP BY customer_id
  ) first_purchase
  GROUP BY cohort_month
) cohort_size
  ON cohort_size.cohort_month = cohort_activity.cohort_month;
