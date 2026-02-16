-- =====================================================
-- E-COMMERCE FUNNEL & COHORT ANALYSIS PROJECT
-- Data Import Script
-- =====================================================

-- IMPORTANT: Update the file paths below to match YOUR local directory
-- where you saved the Olist CSV files

-- Example paths:
-- Windows: 'C:/Users/YourName/Downloads/olist_customers_dataset.csv'
-- Mac/Linux: '/Users/YourName/Downloads/olist_customers_dataset.csv'

-- =====================================================
-- STEP 1: Load CUSTOMERS (must be first - referenced by orders)
-- =====================================================

COPY olist_customers(
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
FROM '/path/to/your/olist_customers_dataset.csv'
DELIMITER ','
CSV HEADER;

-- Verify load
SELECT 'Customers loaded:' as table_name, COUNT(*) as row_count FROM olist_customers;

-- =====================================================
-- STEP 2: Load PRODUCTS (must be before order_items)
-- =====================================================

COPY olist_products(
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
FROM '/path/to/your/olist_products_dataset.csv'
DELIMITER ','
CSV HEADER;

-- Verify load
SELECT 'Products loaded:' as table_name, COUNT(*) as row_count FROM olist_products;

-- =====================================================
-- STEP 3: Load ORDERS (must be before order_items, payments, reviews)
-- =====================================================

COPY olist_orders(
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
)
FROM '/path/to/your/olist_orders_dataset.csv'
DELIMITER ','
CSV HEADER;

-- Verify load
SELECT 'Orders loaded:' as table_name, COUNT(*) as row_count FROM olist_orders;

-- =====================================================
-- STEP 4: Load ORDER ITEMS
-- =====================================================

COPY olist_order_items(
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
)
FROM '/path/to/your/olist_order_items_dataset.csv'
DELIMITER ','
CSV HEADER;

-- Verify load
SELECT 'Order Items loaded:' as table_name, COUNT(*) as row_count FROM olist_order_items;

-- =====================================================
-- STEP 5: Load ORDER PAYMENTS
-- =====================================================

COPY olist_order_payments(
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
FROM '/path/to/your/olist_order_payments_dataset.csv'
DELIMITER ','
CSV HEADER;

-- Verify load
SELECT 'Order Payments loaded:' as table_name, COUNT(*) as row_count FROM olist_order_payments;

-- =====================================================
-- STEP 6: Load ORDER REVIEWS
-- =====================================================

COPY olist_order_reviews(
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
FROM '/path/to/your/olist_order_reviews_dataset.csv'
DELIMITER ','
CSV HEADER;

-- Verify load
SELECT 'Order Reviews loaded:' as table_name, COUNT(*) as row_count FROM olist_order_reviews;

-- =====================================================
-- FINAL VERIFICATION - All Tables Summary
-- =====================================================

SELECT 'CUSTOMERS' as table_name, COUNT(*) as rows FROM olist_customers
UNION ALL
SELECT 'ORDERS', COUNT(*) FROM olist_orders
UNION ALL
SELECT 'PRODUCTS', COUNT(*) FROM olist_products
UNION ALL
SELECT 'ORDER_ITEMS', COUNT(*) FROM olist_order_items
UNION ALL
SELECT 'ORDER_PAYMENTS', COUNT(*) FROM olist_order_payments
UNION ALL
SELECT 'ORDER_REVIEWS', COUNT(*) FROM olist_order_reviews;

-- =====================================================
-- DATA QUALITY CHECKS
-- =====================================================

-- Check for orders without customers (should be 0)
SELECT COUNT(*) as orphaned_orders
FROM olist_orders o
LEFT JOIN olist_customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Check date ranges
SELECT 
    MIN(order_purchase_timestamp) as earliest_order,
    MAX(order_purchase_timestamp) as latest_order,
    MAX(order_purchase_timestamp) - MIN(order_purchase_timestamp) as date_range
FROM olist_orders;

-- Check order status distribution
SELECT 
    order_status,
    COUNT(*) as order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM olist_orders
GROUP BY order_status
ORDER BY order_count DESC;