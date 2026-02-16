-- ============================================
-- Raw data layer: simulates source system tables
-- ============================================

CREATE SCHEMA IF NOT EXISTS raw;

-- Customers
CREATE TABLE raw.customers (
    id          SERIAL PRIMARY KEY,
    first_name  VARCHAR(50),
    last_name   VARCHAR(50),
    email       VARCHAR(100),
    created_at  TIMESTAMP DEFAULT NOW()
);

INSERT INTO raw.customers (first_name, last_name, email, created_at) VALUES
('Alice',   'Anderson', 'alice@example.com',   '2024-01-05 10:00:00'),
('Bob',     'Brown',    'bob@example.com',     '2024-01-12 14:30:00'),
('Charlie', 'Clark',    'charlie@example.com', '2024-02-01 09:15:00'),
('Diana',   'Davis',    'diana@example.com',   '2024-02-14 11:45:00'),
('Eve',     'Evans',    'eve@example.com',     '2024-03-03 16:20:00'),
('Frank',   'Foster',   'frank@example.com',   '2024-03-20 08:00:00'),
('Grace',   'Green',    'grace@example.com',   '2024-04-01 13:10:00'),
('Henry',   'Hall',     'henry@example.com',   '2024-04-15 17:50:00');

-- Products
CREATE TABLE raw.products (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100),
    category    VARCHAR(50),
    price       NUMERIC(10,2),
    created_at  TIMESTAMP DEFAULT NOW()
);

INSERT INTO raw.products (name, category, price, created_at) VALUES
('Laptop Pro',       'Electronics', 1299.00, '2024-01-01'),
('Wireless Mouse',   'Electronics',   29.99, '2024-01-01'),
('Standing Desk',    'Furniture',    449.00, '2024-01-01'),
('Ergonomic Chair',  'Furniture',    599.00, '2024-01-01'),
('USB-C Hub',        'Electronics',   49.99, '2024-01-01'),
('Monitor 27"',      'Electronics',  349.00, '2024-01-01'),
('Desk Lamp',        'Furniture',     39.99, '2024-01-01'),
('Mechanical Keyboard','Electronics',  89.99, '2024-01-01');

-- Orders
CREATE TABLE raw.orders (
    id           SERIAL PRIMARY KEY,
    customer_id  INT REFERENCES raw.customers(id),
    status       VARCHAR(20),
    order_date   DATE,
    created_at   TIMESTAMP DEFAULT NOW()
);

INSERT INTO raw.orders (customer_id, status, order_date, created_at) VALUES
(1, 'completed',  '2024-01-15', '2024-01-15 10:00:00'),
(1, 'completed',  '2024-02-20', '2024-02-20 11:00:00'),
(2, 'completed',  '2024-01-18', '2024-01-18 09:30:00'),
(3, 'completed',  '2024-02-05', '2024-02-05 14:00:00'),
(3, 'completed',  '2024-03-10', '2024-03-10 16:00:00'),
(4, 'returned',   '2024-02-20', '2024-02-20 10:00:00'),
(5, 'completed',  '2024-03-08', '2024-03-08 12:00:00'),
(5, 'processing', '2024-04-01', '2024-04-01 08:00:00'),
(6, 'completed',  '2024-03-25', '2024-03-25 15:00:00'),
(7, 'completed',  '2024-04-05', '2024-04-05 11:30:00'),
(7, 'completed',  '2024-04-12', '2024-04-12 09:00:00'),
(8, 'cancelled',  '2024-04-18', '2024-04-18 14:00:00');

-- Order items (line items)
CREATE TABLE raw.order_items (
    id          SERIAL PRIMARY KEY,
    order_id    INT REFERENCES raw.orders(id),
    product_id  INT REFERENCES raw.products(id),
    quantity    INT,
    unit_price  NUMERIC(10,2)
);

INSERT INTO raw.order_items (order_id, product_id, quantity, unit_price) VALUES
(1,  1, 1, 1299.00),
(1,  2, 2,   29.99),
(2,  5, 1,   49.99),
(2,  8, 1,   89.99),
(3,  3, 1,  449.00),
(3,  7, 1,   39.99),
(4,  6, 2,  349.00),
(5,  4, 1,  599.00),
(5,  2, 1,   29.99),
(6,  1, 1, 1299.00),
(7,  6, 1,  349.00),
(8,  3, 1,  449.00),
(8,  5, 1,   49.99),
(9,  8, 2,   89.99),
(10, 4, 1,  599.00),
(10, 7, 2,   39.99),
(11, 2, 3,   29.99),
(11, 5, 1,   49.99),
(12, 1, 1, 1299.00);

-- Payments
CREATE TABLE raw.payments (
    id          SERIAL PRIMARY KEY,
    order_id    INT REFERENCES raw.orders(id),
    amount      NUMERIC(10,2),
    method      VARCHAR(20),
    status      VARCHAR(20),
    created_at  TIMESTAMP DEFAULT NOW()
);

INSERT INTO raw.payments (order_id, amount, method, status, created_at) VALUES
(1,  1358.98, 'credit_card', 'success', '2024-01-15 10:05:00'),
(2,   139.98, 'credit_card', 'success', '2024-02-20 11:05:00'),
(3,   488.99, 'debit_card',  'success', '2024-01-18 09:35:00'),
(4,   698.00, 'credit_card', 'refunded','2024-02-20 10:05:00'),
(5,   628.99, 'paypal',      'success', '2024-03-10 16:05:00'),
(6,  1299.00, 'credit_card', 'success', '2024-02-20 10:05:00'),
(7,   349.00, 'debit_card',  'success', '2024-03-08 12:05:00'),
(8,   498.99, 'credit_card', 'pending', '2024-04-01 08:05:00'),
(9,   179.98, 'paypal',      'success', '2024-03-25 15:05:00'),
(10,  678.98, 'credit_card', 'success', '2024-04-05 11:35:00'),
(11,  139.96, 'debit_card',  'success', '2024-04-12 09:05:00'),
(12, 1299.00, 'credit_card', 'failed',  '2024-04-18 14:05:00');

-- ============================================
-- Create schemas that dbt will write into
-- ============================================
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS marts;

-- Grant full privileges to the analytics user
GRANT ALL ON SCHEMA raw      TO analytics_user;
GRANT ALL ON SCHEMA staging  TO analytics_user;
GRANT ALL ON SCHEMA marts    TO analytics_user;
GRANT ALL ON ALL TABLES IN SCHEMA raw TO analytics_user;
