"""
Generate synthetic retail data matching the raw tables the loader and dbt
staging models expect: customers.csv, products.csv, sales.csv.

    python scripts/generate_sample_data.py --out data/

Deterministic (seeded) so the committed sample in data/ can be regenerated.
All names and emails are fake.
"""
from __future__ import annotations

import argparse
import csv
import random
from datetime import date, timedelta
from pathlib import Path

FIRST = ["Ava", "Liam", "Noah", "Emma", "Olivia", "Mia", "Lucas", "Amir", "Priya", "Chen",
         "Sofia", "Mateo", "Zara", "Ethan", "Leah", "Omar", "Nina", "Ravi", "Hana", "Jack"]
LAST = ["Smith", "Patel", "Nguyen", "Garcia", "Brown", "Khan", "Martin", "Lee", "Singh", "Lopez",
        "Wilson", "Kim", "Clark", "Silva", "Ahmed", "Walker", "Young", "Hall", "Wright", "Lewis"]
PLACES = {"Canada": ["Toronto", "Vancouver", "Montreal", "Calgary"],
          "United States": ["Chicago", "Austin", "Seattle", "Boston"],
          "United Kingdom": ["London", "Manchester", "Leeds"]}
CATEGORIES = {"electronics": (40, 900), "home": (10, 300), "apparel": (8, 150),
              "sports": (15, 400), "beauty": (5, 90)}
CHANNELS = ["online", "store", "mobile_app"]
START, END = date(2023, 7, 1), date(2024, 12, 31)


def customers(n: int, rng: random.Random) -> list[dict]:
    rows = []
    for i in range(1, n + 1):
        country = rng.choice(list(PLACES))
        first, last = rng.choice(FIRST), rng.choice(LAST)
        rows.append({
            "customer_id": f"C{i:05d}",
            "first_name": first,
            "last_name": last,
            "email": f"{first}.{last}.{i}@example.com".lower(),
            "country": country,
            "city": rng.choice(PLACES[country]),
            "registration_date": (START + timedelta(days=rng.randint(0, 365))).isoformat(),
            "is_active": rng.random() > 0.08,
        })
    return rows


def products(n: int, rng: random.Random) -> list[dict]:
    rows = []
    for i in range(1, n + 1):
        cat = rng.choice(list(CATEGORIES))
        lo, hi = CATEGORIES[cat]
        price = round(rng.uniform(lo, hi), 2)
        rows.append({
            "product_id": f"P{i:04d}",
            "product_name": f"{cat.title()} item {i}",
            "category": cat,
            "unit_price": price,
            "unit_cost": round(price * rng.uniform(0.45, 0.85), 2),
            "stock_quantity": rng.randint(0, 500),
        })
    return rows


def sales(custs: list[dict], prods: list[dict], rng: random.Random) -> list[dict]:
    rows, sale_no = [], 0
    for c in custs:
        first = date.fromisoformat(c["registration_date"])
        # each customer is active for a while, then may stop buying (churn)
        last_active = min(END, first + timedelta(days=rng.randint(30, 560)))
        n_orders = rng.randint(1, 14)
        for _ in range(n_orders):
            day = first + timedelta(days=rng.randint(0, max(0, (last_active - first).days)))
            p = rng.choice(prods)
            sale_no += 1
            rows.append({
                "sale_id": f"S{sale_no:06d}",
                "customer_id": c["customer_id"],
                "product_id": p["product_id"],
                "sale_date": day.isoformat(),
                "quantity": rng.choices([1, 2, 3, 4], weights=[60, 25, 10, 5])[0],
                "unit_price": p["unit_price"],
                "discount_pct": rng.choice([0, 0, 0, 0.05, 0.1, 0.15, 0.2]),
                "channel": rng.choice(CHANNELS),
            })
    rows.sort(key=lambda r: (r["sale_date"], r["sale_id"]))
    return rows


def write(path: Path, rows: list[dict]) -> None:
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print(f"{len(rows):>6,} rows -> {path}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--customers", type=int, default=500)
    ap.add_argument("--products", type=int, default=60)
    ap.add_argument("--out", default="data")
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()

    rng = random.Random(args.seed)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    custs, prods = customers(args.customers, rng), products(args.products, rng)
    write(out / "customers.csv", custs)
    write(out / "products.csv", prods)
    write(out / "sales.csv", sales(custs, prods, rng))


if __name__ == "__main__":
    main()
