-- ============================================
-- Raw data layer: simulates source system tables
-- ============================================

create schema if not exists raw;

-- ---------- Categories ----------
create table raw.categories (
    id                  serial primary key,
    name                varchar(100) not null,
    parent_category_id  int,
    description         text,
    created_at          timestamp default now()
);

insert into raw.categories (name, parent_category_id, description, created_at) values
('Electronics', null,  'Electronic devices and accessories',      '2023-12-01'),
('Computers',   1,     'Laptops, desktops, and peripherals',      '2023-12-01'),
('Accessories', 1,     'Cables, adapters, and small peripherals',  '2023-12-01'),
('Furniture',   null,  'Office and home furniture',                '2023-12-01'),
('Desks',       4,     'Standing and sitting desks',               '2023-12-01'),
('Seating',     4,     'Chairs, stools, and ergonomic seating',    '2023-12-01'),
('Lighting',    4,     'Desk and ambient lighting',                '2023-12-01');

alter table raw.categories
    add constraint fk_parent_category
    foreign key (parent_category_id)
    references raw.categories(id);

-- ---------- Suppliers ----------
create table raw.suppliers (
    id              serial primary key,
    name            varchar(150) not null,
    contact_email   varchar(150),
    country         varchar(60),
    is_active       boolean default true,
    created_at      timestamp default now()
);

insert into raw.suppliers (name, contact_email, country, is_active, created_at) values
('TechSource Global',   'sales@techsource.com',    'United States', true,  '2023-11-01'),
('OfficeWorks Ltd',     'hello@officeworks.co.uk',  'United Kingdom', true,  '2023-11-01'),
('Shenzhen Components', 'info@szcomponents.cn',     'China',         true,  '2023-11-15'),
('Nordic Ergo',         'contact@nordicergo.se',    'Sweden',        true,  '2023-12-01'),
('BrightLight Co',      'orders@brightlight.de',    'Germany',       false, '2023-12-10');

-- ---------- Products ----------
create table raw.products (
    id            serial primary key,
    name          varchar(100),
    category_id   int references raw.categories(id),
    supplier_id   int references raw.suppliers(id),
    price         numeric(10,2),
    cost          numeric(10,2),
    created_at    timestamp default now()
);

insert into raw.products (name, category_id, supplier_id, price, cost, created_at) values
('Laptop Pro',           2, 1, 1299.00, 850.00,  '2024-01-01'),
('Wireless Mouse',       3, 3,   29.99,  12.00,  '2024-01-01'),
('Standing Desk',        5, 2,  449.00, 220.00,  '2024-01-01'),
('Ergonomic Chair',      6, 4,  599.00, 310.00,  '2024-01-01'),
('USB-C Hub',            3, 3,   49.99,  18.00,  '2024-01-01'),
('Monitor 27"',          2, 1,  349.00, 195.00,  '2024-01-01'),
('Desk Lamp',            7, 5,   39.99,  14.00,  '2024-01-01'),
('Mechanical Keyboard',  3, 3,   89.99,  35.00,  '2024-01-01'),
('Webcam HD',            3, 1,   79.99,  28.00,  '2024-02-15'),
('Monitor Arm',          3, 2,   69.99,  25.00,  '2024-03-01');

-- ---------- Customers ----------
create table raw.customers (
    id          serial primary key,
    first_name  varchar(50),
    last_name   varchar(50),
    email       varchar(100) unique,
    country     varchar(60),
    created_at  timestamp default now()
);

insert into raw.customers (first_name, last_name, email, country, created_at) values
('Alice',   'Anderson', 'alice@example.com',   'United States',  '2024-01-05 10:00:00'),
('Bob',     'Brown',    'bob@example.com',     'United Kingdom', '2024-01-12 14:30:00'),
('Charlie', 'Clark',    'charlie@example.com', 'Canada',         '2024-02-01 09:15:00'),
('Diana',   'Davis',    'diana@example.com',   'United States',  '2024-02-14 11:45:00'),
('Eve',     'Evans',    'eve@example.com',     'Germany',        '2024-03-03 16:20:00'),
('Frank',   'Foster',   'frank@example.com',   'Australia',      '2024-03-20 08:00:00'),
('Grace',   'Green',    'grace@example.com',   'United States',  '2024-04-01 13:10:00'),
('Henry',   'Hall',     'henry@example.com',   'Canada',         '2024-04-15 17:50:00'),
('Ivy',     'Irwin',    'ivy@example.com',     'United Kingdom', '2024-05-01 09:00:00'),
('Jake',    'Jensen',   'jake@example.com',    'United States',  '2024-05-18 12:30:00');

-- ---------- Orders ----------
create table raw.orders (
    id            serial primary key,
    customer_id   int references raw.customers(id),
    status        varchar(20),
    order_date    date,
    shipping_date date,
    created_at    timestamp default now()
);

insert into raw.orders (customer_id, status, order_date, shipping_date, created_at) values
( 1, 'completed',  '2024-01-15', '2024-01-17', '2024-01-15 10:00:00'),
( 1, 'completed',  '2024-02-20', '2024-02-22', '2024-02-20 11:00:00'),
( 2, 'completed',  '2024-01-18', '2024-01-20', '2024-01-18 09:30:00'),
( 3, 'completed',  '2024-02-05', '2024-02-07', '2024-02-05 14:00:00'),
( 3, 'completed',  '2024-03-10', '2024-03-12', '2024-03-10 16:00:00'),
( 4, 'returned',   '2024-02-20', '2024-02-22', '2024-02-20 10:00:00'),
( 5, 'completed',  '2024-03-08', '2024-03-10', '2024-03-08 12:00:00'),
( 5, 'processing', '2024-04-01', null,          '2024-04-01 08:00:00'),
( 6, 'completed',  '2024-03-25', '2024-03-27', '2024-03-25 15:00:00'),
( 7, 'completed',  '2024-04-05', '2024-04-07', '2024-04-05 11:30:00'),
( 7, 'completed',  '2024-04-12', '2024-04-14', '2024-04-12 09:00:00'),
( 8, 'cancelled',  '2024-04-18', null,          '2024-04-18 14:00:00'),
( 9, 'completed',  '2024-05-05', '2024-05-07', '2024-05-05 10:00:00'),
( 9, 'completed',  '2024-05-22', '2024-05-24', '2024-05-22 14:30:00'),
(10, 'completed',  '2024-05-28', '2024-05-30', '2024-05-28 09:15:00'),
( 1, 'completed',  '2024-06-02', '2024-06-04', '2024-06-02 11:00:00'),
( 3, 'completed',  '2024-06-10', '2024-06-12', '2024-06-10 16:00:00'),
( 5, 'completed',  '2024-06-15', '2024-06-17', '2024-06-15 08:45:00');

-- ---------- Order items ----------
create table raw.order_items (
    id          serial primary key,
    order_id    int references raw.orders(id),
    product_id  int references raw.products(id),
    quantity    int,
    unit_price  numeric(10,2)
);

insert into raw.order_items (order_id, product_id, quantity, unit_price) values
-- order 1: Laptop Pro + 2x Wireless Mouse
( 1, 1, 1, 1299.00),
( 1, 2, 2,   29.99),
-- order 2: USB-C Hub + Mechanical Keyboard
( 2, 5, 1,   49.99),
( 2, 8, 1,   89.99),
-- order 3: Standing Desk + Desk Lamp
( 3, 3, 1,  449.00),
( 3, 7, 1,   39.99),
-- order 4: 2x Monitor 27"
( 4, 6, 2,  349.00),
-- order 5: Ergonomic Chair + Wireless Mouse
( 5, 4, 1,  599.00),
( 5, 2, 1,   29.99),
-- order 6: Laptop Pro (returned)
( 6, 1, 1, 1299.00),
-- order 7: Monitor 27"
( 7, 6, 1,  349.00),
-- order 8: Standing Desk + USB-C Hub
( 8, 3, 1,  449.00),
( 8, 5, 1,   49.99),
-- order 9: 2x Mechanical Keyboard
( 9, 8, 2,   89.99),
-- order 10: Ergonomic Chair + 2x Desk Lamp
(10, 4, 1,  599.00),
(10, 7, 2,   39.99),
-- order 11: 3x Wireless Mouse + USB-C Hub
(11, 2, 3,   29.99),
(11, 5, 1,   49.99),
-- order 12: Laptop Pro (cancelled)
(12, 1, 1, 1299.00),
-- order 13: Webcam HD + Monitor Arm
(13, 9, 1,   79.99),
(13,10, 1,   69.99),
-- order 14: Laptop Pro + USB-C Hub (discounted)
(14, 1, 1, 1299.00),
(14, 5, 1,   39.99),
-- order 15: Mechanical Keyboard + Webcam HD
(15, 8, 1,   89.99),
(15, 9, 1,   79.99),
-- order 16: Monitor 27" + Monitor Arm
(16, 6, 1,  349.00),
(16,10, 1,   69.99),
-- order 17: Ergonomic Chair
(17, 4, 1,  599.00),
-- order 18: Standing Desk + Desk Lamp + Wireless Mouse
(18, 3, 1,  449.00),
(18, 7, 1,   39.99),
(18, 2, 1,   29.99);

-- ---------- Payments ----------
create table raw.payments (
    id          serial primary key,
    order_id    int references raw.orders(id),
    amount      numeric(10,2),
    method      varchar(20),
    status      varchar(20),
    created_at  timestamp default now()
);

insert into raw.payments (order_id, amount, method, status, created_at) values
( 1, 1358.98, 'credit_card', 'success',  '2024-01-15 10:05:00'),
( 2,  139.98, 'credit_card', 'success',  '2024-02-20 11:05:00'),
( 3,  488.99, 'debit_card',  'success',  '2024-01-18 09:35:00'),
( 4,  698.00, 'credit_card', 'success',  '2024-02-05 14:05:00'),
( 5,  628.99, 'paypal',      'success',  '2024-03-10 16:05:00'),
( 6, 1299.00, 'credit_card', 'refunded', '2024-02-22 10:05:00'),
( 7,  349.00, 'debit_card',  'success',  '2024-03-08 12:05:00'),
( 8,  498.99, 'credit_card', 'pending',  '2024-04-01 08:05:00'),
( 9,  179.98, 'paypal',      'success',  '2024-03-25 15:05:00'),
(10,  678.98, 'credit_card', 'success',  '2024-04-05 11:35:00'),
(11,  139.96, 'debit_card',  'success',  '2024-04-12 09:05:00'),
(12, 1299.00, 'credit_card', 'failed',   '2024-04-18 14:05:00'),
(13,  149.98, 'credit_card', 'success',  '2024-05-05 10:05:00'),
(14, 1338.99, 'paypal',      'success',  '2024-05-22 14:35:00'),
(15,  169.98, 'debit_card',  'success',  '2024-05-28 09:20:00'),
(16,  418.99, 'credit_card', 'success',  '2024-06-02 11:05:00'),
(17,  599.00, 'credit_card', 'success',  '2024-06-10 16:05:00'),
(18,  518.98, 'paypal',      'success',  '2024-06-15 08:50:00');

-- ---------- Inventory ----------
create table raw.inventory (
    id                  serial primary key,
    product_id          int references raw.products(id),
    warehouse_location  varchar(50),
    quantity_on_hand    int,
    quantity_reserved   int default 0,
    reorder_point       int default 10,
    last_restocked_at   timestamp,
    updated_at          timestamp default now()
);

insert into raw.inventory (product_id, warehouse_location, quantity_on_hand, quantity_reserved, reorder_point, last_restocked_at, updated_at) values
( 1, 'US-EAST',  25,  3, 10, '2024-04-01', '2024-06-01'),
( 1, 'US-WEST',  18,  2, 10, '2024-03-15', '2024-06-01'),
( 2, 'US-EAST', 150, 12, 50, '2024-05-01', '2024-06-01'),
( 3, 'US-EAST',   8,  1, 10, '2024-04-20', '2024-06-01'),
( 4, 'US-EAST',  12,  2, 10, '2024-04-15', '2024-06-01'),
( 4, 'EU-CENTRAL', 6, 0,  5, '2024-05-10', '2024-06-01'),
( 5, 'US-EAST',  90,  5, 30, '2024-05-15', '2024-06-01'),
( 6, 'US-EAST',  20,  4, 15, '2024-04-25', '2024-06-01'),
( 7, 'US-EAST',  45,  3, 20, '2024-05-20', '2024-06-01'),
( 8, 'US-EAST',  35,  6, 15, '2024-05-05', '2024-06-01'),
( 9, 'US-EAST',  60,  2, 20, '2024-05-25', '2024-06-01'),
(10, 'US-EAST',  40,  1, 15, '2024-06-01', '2024-06-01');

-- ---------- Reviews ----------
create table raw.reviews (
    id                    serial primary key,
    product_id            int references raw.products(id),
    customer_id           int references raw.customers(id),
    rating                int check (rating between 1 and 5),
    title                 varchar(200),
    body                  text,
    is_verified_purchase  boolean default false,
    created_at            timestamp default now()
);

insert into raw.reviews (product_id, customer_id, rating, title, body, is_verified_purchase, created_at) values
(1, 1, 5, 'Fantastic laptop',           'Exceeds all expectations. Blazing fast and great build quality.',              true,  '2024-02-01 10:00:00'),
(1, 4, 2, 'Overpriced',                 'Nice but not worth the price. Returned it.',                                  true,  '2024-03-05 14:00:00'),
(2, 1, 4, 'Good mouse',                 'Comfortable and reliable. Battery lasts ages.',                               true,  '2024-02-05 09:00:00'),
(3, 2, 5, 'Best desk ever',             'Smooth motor, solid build, and it remembers my height settings perfectly.',    true,  '2024-02-20 11:00:00'),
(4, 3, 5, 'Back saver',                 'My back pain is gone after switching to this chair.',                          true,  '2024-04-01 08:00:00'),
(4, 7, 4, 'Comfortable',                'Very comfortable for long sessions.',                                         true,  '2024-04-20 10:00:00'),
(5, 1, 3, 'Does the job',               'Works fine but gets warm with multiple devices.',                             true,  '2024-03-15 16:00:00'),
(6, 4, 5, 'Stunning display',           'Colors are vibrant, great for design work.',                                  true,  '2024-03-10 12:00:00'),
(6, 7, 4, 'Good value',                 'Solid monitor for the price.',                                                true,  '2024-04-15 09:30:00'),
(7, 9, 3, 'Decent lamp',                'Light is a bit harsh on the highest setting.',                                false, '2024-05-10 17:00:00'),
(8, 6, 5, 'Typing heaven',              'Cherry switches and solid build. Highly recommended for programmers.',         true,  '2024-04-10 14:00:00'),
(8, 2, 4, 'Great keyboard',             'Satisfying key feel, slightly loud for open offices.',                        false, '2024-04-25 11:00:00'),
(9, 9, 4, 'Clear picture',              'Good quality webcam, easy setup.',                                            true,  '2024-05-20 10:00:00'),
(10,7, 5, 'Essential accessory',         'Frees up desk space, smooth adjustments.',                                   true,  '2024-04-22 15:00:00');

-- ---------- Order events ----------
create table raw.order_events (
    id          serial primary key,
    order_id    int references raw.orders(id),
    event_type  varchar(30),
    event_data  jsonb,
    created_at  timestamp default now()
);

insert into raw.order_events (order_id, event_type, event_data, created_at) values
-- order 1 lifecycle
( 1, 'placed',     '{"channel": "web"}',                       '2024-01-15 10:00:00'),
( 1, 'confirmed',  '{}',                                       '2024-01-15 10:02:00'),
( 1, 'processing', '{}',                                       '2024-01-15 14:00:00'),
( 1, 'shipped',    '{"carrier": "FedEx", "tracking": "FX001"}','2024-01-17 09:00:00'),
( 1, 'delivered',  '{}',                                       '2024-01-19 14:30:00'),
-- order 2 lifecycle
( 2, 'placed',     '{"channel": "web"}',                       '2024-02-20 11:00:00'),
( 2, 'confirmed',  '{}',                                       '2024-02-20 11:05:00'),
( 2, 'shipped',    '{"carrier": "UPS", "tracking": "UP002"}',  '2024-02-22 10:00:00'),
( 2, 'delivered',  '{}',                                       '2024-02-24 16:00:00'),
-- order 6: returned
( 6, 'placed',     '{"channel": "web"}',                       '2024-02-20 10:00:00'),
( 6, 'confirmed',  '{}',                                       '2024-02-20 10:05:00'),
( 6, 'shipped',    '{"carrier": "FedEx", "tracking": "FX006"}','2024-02-22 08:00:00'),
( 6, 'delivered',  '{}',                                       '2024-02-24 12:00:00'),
( 6, 'refunded',   '{"reason": "defective product"}',          '2024-03-01 09:00:00'),
-- order 8: processing (still pending)
( 8, 'placed',     '{"channel": "mobile"}',                    '2024-04-01 08:00:00'),
( 8, 'confirmed',  '{}',                                       '2024-04-01 08:10:00'),
( 8, 'processing', '{}',                                       '2024-04-01 12:00:00'),
-- order 12: cancelled
(12, 'placed',     '{"channel": "web"}',                       '2024-04-18 14:00:00'),
(12, 'cancelled',  '{"reason": "payment failed"}',             '2024-04-18 14:10:00'),
-- order 16
(16, 'placed',     '{"channel": "web"}',                       '2024-06-02 11:00:00'),
(16, 'confirmed',  '{}',                                       '2024-06-02 11:03:00'),
(16, 'shipped',    '{"carrier": "DHL", "tracking": "DH016"}',  '2024-06-04 09:00:00'),
(16, 'delivered',  '{}',                                       '2024-06-06 11:00:00');

-- ============================================
-- Create schemas that dbt will write into
-- ============================================
create schema if not exists staging;
create schema if not exists intermediate;
create schema if not exists marts;

-- Grant privileges
grant all on schema raw          to analytics_user;
grant all on schema staging      to analytics_user;
grant all on schema intermediate to analytics_user;
grant all on schema marts        to analytics_user;
grant all on all tables in schema raw to analytics_user;
