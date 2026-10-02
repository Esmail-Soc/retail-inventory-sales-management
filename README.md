# Retail Inventory and Sales Management System



## 📌 Executive Summary

A relational database and web interface for a small retail store. The database stores products, stock, customers, supplier purchases, sales invoices, returns and payments. Database triggers keep the stock correct and enforce the business rules (stock, return and payment limits) whenever a purchase, sale or return is recorded. The web interface lets you manage products and view stock, customers, invoices, returns, payments and reports.



Developed as an academic database project at **Woxsen University**, focusing on data integrity, SQL and basic application security.



This is a classroom project that runs on one computer. The data is made up. It is not a production system (see Security and Known Limits).



---



## 🏗️ Database Design

* **13 tables:** `Category`, `Brand`, `Supplier`, `Customer`, `Product`, `Purchase`, `PurchaseItem`, `Sale`, `SaleItem`, `Returns`, `StockMovement`, `Invoice`, `Payment`. *(`Returns` is plural because `RETURN` is a reserved word in MySQL.)*

* **Constraints:** primary and foreign keys, unique product and invoice codes, CHECK rules (positive prices and quantities, stock never below zero). Foreign keys restrict deletes: a record that is used elsewhere cannot be deleted.

* **6 triggers:** a purchase adds stock, a sale removes stock, a return puts stock back, and every change is written to `StockMovement`. A sale cannot exceed the stock, a return cannot exceed the quantity sold, and payments cannot exceed the invoice amount.

* **5 indexes** on frequently searched columns.

* **9 views:** low stock, stock valuation, supplier purchases, daily sales, monthly sales, returns, fast moving items, profit, pending payments.

* **Normalization:** designed toward 3NF. Two values are stored on purpose: `Product.stock_quantity` (kept in sync by the triggers) and `Invoice.total_amount`.

* **Sample data (made up):** 23 products, 5 suppliers, 11 customers, 8 purchases, 30 sales with invoices and payments (some unpaid), 6 returns.



---



## 🛠️ Tech Stack

* **Database:** MySQL 8.0.16 or newer (CHECK rules are enforced from this version)

* **Backend:** Python 3 (tested with 3.12 and 3.14), Flask, `mysql-connector-python`

* **Frontend:** Jinja templates, HTML, CSS

* **Tests:** 85 automated tests, run on a separate test database



---



## 🔐 Security

**Controls in the web interface**

* Server-side validation of every form field, and of the report filters

* All user-supplied values are passed as SQL query parameters (tested with SQL injection strings)

* Jinja auto-escaping of all output (tested with a `<script>` tag in a product name)

* A CSRF token (one per session) is checked on every POST request

* The MySQL password is typed at start-up (or read from the `RETAIL_DB_PASSWORD` environment variable) and is never stored in a file

* Saving a product together with a new category or brand is all-or-nothing (one transaction)

* The server listens on `127.0.0.1` only, with debug mode off, so errors never show code or stack traces



**Known limits (a classroom project, not production)**

* No login and no user roles. Anyone who can open the page on that computer can add, change or delete products.

* Flask development server, plain HTTP, no rate limiting and no extra security headers.

* Editing and deleting products is not logged. `StockMovement` records stock changes only, not who made them, so it is not a security audit log.

* The setup gives the MySQL user all privileges on `retail_store`. A user with only SELECT, INSERT, UPDATE and DELETE would be safer. This was not tested.

* The return and payment limits are checked by triggers without locking rows. Two people returning the same item, or paying the same invoice, at the exact same moment could both pass the check. This was found in testing and not fixed, because the interface cannot enter returns or payments. Stock still cannot go below zero, because of a CHECK rule.



---



## 🌐 Web Interface

* **Overview:** main numbers, products to reorder, latest invoices

* **Products:** list, search, add, edit, delete (a product with sales or stock history cannot be deleted)

* **Stock:** stock of every product, low-stock filter, stock history of each product

* **Customers:** search and purchase history

* **Invoices:** list, and each bill with its items, payments and returns

* **Reports:** the 9 reports listed above



## ⚠️ Current Limits

* The interface has no screens to enter a sale, a purchase, a return or a payment. They exist in the database (the sample data contains them and the triggers apply to them), but the interface only displays them.

* Customers, suppliers and invoices cannot be added or edited from the interface.



---



## 📂 Repository Layout

```text

retail-inventory-sales-management/

├── database/

│   ├── schema.sql           # Tables, constraints, indexes, triggers

│   ├── sample_data.sql      # Test data

│   └── queries.sql          # 9 views, joins, subqueries, aggregates

├── web/                     # Flask application and templates

├── tests/                   # Automated tests

├── .gitignore

└── README.md

```



## ▶️ How to Run

1. In MySQL, run these files from the `database` folder, in this order: `schema.sql` (this deletes and rebuilds the database `retail_store`), then `sample_data.sql`, then `queries.sql`.

2. The interface connects as the MySQL user `retail_app`. Create it with your own password, or change `DB_USER` in `web/config.py` to a user you already have:

```sql

   CREATE USER 'retail_app'@'localhost' IDENTIFIED BY 'YOUR_PASSWORD';

   GRANT ALL PRIVILEGES ON retail_store.* TO 'retail_app'@'localhost';

```

3. In a terminal in the `web` folder: `pip install -r requirements.txt`

4. Start it: `python server.py` (type the password when asked).

5. Open `http://127.0.0.1:5000` in your browser.



## ✅ Tests (optional)

The tests use a separate database, `retail_store_test`, and need a MySQL user that can create databases (such as `root`). In a terminal in the project folder:

```

set RETAIL_DB_USER=root

python -m unittest discover -s tests

```
---
## 👤 Author
* **Degree:** BCA Cybersecurity @ Woxsen University
* **Focus:** Defensive Security (Blue Team) & Secure Architecture
