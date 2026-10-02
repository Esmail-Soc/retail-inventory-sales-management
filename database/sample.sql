USE retail_store;

INSERT INTO Category (category_name) VALUES
    ('Grocery'),
    ('Beverages'),
    ('Snacks'),
    ('Personal Care'),
    ('Household'),
    ('Dairy');

INSERT INTO Brand (brand_name) VALUES
    ('Tata'),
    ('Aashirvaad'),
    ('Fortune'),
    ('Amul'),
    ('Britannia'),
    ('Parle'),
    ('Nestle'),
    ('Colgate'),
    ('Dettol'),
    ('Surf Excel'),
    ('Coca-Cola'),
    ('Haldiram''s');

INSERT INTO Supplier (name, phone, address) VALUES
    ('Sri Lakshmi Wholesale Traders', '9848011111', 'Begum Bazaar, Hyderabad'),
    ('Balaji Distributors', '9848022222', 'Secunderabad, Hyderabad'),
    ('Metro FMCG Suppliers', '9848033333', 'Kukatpally, Hyderabad'),
    ('Amul Dairy Depot', '9848044444', 'Nampally, Hyderabad'),
    ('Hindustan Home Care Agency', '9848055555', 'Ameerpet, Hyderabad');

INSERT INTO Customer (name, phone, email) VALUES
    ('Walk-in Customer', NULL, NULL),
    ('Ravi Kumar', '9876500001', 'ravi.kumar@gmail.com'),
    ('Sneha Reddy', '9876500002', 'sneha.reddy@gmail.com'),
    ('Mohammed Imran', '9876500003', NULL),
    ('Anjali Sharma', '9876500004', 'anjali.sharma@yahoo.com'),
    ('Venkat Rao', '9876500005', NULL),
    ('Fatima Begum', '9876500006', 'fatima.b@gmail.com'),
    ('Kiran Patel', '9876500007', NULL),
    ('Priya Nair', '9876500008', 'priya.nair@gmail.com'),
    ('Suresh Babu', '9876500009', NULL),
    ('Lakshmi Devi', '9876500010', 'lakshmi.devi@gmail.com');

INSERT INTO Product (product_code, product_name, category_id, brand_id, cost_price, selling_price, reorder_level) VALUES
    ('P001', 'Tata Salt 1kg', 1, 1, 20, 28, 20),
    ('P002', 'Aashirvaad Atta 5kg', 1, 2, 230, 265, 15),
    ('P003', 'Fortune Sunflower Oil 1L', 1, 3, 125, 145, 20),
    ('P004', 'Tata Tea Gold 500g', 1, 1, 210, 245, 10),
    ('P005', 'Tata Sampann Toor Dal 1kg', 1, 1, 120, 150, 15),
    ('P006', 'Amul Butter 500g', 6, 4, 250, 285, 10),
    ('P007', 'Amul Toned Milk 1L', 6, 4, 52, 60, 30),
    ('P008', 'Amul Cheese Slices 200g', 6, 4, 110, 130, 10),
    ('P009', 'Britannia Good Day 200g', 3, 5, 28, 40, 25),
    ('P010', 'Britannia Bread 400g', 1, 5, 32, 45, 15),
    ('P011', 'Parle-G Biscuits 800g', 3, 6, 55, 75, 20),
    ('P012', 'Haldiram''s Aloo Bhujia 400g', 3, 12, 85, 115, 15),
    ('P013', 'Maggi Noodles 12-pack', 3, 7, 140, 170, 20),
    ('P014', 'Nescafe Classic 100g', 2, 7, 255, 310, 10),
    ('P015', 'Coca-Cola 2L', 2, 11, 70, 95, 20),
    ('P016', 'Colgate Toothpaste 200g', 4, 8, 85, 115, 15),
    ('P017', 'Dettol Handwash 250ml', 4, 9, 70, 99, 15),
    ('P018', 'Dettol Soap 3-pack', 4, 9, 95, 135, 15),
    ('P019', 'Surf Excel Powder 1kg', 5, 10, 190, 230, 15),
    ('P020', 'Surf Excel Liquid 1L', 5, 10, 215, 265, 10),
    ('P021', 'Colgate Toothbrush 2-pack', 4, 8, 40, 65, 20),
    ('P022', 'Dettol Floor Cleaner 500ml', 5, 9, 85, 120, 10),
    ('P023', 'Parle Hide & Seek 200g', 3, 6, 30, 45, 15);

INSERT INTO Purchase (supplier_id, purchase_date) VALUES
    (1, '2026-08-01 09:30:00'),
    (2, '2026-08-01 11:00:00'),
    (4, '2026-08-02 10:15:00'),
    (3, '2026-08-03 12:00:00'),
    (5, '2026-08-04 15:30:00'),
    (1, '2026-09-01 09:45:00'),
    (4, '2026-09-05 10:30:00'),
    (2, '2026-09-10 11:15:00');

INSERT INTO PurchaseItem (purchase_id, product_id, quantity, unit_cost) VALUES
    (1, 1, 100, 20),
    (1, 2, 60, 230),
    (1, 3, 80, 125),
    (1, 5, 50, 120),
    (2, 9, 120, 28),
    (2, 10, 30, 32),
    (2, 11, 80, 55),
    (2, 12, 30, 85),
    (2, 23, 20, 30),
    (2, 13, 70, 140),
    (3, 6, 30, 250),
    (3, 7, 120, 52),
    (3, 8, 25, 110),
    (4, 4, 40, 210),
    (4, 14, 14, 255),
    (4, 15, 60, 70),
    (5, 16, 40, 85),
    (5, 17, 20, 70),
    (5, 18, 30, 95),
    (5, 19, 40, 190),
    (5, 20, 20, 215),
    (5, 21, 50, 40),
    (5, 22, 9, 85),
    (6, 1, 50, 20),
    (6, 3, 40, 125),
    (6, 2, 30, 230),
    (7, 7, 80, 52),
    (7, 6, 15, 250),
    (8, 11, 40, 55),
    (8, 13, 30, 140),
    (8, 9, 50, 28);

INSERT INTO Sale (customer_id, sale_date) VALUES
    (1, '2026-08-05 10:53:00'),
    (2, '2026-08-05 11:46:00'),
    (3, '2026-08-07 12:39:00'),
    (1, '2026-08-08 13:32:00'),
    (4, '2026-08-10 14:25:00'),
    (5, '2026-08-12 15:18:00'),
    (1, '2026-08-14 16:11:00'),
    (6, '2026-08-16 17:04:00'),
    (7, '2026-08-18 17:57:00'),
    (1, '2026-08-20 10:50:00'),
    (8, '2026-08-22 11:43:00'),
    (2, '2026-08-25 12:36:00'),
    (9, '2026-08-28 13:29:00'),
    (1, '2026-08-30 14:22:00'),
    (3, '2026-09-02 15:15:00'),
    (10, '2026-09-03 16:08:00'),
    (1, '2026-09-05 17:01:00'),
    (5, '2026-09-07 17:54:00'),
    (1, '2026-09-09 10:47:00'),
    (6, '2026-09-11 11:40:00'),
    (7, '2026-09-13 12:33:00'),
    (1, '2026-09-15 13:26:00'),
    (4, '2026-09-17 14:19:00'),
    (8, '2026-09-19 15:12:00'),
    (1, '2026-09-21 16:05:00'),
    (9, '2026-09-23 16:58:00'),
    (2, '2026-09-25 17:51:00'),
    (1, '2026-09-27 10:44:00'),
    (10, '2026-09-28 11:37:00'),
    (1, '2026-09-30 12:30:00');

INSERT INTO SaleItem (sale_id, product_id, quantity, unit_price) VALUES
    (1, 7, 2, 60),
    (1, 10, 1, 45),
    (1, 9, 2, 40),
    (2, 2, 1, 265),
    (2, 3, 1, 140),
    (2, 1, 2, 28),
    (2, 5, 1, 150),
    (3, 7, 4, 60),
    (3, 6, 1, 285),
    (3, 11, 2, 75),
    (4, 15, 2, 95),
    (4, 12, 1, 115),
    (4, 13, 2, 170),
    (5, 16, 1, 115),
    (5, 17, 1, 99),
    (5, 18, 1, 135),
    (5, 21, 2, 65),
    (6, 2, 2, 265),
    (6, 3, 2, 140),
    (6, 1, 4, 28),
    (6, 5, 2, 150),
    (6, 4, 1, 245),
    (7, 7, 3, 60),
    (7, 9, 3, 40),
    (7, 10, 2, 45),
    (8, 14, 1, 310),
    (8, 8, 1, 130),
    (8, 6, 1, 285),
    (9, 19, 1, 230),
    (9, 20, 1, 265),
    (9, 22, 1, 120),
    (10, 13, 4, 170),
    (10, 12, 3, 115),
    (10, 11, 3, 75),
    (10, 15, 1, 95),
    (11, 7, 6, 60),
    (11, 10, 3, 45),
    (11, 9, 4, 40),
    (11, 8, 1, 130),
    (12, 2, 1, 265),
    (12, 1, 3, 28),
    (12, 3, 1, 140),
    (13, 16, 2, 115),
    (13, 17, 2, 99),
    (13, 18, 2, 135),
    (13, 21, 3, 65),
    (14, 7, 2, 60),
    (14, 9, 2, 40),
    (14, 15, 2, 95),
    (15, 7, 5, 60),
    (15, 10, 2, 45),
    (15, 11, 4, 75),
    (15, 13, 3, 170),
    (16, 2, 2, 265),
    (16, 3, 2, 145),
    (16, 1, 5, 28),
    (16, 5, 3, 150),
    (16, 4, 2, 245),
    (17, 9, 4, 40),
    (17, 12, 2, 115),
    (17, 15, 3, 95),
    (18, 14, 2, 310),
    (18, 6, 2, 285),
    (18, 8, 2, 130),
    (19, 7, 8, 60),
    (19, 10, 4, 45),
    (19, 9, 5, 40),
    (20, 19, 2, 230),
    (20, 22, 1, 120),
    (20, 21, 4, 65),
    (20, 16, 2, 115),
    (21, 13, 5, 170),
    (21, 11, 5, 75),
    (21, 12, 4, 115),
    (21, 9, 6, 40),
    (22, 7, 6, 60),
    (22, 1, 6, 28),
    (22, 10, 3, 45),
    (23, 2, 3, 265),
    (23, 3, 3, 145),
    (23, 5, 2, 150),
    (23, 4, 2, 245),
    (23, 14, 1, 310),
    (24, 17, 3, 99),
    (24, 18, 2, 135),
    (24, 16, 2, 115),
    (24, 20, 1, 265),
    (25, 7, 7, 60),
    (25, 9, 5, 40),
    (25, 15, 4, 95),
    (25, 10, 3, 45),
    (26, 6, 2, 285),
    (26, 8, 1, 130),
    (26, 13, 4, 170),
    (26, 12, 3, 115),
    (27, 1, 5, 28),
    (27, 3, 2, 145),
    (27, 2, 2, 265),
    (27, 11, 6, 75),
    (28, 7, 9, 60),
    (28, 9, 6, 40),
    (28, 10, 4, 45),
    (28, 13, 3, 170),
    (29, 14, 2, 310),
    (29, 4, 2, 245),
    (29, 17, 2, 99),
    (29, 12, 4, 115),
    (30, 7, 10, 60),
    (30, 11, 5, 75),
    (30, 9, 5, 40),
    (30, 15, 3, 95),
    (30, 21, 3, 65);

INSERT INTO Returns (sale_item_id, quantity, return_date, reason)
SELECT sale_item_id, 1, '2026-08-08 12:00:00', 'Bought by mistake'
FROM SaleItem WHERE sale_id = 3 AND product_id = 7;
INSERT INTO Returns (sale_item_id, quantity, return_date, reason)
SELECT sale_item_id, 1, '2026-08-14 12:00:00', 'Customer changed mind'
FROM SaleItem WHERE sale_id = 6 AND product_id = 2;
INSERT INTO Returns (sale_item_id, quantity, return_date, reason)
SELECT sale_item_id, 1, '2026-08-30 12:00:00', 'Wrong size ordered'
FROM SaleItem WHERE sale_id = 13 AND product_id = 18;
INSERT INTO Returns (sale_item_id, quantity, return_date, reason)
SELECT sale_item_id, 1, '2026-09-05 12:00:00', 'Wrong size ordered'
FROM SaleItem WHERE sale_id = 16 AND product_id = 5;
INSERT INTO Returns (sale_item_id, quantity, return_date, reason)
SELECT sale_item_id, 1, '2026-09-13 12:00:00', 'Bought by mistake'
FROM SaleItem WHERE sale_id = 20 AND product_id = 19;
INSERT INTO Returns (sale_item_id, quantity, return_date, reason)
SELECT sale_item_id, 2, '2026-09-23 12:00:00', 'Customer changed mind'
FROM SaleItem WHERE sale_id = 25 AND product_id = 15;

INSERT INTO Invoice (invoice_code, sale_id, invoice_date, total_amount)
SELECT CONCAT('INV-', LPAD(s.sale_id, 4, '0')),
       s.sale_id,
       s.sale_date,
       SUM(si.quantity * si.unit_price)
FROM Sale s
JOIN SaleItem si ON si.sale_id = s.sale_id
GROUP BY s.sale_id, s.sale_date
ORDER BY s.sale_id;

INSERT INTO Payment (invoice_id, amount, payment_date, payment_method)
SELECT invoice_id, total_amount, invoice_date, ELT(MOD(sale_id, 3) + 1, 'Cash', 'UPI', 'Card')
FROM Invoice
WHERE sale_id NOT IN (6, 16, 23, 26, 28, 29, 30);

INSERT INTO Payment (invoice_id, amount, payment_date, payment_method)
SELECT invoice_id, ROUND(total_amount / 2, 2), invoice_date, 'UPI'
FROM Invoice WHERE sale_id IN (6, 16, 23);
INSERT INTO Payment (invoice_id, amount, payment_date, payment_method)
SELECT invoice_id, total_amount - ROUND(total_amount / 2, 2), DATE_ADD(invoice_date, INTERVAL 7 DAY), 'Cash'
FROM Invoice WHERE sale_id IN (6, 16, 23);

INSERT INTO Payment (invoice_id, amount, payment_date, payment_method)
SELECT invoice_id, ROUND(total_amount * 0.6, 2), invoice_date, 'Cash'
FROM Invoice WHERE sale_id = 26;
INSERT INTO Payment (invoice_id, amount, payment_date, payment_method)
SELECT invoice_id, ROUND(total_amount * 0.4, 2), invoice_date, 'Cash'
FROM Invoice WHERE sale_id = 28;

SELECT 'Category' AS table_name, COUNT(*) AS total_rows FROM Category
UNION ALL SELECT 'Brand', COUNT(*) FROM Brand
UNION ALL SELECT 'Supplier', COUNT(*) FROM Supplier
UNION ALL SELECT 'Customer', COUNT(*) FROM Customer
UNION ALL SELECT 'Product', COUNT(*) FROM Product
UNION ALL SELECT 'Purchase', COUNT(*) FROM Purchase
UNION ALL SELECT 'PurchaseItem', COUNT(*) FROM PurchaseItem
UNION ALL SELECT 'Sale', COUNT(*) FROM Sale
UNION ALL SELECT 'SaleItem', COUNT(*) FROM SaleItem
UNION ALL SELECT 'Returns', COUNT(*) FROM Returns
UNION ALL SELECT 'StockMovement', COUNT(*) FROM StockMovement
UNION ALL SELECT 'Invoice', COUNT(*) FROM Invoice
UNION ALL SELECT 'Payment', COUNT(*) FROM Payment;
