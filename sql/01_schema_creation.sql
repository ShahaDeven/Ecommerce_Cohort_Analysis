-- =====================================================
-- E-COMMERCE FUNNEL & COHORT ANALYSIS PROJECT
-- Database Schema Creation Script
-- =====================================================

-- Drop tables if they exist (for clean re-runs)
DROP TABLE IF EXISTS olist_order_reviews CASCADE;
DROP TABLE IF EXISTS olist_order_payments CASCADE;
DROP TABLE IF EXISTS olist_order_items CASCADE;
DROP TABLE IF EXISTS olist_products CASCADE;
DROP TABLE IF EXISTS olist_orders CASCADE;
DROP TABLE IF EXISTS olist_customers CASCADE;

-- =====================================================
-- 1. CUSTOMERS TABLE
-- =====================================================
CREATE TABLE olist_customers (
    customer_id VARCHAR(255) PRIMARY KEY,
    customer_unique_id VARCHAR(255) NOT NULL,
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

-- =====================================================
-- 2. ORDERS TABLE (Core table for funnel & cohorts)
-- =====================================================
CREATE TABLE olist_orders (
    order_id VARCHAR(255) PRIMARY KEY,
    customer_id VARCHAR(255) NOT NULL,
    order_status VARCHAR(50) NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES olist_customers(customer_id)
);

-- =====================================================
-- 3. PRODUCTS TABLE
-- =====================================================
CREATE TABLE olist_products (
    product_id VARCHAR(255) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- =====================================================
-- 4. ORDER ITEMS TABLE (For revenue & CLV)
-- =====================================================
CREATE TABLE olist_order_items (
    order_id VARCHAR(255) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(255) NOT NULL,
    seller_id VARCHAR(255),
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10, 2) NOT NULL,
    freight_value DECIMAL(10, 2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES olist_orders(order_id),
    FOREIGN KEY (product_id) REFERENCES olist_products(product_id)
);

-- =====================================================
-- 5. ORDER PAYMENTS TABLE (For revenue calculations)
-- =====================================================
CREATE TABLE olist_order_payments (
    order_id VARCHAR(255) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES olist_orders(order_id)
);

-- =====================================================
-- 6. ORDER REVIEWS TABLE (For satisfaction analysis)
-- =====================================================
-- Note: Using composite primary key (review_id, order_id) to handle
-- duplicate review_ids in the source dataset (data quality issue)
CREATE TABLE olist_order_reviews (
    review_id VARCHAR(255),
    order_id VARCHAR(255) NOT NULL,
    review_score INT CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    PRIMARY KEY (review_id, order_id),
    FOREIGN KEY (order_id) REFERENCES olist_orders(order_id)
);

-- =====================================================
-- CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Customers
CREATE INDEX idx_customers_unique_id ON olist_customers(customer_unique_id);

-- Orders (critical for cohort analysis)
CREATE INDEX idx_orders_customer_id ON olist_orders(customer_id);
CREATE INDEX idx_orders_purchase_timestamp ON olist_orders(order_purchase_timestamp);
CREATE INDEX idx_orders_status ON olist_orders(order_status);

-- Order Items
CREATE INDEX idx_order_items_product_id ON olist_order_items(product_id);

-- Order Payments
CREATE INDEX idx_payments_order_id ON olist_order_payments(order_id);

-- Order Reviews
CREATE INDEX idx_reviews_order_id ON olist_order_reviews(order_id);
CREATE INDEX idx_reviews_score ON olist_order_reviews(review_score);

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check that all tables were created
SELECT 
    table_name,
    (SELECT COUNT(*) 
     FROM information_schema.columns 
     WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;