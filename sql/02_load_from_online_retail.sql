USE retail_sales;

SET NAMES utf8mb4;

DELETE FROM invoice_lines;
DELETE FROM invoices;
DELETE FROM products;
DELETE FROM customers;

ALTER TABLE invoice_lines AUTO_INCREMENT = 1;

-- A customer can appear under multiple countries in this dataset, so keep one
-- canonical country per customer based on frequency, then most recent activity.
INSERT INTO customers (customer_id, country)
SELECT customer_id, country
FROM (
  SELECT
    customer_id,
    country,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id
      ORDER BY country_row_count DESC, latest_invoice_date DESC, country ASC
    ) AS rn
  FROM (
    SELECT
      CAST(customer_id AS UNSIGNED) AS customer_id,
      TRIM(country) AS country,
      COUNT(*) AS country_row_count,
      MAX(invoice_date) AS latest_invoice_date
    FROM ecommerce.online_retail
    WHERE customer_id IS NOT NULL
      AND country IS NOT NULL
      AND TRIM(country) <> ''
    GROUP BY CAST(customer_id AS UNSIGNED), TRIM(country)
  ) customer_country_stats
) ranked_customers
WHERE rn = 1;

-- A stock code can also have multiple description variants, so keep the most
-- common description for each product code.
INSERT INTO products (stock_code, description)
SELECT stock_code, description
FROM (
  SELECT
    stock_code,
    description,
    ROW_NUMBER() OVER (
      PARTITION BY stock_code
      ORDER BY description_row_count DESC, latest_invoice_date DESC, COALESCE(description, '') ASC
    ) AS rn
  FROM (
    SELECT
      TRIM(stock_code) AS stock_code,
      NULLIF(TRIM(description), '') AS description,
      COUNT(*) AS description_row_count,
      MAX(invoice_date) AS latest_invoice_date
    FROM ecommerce.online_retail
    WHERE stock_code IS NOT NULL
      AND TRIM(stock_code) <> ''
    GROUP BY TRIM(stock_code), NULLIF(TRIM(description), '')
  ) product_description_stats
) ranked_products
WHERE rn = 1;

INSERT INTO invoices (invoice, customer_id, invoice_date, country)
SELECT
  TRIM(invoice) AS invoice,
  CAST(customer_id AS UNSIGNED) AS customer_id,
  MIN(invoice_date) AS invoice_date,
  TRIM(country) AS country
FROM ecommerce.online_retail
WHERE invoice IS NOT NULL
  AND TRIM(invoice) <> ''
  AND customer_id IS NOT NULL
  AND country IS NOT NULL
  AND TRIM(country) <> ''
GROUP BY
  TRIM(invoice),
  CAST(customer_id AS UNSIGNED),
  TRIM(country);

INSERT INTO invoice_lines (invoice, line_no, stock_code, quantity, price)
SELECT
  numbered_lines.invoice,
  numbered_lines.line_no,
  numbered_lines.stock_code,
  numbered_lines.quantity,
  numbered_lines.price
FROM (
  SELECT
    TRIM(invoice) AS invoice,
    ROW_NUMBER() OVER (
      PARTITION BY TRIM(invoice)
      ORDER BY
        invoice_date,
        TRIM(stock_code),
        COALESCE(TRIM(description), ''),
        CAST(quantity AS SIGNED),
        CAST(price AS DECIMAL(10,2)),
        COALESCE(CAST(customer_id AS UNSIGNED), 0),
        COALESCE(TRIM(country), '')
    ) AS line_no,
    TRIM(stock_code) AS stock_code,
    CAST(quantity AS SIGNED) AS quantity,
    CAST(price AS DECIMAL(10,2)) AS price
  FROM ecommerce.online_retail
  WHERE invoice IS NOT NULL
    AND TRIM(invoice) <> ''
    AND stock_code IS NOT NULL
    AND TRIM(stock_code) <> ''
) numbered_lines
INNER JOIN invoices i
  ON i.invoice = numbered_lines.invoice
INNER JOIN products p
  ON p.stock_code = numbered_lines.stock_code;

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'invoices' AS table_name, COUNT(*) AS row_count FROM invoices
UNION ALL
SELECT 'invoice_lines' AS table_name, COUNT(*) AS row_count FROM invoice_lines;
