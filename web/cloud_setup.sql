-- Cloud setup (no triggers). Run the WHOLE file once in MySQL Workbench on the Clever Cloud database.
-- It can be run again: it first removes the old tables.
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS Invoice;
DROP TABLE IF EXISTS StockMovement;
DROP TABLE IF EXISTS Returns;
DROP TABLE IF EXISTS SaleItem;
DROP TABLE IF EXISTS Sale;
DROP TABLE IF EXISTS PurchaseItem;
DROP TABLE IF EXISTS Purchase;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Supplier;
DROP TABLE IF EXISTS Brand;
DROP TABLE IF EXISTS Category;
SET FOREIGN_KEY_CHECKS = 1;
CREATE TABLE Category (
    category_id    INT AUTO_INCREMENT PRIMARY KEY,
    category_name  VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Brand (
    brand_id    INT AUTO_INCREMENT PRIMARY KEY,
    brand_name  VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Supplier (
    supplier_id  INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    phone        VARCHAR(15),
    address      VARCHAR(200)
);

CREATE TABLE Customer (
    customer_id  INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    phone        VARCHAR(15) UNIQUE,
    email        VARCHAR(100) UNIQUE
);

CREATE TABLE Product (
    product_id      INT AUTO_INCREMENT PRIMARY KEY,
    product_code    VARCHAR(20)  NOT NULL UNIQUE,
    product_name    VARCHAR(100) NOT NULL,
    category_id     INT NOT NULL,
    brand_id        INT NOT NULL,
    cost_price      DECIMAL(10,2) NOT NULL,
    selling_price   DECIMAL(10,2) NOT NULL,
    stock_quantity  INT NOT NULL DEFAULT 0,
    reorder_level   INT NOT NULL DEFAULT 10,
    CONSTRAINT fk_product_category FOREIGN KEY (category_id) REFERENCES Category(category_id),
    CONSTRAINT fk_product_brand    FOREIGN KEY (brand_id)    REFERENCES Brand(brand_id),
    CONSTRAINT chk_cost_price     CHECK (cost_price > 0),
    CONSTRAINT chk_selling_price  CHECK (selling_price > 0),
    CONSTRAINT chk_stock_not_neg  CHECK (stock_quantity >= 0),
    CONSTRAINT chk_reorder_level  CHECK (reorder_level >= 0)
);

CREATE TABLE Purchase (
    purchase_id    INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id    INT NOT NULL,
    purchase_date  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_purchase_supplier FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id)
);

CREATE TABLE PurchaseItem (
    purchase_item_id  INT AUTO_INCREMENT PRIMARY KEY,
    purchase_id       INT NOT NULL,
    product_id        INT NOT NULL,
    quantity          INT NOT NULL,
    unit_cost         DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_pi_purchase FOREIGN KEY (purchase_id) REFERENCES Purchase(purchase_id),
    CONSTRAINT fk_pi_product  FOREIGN KEY (product_id)  REFERENCES Product(product_id),
    CONSTRAINT chk_pi_quantity  CHECK (quantity > 0),
    CONSTRAINT chk_pi_unit_cost CHECK (unit_cost > 0)
);

CREATE TABLE Sale (
    sale_id      INT AUTO_INCREMENT PRIMARY KEY,
    customer_id  INT NOT NULL,
    sale_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sale_customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

CREATE TABLE SaleItem (
    sale_item_id  INT AUTO_INCREMENT PRIMARY KEY,
    sale_id       INT NOT NULL,
    product_id    INT NOT NULL,
    quantity      INT NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_si_sale    FOREIGN KEY (sale_id)    REFERENCES Sale(sale_id),
    CONSTRAINT fk_si_product FOREIGN KEY (product_id) REFERENCES Product(product_id),
    CONSTRAINT chk_si_quantity   CHECK (quantity > 0),
    CONSTRAINT chk_si_unit_price CHECK (unit_price > 0)
);

CREATE TABLE Returns (
    return_id     INT AUTO_INCREMENT PRIMARY KEY,
    sale_item_id  INT NOT NULL,
    quantity      INT NOT NULL,
    return_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reason        VARCHAR(200),
    CONSTRAINT fk_return_saleitem FOREIGN KEY (sale_item_id) REFERENCES SaleItem(sale_item_id),
    CONSTRAINT chk_return_quantity CHECK (quantity > 0)
);

CREATE TABLE StockMovement (
    movement_id     INT AUTO_INCREMENT PRIMARY KEY,
    product_id      INT NOT NULL,
    movement_type   ENUM('IN','OUT') NOT NULL,
    source          ENUM('PURCHASE','SALE','RETURN') NOT NULL,
    quantity        INT NOT NULL,
    movement_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reference_id    INT NOT NULL,
    CONSTRAINT fk_sm_product FOREIGN KEY (product_id) REFERENCES Product(product_id),
    CONSTRAINT chk_sm_quantity CHECK (quantity > 0)
);

CREATE TABLE Invoice (
    invoice_id    INT AUTO_INCREMENT PRIMARY KEY,
    invoice_code  VARCHAR(20) NOT NULL UNIQUE,
    sale_id       INT NOT NULL UNIQUE,
    invoice_date  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount  DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_invoice_sale FOREIGN KEY (sale_id) REFERENCES Sale(sale_id),
    CONSTRAINT chk_invoice_total CHECK (total_amount >= 0)
);

CREATE TABLE Payment (
    payment_id      INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id      INT NOT NULL,
    amount          DECIMAL(12,2) NOT NULL,
    payment_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_method  ENUM('Cash','Card','UPI') NOT NULL DEFAULT 'Cash',
    CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id),
    CONSTRAINT chk_payment_amount CHECK (amount > 0)
);

CREATE INDEX idx_product_name   ON Product(product_name);
CREATE INDEX idx_customer_name  ON Customer(name);
CREATE INDEX idx_sale_date      ON Sale(sale_date);
CREATE INDEX idx_purchase_date  ON Purchase(purchase_date);
CREATE INDEX idx_stock_product_date ON StockMovement(product_id, movement_date);

-- Data: the same final data that schema.sql + sample_data.sql give (stock levels and stock history included)
SET FOREIGN_KEY_CHECKS = 0;
INSERT INTO `Brand` (`brand_id`, `brand_name`) VALUES (2,'Aashirvaad');
INSERT INTO `Brand` (`brand_id`, `brand_name`) VALUES (4,'Amul');
INSERT INTO `Brand` (`brand_id`, `brand_name`) VALUES (5,'Britannia');
INSERT INTO `Brand` (`brand_id`, `brand_name`) VALUES (11,'Coca-Cola');
INSERT INTO `Brand` (`brand_id`, `brand_name`) VALUES (8,'Colgate');
INSERT INTO `Brand` (`brand_id`, `brand_name`) VALUES (9,'Dettol');
INSERT INTO `Brand` (`brand_id`, `brand_name`) VALUES (3,'Fortune');
INSERT INTO `Brand` (`brand_id`, `brand_name`) VALUES (12,'Haldiram\'s');
INSERT INTO `Brand` (`brand_id`, `brand_name`) VALUES (7,'Nestle');
INSERT INTO `Brand` (`brand_id`, `brand_name`) VALUES (6,'Parle');
INSERT INTO `Brand` (`brand_id`, `brand_name`) VALUES (10,'Surf Excel');
INSERT INTO `Brand` (`brand_id`, `brand_name`) VALUES (1,'Tata');
INSERT INTO `Category` (`category_id`, `category_name`) VALUES (2,'Beverages');
INSERT INTO `Category` (`category_id`, `category_name`) VALUES (6,'Dairy');
INSERT INTO `Category` (`category_id`, `category_name`) VALUES (1,'Grocery');
INSERT INTO `Category` (`category_id`, `category_name`) VALUES (5,'Household');
INSERT INTO `Category` (`category_id`, `category_name`) VALUES (4,'Personal Care');
INSERT INTO `Category` (`category_id`, `category_name`) VALUES (3,'Snacks');
INSERT INTO `Customer` (`customer_id`, `name`, `phone`, `email`) VALUES (1,'Walk-in Customer',NULL,NULL);
INSERT INTO `Customer` (`customer_id`, `name`, `phone`, `email`) VALUES (2,'Ravi Kumar','9876500001','ravi.kumar@gmail.com');
INSERT INTO `Customer` (`customer_id`, `name`, `phone`, `email`) VALUES (3,'Sneha Reddy','9876500002','sneha.reddy@gmail.com');
INSERT INTO `Customer` (`customer_id`, `name`, `phone`, `email`) VALUES (4,'Mohammed Imran','9876500003',NULL);
INSERT INTO `Customer` (`customer_id`, `name`, `phone`, `email`) VALUES (5,'Anjali Sharma','9876500004','anjali.sharma@yahoo.com');
INSERT INTO `Customer` (`customer_id`, `name`, `phone`, `email`) VALUES (6,'Venkat Rao','9876500005',NULL);
INSERT INTO `Customer` (`customer_id`, `name`, `phone`, `email`) VALUES (7,'Fatima Begum','9876500006','fatima.b@gmail.com');
INSERT INTO `Customer` (`customer_id`, `name`, `phone`, `email`) VALUES (8,'Kiran Patel','9876500007',NULL);
INSERT INTO `Customer` (`customer_id`, `name`, `phone`, `email`) VALUES (9,'Priya Nair','9876500008','priya.nair@gmail.com');
INSERT INTO `Customer` (`customer_id`, `name`, `phone`, `email`) VALUES (10,'Suresh Babu','9876500009',NULL);
INSERT INTO `Customer` (`customer_id`, `name`, `phone`, `email`) VALUES (11,'Lakshmi Devi','9876500010','lakshmi.devi@gmail.com');
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (1,'INV-0001',1,'2026-08-05 10:53:00',245.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (2,'INV-0002',2,'2026-08-05 11:46:00',611.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (3,'INV-0003',3,'2026-08-07 12:39:00',675.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (4,'INV-0004',4,'2026-08-08 13:32:00',645.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (5,'INV-0005',5,'2026-08-10 14:25:00',479.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (6,'INV-0006',6,'2026-08-12 15:18:00',1467.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (7,'INV-0007',7,'2026-08-14 16:11:00',390.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (8,'INV-0008',8,'2026-08-16 17:04:00',725.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (9,'INV-0009',9,'2026-08-18 17:57:00',615.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (10,'INV-0010',10,'2026-08-20 10:50:00',1345.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (11,'INV-0011',11,'2026-08-22 11:43:00',785.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (12,'INV-0012',12,'2026-08-25 12:36:00',489.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (13,'INV-0013',13,'2026-08-28 13:29:00',893.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (14,'INV-0014',14,'2026-08-30 14:22:00',390.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (15,'INV-0015',15,'2026-09-02 15:15:00',1200.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (16,'INV-0016',16,'2026-09-03 16:08:00',1900.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (17,'INV-0017',17,'2026-09-05 17:01:00',675.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (18,'INV-0018',18,'2026-09-07 17:54:00',1450.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (19,'INV-0019',19,'2026-09-09 10:47:00',860.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (20,'INV-0020',20,'2026-09-11 11:40:00',1070.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (21,'INV-0021',21,'2026-09-13 12:33:00',1925.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (22,'INV-0022',22,'2026-09-15 13:26:00',663.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (23,'INV-0023',23,'2026-09-17 14:19:00',2330.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (24,'INV-0024',24,'2026-09-19 15:12:00',1062.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (25,'INV-0025',25,'2026-09-21 16:05:00',1135.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (26,'INV-0026',26,'2026-09-23 16:58:00',1725.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (27,'INV-0027',27,'2026-09-25 17:51:00',1410.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (28,'INV-0028',28,'2026-09-27 10:44:00',1470.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (29,'INV-0029',29,'2026-09-28 11:37:00',1768.00);
INSERT INTO `Invoice` (`invoice_id`, `invoice_code`, `sale_id`, `invoice_date`, `total_amount`) VALUES (30,'INV-0030',30,'2026-09-30 12:30:00',1655.00);
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (1,1,245.00,'2026-08-05 10:53:00','UPI');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (2,2,611.00,'2026-08-05 11:46:00','Card');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (3,3,675.00,'2026-08-07 12:39:00','Cash');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (4,4,645.00,'2026-08-08 13:32:00','UPI');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (5,5,479.00,'2026-08-10 14:25:00','Card');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (6,7,390.00,'2026-08-14 16:11:00','UPI');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (7,8,725.00,'2026-08-16 17:04:00','Card');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (8,9,615.00,'2026-08-18 17:57:00','Cash');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (9,10,1345.00,'2026-08-20 10:50:00','UPI');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (10,11,785.00,'2026-08-22 11:43:00','Card');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (11,12,489.00,'2026-08-25 12:36:00','Cash');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (12,13,893.00,'2026-08-28 13:29:00','UPI');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (13,14,390.00,'2026-08-30 14:22:00','Card');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (14,15,1200.00,'2026-09-02 15:15:00','Cash');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (15,17,675.00,'2026-09-05 17:01:00','Card');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (16,18,1450.00,'2026-09-07 17:54:00','Cash');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (17,19,860.00,'2026-09-09 10:47:00','UPI');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (18,20,1070.00,'2026-09-11 11:40:00','Card');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (19,21,1925.00,'2026-09-13 12:33:00','Cash');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (20,22,663.00,'2026-09-15 13:26:00','UPI');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (21,24,1062.00,'2026-09-19 15:12:00','Cash');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (22,25,1135.00,'2026-09-21 16:05:00','UPI');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (23,27,1410.00,'2026-09-25 17:51:00','Cash');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (32,6,733.50,'2026-08-12 15:18:00','UPI');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (33,16,950.00,'2026-09-03 16:08:00','UPI');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (34,23,1165.00,'2026-09-17 14:19:00','UPI');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (35,6,733.50,'2026-08-19 15:18:00','Cash');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (36,16,950.00,'2026-09-10 16:08:00','Cash');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (37,23,1165.00,'2026-09-24 14:19:00','Cash');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (38,26,1035.00,'2026-09-23 16:58:00','Cash');
INSERT INTO `Payment` (`payment_id`, `invoice_id`, `amount`, `payment_date`, `payment_method`) VALUES (39,28,588.00,'2026-09-27 10:44:00','Cash');
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (1,'P001','Tata Salt 1kg',1,1,20.00,28.00,125,20);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (2,'P002','Aashirvaad Atta 5kg',1,2,230.00,265.00,80,15);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (3,'P003','Fortune Sunflower Oil 1L',1,3,125.00,145.00,109,20);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (4,'P004','Tata Tea Gold 500g',1,1,210.00,245.00,33,10);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (5,'P005','Tata Sampann Toor Dal 1kg',1,1,120.00,150.00,43,15);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (6,'P006','Amul Butter 500g',6,4,250.00,285.00,39,10);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (7,'P007','Amul Toned Milk 1L',6,4,52.00,60.00,139,30);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (8,'P008','Amul Cheese Slices 200g',6,4,110.00,130.00,20,10);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (9,'P009','Britannia Good Day 200g',3,5,28.00,40.00,128,25);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (10,'P010','Britannia Bread 400g',1,5,32.00,45.00,8,15);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (11,'P011','Parle-G Biscuits 800g',3,6,55.00,75.00,95,20);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (12,'P012','Haldiram\'s Aloo Bhujia 400g',3,12,85.00,115.00,13,15);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (13,'P013','Maggi Noodles 12-pack',3,7,140.00,170.00,79,20);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (14,'P014','Nescafe Classic 100g',2,7,255.00,310.00,8,10);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (15,'P015','Coca-Cola 2L',2,11,70.00,95.00,47,20);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (16,'P016','Colgate Toothpaste 200g',4,8,85.00,115.00,33,15);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (17,'P017','Dettol Handwash 250ml',4,9,70.00,99.00,12,15);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (18,'P018','Dettol Soap 3-pack',4,9,95.00,135.00,26,15);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (19,'P019','Surf Excel Powder 1kg',5,10,190.00,230.00,38,15);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (20,'P020','Surf Excel Liquid 1L',5,10,215.00,265.00,18,10);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (21,'P021','Colgate Toothbrush 2-pack',4,8,40.00,65.00,38,20);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (22,'P022','Dettol Floor Cleaner 500ml',5,9,85.00,120.00,7,10);
INSERT INTO `Product` (`product_id`, `product_code`, `product_name`, `category_id`, `brand_id`, `cost_price`, `selling_price`, `stock_quantity`, `reorder_level`) VALUES (23,'P023','Parle Hide & Seek 200g',3,6,30.00,45.00,20,15);
INSERT INTO `Purchase` (`purchase_id`, `supplier_id`, `purchase_date`) VALUES (1,1,'2026-08-01 09:30:00');
INSERT INTO `Purchase` (`purchase_id`, `supplier_id`, `purchase_date`) VALUES (2,2,'2026-08-01 11:00:00');
INSERT INTO `Purchase` (`purchase_id`, `supplier_id`, `purchase_date`) VALUES (3,4,'2026-08-02 10:15:00');
INSERT INTO `Purchase` (`purchase_id`, `supplier_id`, `purchase_date`) VALUES (4,3,'2026-08-03 12:00:00');
INSERT INTO `Purchase` (`purchase_id`, `supplier_id`, `purchase_date`) VALUES (5,5,'2026-08-04 15:30:00');
INSERT INTO `Purchase` (`purchase_id`, `supplier_id`, `purchase_date`) VALUES (6,1,'2026-09-01 09:45:00');
INSERT INTO `Purchase` (`purchase_id`, `supplier_id`, `purchase_date`) VALUES (7,4,'2026-09-05 10:30:00');
INSERT INTO `Purchase` (`purchase_id`, `supplier_id`, `purchase_date`) VALUES (8,2,'2026-09-10 11:15:00');
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (1,1,1,100,20.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (2,1,2,60,230.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (3,1,3,80,125.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (4,1,5,50,120.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (5,2,9,120,28.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (6,2,10,30,32.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (7,2,11,80,55.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (8,2,12,30,85.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (9,2,23,20,30.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (10,2,13,70,140.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (11,3,6,30,250.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (12,3,7,120,52.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (13,3,8,25,110.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (14,4,4,40,210.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (15,4,14,14,255.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (16,4,15,60,70.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (17,5,16,40,85.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (18,5,17,20,70.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (19,5,18,30,95.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (20,5,19,40,190.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (21,5,20,20,215.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (22,5,21,50,40.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (23,5,22,9,85.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (24,6,1,50,20.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (25,6,3,40,125.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (26,6,2,30,230.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (27,7,7,80,52.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (28,7,6,15,250.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (29,8,11,40,55.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (30,8,13,30,140.00);
INSERT INTO `PurchaseItem` (`purchase_item_id`, `purchase_id`, `product_id`, `quantity`, `unit_cost`) VALUES (31,8,9,50,28.00);
INSERT INTO `Returns` (`return_id`, `sale_item_id`, `quantity`, `return_date`, `reason`) VALUES (1,8,1,'2026-08-08 12:00:00','Bought by mistake');
INSERT INTO `Returns` (`return_id`, `sale_item_id`, `quantity`, `return_date`, `reason`) VALUES (2,18,1,'2026-08-14 12:00:00','Customer changed mind');
INSERT INTO `Returns` (`return_id`, `sale_item_id`, `quantity`, `return_date`, `reason`) VALUES (3,45,1,'2026-08-30 12:00:00','Wrong size ordered');
INSERT INTO `Returns` (`return_id`, `sale_item_id`, `quantity`, `return_date`, `reason`) VALUES (4,57,1,'2026-09-05 12:00:00','Wrong size ordered');
INSERT INTO `Returns` (`return_id`, `sale_item_id`, `quantity`, `return_date`, `reason`) VALUES (5,68,1,'2026-09-13 12:00:00','Bought by mistake');
INSERT INTO `Returns` (`return_id`, `sale_item_id`, `quantity`, `return_date`, `reason`) VALUES (6,90,2,'2026-09-23 12:00:00','Customer changed mind');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (1,1,'2026-08-05 10:53:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (2,2,'2026-08-05 11:46:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (3,3,'2026-08-07 12:39:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (4,1,'2026-08-08 13:32:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (5,4,'2026-08-10 14:25:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (6,5,'2026-08-12 15:18:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (7,1,'2026-08-14 16:11:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (8,6,'2026-08-16 17:04:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (9,7,'2026-08-18 17:57:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (10,1,'2026-08-20 10:50:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (11,8,'2026-08-22 11:43:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (12,2,'2026-08-25 12:36:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (13,9,'2026-08-28 13:29:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (14,1,'2026-08-30 14:22:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (15,3,'2026-09-02 15:15:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (16,10,'2026-09-03 16:08:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (17,1,'2026-09-05 17:01:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (18,5,'2026-09-07 17:54:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (19,1,'2026-09-09 10:47:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (20,6,'2026-09-11 11:40:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (21,7,'2026-09-13 12:33:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (22,1,'2026-09-15 13:26:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (23,4,'2026-09-17 14:19:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (24,8,'2026-09-19 15:12:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (25,1,'2026-09-21 16:05:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (26,9,'2026-09-23 16:58:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (27,2,'2026-09-25 17:51:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (28,1,'2026-09-27 10:44:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (29,10,'2026-09-28 11:37:00');
INSERT INTO `Sale` (`sale_id`, `customer_id`, `sale_date`) VALUES (30,1,'2026-09-30 12:30:00');
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (1,1,7,2,60.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (2,1,10,1,45.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (3,1,9,2,40.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (4,2,2,1,265.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (5,2,3,1,140.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (6,2,1,2,28.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (7,2,5,1,150.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (8,3,7,4,60.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (9,3,6,1,285.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (10,3,11,2,75.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (11,4,15,2,95.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (12,4,12,1,115.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (13,4,13,2,170.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (14,5,16,1,115.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (15,5,17,1,99.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (16,5,18,1,135.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (17,5,21,2,65.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (18,6,2,2,265.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (19,6,3,2,140.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (20,6,1,4,28.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (21,6,5,2,150.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (22,6,4,1,245.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (23,7,7,3,60.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (24,7,9,3,40.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (25,7,10,2,45.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (26,8,14,1,310.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (27,8,8,1,130.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (28,8,6,1,285.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (29,9,19,1,230.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (30,9,20,1,265.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (31,9,22,1,120.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (32,10,13,4,170.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (33,10,12,3,115.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (34,10,11,3,75.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (35,10,15,1,95.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (36,11,7,6,60.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (37,11,10,3,45.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (38,11,9,4,40.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (39,11,8,1,130.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (40,12,2,1,265.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (41,12,1,3,28.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (42,12,3,1,140.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (43,13,16,2,115.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (44,13,17,2,99.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (45,13,18,2,135.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (46,13,21,3,65.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (47,14,7,2,60.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (48,14,9,2,40.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (49,14,15,2,95.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (50,15,7,5,60.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (51,15,10,2,45.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (52,15,11,4,75.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (53,15,13,3,170.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (54,16,2,2,265.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (55,16,3,2,145.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (56,16,1,5,28.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (57,16,5,3,150.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (58,16,4,2,245.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (59,17,9,4,40.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (60,17,12,2,115.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (61,17,15,3,95.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (62,18,14,2,310.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (63,18,6,2,285.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (64,18,8,2,130.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (65,19,7,8,60.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (66,19,10,4,45.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (67,19,9,5,40.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (68,20,19,2,230.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (69,20,22,1,120.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (70,20,21,4,65.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (71,20,16,2,115.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (72,21,13,5,170.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (73,21,11,5,75.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (74,21,12,4,115.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (75,21,9,6,40.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (76,22,7,6,60.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (77,22,1,6,28.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (78,22,10,3,45.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (79,23,2,3,265.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (80,23,3,3,145.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (81,23,5,2,150.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (82,23,4,2,245.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (83,23,14,1,310.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (84,24,17,3,99.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (85,24,18,2,135.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (86,24,16,2,115.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (87,24,20,1,265.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (88,25,7,7,60.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (89,25,9,5,40.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (90,25,15,4,95.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (91,25,10,3,45.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (92,26,6,2,285.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (93,26,8,1,130.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (94,26,13,4,170.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (95,26,12,3,115.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (96,27,1,5,28.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (97,27,3,2,145.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (98,27,2,2,265.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (99,27,11,6,75.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (100,28,7,9,60.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (101,28,9,6,40.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (102,28,10,4,45.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (103,28,13,3,170.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (104,29,14,2,310.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (105,29,4,2,245.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (106,29,17,2,99.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (107,29,12,4,115.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (108,30,7,10,60.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (109,30,11,5,75.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (110,30,9,5,40.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (111,30,15,3,95.00);
INSERT INTO `SaleItem` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES (112,30,21,3,65.00);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (1,1,'IN','PURCHASE',100,'2026-08-01 09:30:00',1);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (2,2,'IN','PURCHASE',60,'2026-08-01 09:30:00',1);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (3,3,'IN','PURCHASE',80,'2026-08-01 09:30:00',1);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (4,5,'IN','PURCHASE',50,'2026-08-01 09:30:00',1);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (5,9,'IN','PURCHASE',120,'2026-08-01 11:00:00',2);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (6,10,'IN','PURCHASE',30,'2026-08-01 11:00:00',2);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (7,11,'IN','PURCHASE',80,'2026-08-01 11:00:00',2);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (8,12,'IN','PURCHASE',30,'2026-08-01 11:00:00',2);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (9,23,'IN','PURCHASE',20,'2026-08-01 11:00:00',2);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (10,13,'IN','PURCHASE',70,'2026-08-01 11:00:00',2);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (11,6,'IN','PURCHASE',30,'2026-08-02 10:15:00',3);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (12,7,'IN','PURCHASE',120,'2026-08-02 10:15:00',3);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (13,8,'IN','PURCHASE',25,'2026-08-02 10:15:00',3);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (14,4,'IN','PURCHASE',40,'2026-08-03 12:00:00',4);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (15,14,'IN','PURCHASE',14,'2026-08-03 12:00:00',4);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (16,15,'IN','PURCHASE',60,'2026-08-03 12:00:00',4);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (17,16,'IN','PURCHASE',40,'2026-08-04 15:30:00',5);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (18,17,'IN','PURCHASE',20,'2026-08-04 15:30:00',5);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (19,18,'IN','PURCHASE',30,'2026-08-04 15:30:00',5);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (20,19,'IN','PURCHASE',40,'2026-08-04 15:30:00',5);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (21,20,'IN','PURCHASE',20,'2026-08-04 15:30:00',5);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (22,21,'IN','PURCHASE',50,'2026-08-04 15:30:00',5);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (23,22,'IN','PURCHASE',9,'2026-08-04 15:30:00',5);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (24,1,'IN','PURCHASE',50,'2026-09-01 09:45:00',6);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (25,3,'IN','PURCHASE',40,'2026-09-01 09:45:00',6);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (26,2,'IN','PURCHASE',30,'2026-09-01 09:45:00',6);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (27,7,'IN','PURCHASE',80,'2026-09-05 10:30:00',7);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (28,6,'IN','PURCHASE',15,'2026-09-05 10:30:00',7);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (29,11,'IN','PURCHASE',40,'2026-09-10 11:15:00',8);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (30,13,'IN','PURCHASE',30,'2026-09-10 11:15:00',8);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (31,9,'IN','PURCHASE',50,'2026-09-10 11:15:00',8);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (32,7,'OUT','SALE',2,'2026-08-05 10:53:00',1);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (33,10,'OUT','SALE',1,'2026-08-05 10:53:00',1);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (34,9,'OUT','SALE',2,'2026-08-05 10:53:00',1);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (35,2,'OUT','SALE',1,'2026-08-05 11:46:00',2);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (36,3,'OUT','SALE',1,'2026-08-05 11:46:00',2);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (37,1,'OUT','SALE',2,'2026-08-05 11:46:00',2);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (38,5,'OUT','SALE',1,'2026-08-05 11:46:00',2);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (39,7,'OUT','SALE',4,'2026-08-07 12:39:00',3);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (40,6,'OUT','SALE',1,'2026-08-07 12:39:00',3);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (41,11,'OUT','SALE',2,'2026-08-07 12:39:00',3);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (42,15,'OUT','SALE',2,'2026-08-08 13:32:00',4);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (43,12,'OUT','SALE',1,'2026-08-08 13:32:00',4);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (44,13,'OUT','SALE',2,'2026-08-08 13:32:00',4);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (45,16,'OUT','SALE',1,'2026-08-10 14:25:00',5);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (46,17,'OUT','SALE',1,'2026-08-10 14:25:00',5);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (47,18,'OUT','SALE',1,'2026-08-10 14:25:00',5);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (48,21,'OUT','SALE',2,'2026-08-10 14:25:00',5);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (49,2,'OUT','SALE',2,'2026-08-12 15:18:00',6);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (50,3,'OUT','SALE',2,'2026-08-12 15:18:00',6);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (51,1,'OUT','SALE',4,'2026-08-12 15:18:00',6);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (52,5,'OUT','SALE',2,'2026-08-12 15:18:00',6);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (53,4,'OUT','SALE',1,'2026-08-12 15:18:00',6);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (54,7,'OUT','SALE',3,'2026-08-14 16:11:00',7);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (55,9,'OUT','SALE',3,'2026-08-14 16:11:00',7);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (56,10,'OUT','SALE',2,'2026-08-14 16:11:00',7);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (57,14,'OUT','SALE',1,'2026-08-16 17:04:00',8);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (58,8,'OUT','SALE',1,'2026-08-16 17:04:00',8);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (59,6,'OUT','SALE',1,'2026-08-16 17:04:00',8);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (60,19,'OUT','SALE',1,'2026-08-18 17:57:00',9);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (61,20,'OUT','SALE',1,'2026-08-18 17:57:00',9);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (62,22,'OUT','SALE',1,'2026-08-18 17:57:00',9);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (63,13,'OUT','SALE',4,'2026-08-20 10:50:00',10);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (64,12,'OUT','SALE',3,'2026-08-20 10:50:00',10);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (65,11,'OUT','SALE',3,'2026-08-20 10:50:00',10);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (66,15,'OUT','SALE',1,'2026-08-20 10:50:00',10);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (67,7,'OUT','SALE',6,'2026-08-22 11:43:00',11);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (68,10,'OUT','SALE',3,'2026-08-22 11:43:00',11);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (69,9,'OUT','SALE',4,'2026-08-22 11:43:00',11);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (70,8,'OUT','SALE',1,'2026-08-22 11:43:00',11);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (71,2,'OUT','SALE',1,'2026-08-25 12:36:00',12);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (72,1,'OUT','SALE',3,'2026-08-25 12:36:00',12);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (73,3,'OUT','SALE',1,'2026-08-25 12:36:00',12);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (74,16,'OUT','SALE',2,'2026-08-28 13:29:00',13);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (75,17,'OUT','SALE',2,'2026-08-28 13:29:00',13);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (76,18,'OUT','SALE',2,'2026-08-28 13:29:00',13);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (77,21,'OUT','SALE',3,'2026-08-28 13:29:00',13);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (78,7,'OUT','SALE',2,'2026-08-30 14:22:00',14);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (79,9,'OUT','SALE',2,'2026-08-30 14:22:00',14);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (80,15,'OUT','SALE',2,'2026-08-30 14:22:00',14);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (81,7,'OUT','SALE',5,'2026-09-02 15:15:00',15);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (82,10,'OUT','SALE',2,'2026-09-02 15:15:00',15);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (83,11,'OUT','SALE',4,'2026-09-02 15:15:00',15);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (84,13,'OUT','SALE',3,'2026-09-02 15:15:00',15);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (85,2,'OUT','SALE',2,'2026-09-03 16:08:00',16);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (86,3,'OUT','SALE',2,'2026-09-03 16:08:00',16);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (87,1,'OUT','SALE',5,'2026-09-03 16:08:00',16);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (88,5,'OUT','SALE',3,'2026-09-03 16:08:00',16);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (89,4,'OUT','SALE',2,'2026-09-03 16:08:00',16);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (90,9,'OUT','SALE',4,'2026-09-05 17:01:00',17);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (91,12,'OUT','SALE',2,'2026-09-05 17:01:00',17);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (92,15,'OUT','SALE',3,'2026-09-05 17:01:00',17);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (93,14,'OUT','SALE',2,'2026-09-07 17:54:00',18);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (94,6,'OUT','SALE',2,'2026-09-07 17:54:00',18);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (95,8,'OUT','SALE',2,'2026-09-07 17:54:00',18);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (96,7,'OUT','SALE',8,'2026-09-09 10:47:00',19);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (97,10,'OUT','SALE',4,'2026-09-09 10:47:00',19);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (98,9,'OUT','SALE',5,'2026-09-09 10:47:00',19);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (99,19,'OUT','SALE',2,'2026-09-11 11:40:00',20);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (100,22,'OUT','SALE',1,'2026-09-11 11:40:00',20);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (101,21,'OUT','SALE',4,'2026-09-11 11:40:00',20);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (102,16,'OUT','SALE',2,'2026-09-11 11:40:00',20);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (103,13,'OUT','SALE',5,'2026-09-13 12:33:00',21);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (104,11,'OUT','SALE',5,'2026-09-13 12:33:00',21);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (105,12,'OUT','SALE',4,'2026-09-13 12:33:00',21);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (106,9,'OUT','SALE',6,'2026-09-13 12:33:00',21);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (107,7,'OUT','SALE',6,'2026-09-15 13:26:00',22);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (108,1,'OUT','SALE',6,'2026-09-15 13:26:00',22);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (109,10,'OUT','SALE',3,'2026-09-15 13:26:00',22);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (110,2,'OUT','SALE',3,'2026-09-17 14:19:00',23);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (111,3,'OUT','SALE',3,'2026-09-17 14:19:00',23);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (112,5,'OUT','SALE',2,'2026-09-17 14:19:00',23);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (113,4,'OUT','SALE',2,'2026-09-17 14:19:00',23);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (114,14,'OUT','SALE',1,'2026-09-17 14:19:00',23);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (115,17,'OUT','SALE',3,'2026-09-19 15:12:00',24);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (116,18,'OUT','SALE',2,'2026-09-19 15:12:00',24);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (117,16,'OUT','SALE',2,'2026-09-19 15:12:00',24);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (118,20,'OUT','SALE',1,'2026-09-19 15:12:00',24);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (119,7,'OUT','SALE',7,'2026-09-21 16:05:00',25);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (120,9,'OUT','SALE',5,'2026-09-21 16:05:00',25);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (121,15,'OUT','SALE',4,'2026-09-21 16:05:00',25);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (122,10,'OUT','SALE',3,'2026-09-21 16:05:00',25);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (123,6,'OUT','SALE',2,'2026-09-23 16:58:00',26);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (124,8,'OUT','SALE',1,'2026-09-23 16:58:00',26);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (125,13,'OUT','SALE',4,'2026-09-23 16:58:00',26);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (126,12,'OUT','SALE',3,'2026-09-23 16:58:00',26);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (127,1,'OUT','SALE',5,'2026-09-25 17:51:00',27);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (128,3,'OUT','SALE',2,'2026-09-25 17:51:00',27);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (129,2,'OUT','SALE',2,'2026-09-25 17:51:00',27);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (130,11,'OUT','SALE',6,'2026-09-25 17:51:00',27);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (131,7,'OUT','SALE',9,'2026-09-27 10:44:00',28);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (132,9,'OUT','SALE',6,'2026-09-27 10:44:00',28);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (133,10,'OUT','SALE',4,'2026-09-27 10:44:00',28);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (134,13,'OUT','SALE',3,'2026-09-27 10:44:00',28);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (135,14,'OUT','SALE',2,'2026-09-28 11:37:00',29);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (136,4,'OUT','SALE',2,'2026-09-28 11:37:00',29);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (137,17,'OUT','SALE',2,'2026-09-28 11:37:00',29);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (138,12,'OUT','SALE',4,'2026-09-28 11:37:00',29);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (139,7,'OUT','SALE',10,'2026-09-30 12:30:00',30);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (140,11,'OUT','SALE',5,'2026-09-30 12:30:00',30);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (141,9,'OUT','SALE',5,'2026-09-30 12:30:00',30);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (142,15,'OUT','SALE',3,'2026-09-30 12:30:00',30);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (143,21,'OUT','SALE',3,'2026-09-30 12:30:00',30);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (144,7,'IN','RETURN',1,'2026-08-08 12:00:00',1);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (145,2,'IN','RETURN',1,'2026-08-14 12:00:00',2);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (146,18,'IN','RETURN',1,'2026-08-30 12:00:00',3);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (147,5,'IN','RETURN',1,'2026-09-05 12:00:00',4);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (148,19,'IN','RETURN',1,'2026-09-13 12:00:00',5);
INSERT INTO `StockMovement` (`movement_id`, `product_id`, `movement_type`, `source`, `quantity`, `movement_date`, `reference_id`) VALUES (149,15,'IN','RETURN',2,'2026-09-23 12:00:00',6);
INSERT INTO `Supplier` (`supplier_id`, `name`, `phone`, `address`) VALUES (1,'Sri Lakshmi Wholesale Traders','9848011111','Begum Bazaar, Hyderabad');
INSERT INTO `Supplier` (`supplier_id`, `name`, `phone`, `address`) VALUES (2,'Balaji Distributors','9848022222','Secunderabad, Hyderabad');
INSERT INTO `Supplier` (`supplier_id`, `name`, `phone`, `address`) VALUES (3,'Metro FMCG Suppliers','9848033333','Kukatpally, Hyderabad');
INSERT INTO `Supplier` (`supplier_id`, `name`, `phone`, `address`) VALUES (4,'Amul Dairy Depot','9848044444','Nampally, Hyderabad');
INSERT INTO `Supplier` (`supplier_id`, `name`, `phone`, `address`) VALUES (5,'Hindustan Home Care Agency','9848055555','Ameerpet, Hyderabad');
SET FOREIGN_KEY_CHECKS = 1;

-- Reports
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
