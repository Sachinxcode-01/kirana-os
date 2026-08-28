import os
import uuid
import psycopg2
from dotenv import load_dotenv

env_path = os.path.join(os.path.dirname(__file__), '../apps/mobile/.env')
load_dotenv(env_path)

direct_url = os.getenv('DIRECT_URL', 'postgresql://postgres.ehjijetpbnsqswlxmzjv:%263%25Q3nDKkiUk%26bA@aws-0-ap-south-1.pooler.supabase.com:5432/postgres')
shop_id = "6dc90524-1e96-443d-b4c4-9e6dc8961783"

print("Connecting to live Supabase PostgreSQL...")
conn = psycopg2.connect(direct_url)
cursor = conn.cursor()

try:
    print("1. Creating live test product and supplier...")
    prod_id = str(uuid.uuid4())
    supp_id = str(uuid.uuid4())
    pur_id = str(uuid.uuid4())
    pur_item_id = str(uuid.uuid4())

    # Insert test product
    cursor.execute("""
        INSERT INTO products (id, shop_id, name, mrp_paise, selling_price_paise, purchase_price_paise, current_stock, unit)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """, (prod_id, shop_id, "Live Test Basmati Rice 5kg", 35000, 35000, 28000, 10.0, "bag"))

    # Insert test supplier
    cursor.execute("""
        INSERT INTO suppliers (id, shop_id, name, phone, current_balance_paise)
        VALUES (%s, %s, %s, %s, %s)
    """, (supp_id, shop_id, "Live Test Grain Wholesaler", "9988776655", 0))

    conn.commit()

    print("2. Recording stock purchase entry in Supabase...")
    # Insert purchase invoice
    cursor.execute("""
        INSERT INTO purchases (id, shop_id, supplier_id, supplier_name_snapshot, invoice_number, invoice_date, subtotal_paise, tax_total_paise, total_paise, status)
        VALUES (%s, %s, %s, %s, %s, NOW(), %s, %s, %s, %s)
    """, (pur_id, shop_id, supp_id, "Live Test Grain Wholesaler", "INV-LIVE-001", 140000, 0, 140000, "completed"))

    # Insert purchase item
    cursor.execute("""
        INSERT INTO purchase_items (id, purchase_id, product_id, quantity, purchase_price_paise, tax_rate, total_paise)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, (pur_item_id, pur_id, prod_id, 5.0, 28000, 0.0, 140000))

    # Update product stock (+5 bags)
    cursor.execute("""
        UPDATE products SET current_stock = current_stock + 5.0 WHERE id = %s
    """, (prod_id,))

    # Update supplier payable balance (+ Rs 1,400.00 / 140,000 paise)
    cursor.execute("""
        UPDATE suppliers SET current_balance_paise = current_balance_paise + 140000 WHERE id = %s
    """, (supp_id,))

    conn.commit()

    # 3. Verification step 1
    cursor.execute("SELECT current_stock FROM products WHERE id = %s", (prod_id,))
    stock = cursor.fetchone()[0]

    cursor.execute("SELECT current_balance_paise FROM suppliers WHERE id = %s", (supp_id,))
    balance = cursor.fetchone()[0]

    print(f"VERIFICATION 1 -> Product stock after purchase: {stock} (Expected: 15.0)")
    print(f"VERIFICATION 1 -> Supplier payable balance after purchase: {balance} paise (Expected: 140000 paise / Rs 1,400)")

    assert float(stock) == 15.0, f"Stock mismatch! Got {stock}"
    assert int(balance) == 140000, f"Balance mismatch! Got {balance}"

    print("4. Recording supplier payment settlement of Rs 800 (80,000 paise)...")
    cursor.execute("""
        UPDATE suppliers SET current_balance_paise = current_balance_paise - 80000 WHERE id = %s
    """, (supp_id,))
    conn.commit()

    cursor.execute("SELECT current_balance_paise FROM suppliers WHERE id = %s", (supp_id,))
    new_balance = cursor.fetchone()[0]

    print(f"VERIFICATION 2 -> Supplier payable balance after payment: {new_balance} paise (Expected: 60000 paise / Rs 600)")
    assert int(new_balance) == 60000, f"New balance mismatch! Got {new_balance}"

    print("[SUCCESS] LIVE SUPABASE POSTGRESQL VERIFICATION SUCCESSFUL!")

except Exception as e:
    conn.rollback()
    print(f"Error occurred: {e}")
    raise e

finally:
    print("Cleaning up live test data...")
    try:
        cursor.execute("DELETE FROM purchase_items WHERE id = %s", (pur_item_id,))
        cursor.execute("DELETE FROM purchases WHERE id = %s", (pur_id,))
        cursor.execute("DELETE FROM suppliers WHERE id = %s", (supp_id,))
        cursor.execute("DELETE FROM products WHERE id = %s", (prod_id,))
        conn.commit()
    except Exception as cleanup_err:
        print(f"Cleanup note: {cleanup_err}")
    finally:
        cursor.close()
        conn.close()
