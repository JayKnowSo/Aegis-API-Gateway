import psycopg # or use your existing engine

# Update these with your actual db details
conn = psycopg.connect("dbname=greeting_app user=greeting_user password=Kissjada88$")
cur = conn.cursor()

try:
    cur.execute("ALTER TABLE sessionrecord ADD COLUMN number INTEGER;")
    conn.commit()
    print("Column added successfully!")
except Exception as e:
    print(f"Error: {e}")
finally:
    cur.close()
    conn.close()
