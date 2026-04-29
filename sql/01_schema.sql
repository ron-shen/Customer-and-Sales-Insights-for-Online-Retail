CREATE DATABASE IF NOT EXISTS retail_sales
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE retail_sales;

SET NAMES utf8mb4;

DROP TABLE IF EXISTS invoice_lines;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
  customer_id BIGINT NOT NULL,
  country VARCHAR(100) NOT NULL,
  PRIMARY KEY (customer_id),
  KEY idx_customers_country (country)
) ENGINE=InnoDB;

CREATE TABLE products (
  stock_code VARCHAR(40) NOT NULL,
  description VARCHAR(255) NULL,
  PRIMARY KEY (stock_code)
) ENGINE=InnoDB;

CREATE TABLE invoices (
  invoice VARCHAR(20) NOT NULL,
  customer_id BIGINT NOT NULL,
  invoice_date DATETIME NOT NULL,
  country VARCHAR(100) NOT NULL,
  PRIMARY KEY (invoice),
  KEY idx_invoices_customer_id (customer_id),
  KEY idx_invoices_invoice_date (invoice_date),
  KEY idx_invoices_country (country),
  CONSTRAINT fk_invoices_customer
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
) ENGINE=InnoDB;

CREATE TABLE invoice_lines (
  invoice_line_id BIGINT NOT NULL AUTO_INCREMENT,
  invoice VARCHAR(20) NOT NULL,
  line_no INT NOT NULL,
  stock_code VARCHAR(40) NOT NULL,
  quantity INT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (invoice_line_id),
  UNIQUE KEY uq_invoice_lines_invoice_line_no (invoice, line_no),
  KEY idx_invoice_lines_invoice (invoice),
  KEY idx_invoice_lines_stock_code (stock_code),
  CONSTRAINT fk_invoice_lines_invoice
    FOREIGN KEY (invoice) REFERENCES invoices (invoice),
  CONSTRAINT fk_invoice_lines_product
    FOREIGN KEY (stock_code) REFERENCES products (stock_code)
) ENGINE=InnoDB;
