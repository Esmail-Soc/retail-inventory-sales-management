DROP DATABASE IF EXISTS retail_store;
CREATE DATABASE retail_store;
USE retail_store;

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

DELIMITER //

CREATE TRIGGER trg_purchaseitem_after_insert
AFTER INSERT ON PurchaseItem
FOR EACH ROW
BEGIN
    DECLARE buy_date DATETIME;

    SELECT purchase_date INTO buy_date
    FROM Purchase
    WHERE purchase_id = NEW.purchase_id;

    UPDATE Product
    SET stock_quantity = stock_quantity + NEW.quantity
    WHERE product_id = NEW.product_id;

    INSERT INTO StockMovement (product_id, movement_type, source, quantity, movement_date, reference_id)
    VALUES (NEW.product_id, 'IN', 'PURCHASE', NEW.quantity, buy_date, NEW.purchase_id);
END//

CREATE TRIGGER trg_saleitem_before_insert
BEFORE INSERT ON SaleItem
FOR EACH ROW
BEGIN
    DECLARE current_stock INT;

    SELECT stock_quantity INTO current_stock
    FROM Product
    WHERE product_id = NEW.product_id;

    IF current_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Not enough stock for this product';
    END IF;
END//

CREATE TRIGGER trg_saleitem_after_insert
AFTER INSERT ON SaleItem
FOR EACH ROW
BEGIN
    DECLARE selling_date DATETIME;

    SELECT sale_date INTO selling_date
    FROM Sale
    WHERE sale_id = NEW.sale_id;

    UPDATE Product
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id;

    INSERT INTO StockMovement (product_id, movement_type, source, quantity, movement_date, reference_id)
    VALUES (NEW.product_id, 'OUT', 'SALE', NEW.quantity, selling_date, NEW.sale_id);
END//

CREATE TRIGGER trg_returns_before_insert
BEFORE INSERT ON Returns
FOR EACH ROW
BEGIN
    DECLARE sold_qty INT;
    DECLARE already_returned INT;

    SELECT quantity INTO sold_qty
    FROM SaleItem
    WHERE sale_item_id = NEW.sale_item_id;

    SELECT COALESCE(SUM(quantity), 0) INTO already_returned
    FROM Returns
    WHERE sale_item_id = NEW.sale_item_id;

    IF already_returned + NEW.quantity > sold_qty THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Return quantity is more than the quantity sold';
    END IF;
END//

CREATE TRIGGER trg_returns_after_insert
AFTER INSERT ON Returns
FOR EACH ROW
BEGIN
    DECLARE prod_id INT;

    SELECT product_id INTO prod_id
    FROM SaleItem
    WHERE sale_item_id = NEW.sale_item_id;

    UPDATE Product
    SET stock_quantity = stock_quantity + NEW.quantity
    WHERE product_id = prod_id;

    INSERT INTO StockMovement (product_id, movement_type, source, quantity, movement_date, reference_id)
    VALUES (prod_id, 'IN', 'RETURN', NEW.quantity, NEW.return_date, NEW.return_id);
END//

CREATE TRIGGER trg_payment_before_insert
BEFORE INSERT ON Payment
FOR EACH ROW
BEGIN
    DECLARE invoice_total DECIMAL(12,2);
    DECLARE already_paid DECIMAL(12,2);

    SELECT total_amount INTO invoice_total
    FROM Invoice
    WHERE invoice_id = NEW.invoice_id;

    SELECT COALESCE(SUM(amount), 0) INTO already_paid
    FROM Payment
    WHERE invoice_id = NEW.invoice_id;

    IF already_paid + NEW.amount > invoice_total THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment is more than the invoice amount';
    END IF;
END//

DELIMITER ;
