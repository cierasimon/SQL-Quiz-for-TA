import os
import sys
import psycopg2
from psycopg2 import errors
from dotenv import load_dotenv

# Read .env. The same script works for Docker (localhost) and Supabase (cloud);
# only the values in .env change.

load_dotenv()

def env(name, default=None):
    value = os.getenv(name, default)
    return value.strip() if value else value


DB_NAME = env("POSTGRES_DB", "postgres")
DB_USER = env("POSTGRES_USER")
DB_PASSWORD = env("POSTGRES_PASSWORD")
DB_HOST = env("DB_HOST")
DB_PORT = env("DB_PORT", "5432")
DB_SSLMODE = env("DB_SSLMODE", "require")

# Five questions x 4 points = 20 points. Hint SQL uses %s parameters, never f-strings.
QUESTIONS = [
    {
        "id": 1,
        "points": 4,
        "prompt": "List the name and retail_price of every garment priced above $1,200, most expensive first.",
        "hint_sql": """
            SELECT name, retail_price
            FROM garments
            WHERE retail_price > %s
            ORDER BY retail_price DESC;
        """,
        "params": (1200,),
    },
    {
        "id": 2,
        "points": 4,
        "prompt": "How many garments are there in each category? Show category and count, highest count first (ties alphabetical).",
        "hint_sql": """
            SELECT category, COUNT(*) AS garment_count
            FROM garments
            GROUP BY category
            ORDER BY garment_count DESC, category ASC;
        """,
        "params": (),
    },
    {
        "id": 3,
        "points": 4,
        "prompt": "Show the garment name and brand for every ankle boot, ordered by brand.",
        "hint_sql": """
            SELECT g.name, c.brand
            FROM garments g
            JOIN collections c ON c.collection_id = g.collection_id
            WHERE g.category = %s
            ORDER BY c.brand ASC, g.name ASC;
        """,
        "params": ("ankle boot",),
    },
    {
        "id": 4,
        "points": 4,
        "prompt": "What is the total revenue (quantity * unit_price) per brand, counting only 'paid' and 'shipped' sales? Highest first.",
        "hint_sql": """
            SELECT c.brand, SUM(s.quantity * s.unit_price) AS revenue
            FROM sales s
            JOIN garments g ON g.garment_id = s.garment_id
            JOIN collections c ON c.collection_id = g.collection_id
            WHERE s.status IN (%s, %s)
            GROUP BY c.brand
            ORDER BY revenue DESC, c.brand ASC;
        """,
        "params": ("paid", "shipped"),
    },
    {
        "id": 5,
        "points": 4,
        "prompt": "Using a CTE, list the brands whose paid/shipped revenue is above the average brand revenue.",
        "hint_sql": """
            WITH brand_revenue AS (
                SELECT c.brand, SUM(s.quantity * s.unit_price) AS revenue
                FROM sales s
                JOIN garments g ON g.garment_id = s.garment_id
                JOIN collections c ON c.collection_id = g.collection_id
                WHERE s.status IN (%s, %s)
                GROUP BY c.brand
            )
            SELECT brand, revenue
            FROM brand_revenue
            WHERE revenue > (SELECT AVG(revenue) FROM brand_revenue)
            ORDER BY revenue DESC;
        """,
        "params": ("paid", "shipped"),
    },
]

assert sum(q["points"] for q in QUESTIONS) == 20, "Quiz points must sum to 20"


def connect():
    missing = [k for k, v in {"POSTGRES_USER": DB_USER, "POSTGRES_PASSWORD": DB_PASSWORD, "DB_HOST": DB_HOST}.items() if not v]
    if missing:
        sys.exit(f"Missing environment variables: {', '.join(missing)}")
    return psycopg2.connect(
        dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD,
        host=DB_HOST, port=DB_PORT, sslmode=DB_SSLMODE,
    )


def run_select(conn, sql, params=()):
    """Run one read-only query inside a read-only transaction; return (columns, rows)."""
    with conn.cursor() as cur:
        cur.execute("SET statement_timeout = 5000")  # 5s cap on taker queries
        cur.execute(sql, params or None)
        cols = [d[0] for d in cur.description]
        rows = cur.fetchall()
    return cols, rows


def run_taker_sql(conn, sql):
    """Guardrails for SQL typed by a quiz taker: single SELECT/WITH only, read-only session.

    The real protection is the database: connect with a role that only has SELECT.
    These checks are a second layer, not a substitute.
    """
    cleaned = sql.strip().rstrip(";").strip()
    if ";" in cleaned:
        raise ValueError("Only one statement is allowed.")
    if not cleaned.lower().startswith(("select", "with")):
        raise ValueError("Only SELECT queries are allowed.")
    try:
        return run_select(conn, cleaned.replace("%", "%%"))
    except psycopg2.Error:
        conn.rollback()
        raise


def print_table(cols, rows):
    print(" | ".join(cols))
    print("-" * 40)
    for row in rows:
        print(" | ".join(str(v) for v in row))
    print(f"({len(rows)} rows)")


def main():
    conn = connect()
    conn.set_session(readonly=True)  # hint runs can never modify data
    print(f"Connected to {DB_NAME} at {DB_HOST}:{DB_PORT} as {DB_USER}\n")

    if len(sys.argv) > 1:
        try:
            print_table(*run_taker_sql(conn, sys.argv[1]))
        except (ValueError, psycopg2.Error) as e:
            print("Query rejected/failed:", str(e).strip().splitlines()[0])
    else:
        for q in QUESTIONS:
            print(f"Q{q['id']} ({q['points']} pts): {q['prompt']}")
            print_table(*run_select(conn, q["hint_sql"], q["params"]))
            print()

    conn.close()


if __name__ == "__main__":
    main()