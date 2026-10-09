"""
Generate synthetic B2B SaaS GTM data for the analytics stack.

Writes three CSVs into ../seeds/ (loaded into the warehouse with `dbt seed`):
  raw_deals.csv          one row per deal
  raw_touches.csv        marketing/sales touches that preceded each deal
  raw_stage_history.csv  every stage each deal entered, with the date

All data is synthetic. Run:  python scripts/generate_data.py
"""
import csv
import random
from datetime import date, timedelta
from pathlib import Path

random.seed(42)

N_DEALS = 400
START = date(2025, 10, 1)
END = date(2026, 9, 30)  # "today" for the dataset
OUT = Path(__file__).resolve().parent.parent / "seeds"

STAGES = ["Prospecting", "Discovery", "Demo", "Proposal", "Negotiation"]
# chance a deal advances from each stage to the next (Negotiation -> Won)
ADVANCE = {"Prospecting": 0.80, "Discovery": 0.75, "Demo": 0.72,
           "Proposal": 0.70, "Negotiation": 0.78}
DAYS_IN_STAGE = {"Prospecting": (7, 21), "Discovery": (10, 28), "Demo": (10, 28),
                 "Proposal": (14, 35), "Negotiation": (10, 30)}

# channel -> relative weight of sourcing deals, and a win-rate multiplier
CHANNELS = {
    "Cold Email": (0.35, 0.85),
    "LinkedIn": (0.25, 1.00),
    "Referral": (0.10, 1.40),
    "Webinar": (0.15, 1.10),
    "Inbound Website": (0.15, 1.20),
}
SEGMENTS = {"SMB": (8_000, 20_000), "Mid-Market": (20_000, 60_000),
            "Enterprise": (60_000, 150_000)}
OWNERS = ["Alex Morgan", "Priya Shah", "Tom Reid", "Grace Okafor"]
INDUSTRIES = ["Asset Management", "Hedge Fund", "Private Equity",
              "Wealth Management", "Fintech", "Insurance"]
PREFIX = ["North", "Harbour", "Granite", "Summit", "Clear", "Oak", "Atlas",
          "Beacon", "Silver", "Meridian", "Kestrel", "Thistle", "Forth", "Tay"]
SUFFIX = ["Capital", "Partners", "Investments", "Advisors", "Analytics",
          "Asset Management", "Holdings", "Group"]


def pick_weighted(options: dict) -> str:
    names = list(options)
    return random.choices(names, weights=[options[n][0] for n in names])[0]


deals, touches, history = [], [], []
touch_id = 0

for i in range(1, N_DEALS + 1):
    deal_id = f"D{i:04d}"
    created = START + timedelta(days=random.randint(0, (END - START).days - 5))
    segment = random.choices(list(SEGMENTS), weights=[0.5, 0.35, 0.15])[0]
    amount = round(random.uniform(*SEGMENTS[segment]) / 500) * 500
    source = pick_weighted(CHANNELS)
    win_mult = CHANNELS[source][1]

    # walk the deal through stages until it is lost, won, or reaches "today"
    current, d, outcome = None, created, "Open"
    for stage in STAGES:
        history.append([deal_id, stage, d.isoformat()])
        current = stage
        d += timedelta(days=random.randint(*DAYS_IN_STAGE[stage]))
        if d > END:
            break  # still sitting in this stage today
        if random.random() > min(ADVANCE[stage] * win_mult ** 0.5, 0.95):
            outcome = "Closed Lost"
            break
    else:
        if d <= END:
            outcome = "Closed Won"

    if outcome == "Open":
        close_date = ""
        expected_close = (d + timedelta(days=random.randint(10, 60))).isoformat()
        stage = current
    else:
        close_date = d.isoformat()
        expected_close = close_date
        stage = outcome
        history.append([deal_id, outcome, close_date])

    deals.append([deal_id, f"{random.choice(PREFIX)} {random.choice(SUFFIX)}",
                  random.choice(INDUSTRIES), segment, random.choice(OWNERS),
                  amount, stage, created.isoformat(), expected_close, close_date,
                  source])

    # 1-5 touches in the 60 days before the deal was created.
    # The first touch is always the sourcing channel.
    n = random.randint(1, 5)
    touch_dates = sorted(created - timedelta(days=random.randint(0, 60)) for _ in range(n))
    for j, td in enumerate(touch_dates):
        touch_id += 1
        channel = source if j == 0 else random.choice(list(CHANNELS))
        touches.append([f"T{touch_id:05d}", deal_id, channel, td.isoformat()])

OUT.mkdir(exist_ok=True)
files = {
    "raw_deals.csv": (["deal_id", "company_name", "industry", "segment", "owner",
                       "amount_gbp", "stage", "created_date", "expected_close_date",
                       "close_date", "source_channel"], deals),
    "raw_touches.csv": (["touch_id", "deal_id", "channel", "touch_date"], touches),
    "raw_stage_history.csv": (["deal_id", "stage", "entered_date"], history),
}
for name, (header, rows) in files.items():
    with open(OUT / name, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)
    print(f"wrote {len(rows):>5} rows -> seeds/{name}")
