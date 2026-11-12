"""Nwasy financial model. Change the numbers in ASSUMPTIONS and run:

    python docs/master-plan/financial_model.py

It prints the tables used in the business plan and rewrites
financial-model.csv next to this file. Every number here is an assumption
until replaced by a real quote or real sales. All amounts are Egyptian pounds.
"""

import csv
from pathlib import Path

ASSUMPTIONS = {
    # ── Cost to build one sabil (one-time) ──────────────────────────────────
    "cooler_unit": 9_000,        # 3-tap stainless street cooler (retail range found: 5,500-10,000+)
    "filter_kit": 1_000,         # 3-stage filter housing with first cartridges
    "installation": 2_000,       # plumbing, electrics, fixing; ASSUMPTION, get a quote
    "plaque": 500,               # dedication plaque with QR code
    # ── Cost to look after one cooler for a year ────────────────────────────
    "cartridges_per_year": 1_800,  # 3-4 changes at 450-500 a set
    "visit_cost": 250,             # technician visit; ASSUMPTION
    "visits_per_year": 12,
    "repairs_reserve": 1_200,      # set aside per cooler per year
    # ── Prices ──────────────────────────────────────────────────────────────
    "price_sabil": 24_900,       # new cooler + first year of care + proof page
    "price_care_year": 9_900,    # a year of care: renewals and existing coolers
    "price_corporate_sabil": 22_000,  # per cooler in a company network (volume price)
    "payment_fee": 0.025,        # card / wallet fees on revenue; ASSUMPTION
    "renewal_rate": 0.70,        # share of cared-for coolers that renew each year
    # ── Volumes per year ────────────────────────────────────────────────────
    "new_sabils": [60, 240, 600],
    "new_care_plans": [40, 200, 500],       # existing coolers joining a care plan
    "corporate_sabils": [0, 40, 300],
    "new_plan_year_share": 0.5,             # a plan sold mid-year earns half a year
    # ── Street vendors (food trucks, coffee carts): monthly subscription ────
    # Free listing for everyone; paid plan adds a highlighted pin, menu,
    # photos and "open now" alerts to followers. Charged only in districts
    # where the app already has an audience (so: nothing for most of year 1).
    "vendor_price_month": 250,
    "vendor_avg_paying": [10, 360, 2100],   # average number of paying vendors across the year
    "vendor_direct_share": 0.20,            # payment fees, support, sales commission
    # ── Running costs per year (not tied to a cooler) ───────────────────────
    "team": [90_000, 1_010_000, 2_600_000],
    "marketing": [120_000, 400_000, 900_000],
    "technology": [36_000, 120_000, 300_000],
    "legal_admin": [60_000, 120_000, 250_000],
    "other": [24_000, 100_000, 200_000],
}


def model(a: dict) -> list[dict]:
    setup = a["cooler_unit"] + a["filter_kit"] + a["installation"] + a["plaque"]
    care = a["cartridges_per_year"] + a["visit_cost"] * a["visits_per_year"] + a["repairs_reserve"]
    rows = []
    under_care_last_year = 0.0
    for y in range(3):
        sabils, plans, corp = a["new_sabils"][y], a["new_care_plans"][y], a["corporate_sabils"][y]
        renewals = under_care_last_year * a["renewal_rate"]

        vendor_revenue = a["vendor_avg_paying"][y] * a["vendor_price_month"] * 12
        revenue = (
            vendor_revenue
            + sabils * a["price_sabil"]
            + corp * a["price_corporate_sabil"]
            + plans * a["price_care_year"] * a["new_plan_year_share"]
            + renewals * a["price_care_year"]
        )
        direct = (
            (sabils + corp) * (setup + care)
            + plans * care * a["new_plan_year_share"]
            + renewals * care
            + (revenue - vendor_revenue) * a["payment_fee"]
            + vendor_revenue * a["vendor_direct_share"]
        )
        running = sum(a[k][y] for k in ("team", "marketing", "technology", "legal_admin", "other"))
        under_care = sabils + corp + plans + renewals
        rows.append(
            {
                "year": y + 1,
                "new_sabils": sabils,
                "corporate_sabils": corp,
                "new_care_plans": plans,
                "renewals": round(renewals),
                "coolers_under_care": round(under_care),
                "paying_vendors_avg": a["vendor_avg_paying"][y],
                "revenue_water": round(revenue - vendor_revenue),
                "revenue_vendors": round(vendor_revenue),
                "revenue": round(revenue),
                "direct_costs": round(direct),
                "gross_profit": round(revenue - direct),
                "gross_margin_pct": round(100 * (revenue - direct) / revenue, 1),
                "running_costs": running,
                "profit_before_tax": round(revenue - direct - running),
            }
        )
        under_care_last_year = under_care
    return rows


def unit_economics(a: dict) -> dict:
    setup = a["cooler_unit"] + a["filter_kit"] + a["installation"] + a["plaque"]
    care = a["cartridges_per_year"] + a["visit_cost"] * a["visits_per_year"] + a["repairs_reserve"]
    fee_sabil = a["price_sabil"] * a["payment_fee"]
    fee_care = a["price_care_year"] * a["payment_fee"]
    return {
        "setup_cost": setup,
        "care_cost_per_year": care,
        "sabil_cost_year_one": setup + care,
        "sabil_profit": round(a["price_sabil"] - setup - care - fee_sabil),
        "sabil_margin_pct": round(100 * (a["price_sabil"] - setup - care - fee_sabil) / a["price_sabil"], 1),
        "care_profit": round(a["price_care_year"] - care - fee_care),
        "care_margin_pct": round(100 * (a["price_care_year"] - care - fee_care) / a["price_care_year"], 1),
    }


def break_even_sabils(a: dict, year: int = 0) -> int:
    """New sabils needed in a year to cover that year's running costs (no care plans)."""
    u = unit_economics(a)
    running = sum(a[k][year] for k in ("team", "marketing", "technology", "legal_admin", "other"))
    return -(-running // u["sabil_profit"])


if __name__ == "__main__":
    u = unit_economics(ASSUMPTIONS)
    print("Per cooler")
    for k, v in u.items():
        print(f"  {k:<22} {v:>10,}")
    print(f"  break-even year 1      {break_even_sabils(ASSUMPTIONS):>10,} new sabils")
    rows = model(ASSUMPTIONS)
    print("\nThree years")
    for k in rows[0]:
        print(f"  {k:<20}" + "".join(f"{r[k]:>14,}" for r in rows))
    out = Path(__file__).with_name("financial-model.csv")
    with out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print(f"\nWrote {out.name}")
