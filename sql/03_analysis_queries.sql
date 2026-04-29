USE retail_sales;

/* 1a. Monthly sales trend */
WITH line_items AS (
  SELECT
    i.invoice,
    i.customer_id,
    i.invoice_date,
    i.country,
    il.stock_code,
    il.quantity,
    il.price,
    il.quantity * il.price AS line_amount,
    CASE
      WHEN i.invoice LIKE 'C%' OR il.quantity < 0 THEN 1
      ELSE 0
    END AS is_cancellation
  FROM invoices i
  JOIN invoice_lines il
    ON il.invoice = i.invoice
)
SELECT
  DATE_FORMAT(invoice_date, '%Y-%m-01') AS month_start,
  ROUND(SUM(CASE WHEN is_cancellation = 0 THEN line_amount ELSE 0 END), 2) AS gross_sales,
  ROUND(ABS(SUM(CASE WHEN is_cancellation = 1 THEN line_amount ELSE 0 END)), 2) AS return_value,
  ROUND(SUM(line_amount), 2) AS net_sales,
  COUNT(DISTINCT CASE WHEN is_cancellation = 0 THEN invoice END) AS completed_invoices
FROM line_items
GROUP BY DATE_FORMAT(invoice_date, '%Y-%m-01')
ORDER BY month_start;

/* 1b. Seasonality by calendar month */
WITH line_items AS (
  SELECT
    i.invoice_date,
    il.quantity * il.price AS line_amount,
    CASE
      WHEN i.invoice LIKE 'C%' OR il.quantity < 0 THEN 1
      ELSE 0
    END AS is_cancellation
  FROM invoices i
  JOIN invoice_lines il
    ON il.invoice = i.invoice
),
monthly_net_sales AS (
  SELECT
    YEAR(invoice_date) AS sales_year,
    MONTH(invoice_date) AS sales_month_num,
    MONTHNAME(invoice_date) AS sales_month_name,
    SUM(line_amount) AS monthly_net_sales
  FROM line_items
  GROUP BY YEAR(invoice_date), MONTH(invoice_date), MONTHNAME(invoice_date)
)
SELECT
  sales_month_num,
  sales_month_name,
  ROUND(AVG(monthly_net_sales), 2) AS avg_monthly_net_sales,
  ROUND(MIN(monthly_net_sales), 2) AS min_monthly_net_sales,
  ROUND(MAX(monthly_net_sales), 2) AS max_monthly_net_sales
FROM monthly_net_sales
GROUP BY sales_month_num, sales_month_name
ORDER BY sales_month_num;

/* 2. UK vs rest-of-world performance */
WITH line_items AS (
  SELECT
    i.invoice,
    i.customer_id,
    i.country,
    il.quantity * il.price AS line_amount,
    CASE
      WHEN i.invoice LIKE 'C%' OR il.quantity < 0 THEN 1
      ELSE 0
    END AS is_cancellation
  FROM invoices i
  JOIN invoice_lines il
    ON il.invoice = i.invoice
)
SELECT
  CASE
    WHEN country = 'United Kingdom' THEN 'United Kingdom'
    ELSE 'Rest of World'
  END AS market,
  COUNT(DISTINCT customer_id) AS customers,
  COUNT(DISTINCT CASE WHEN is_cancellation = 0 THEN invoice END) AS completed_invoices,
  ROUND(SUM(CASE WHEN is_cancellation = 0 THEN line_amount ELSE 0 END), 2) AS gross_sales,
  ROUND(ABS(SUM(CASE WHEN is_cancellation = 1 THEN line_amount ELSE 0 END)), 2) AS return_value,
  ROUND(SUM(line_amount), 2) AS net_sales
FROM line_items
GROUP BY
  CASE
    WHEN country = 'United Kingdom' THEN 'United Kingdom'
    ELSE 'Rest of World'
  END
ORDER BY net_sales DESC;

/* 3a. Top products by net revenue */
WITH product_performance AS (
  SELECT
    il.stock_code,
    p.description,
    ROUND(SUM(il.quantity * il.price), 2) AS net_revenue,
    ROUND(SUM(CASE WHEN i.invoice NOT LIKE 'C%' AND il.quantity > 0 THEN il.quantity * il.price ELSE 0 END), 2) AS gross_sales,
    ROUND(ABS(SUM(CASE WHEN i.invoice LIKE 'C%' OR il.quantity < 0 THEN il.quantity * il.price ELSE 0 END)), 2) AS return_value
  FROM invoice_lines il
  JOIN invoices i
    ON i.invoice = il.invoice
  LEFT JOIN products p
    ON p.stock_code = il.stock_code
  GROUP BY il.stock_code, p.description
)
SELECT
  stock_code,
  description,
  gross_sales,
  return_value,
  net_revenue
FROM product_performance
ORDER BY net_revenue DESC
LIMIT 20;

/* 3b. Top products by return rate (amount-based) */
WITH product_performance AS (
  SELECT
    il.stock_code,
    p.description,
    SUM(CASE WHEN i.invoice NOT LIKE 'C%' AND il.quantity > 0 THEN il.quantity * il.price ELSE 0 END) AS gross_sales,
    ABS(SUM(CASE WHEN i.invoice LIKE 'C%' OR il.quantity < 0 THEN il.quantity * il.price ELSE 0 END)) AS return_value
  FROM invoice_lines il
  JOIN invoices i
    ON i.invoice = il.invoice
  LEFT JOIN products p
    ON p.stock_code = il.stock_code
  GROUP BY il.stock_code, p.description
)
SELECT
  stock_code,
  description,
  ROUND(gross_sales, 2) AS gross_sales,
  ROUND(return_value, 2) AS return_value,
  ROUND(return_value / NULLIF(gross_sales, 0), 4) AS return_rate
FROM product_performance
WHERE gross_sales >= 1000
ORDER BY return_rate DESC, gross_sales DESC
LIMIT 20;

/* 4a. Repeat vs one-time customers */
WITH positive_invoices AS (
  SELECT
    i.customer_id,
    i.invoice,
    SUM(il.quantity * il.price) AS invoice_amount
  FROM invoices i
  JOIN invoice_lines il
    ON il.invoice = i.invoice
  WHERE i.invoice NOT LIKE 'C%'
    AND il.quantity > 0
  GROUP BY i.customer_id, i.invoice
),
customer_orders AS (
  SELECT
    customer_id,
    COUNT(DISTINCT invoice) AS order_count,
    SUM(invoice_amount) AS lifetime_value
  FROM positive_invoices
  GROUP BY customer_id
)
SELECT
  CASE
    WHEN order_count = 1 THEN 'One-time'
    ELSE 'Repeat'
  END AS customer_segment,
  COUNT(*) AS customers,
  ROUND(AVG(order_count), 2) AS avg_orders_per_customer,
  ROUND(SUM(lifetime_value), 2) AS total_revenue
FROM customer_orders
GROUP BY
  CASE
    WHEN order_count = 1 THEN 'One-time'
    ELSE 'Repeat'
  END
ORDER BY total_revenue DESC;

/* 4b. RFM segmentation */
WITH positive_invoices AS (
  SELECT
    i.customer_id,
    i.invoice,
    DATE(i.invoice_date) AS invoice_date,
    SUM(il.quantity * il.price) AS invoice_amount
  FROM invoices i
  JOIN invoice_lines il
    ON il.invoice = i.invoice
  WHERE i.invoice NOT LIKE 'C%'
    AND il.quantity > 0
  GROUP BY i.customer_id, i.invoice, DATE(i.invoice_date)
),
rfm_base AS (
  SELECT
    customer_id,
    DATEDIFF((SELECT MAX(invoice_date) FROM positive_invoices), MAX(invoice_date)) AS recency_days,
    COUNT(*) AS frequency,
    SUM(invoice_amount) AS monetary
  FROM positive_invoices
  GROUP BY customer_id
),
rfm_scores AS (
  SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    6 - NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
  FROM rfm_base
)
SELECT
  customer_id,
  recency_days,
  frequency,
  ROUND(monetary, 2) AS monetary,
  r_score,
  f_score,
  m_score,
  CASE
    WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
    WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal'
    WHEN r_score >= 4 AND frequency <= 2 THEN 'Recent'
    WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
    ELSE 'Needs Attention'
  END AS rfm_segment
FROM rfm_scores
ORDER BY monetary DESC, frequency DESC;

/* 5. Cohort retention by first purchase month */
WITH purchase_months AS (
  SELECT DISTINCT
    i.customer_id,
    DATE_FORMAT(i.invoice_date, '%Y-%m-01') AS order_month
  FROM invoices i
  JOIN invoice_lines il
    ON il.invoice = i.invoice
  WHERE i.invoice NOT LIKE 'C%'
    AND il.quantity > 0
),
first_purchase AS (
  SELECT
    customer_id,
    MIN(order_month) AS cohort_month
  FROM purchase_months
  GROUP BY customer_id
),
cohort_size AS (
  SELECT
    cohort_month,
    COUNT(*) AS cohort_customers
  FROM first_purchase
  GROUP BY cohort_month
),
cohort_activity AS (
  SELECT
    fp.cohort_month,
    pm.order_month AS activity_month,
    TIMESTAMPDIFF(MONTH, fp.cohort_month, pm.order_month) AS months_since_first_purchase,
    COUNT(DISTINCT pm.customer_id) AS active_customers
  FROM first_purchase fp
  JOIN purchase_months pm
    ON pm.customer_id = fp.customer_id
  GROUP BY fp.cohort_month, pm.order_month, TIMESTAMPDIFF(MONTH, fp.cohort_month, pm.order_month)
)
SELECT
  ca.cohort_month,
  ca.activity_month,
  ca.months_since_first_purchase,
  cs.cohort_customers,
  ca.active_customers,
  ROUND(ca.active_customers / cs.cohort_customers * 100, 2) AS retention_rate_pct
FROM cohort_activity ca
JOIN cohort_size cs
  ON cs.cohort_month = ca.cohort_month
ORDER BY ca.cohort_month, ca.months_since_first_purchase;

/* 6a. Cancellation analysis summary */
WITH invoice_flags AS (
  SELECT
    i.invoice,
    DATE(i.invoice_date) AS invoice_date,
    i.country,
    CASE WHEN i.invoice LIKE 'C%' THEN 1 ELSE 0 END AS is_c_invoice,
    MAX(CASE WHEN il.quantity < 0 THEN 1 ELSE 0 END) AS has_negative_line,
    SUM(il.quantity * il.price) AS net_amount
  FROM invoices i
  JOIN invoice_lines il
    ON il.invoice = i.invoice
  GROUP BY i.invoice, DATE(i.invoice_date), i.country, CASE WHEN i.invoice LIKE 'C%' THEN 1 ELSE 0 END
)
SELECT
  DATE_FORMAT(invoice_date, '%Y-%m-01') AS month_start,
  COUNT(*) AS total_invoices,
  SUM(is_c_invoice) AS c_prefixed_invoices,
  SUM(has_negative_line) AS invoices_with_negative_lines,
  ROUND(SUM(is_c_invoice) / COUNT(*) * 100, 2) AS c_invoice_pct,
  ROUND(SUM(has_negative_line) / COUNT(*) * 100, 2) AS negative_line_pct,
  ROUND(ABS(SUM(CASE WHEN is_c_invoice = 1 OR has_negative_line = 1 THEN net_amount ELSE 0 END)), 2) AS cancellation_value
FROM invoice_flags
GROUP BY DATE_FORMAT(invoice_date, '%Y-%m-01')
ORDER BY month_start;

/* 6b. Duplicate-looking invoice lines */
SELECT
  invoice,
  stock_code,
  quantity,
  price,
  COUNT(*) AS duplicate_row_count
FROM invoice_lines
GROUP BY invoice, stock_code, quantity, price
HAVING COUNT(*) > 1
ORDER BY duplicate_row_count DESC, invoice, stock_code;

/* 6c. Odd stock codes such as BANK CHARGES or special service rows */
SELECT
  p.stock_code,
  p.description,
  COUNT(*) AS line_count,
  ROUND(SUM(il.quantity * il.price), 2) AS net_revenue
FROM products p
LEFT JOIN invoice_lines il
  ON il.stock_code = p.stock_code
WHERE p.stock_code IN ('BANK CHARGES', 'POST', 'D', 'M', 'DOT')
   OR p.stock_code LIKE '% %'
GROUP BY p.stock_code, p.description
ORDER BY line_count DESC, p.stock_code;

/* 6d. Missingness and non-positive value checks */
SELECT 'products_missing_description' AS check_name, COUNT(*) AS issue_count
FROM products
WHERE description IS NULL OR TRIM(description) = ''
UNION ALL
SELECT 'invoices_missing_country' AS check_name, COUNT(*) AS issue_count
FROM invoices
WHERE country IS NULL OR TRIM(country) = ''
UNION ALL
SELECT 'customers_missing_country' AS check_name, COUNT(*) AS issue_count
FROM customers
WHERE country IS NULL OR TRIM(country) = ''
UNION ALL
SELECT 'invoice_lines_zero_quantity' AS check_name, COUNT(*) AS issue_count
FROM invoice_lines
WHERE quantity = 0
UNION ALL
SELECT 'invoice_lines_non_positive_price' AS check_name, COUNT(*) AS issue_count
FROM invoice_lines
WHERE price <= 0;

/* 6e. Cancellation logic sanity check */
WITH invoice_flags AS (
  SELECT
    i.invoice,
    CASE WHEN i.invoice LIKE 'C%' THEN 1 ELSE 0 END AS is_c_invoice,
    MAX(CASE WHEN il.quantity < 0 THEN 1 ELSE 0 END) AS has_negative_line
  FROM invoices i
  JOIN invoice_lines il
    ON il.invoice = i.invoice
  GROUP BY i.invoice, CASE WHEN i.invoice LIKE 'C%' THEN 1 ELSE 0 END
)
SELECT
  SUM(CASE WHEN is_c_invoice = 1 AND has_negative_line = 1 THEN 1 ELSE 0 END) AS matched_cancellations,
  SUM(CASE WHEN is_c_invoice = 1 AND has_negative_line = 0 THEN 1 ELSE 0 END) AS c_invoice_without_negative_lines,
  SUM(CASE WHEN is_c_invoice = 0 AND has_negative_line = 1 THEN 1 ELSE 0 END) AS negative_lines_without_c_invoice
FROM invoice_flags;
