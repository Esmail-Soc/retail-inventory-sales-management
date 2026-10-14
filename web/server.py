import getpass
import os
import re
import secrets
import sys
from contextlib import contextmanager
from datetime import date, datetime
from decimal import Decimal, InvalidOperation

import mysql.connector
from flask import (Flask, abort, flash, g, redirect, render_template,
                   request, session, url_for)
from mysql.connector import Error as MySQLError

import config

app = Flask(__name__)
app.secret_key = os.urandom(24)


class DatabaseUnavailable(Exception):
    pass


def get_db():
    if "db" not in g:
        password = app.config.get("DB_PASSWORD")
        if password is None:
            password = os.environ.get("RETAIL_DB_PASSWORD", "")
        try:
            g.db = mysql.connector.connect(
                host=os.environ.get("RETAIL_DB_HOST", config.DB_HOST),
                port=int(os.environ.get("RETAIL_DB_PORT", config.DB_PORT)),
                user=os.environ.get("RETAIL_DB_USER", config.DB_USER),
                password=password,
                database=os.environ.get("RETAIL_DB_NAME", config.DB_NAME),
                autocommit=True,
            )
        except MySQLError as error:
            raise DatabaseUnavailable(error.msg)
    return g.db


@app.teardown_appcontext
def close_db(error):
    db = g.pop("db", None)
    if db is not None:
        db.close()


def query(sql, params=()):
    cursor = get_db().cursor(dictionary=True)
    try:
        cursor.execute(sql, params)
        return cursor.fetchall()
    finally:
        cursor.close()


def query_one(sql, params=()):
    rows = query(sql, params)
    return rows[0] if rows else None


def execute(sql, params=()):
    cursor = get_db().cursor()
    try:
        cursor.execute(sql, params)
        return cursor.lastrowid
    finally:
        cursor.close()


@contextmanager
def transaction():
    db = get_db()
    db.start_transaction()
    try:
        yield
        db.commit()
    except Exception:
        db.rollback()
        raise


def friendly_db_error(error):
    code = getattr(error, "errno", None)
    if code == 1644:
        return error.msg
    if code in (3819, 4025):
        return "That value is not allowed (prices and quantities must be positive)."
    if code == 1062:
        return "That value already exists. It must be unique."
    if code == 1451:
        return "This record is used by other records, so it cannot be deleted."
    if code == 1452:
        return "A related record does not exist."
    return f"Database problem: {error.msg}"


def like_pattern(term):
    term = term.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
    return f"%{term}%"


def csrf_token():
    if "csrf" not in session:
        session["csrf"] = secrets.token_hex(16)
    return session["csrf"]


app.jinja_env.globals["csrf_token"] = csrf_token


@app.before_request
def check_form_token():
    if request.method == "POST":
        token = session.get("csrf")
        if not token or request.form.get("csrf") != token:
            abort(400)


@app.template_filter("money")
def money(value):
    if value is None:
        return "-"
    return f"{value:,.2f}"


@app.template_filter("dt")
def show_date(value):
    if isinstance(value, datetime):
        return value.strftime("%d %b %Y, %H:%M")
    if isinstance(value, date):
        return value.strftime("%d %b %Y")
    return "-" if value is None else str(value)


def error_page(title, message, status):
    return render_template("error.html", title=title, message=message), status


@app.errorhandler(DatabaseUnavailable)
def handle_no_database(error):
    return error_page(
        "Cannot reach the database",
        f"MySQL said: {error}. Check that MySQL is running and that the password is right, "
        "then restart this program.", 503)


@app.errorhandler(MySQLError)
def handle_database_error(error):
    return error_page("The database refused that", friendly_db_error(error), 500)


@app.errorhandler(404)
def handle_not_found(error):
    return error_page("Page not found", "There is nothing at this address.", 404)


@app.errorhandler(400)
def handle_bad_request(error):
    return error_page("That form has expired",
                      "Go back, reload the page and send the form again.", 400)


@app.errorhandler(405)
def handle_wrong_method(error):
    return error_page("Page not found", "There is nothing at this address.", 405)


@app.route("/")
def home():
    facts = query_one("""
        SELECT (SELECT COUNT(*) FROM Product)                                  AS products,
               (SELECT COUNT(*) FROM Customer WHERE name <> 'Walk-in Customer') AS customers,
               (SELECT COUNT(*) FROM Invoice)                                  AS invoices,
               (SELECT COALESCE(SUM(total_amount), 0) FROM Invoice)            AS sales,
               (SELECT COALESCE(SUM(balance), 0) FROM v_pending_payments)      AS pending""")
    low_stock = query("SELECT * FROM v_low_stock ORDER BY short_by DESC, product_name LIMIT 6")
    low_count = query_one("SELECT COUNT(*) AS n FROM v_low_stock")["n"]
    latest = query("""
        SELECT i.invoice_code, i.invoice_date, c.name AS customer, i.total_amount
        FROM Invoice i
        JOIN Sale s ON s.sale_id = i.sale_id
        JOIN Customer c ON c.customer_id = s.customer_id
        ORDER BY i.invoice_date DESC, i.invoice_id DESC
        LIMIT 6""")
    return render_template("home.html", facts=facts, low_stock=low_stock,
                           low_count=low_count, latest=latest)


PRODUCT_SQL = """
    SELECT p.product_id, p.product_code, p.product_name,
           p.category_id, c.category_name, p.brand_id, b.brand_name,
           p.cost_price, p.selling_price, p.stock_quantity, p.reorder_level
    FROM Product p
    JOIN Category c ON c.category_id = p.category_id
    JOIN Brand b    ON b.brand_id    = p.brand_id
"""

CODE_PATTERN = re.compile(r"[A-Z0-9][A-Z0-9_-]*")


def clean_money(text):
    try:
        amount = Decimal(text)
        if not amount.is_finite():
            raise InvalidOperation
        if amount != amount.quantize(Decimal("0.01")):
            return None, "Use at most 2 digits after the decimal point."
    except InvalidOperation:
        return None, "Enter a number, for example 125.50."
    if amount <= 0:
        return None, "The value must be more than 0."
    if amount > Decimal("99999999.99"):
        return None, "That value is too large."
    return amount.quantize(Decimal("0.01")), None


def clean_whole_number(text, minimum, maximum):
    if not re.fullmatch(r"\d{1,9}", text):
        return None, "Enter a whole number."
    number = int(text)
    if number < minimum or number > maximum:
        return None, f"The number must be between {minimum} and {maximum}."
    return number, None


def check_lookup(table, id_column, chosen_id, new_name, label, errors, field):
    if new_name:
        if len(new_name) > 50:
            errors[field] = f"The {label} name can have at most 50 characters."
    elif chosen_id:
        if not chosen_id.isdigit() or not query_one(
                f"SELECT 1 AS x FROM {table} WHERE {id_column} = %s", (chosen_id,)):
            errors[field] = f"That {label} does not exist. Choose one from the list."
    else:
        errors[field] = f"Choose a {label} or type a new one."


def check_product_form(form, editing):
    values = {name: form.get(name, "").strip() for name in (
        "product_code", "product_name", "category_id", "new_category",
        "brand_id", "new_brand", "cost_price", "selling_price", "reorder_level")}
    values["product_code"] = values["product_code"].upper()
    errors = {}
    parsed = {}

    if not editing:
        code = values["product_code"]
        if not code:
            errors["product_code"] = "Enter a product code."
        elif len(code) > 20 or not CODE_PATTERN.fullmatch(code):
            errors["product_code"] = "Use up to 20 letters, numbers or - (no spaces)."
        parsed["product_code"] = code

    name = values["product_name"]
    if not name:
        errors["product_name"] = "Enter the product name."
    elif len(name) > 100:
        errors["product_name"] = "The name can have at most 100 characters."
    parsed["product_name"] = name

    check_lookup("Category", "category_id", values["category_id"], values["new_category"],
                 "category", errors, "category_id")
    check_lookup("Brand", "brand_id", values["brand_id"], values["new_brand"],
                 "brand", errors, "brand_id")

    for field in ("cost_price", "selling_price"):
        parsed[field], message = clean_money(values[field])
        if message:
            errors[field] = message

    parsed["reorder_level"], message = clean_whole_number(values["reorder_level"], 0, 100000)
    if message:
        errors["reorder_level"] = message

    return values, parsed, errors


def lookup_id(table, id_column, name_column, chosen_id, new_name):
    if not new_name:
        return int(chosen_id)
    row = query_one(f"SELECT {id_column} AS id FROM {table} WHERE {name_column} = %s", (new_name,))
    if row:
        return row["id"]
    return execute(f"INSERT INTO {table} ({name_column}) VALUES (%s)", (new_name,))


def form_choices():
    return {"categories": query("SELECT category_id, category_name FROM Category ORDER BY category_name"),
            "brands": query("SELECT brand_id, brand_name FROM Brand ORDER BY brand_name")}


@app.route("/products")
def products():
    search = request.args.get("q", "").strip()[:100]
    if search:
        rows = query(PRODUCT_SQL + """ WHERE p.product_code LIKE %s OR p.product_name LIKE %s
                                      OR c.category_name LIKE %s OR b.brand_name LIKE %s
                                      ORDER BY p.product_code""", (like_pattern(search),) * 4)
    else:
        rows = query(PRODUCT_SQL + " ORDER BY p.product_code")
    return render_template("products.html", rows=rows, search=search)


@app.route("/products/new", methods=["GET", "POST"])
def product_new():
    values = {"reorder_level": "10"}
    errors = {}

    if request.method == "POST":
        values, parsed, errors = check_product_form(request.form, editing=False)
        if not errors and query_one("SELECT 1 AS x FROM Product WHERE product_code = %s",
                                    (parsed["product_code"],)):
            errors["product_code"] = "This product code is already used. Choose another one."

        if not errors:
            try:
                with transaction():
                    category_id = lookup_id("Category", "category_id", "category_name",
                                            values["category_id"], values["new_category"])
                    brand_id = lookup_id("Brand", "brand_id", "brand_name",
                                         values["brand_id"], values["new_brand"])
                    execute("""INSERT INTO Product (product_code, product_name, category_id, brand_id,
                                                    cost_price, selling_price, reorder_level)
                               VALUES (%s, %s, %s, %s, %s, %s, %s)""",
                            (parsed["product_code"], parsed["product_name"], category_id, brand_id,
                             parsed["cost_price"], parsed["selling_price"], parsed["reorder_level"]))
            except MySQLError as error:
                errors["form"] = friendly_db_error(error)
            else:
                flash(f"Product {parsed['product_code']} was added. Its stock is 0 until a purchase is recorded.", "ok")
                if parsed["selling_price"] < parsed["cost_price"]:
                    flash("Check the prices: the selling price is lower than the cost price.", "warn")
                return redirect(url_for("products", q=parsed["product_code"]))

    return render_template("product_form.html", editing=False, values=values, errors=errors,
                           product=None, **form_choices())


@app.route("/products/<int:product_id>/edit", methods=["GET", "POST"])
def product_edit(product_id):
    product = query_one(PRODUCT_SQL + " WHERE p.product_id = %s", (product_id,))
    if product is None:
        abort(404)

    errors = {}
    values = {"product_name": product["product_name"],
              "category_id": str(product["category_id"]), "new_category": "",
              "brand_id": str(product["brand_id"]), "new_brand": "",
              "cost_price": f"{product['cost_price']:.2f}",
              "selling_price": f"{product['selling_price']:.2f}",
              "reorder_level": str(product["reorder_level"])}

    if request.method == "POST":
        values, parsed, errors = check_product_form(request.form, editing=True)
        if not errors:
            try:
                with transaction():
                    category_id = lookup_id("Category", "category_id", "category_name",
                                            values["category_id"], values["new_category"])
                    brand_id = lookup_id("Brand", "brand_id", "brand_name",
                                         values["brand_id"], values["new_brand"])
                    execute("""UPDATE Product
                               SET product_name = %s, category_id = %s, brand_id = %s,
                                   cost_price = %s, selling_price = %s, reorder_level = %s
                               WHERE product_id = %s""",
                            (parsed["product_name"], category_id, brand_id, parsed["cost_price"],
                             parsed["selling_price"], parsed["reorder_level"], product_id))
            except MySQLError as error:
                errors["form"] = friendly_db_error(error)
            else:
                flash(f"Product {product['product_code']} was saved.", "ok")
                if parsed["selling_price"] < parsed["cost_price"]:
                    flash("Check the prices: the selling price is lower than the cost price.", "warn")
                return redirect(url_for("products", q=product["product_code"]))

    return render_template("product_form.html", editing=True, values=values, errors=errors,
                           product=product, **form_choices())


@app.route("/products/<int:product_id>/delete", methods=["POST"])
def product_delete(product_id):
    product = query_one("SELECT product_code, product_name FROM Product WHERE product_id = %s", (product_id,))
    if product is None:
        abort(404)
    try:
        execute("DELETE FROM Product WHERE product_id = %s", (product_id,))
    except MySQLError as error:
        if error.errno == 1451:
            flash(f"{product['product_name']} cannot be deleted: it already has purchases, sales "
                  "or stock history.", "error")
        else:
            flash(friendly_db_error(error), "error")
    else:
        flash(f"Product {product['product_code']} was deleted.", "ok")
    return redirect(url_for("products"))


@app.route("/stock")
def stock():
    only_low = request.args.get("low") == "1"
    rows = query("""
        SELECT product_id, product_code, product_name, stock_quantity, reorder_level,
               stock_quantity < reorder_level AS is_low
        FROM Product""" + (" WHERE stock_quantity < reorder_level" if only_low else "") + """
        ORDER BY product_code""")
    return render_template("stock.html", rows=rows, only_low=only_low)


@app.route("/stock/<int:product_id>")
def stock_history(product_id):
    product = query_one("SELECT product_id, product_code, product_name, stock_quantity, reorder_level "
                        "FROM Product WHERE product_id = %s", (product_id,))
    if product is None:
        abort(404)
    movements = query("""
        SELECT movement_date, movement_type, source, quantity, reference_id
        FROM StockMovement WHERE product_id = %s
        ORDER BY movement_date DESC, movement_id DESC LIMIT 200""", (product_id,))
    return render_template("stock_history.html", product=product, movements=movements)


@app.route("/customers")
def customers():
    search = request.args.get("q", "").strip()[:100]
    sql = """SELECT customer_id, name, phone, email FROM Customer"""
    if search:
        rows = query(sql + " WHERE name LIKE %s OR phone LIKE %s OR email LIKE %s ORDER BY name",
                     (like_pattern(search),) * 3)
    else:
        rows = query(sql + " ORDER BY name")
    return render_template("customers.html", rows=rows, search=search)


@app.route("/customers/<int:customer_id>")
def customer_detail(customer_id):
    customer = query_one("SELECT customer_id, name, phone, email FROM Customer WHERE customer_id = %s",
                         (customer_id,))
    if customer is None:
        abort(404)
    invoices = query("""
        SELECT i.invoice_code, i.invoice_date, i.total_amount,
               COALESCE(SUM(pay.amount), 0) AS paid
        FROM Sale s
        JOIN Invoice i ON i.sale_id = s.sale_id
        LEFT JOIN Payment pay ON pay.invoice_id = i.invoice_id
        WHERE s.customer_id = %s
        GROUP BY i.invoice_id, i.invoice_code, i.invoice_date, i.total_amount
        ORDER BY i.invoice_date DESC""", (customer_id,))
    return render_template("customer_detail.html", customer=customer, invoices=invoices)


INVOICE_LIST_SQL = """
    SELECT i.invoice_code, i.invoice_date, c.customer_id, c.name AS customer, i.total_amount,
           COALESCE(SUM(pay.amount), 0) AS paid
    FROM Invoice i
    JOIN Sale s     ON s.sale_id = i.sale_id
    JOIN Customer c ON c.customer_id = s.customer_id
    LEFT JOIN Payment pay ON pay.invoice_id = i.invoice_id
"""


@app.route("/invoices")
def invoices():
    search = request.args.get("q", "").strip()[:100]
    where = " WHERE i.invoice_code LIKE %s OR c.name LIKE %s" if search else ""
    rows = query(INVOICE_LIST_SQL + where + """
        GROUP BY i.invoice_id, i.invoice_code, i.invoice_date, c.customer_id, c.name, i.total_amount
        ORDER BY i.invoice_date DESC, i.invoice_id DESC""",
                 (like_pattern(search),) * 2 if search else ())
    return render_template("invoices.html", rows=rows, search=search)


@app.route("/invoices/<code>")
def invoice_detail(code):
    invoice = query_one(INVOICE_LIST_SQL + """
        WHERE i.invoice_code = %s
        GROUP BY i.invoice_id, i.invoice_code, i.invoice_date, c.customer_id, c.name, i.total_amount""",
                        (code.upper(),))
    if invoice is None:
        abort(404)
    items = query("""
        SELECT p.product_name, si.quantity, si.unit_price, si.quantity * si.unit_price AS line_total
        FROM SaleItem si
        JOIN Invoice i ON i.sale_id = si.sale_id
        JOIN Product p ON p.product_id = si.product_id
        WHERE i.invoice_code = %s ORDER BY si.sale_item_id""", (invoice["invoice_code"],))
    payments = query("""
        SELECT pay.payment_date, pay.payment_method, pay.amount
        FROM Payment pay JOIN Invoice i ON i.invoice_id = pay.invoice_id
        WHERE i.invoice_code = %s ORDER BY pay.payment_date, pay.payment_id""", (invoice["invoice_code"],))
    returned = query("""
        SELECT r.return_date, p.product_name, r.quantity, r.quantity * si.unit_price AS refund, r.reason
        FROM Returns r
        JOIN SaleItem si ON si.sale_item_id = r.sale_item_id
        JOIN Invoice i   ON i.sale_id = si.sale_id
        JOIN Product p   ON p.product_id = si.product_id
        WHERE i.invoice_code = %s ORDER BY r.return_date, r.return_id""", (invoice["invoice_code"],))
    return render_template("invoice_detail.html", invoice=invoice, items=items,
                           payments=payments, returned=returned)


REPORTS = {
    "low-stock": {
        "title": "Low stock",
        "about": "Products with less stock than their reorder level. These are the ones to order.",
        "sql": "SELECT * FROM v_low_stock ORDER BY short_by DESC, product_name",
        "columns": [("Code", "product_code", "text"), ("Product", "product_name", "text"),
                    ("Category", "category_name", "text"), ("In stock", "stock_quantity", "int"),
                    ("Reorder level", "reorder_level", "int"), ("Short by", "short_by", "int")],
    },
    "stock-valuation": {
        "title": "Stock valuation",
        "about": "How much money is sitting on the shelves, at cost price and at selling price.",
        "sql": "SELECT * FROM v_stock_valuation ORDER BY value_at_cost DESC",
        "columns": [("Code", "product_code", "text"), ("Product", "product_name", "text"),
                    ("In stock", "stock_quantity", "int"), ("Cost price", "cost_price", "money"),
                    ("Selling price", "selling_price", "money"),
                    ("Value at cost", "value_at_cost", "money"),
                    ("Value at selling price", "value_at_selling_price", "money")],
        "summary_sql": """SELECT COALESCE(SUM(value_at_cost), 0) AS cost,
                                 COALESCE(SUM(value_at_selling_price), 0) AS price
                          FROM v_stock_valuation""",
        "summary": [("Total stock at cost price", "cost", "money"),
                    ("Total stock at selling price", "price", "money")],
    },
    "supplier-purchases": {
        "title": "Supplier purchases",
        "about": "What we bought from each supplier. A supplier with no purchases still appears.",
        "sql": "SELECT * FROM v_supplier_purchases ORDER BY total_amount DESC, supplier_name",
        "columns": [("Supplier", "supplier_name", "text"), ("Purchases", "total_purchases", "int"),
                    ("Items bought", "total_items", "int"), ("Total amount", "total_amount", "money")],
    },
    "daily-sales": {
        "title": "Daily sales",
        "about": "Invoices and sales amount for each day.",
        "sql": "SELECT * FROM v_daily_sales ORDER BY sale_day DESC",
        "filter": "date",
        "columns": [("Day", "sale_day", "date"), ("Invoices", "total_invoices", "int"),
                    ("Total sales", "total_sales", "money")],
    },
    "monthly-sales": {
        "title": "Monthly sales",
        "about": "Invoices, sales amount and average bill for each month.",
        "sql": "SELECT * FROM v_monthly_sales ORDER BY sale_month DESC",
        "columns": [("Month", "sale_month", "text"), ("Invoices", "total_invoices", "int"),
                    ("Total sales", "total_sales", "money"), ("Average bill", "average_bill", "money")],
    },
    "returns": {
        "title": "Returns",
        "about": "Items customers brought back, with the refund value.",
        "sql": "SELECT * FROM v_returns_report ORDER BY return_date DESC, return_id DESC",
        "columns": [("Date", "return_date", "datetime"), ("Product", "product_name", "text"),
                    ("Customer", "customer_name", "text"), ("Quantity", "quantity", "int"),
                    ("Price each", "unit_price", "money"), ("Refund", "refund_amount", "money"),
                    ("Reason", "reason", "text")],
    },
    "fast-moving": {
        "title": "Fast moving items",
        "about": "The products that sell the most pieces.",
        "sql": "SELECT * FROM v_fast_moving ORDER BY total_sold DESC, product_name LIMIT %s",
        "filter": "top",
        "columns": [("Product", "product_name", "text"), ("Pieces sold", "total_sold", "int"),
                    ("Number of sales", "number_of_sales", "int")],
    },
    "profit": {
        "title": "Profit",
        "about": "Revenue, cost and profit of each product. Returned items are not counted.",
        "sql": "SELECT * FROM v_product_profit ORDER BY profit DESC, product_name",
        "columns": [("Product", "product_name", "text"), ("Net pieces sold", "net_quantity_sold", "int"),
                    ("Revenue", "revenue", "money"), ("Cost", "cost", "money"), ("Profit", "profit", "money")],
        "summary_sql": """SELECT COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(cost), 0) AS cost,
                                 COALESCE(SUM(profit), 0) AS profit
                          FROM v_product_profit""",
        "summary": [("Total revenue", "revenue", "money"), ("Total cost", "cost", "money"),
                    ("Total profit", "profit", "money")],
    },
    "pending-payments": {
        "title": "Pending payments",
        "about": "Invoices that are not fully paid yet.",
        "sql": "SELECT * FROM v_pending_payments ORDER BY balance DESC, invoice_code",
        "columns": [("Invoice", "invoice_code", "invoice"), ("Customer", "customer_name", "text"),
                    ("Date", "invoice_date", "datetime"), ("Total", "total_amount", "money"),
                    ("Paid", "paid_amount", "money"), ("Balance", "balance", "money")],
        "summary_sql": "SELECT COALESCE(SUM(balance), 0) AS balance FROM v_pending_payments",
        "summary": [("Total still to be received", "balance", "money")],
    },
}


@app.route("/reports")
def reports_index():
    return render_template("reports_index.html", reports=REPORTS)


@app.route("/reports/<slug>")
def report(slug):
    config_of_report = REPORTS.get(slug)
    if config_of_report is None:
        abort(404)

    filter_kind = config_of_report.get("filter")
    filter_value = request.args.get("date" if filter_kind == "date" else "top", "").strip()
    problem = None
    params = ()
    sql = config_of_report["sql"]

    if filter_kind == "date" and filter_value:
        try:
            datetime.strptime(filter_value, "%Y-%m-%d")
            sql = "SELECT * FROM v_daily_sales WHERE sale_day = %s"
            params = (filter_value,)
        except ValueError:
            problem = "Use the date format YYYY-MM-DD, for example 2026-09-30. All days are shown."
    elif filter_kind == "top":
        top, message = clean_whole_number(filter_value or "5", 1, 100)
        if message:
            problem = "Choose a number from 1 to 100. The top 5 are shown."
            top = 5
        filter_value = str(top)
        params = (top,)

    rows = query(sql, params)
    summary = None
    if "summary_sql" in config_of_report:
        summary = query_one(config_of_report["summary_sql"])
    return render_template("report.html", slug=slug, report=config_of_report, rows=rows,
                           summary=summary, filter_value=filter_value, problem=problem)


ROWS = 6
PAYMENT_METHODS = ["Cash", "Card", "UPI"]


class FormProblem(Exception):
    pass


def get_invoice(code):
    return query_one(INVOICE_LIST_SQL + """
        WHERE i.invoice_code = %s
        GROUP BY i.invoice_id, i.invoice_code, i.invoice_date, c.customer_id, c.name, i.total_amount""",
                     (code.upper(),))


def product_choices():
    return query("""SELECT product_id, product_code, product_name, cost_price, selling_price, stock_quantity
                    FROM Product ORDER BY product_name""")


def blank_rows():
    return [{"product_id": "", "quantity": "", "unit_cost": "", "error": ""} for _ in range(ROWS)]


def read_rows(form):
    ids = form.getlist("product_id")[:20]
    quantities = form.getlist("quantity")
    costs = form.getlist("unit_cost")
    rows = []
    for i, product_id in enumerate(ids):
        rows.append({"product_id": product_id.strip(),
                     "quantity": quantities[i].strip() if i < len(quantities) else "",
                     "unit_cost": costs[i].strip() if i < len(costs) else "",
                     "error": ""})
    return rows


def check_rows(rows, products_by_id, with_cost):
    lines = []
    for row in rows:
        if not row["product_id"] and not row["quantity"] and not row["unit_cost"]:
            continue
        if not row["product_id"].isdigit() or int(row["product_id"]) not in products_by_id:
            row["error"] = "Choose a product from the list."
            continue
        product = products_by_id[int(row["product_id"])]
        quantity, message = clean_whole_number(row["quantity"], 1, 100000)
        if message:
            row["error"] = "Quantity: " + message
            continue
        unit_cost = product["cost_price"]
        if with_cost and row["unit_cost"]:
            unit_cost, message = clean_money(row["unit_cost"])
            if message:
                row["error"] = "Cost: " + message
                continue
        lines.append({"product_id": product["product_id"], "quantity": quantity, "unit_cost": unit_cost})
    return lines


def merge_lines(lines):
    merged = {}
    for line in lines:
        if line["product_id"] in merged:
            merged[line["product_id"]]["quantity"] += line["quantity"]
        else:
            merged[line["product_id"]] = dict(line)
    return list(merged.values())


def save_sale(customer_id, lines, payment, part_amount, method):
    with transaction():
        prepared = []
        total = Decimal("0")
        for line in lines:
            product = query_one("SELECT product_name, selling_price, stock_quantity FROM Product "
                                "WHERE product_id = %s", (line["product_id"],))
            if product is None:
                raise FormProblem("A product on the bill no longer exists.")
            if product["stock_quantity"] < line["quantity"]:
                raise FormProblem(f"Not enough stock for {product['product_name']}: "
                                  f"only {product['stock_quantity']} left.")
            prepared.append((line["product_id"], line["quantity"], product["selling_price"]))
            total += line["quantity"] * product["selling_price"]

        if payment == "full":
            paid = total
        elif payment == "part":
            paid = part_amount
        else:
            paid = Decimal("0")
        if paid > total:
            raise FormProblem(f"The amount paid is more than the bill total of Rs. {total:,.2f}.")

        sale_id = execute("INSERT INTO Sale (customer_id) VALUES (%s)", (customer_id,))
        for product_id, quantity, price in prepared:
            execute("""INSERT INTO SaleItem (sale_id, product_id, quantity, unit_price)
                       VALUES (%s, %s, %s, %s)""", (sale_id, product_id, quantity, price))
        invoice_code = f"INV-{sale_id:04d}"
        invoice_id = execute("INSERT INTO Invoice (invoice_code, sale_id, total_amount) VALUES (%s, %s, %s)",
                             (invoice_code, sale_id, total))
        if paid > 0:
            execute("INSERT INTO Payment (invoice_id, amount, payment_method) VALUES (%s, %s, %s)",
                    (invoice_id, paid, method))
    return invoice_code


@app.route("/sales/new", methods=["GET", "POST"])
def sale_new():
    products = product_choices()
    by_id = {p["product_id"]: p for p in products}
    customer_list = query("""SELECT customer_id, name, phone FROM Customer
                             ORDER BY name = 'Walk-in Customer' DESC, name""")
    values = {"customer_id": str(customer_list[0]["customer_id"]) if customer_list else "",
              "payment": "full", "paid_amount": "", "method": "Cash"}
    rows = blank_rows()
    errors = {}

    if request.method == "POST":
        rows = read_rows(request.form)
        values = {name: request.form.get(name, "").strip()
                  for name in ("customer_id", "payment", "paid_amount", "method")}
        lines = check_rows(rows, by_id, with_cost=False)
        if any(row["error"] for row in rows):
            errors["form"] = "Fix the items marked below."
        elif not lines:
            errors["form"] = "Add at least one product to the bill."
        if values["customer_id"] not in {str(c["customer_id"]) for c in customer_list}:
            errors["customer_id"] = "Choose a customer from the list."
        if values["payment"] not in ("full", "part", "later"):
            errors["payment"] = "Choose how the customer pays."
        part_amount = None
        if values["payment"] == "part":
            part_amount, message = clean_money(values["paid_amount"])
            if message:
                errors["paid_amount"] = message
        if values["payment"] != "later" and values["method"] not in PAYMENT_METHODS:
            errors["method"] = "Choose a payment method."

        if not errors:
            try:
                invoice_code = save_sale(int(values["customer_id"]), merge_lines(lines),
                                         values["payment"], part_amount, values["method"])
            except FormProblem as problem:
                errors["form"] = str(problem)
            except MySQLError as error:
                errors["form"] = friendly_db_error(error)
            else:
                flash(f"The sale was saved as invoice {invoice_code}. The stock was reduced.", "ok")
                return redirect(url_for("invoice_detail", code=invoice_code))

    return render_template("sale_form.html", rows=rows, products=products, customers=customer_list,
                           values=values, errors=errors, methods=PAYMENT_METHODS)


@app.route("/invoices/<code>/pay", methods=["POST"])
def invoice_pay(code):
    invoice = get_invoice(code)
    if invoice is None:
        abort(404)
    balance = invoice["total_amount"] - invoice["paid"]
    amount, problem = clean_money(request.form.get("amount", "").strip())
    method = request.form.get("method", "").strip()
    if not problem and method not in PAYMENT_METHODS:
        problem = "Choose a payment method."
    if not problem and amount > balance:
        problem = f"The amount is more than the balance of Rs. {balance:,.2f}."
    if problem:
        flash(f"The payment was not saved. {problem}", "error")
    else:
        try:
            invoice_id = query_one("SELECT invoice_id FROM Invoice WHERE invoice_code = %s",
                                   (invoice["invoice_code"],))["invoice_id"]
            execute("INSERT INTO Payment (invoice_id, amount, payment_method) VALUES (%s, %s, %s)",
                    (invoice_id, amount, method))
        except MySQLError as error:
            flash(f"The payment was not saved. {friendly_db_error(error)}", "error")
        else:
            flash(f"Payment of Rs. {amount:,.2f} was saved.", "ok")
    return redirect(url_for("invoice_detail", code=invoice["invoice_code"]))


def save_purchase(supplier_id, lines):
    with transaction():
        purchase_id = execute("INSERT INTO Purchase (supplier_id) VALUES (%s)", (supplier_id,))
        for line in lines:
            execute("""INSERT INTO PurchaseItem (purchase_id, product_id, quantity, unit_cost)
                       VALUES (%s, %s, %s, %s)""",
                    (purchase_id, line["product_id"], line["quantity"], line["unit_cost"]))
    return purchase_id


@app.route("/purchases")
def purchases():
    rows = query("""
        SELECT pu.purchase_id, pu.purchase_date, s.name AS supplier,
               COUNT(pi.purchase_item_id) AS item_lines,
               COALESCE(SUM(pi.quantity), 0) AS pieces,
               COALESCE(SUM(pi.quantity * pi.unit_cost), 0) AS total_cost
        FROM Purchase pu
        JOIN Supplier s ON s.supplier_id = pu.supplier_id
        LEFT JOIN PurchaseItem pi ON pi.purchase_id = pu.purchase_id
        GROUP BY pu.purchase_id, pu.purchase_date, s.name
        ORDER BY pu.purchase_date DESC, pu.purchase_id DESC""")
    return render_template("purchases.html", rows=rows)


@app.route("/purchases/<int:purchase_id>")
def purchase_detail(purchase_id):
    purchase = query_one("""SELECT pu.purchase_id, pu.purchase_date, s.supplier_id, s.name AS supplier
                            FROM Purchase pu JOIN Supplier s ON s.supplier_id = pu.supplier_id
                            WHERE pu.purchase_id = %s""", (purchase_id,))
    if purchase is None:
        abort(404)
    items = query("""SELECT p.product_name, pi.quantity, pi.unit_cost, pi.quantity * pi.unit_cost AS line_total
                     FROM PurchaseItem pi JOIN Product p ON p.product_id = pi.product_id
                     WHERE pi.purchase_id = %s ORDER BY pi.purchase_item_id""", (purchase_id,))
    total = sum((item["line_total"] for item in items), Decimal("0"))
    return render_template("purchase_detail.html", purchase=purchase, items=items, total=total)


@app.route("/purchases/new", methods=["GET", "POST"])
def purchase_new():
    products = product_choices()
    by_id = {p["product_id"]: p for p in products}
    supplier_list = query("SELECT supplier_id, name FROM Supplier ORDER BY name")
    values = {"supplier_id": ""}
    rows = blank_rows()
    errors = {}

    if request.method == "POST":
        rows = read_rows(request.form)
        values = {"supplier_id": request.form.get("supplier_id", "").strip()}
        lines = check_rows(rows, by_id, with_cost=True)
        if any(row["error"] for row in rows):
            errors["form"] = "Fix the items marked below."
        elif not lines:
            errors["form"] = "Add at least one product to the purchase."
        if values["supplier_id"] not in {str(s["supplier_id"]) for s in supplier_list}:
            errors["supplier_id"] = "Choose a supplier from the list."

        if not errors:
            try:
                purchase_id = save_purchase(int(values["supplier_id"]), lines)
            except MySQLError as error:
                errors["form"] = friendly_db_error(error)
            else:
                flash(f"Purchase no. {purchase_id} was saved. The stock was increased.", "ok")
                return redirect(url_for("purchase_detail", purchase_id=purchase_id))

    return render_template("purchase_form.html", rows=rows, products=products, suppliers=supplier_list,
                           values=values, errors=errors)


def return_items(invoice_code):
    items = query("""
        SELECT si.sale_item_id, p.product_name, si.quantity AS sold, si.unit_price,
               COALESCE((SELECT SUM(r.quantity) FROM Returns r
                         WHERE r.sale_item_id = si.sale_item_id), 0) AS returned
        FROM SaleItem si
        JOIN Invoice i ON i.sale_id = si.sale_id
        JOIN Product p ON p.product_id = si.product_id
        WHERE i.invoice_code = %s
        ORDER BY si.sale_item_id""", (invoice_code,))
    for item in items:
        item["can_return"] = item["sold"] - item["returned"]
        item["entered"] = ""
        item["error"] = ""
    return items


@app.route("/returns/new", methods=["GET", "POST"])
def return_new():
    code = request.values.get("invoice", "").strip().upper()[:20]
    invoice = None
    items = []
    errors = {}
    reason = ""

    if code:
        invoice = get_invoice(code)
        if invoice is None:
            errors["invoice"] = f"Invoice {code} was not found. Check the code and try again."
        else:
            items = return_items(invoice["invoice_code"])

    if request.method == "POST" and invoice:
        reason = request.form.get("reason", "").strip()
        if len(reason) > 200:
            errors["reason"] = "The reason can have at most 200 characters."
        chosen = []
        for item in items:
            text = request.form.get(f"qty_{item['sale_item_id']}", "").strip()
            item["entered"] = text
            if text in ("", "0"):
                continue
            number, message = clean_whole_number(text, 1, 100000)
            if message:
                item["error"] = message
            elif number > item["can_return"]:
                item["error"] = f"At most {item['can_return']} can still be returned."
            else:
                chosen.append((item, number))
        if any(item["error"] for item in items):
            errors["form"] = "Fix the quantities marked below."
        elif not chosen and not errors:
            errors["form"] = "Enter a quantity for at least one item."

        if not errors:
            try:
                with transaction():
                    for item, number in chosen:
                        execute("INSERT INTO Returns (sale_item_id, quantity, reason) VALUES (%s, %s, %s)",
                                (item["sale_item_id"], number, reason or None))
            except MySQLError as error:
                errors["form"] = friendly_db_error(error)
            else:
                refund = sum((number * item["unit_price"] for item, number in chosen), Decimal("0"))
                flash(f"The return was saved. Refund to the customer: Rs. {refund:,.2f}. "
                      "The returned items are back in stock.", "ok")
                return redirect(url_for("invoice_detail", code=invoice["invoice_code"]))

    return render_template("return_form.html", code=code, invoice=invoice, items=items,
                           errors=errors, reason=reason)


NEEDED_VIEWS = ["v_low_stock", "v_stock_valuation", "v_supplier_purchases", "v_daily_sales",
                "v_monthly_sales", "v_returns_report", "v_fast_moving", "v_product_profit",
                "v_pending_payments"]


def check_database():
    try:
        with app.app_context():
            rows = query("SELECT TABLE_NAME AS name FROM information_schema.VIEWS "
                         "WHERE TABLE_SCHEMA = DATABASE()")
    except DatabaseUnavailable as error:
        return (f"Could not connect to the database: {error}\n"
                "Check that MySQL is running and that the password is right.")
    existing = {row["name"].lower() for row in rows}
    missing = [view for view in NEEDED_VIEWS if view not in existing]
    if missing:
        return ("The database is missing these views: " + ", ".join(missing) + "\n"
                "Run schema.sql, sample_data.sql and queries.sql in MySQL first (in this order).")
    return None


def main():
    print("Retail Inventory and Sales Management System")
    password = os.environ.get("RETAIL_DB_PASSWORD")
    if password is None:
        password = getpass.getpass(f"MySQL password for user '{os.environ.get('RETAIL_DB_USER', config.DB_USER)}': ")
    app.config["DB_PASSWORD"] = password

    problem = check_database()
    if problem:
        print("\n" + problem)
        sys.exit(1)

    print(f"\nConnected. Open http://{config.WEB_HOST}:{config.WEB_PORT} in your browser.")
    print("Press Ctrl+C here to stop.")
    app.run(host=config.WEB_HOST, port=config.WEB_PORT, debug=False)


if __name__ == "__main__":
    main()
