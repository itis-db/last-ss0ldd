CREATE TABLE products (
                          id SERIAL PRIMARY KEY,
                          name VARCHAR(100),
                          category VARCHAR(50),
                          price NUMERIC(10, 2)
);

CREATE TABLE orders (
                        id SERIAL PRIMARY KEY,
                        order_date DATE,
                        customer_id INT
);

CREATE TABLE order_items (
                             id SERIAL PRIMARY KEY,
                             order_id INT REFERENCES orders(id),
                             product_id INT REFERENCES products(id),
                             quantity INT,
                             amount NUMERIC(10, 2)
);

-- Очистка таблиц
TRUNCATE TABLE order_items, orders, products RESTART IDENTITY;
-- Товары
INSERT INTO products (name, category, price) VALUES
                                                 ('Ноутбук Lenovo', 'Электроника', 45000.00),
                                                 ('Смартфон Xiaomi', 'Электроника', 22000.50),
                                                 ('Кофеварка Bosch', 'Бытовая техника', 15000.00),
                                                 ('Футболка мужская', 'Одежда', 1500.00),
                                                 ('Джинсы женские', 'Одежда', 3500.99),
                                                 ('Шампунь Head&Shoulders', 'Косметика', 450.50),
                                                 ('Книга "SQL для всех"', 'Книги', 1200.00),
                                                 ('Монитор Samsung', 'Электроника', 18000.00),
                                                 ('Чайник электрический', 'Бытовая техника', 2500.00),
                                                 ('Кроссовки Nike', 'Одежда', 7500.00),
                                                 ('Планшет Huawei', 'Электроника', 32000.00),
                                                 ('Блендер Philips', 'Бытовая техника', 6500.00);
-- Заказы (за последние 2 года)
INSERT INTO orders (order_date, customer_id) VALUES
                                                 ('2025-05-01', 101),
                                                 ('2025-05-03', 102),
                                                 ('2025-05-05', 103),
                                                 ('2025-05-10', 104),
                                                 ('2025-05-15', 101),
                                                 ('2025-05-20', 105),
                                                 ('2025-06-01', 102),
                                                 ('2025-06-02', 103),
                                                 ('2024-05-01', 104),
                                                 ('2024-05-15', 105),
                                                 ('2024-06-01', 101);
-- Позиции заказов
INSERT INTO order_items (order_id, product_id, quantity, amount) VALUES
                                                                     (1, 1, 1, 45000.00),
                                                                     (1, 8, 1, 18000.00),
                                                                     (2, 2, 1, 22000.50),
                                                                     (2, 4, 2, 3000.00),
                                                                     (3, 5, 1, 3500.99),
                                                                     (3, 10, 1, 7500.00),
                                                                     (3, 6, 3, 1351.50),
                                                                     (4, 3, 1, 15000.00),
                                                                     (4, 9, 1, 2500.00),
                                                                     (5, 11, 1, 32000.00),
                                                                     (5, 12, 1, 6500.00),
                                                                     (6, 7, 5, 6000.00),
                                                                     (7, 1, 1, 45000.00),
                                                                     (7, 2, 1, 22000.50),
                                                                     (8, 5, 2, 7001.98),
                                                                     (9, 3, 1, 15000.00),
                                                                     (9, 6, 2, 901.00),
                                                                     (10, 4, 3, 4500.00),
                                                                     (10, 10, 1, 7500.00),
                                                                     (11, 7, 2, 2400.00),
                                                                     (11, 11, 1, 32000.00);

WITH category_sales AS (
    SELECT
        p.category,
        SUM(oi.amount) AS total_sales,
        COUNT(DISTINCT o.id) AS total_orders
    FROM order_items oi
             JOIN orders o ON oi.order_id = o.id
             JOIN products p ON oi.product_id = p.id
    GROUP BY p.category
),
     total_all_sales AS (
         SELECT SUM(amount) AS grand_total FROM order_items
     )
SELECT
    cs.category,
    cs.total_sales,
    ROUND(cs.total_sales / cs.total_orders, 2) AS avg_per_order,
    ROUND((cs.total_sales / tas.grand_total) * 100, 2) AS category_share
FROM category_sales cs
         CROSS JOIN total_all_sales tas;

WITH order_totals AS (
    SELECT
        o.id AS order_id,
        o.customer_id,
        o.order_date,
        SUM(oi.amount) AS order_total
    FROM orders o
             JOIN order_items oi ON o.id = oi.order_id
    GROUP BY o.id, o.customer_id, o.order_date
),
     customer_stats AS (
         SELECT
             customer_id,
             SUM(order_total) AS total_spent,
             AVG(order_total) AS avg_order_amount
         FROM order_totals
         GROUP BY customer_id
     )
SELECT
    ot.order_id,
    ot.customer_id,
    ot.order_date,
    ot.order_total,
    cs.total_spent,
    ROUND(cs.avg_order_amount, 2) AS avg_order_amount,
    ROUND(ot.order_total - cs.avg_order_amount, 2) AS difference_from_avg
FROM order_totals ot
         JOIN customer_stats cs ON ot.customer_id = cs.customer_id
ORDER BY ot.customer_id, ot.order_date;



WITH monthly_sales AS (
    SELECT
        TO_CHAR(o.order_date, 'YYYY-MM') AS year_month,
        TO_CHAR(o.order_date, 'MM') AS month,
        TO_CHAR(o.order_date, 'YYYY') AS year,
        SUM(oi.amount) AS total_sales
    FROM orders o
             JOIN order_items oi ON o.id = oi.order_id
    GROUP BY TO_CHAR(o.order_date, 'YYYY-MM'), TO_CHAR(o.order_date, 'MM'), TO_CHAR(o.order_date, 'YYYY')
),
     yearly_comparison AS (
         SELECT
             ms.year_month,
             ms.total_sales,
             ms.month,
             ms.year,
             LAG(ms.total_sales, 1) OVER (ORDER BY ms.year_month) AS prev_month_sales,
             prev_year.total_sales AS prev_year_sales
         FROM monthly_sales ms
                  LEFT JOIN monthly_sales prev_year
                            ON ms.month = prev_year.month
                                AND ms.year::INT = prev_year.year::INT + 1
     )
SELECT
    year_month,
    total_sales,
    ROUND(
            CASE
                WHEN prev_month_sales IS NOT NULL THEN
                    ((total_sales - prev_month_sales) / prev_month_sales * 100)::NUMERIC
                ELSE NULL
                END, 2
    ) AS prev_month_diff,
    ROUND(
            CASE
                WHEN prev_year_sales IS NOT NULL THEN
                    ((total_sales - prev_year_sales) / prev_year_sales * 100)::NUMERIC
                ELSE NULL
                END, 2
    ) AS prev_year_diff
FROM yearly_comparison
ORDER BY year_month;