USE retail_store;

CREATE OR REPLACE VIEW v_low_stock AS
SELECT p.product_id,
       p.product_code,
       p.product_name,
       c.category_name,
       p.stock_quantity,
       p.reorder_level,
       (p.reorder_level - p.stock_quantity) AS short_by
FROM Product p
JOIN Category c ON c.category_id = p.category_id
WHERE p.stock_quantity < p.reorder_level;

CREATE OR REPLACE VIEW v_stock_valuation AS
SELECT p.product_id,
       p.product_code,
       p.product_name,
       p.stock_quantity,
       p.cost_price,
       p.selling_price,
       (p.stock_quantity * p.cost_price)    AS value_at_cost,
       (p.stock_quantity * p.selling_price) AS value_at_selling_price
FROM Product p;

CREATE OR REPLACE VIEW v_supplier_purchases AS
SELECT s.supplier_id,
       s.name AS supplier_name,
       COUNT(DISTINCT pu.purchase_id)              AS total_purchases,
       COALESCE(SUM(pi.quantity), 0)               AS total_items,
       COALESCE(SUM(pi.quantity * pi.unit_cost), 0) AS total_amount
FROM Supplier s
LEFT JOIN Purchase pu     ON pu.supplier_id = s.supplier_id
LEFT JOIN PurchaseItem pi ON pi.purchase_id = pu.purchase_id
GROUP BY s.supplier_id, s.name;

CREATE OR REPLACE VIEW v_daily_sales AS
SELECT DATE(invoice_date) AS sale_day,
       COUNT(*)           AS total_invoices,
       SUM(total_amount)  AS total_sales
FROM Invoice
GROUP BY DATE(invoice_date);

CREATE OR REPLACE VIEW v_monthly_sales AS
SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS sale_month,
       COUNT(*)                           AS total_invoices,
       SUM(total_amount)                  AS total_sales,
       ROUND(AVG(total_amount), 2)        AS average_bill
FROM Invoice
GROUP BY DATE_FORMAT(invoice_date, '%Y-%m');

CREATE OR REPLACE VIEW v_returns_report AS
SELECT r.return_id,
       r.return_date,
       p.product_name,
       cu.name AS customer_name,
       r.quantity,
       si.unit_price,
       (r.quantity * si.unit_price) AS refund_amount,
       r.reason
FROM Returns r
JOIN SaleItem si ON si.sale_item_id = r.sale_item_id
JOIN Product p   ON p.product_id    = si.product_id
JOIN Sale s      ON s.sale_id       = si.sale_id
JOIN Customer cu ON cu.customer_id  = s.customer_id;

CREATE OR REPLACE VIEW v_fast_moving AS
SELECT p.product_id,
       p.product_name,
       SUM(si.quantity)             AS total_sold,
       COUNT(DISTINCT si.sale_id)   AS number_of_sales
FROM Product p
JOIN SaleItem si ON si.product_id = p.product_id
GROUP BY p.product_id, p.product_name;

CREATE OR REPLACE VIEW v_product_profit AS
SELECT p.product_id,
       p.product_name,
       SUM(si.quantity - COALESCE(r.returned, 0))                               AS net_quantity_sold,
       SUM((si.quantity - COALESCE(r.returned, 0)) * si.unit_price)             AS revenue,
       SUM((si.quantity - COALESCE(r.returned, 0)) * p.cost_price)              AS cost,
       SUM((si.quantity - COALESCE(r.returned, 0)) * (si.unit_price - p.cost_price)) AS profit
FROM SaleItem si
JOIN Product p ON p.product_id = si.product_id
LEFT JOIN (SELECT sale_item_id, SUM(quantity) AS returned
           FROM Returns
           GROUP BY sale_item_id) r ON r.sale_item_id = si.sale_item_id
GROUP BY p.product_id, p.product_name;

CREATE OR REPLACE VIEW v_pending_payments AS
SELECT i.invoice_code,
       cu.name AS customer_name,
       i.invoice_date,
       i.total_amount,
       COALESCE(SUM(pay.amount), 0)                  AS paid_amount,
       i.total_amount - COALESCE(SUM(pay.amount), 0) AS balance
FROM Invoice i
JOIN Sale s      ON s.sale_id      = i.sale_id
JOIN Customer cu ON cu.customer_id = s.customer_id
LEFT JOIN Payment pay ON pay.invoice_id = i.invoice_id
GROUP BY i.invoice_id, i.invoice_code, cu.name, i.invoice_date, i.total_amount
HAVING balance > 0;

SELECT * FROM v_low_stock ORDER BY short_by DESC;

SELECT * FROM v_stock_valuation ORDER BY value_at_cost DESC;

SELECT SUM(value_at_cost)          AS total_value_at_cost,
       SUM(value_at_selling_price) AS total_value_at_selling_price
FROM v_stock_valuation;

SELECT * FROM v_supplier_purchases ORDER BY total_amount DESC;

SELECT * FROM v_daily_sales ORDER BY sale_day;

SELECT * FROM v_daily_sales WHERE sale_day = '2026-09-30';

SELECT * FROM v_monthly_sales ORDER BY sale_month;

SELECT * FROM v_returns_report ORDER BY return_date;

SELECT * FROM v_fast_moving ORDER BY total_sold DESC LIMIT 5;

SELECT * FROM v_fast_moving WHERE total_sold < 10 ORDER BY total_sold;

SELECT * FROM v_product_profit ORDER BY profit DESC;

SELECT SUM(revenue) AS total_revenue,
       SUM(cost)    AS total_cost,
       SUM(profit)  AS total_profit,
       ROUND(SUM(profit) / SUM(revenue) * 100, 2) AS profit_percent
FROM v_product_profit;

SELECT * FROM v_pending_payments ORDER BY balance DESC;

SELECT i.invoice_code,
       cu.name AS customer,
       p.product_name,
       si.quantity,
       si.unit_price,
       (si.quantity * si.unit_price) AS line_total
FROM Invoice i
JOIN Sale s      ON s.sale_id      = i.sale_id
JOIN Customer cu ON cu.customer_id = s.customer_id
JOIN SaleItem si ON si.sale_id     = s.sale_id
JOIN Product p   ON p.product_id   = si.product_id
WHERE i.invoice_code = 'INV-0006';

SELECT p.product_code, p.product_name, p.stock_quantity
FROM Product p
LEFT JOIN SaleItem si ON si.product_id = p.product_id
WHERE si.sale_item_id IS NULL;

SELECT product_name, selling_price
FROM Product
WHERE selling_price > (SELECT AVG(selling_price) FROM Product)
ORDER BY selling_price DESC;

SELECT c.customer_id, c.name, c.phone
FROM Customer c
WHERE NOT EXISTS (SELECT 1 FROM Sale s WHERE s.customer_id = c.customer_id);

SELECT c.name, SUM(i.total_amount) AS total_spent
FROM Customer c
JOIN Sale s    ON s.customer_id = c.customer_id
JOIN Invoice i ON i.sale_id     = s.sale_id
WHERE c.customer_id <> 1
GROUP BY c.customer_id, c.name
HAVING SUM(i.total_amount) > (SELECT AVG(t.total)
                              FROM (SELECT SUM(i2.total_amount) AS total
                                    FROM Sale s2
                                    JOIN Invoice i2 ON i2.sale_id = s2.sale_id
                                    WHERE s2.customer_id <> 1
                                    GROUP BY s2.customer_id) t)
ORDER BY total_spent DESC;

SELECT cat.category_name,
       SUM(si.quantity)                AS pieces_sold,
       SUM(si.quantity * si.unit_price) AS sales_amount
FROM SaleItem si
JOIN Product p   ON p.product_id   = si.product_id
JOIN Category cat ON cat.category_id = p.category_id
GROUP BY cat.category_id, cat.category_name
ORDER BY sales_amount DESC;

SELECT payment_method,
       COUNT(*)    AS number_of_payments,
       SUM(amount) AS total_received
FROM Payment
GROUP BY payment_method;

SELECT MAX(total_amount)           AS biggest_bill,
       MIN(total_amount)           AS smallest_bill,
       ROUND(AVG(total_amount), 2) AS average_bill
FROM Invoice;

SELECT product_code, product_name
FROM Product
WHERE product_id IN (SELECT pi.product_id
                     FROM PurchaseItem pi
                     JOIN Purchase pu ON pu.purchase_id = pi.purchase_id
                     JOIN Supplier s  ON s.supplier_id  = pu.supplier_id
                     WHERE s.name = 'Balaji Distributors');

SELECT sm.movement_date, sm.movement_type, sm.source, sm.quantity
FROM StockMovement sm
JOIN Product p ON p.product_id = sm.product_id
WHERE p.product_code = 'P010'
ORDER BY sm.movement_date, sm.movement_id;

SELECT customer_id, name, phone, email
FROM Customer
WHERE name LIKE '%kumar%';

SELECT customer_id, name, phone, email
FROM Customer
WHERE phone = '9876500002';

SELECT product_code, product_name, selling_price, stock_quantity
FROM Product
WHERE product_name LIKE '%Dettol%';

EXPLAIN SELECT * FROM Product  WHERE product_name = 'Tata Salt 1kg';
EXPLAIN SELECT * FROM Customer WHERE phone = '9876500002';
EXPLAIN SELECT * FROM Sale     WHERE sale_date >= '2026-09-28';
EXPLAIN SELECT * FROM StockMovement WHERE product_id = 10 ORDER BY movement_date;
