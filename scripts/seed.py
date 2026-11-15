"""Load sample data (Maadi, Cairo) for development.

    python -m scripts.seed

Creates two test accounts (development only):
    tester   / tester1234   (new user, submissions need approval)
    trusted  / trusted1234  (trust 600, submissions go live instantly)
"""

import asyncio

from sqlalchemy import select

from app.config import get_settings
from app.db import SessionLocal, engine
from app.models import CoolerStatus, CupsType, Sponsor, SponsorType, User, WaterCooler
from app.security import hash_password
from app.services.coolers import point

W, E, B = CoolerStatus.Working, CoolerStatus.Empty, CoolerStatus.Broken

COOLERS = [
    ("Maadi Metro Station", 29.9596, 31.2575, W, True, CupsType.Disposable),
    ("Road 9 Public Cooler", 29.9621, 31.2601, W, True, CupsType.Communal),
    ("Maadi Corniche", 29.9558, 31.2329, E, False, None),
    ("Maadi Grand Mall", 29.9609, 31.2572, B, None, None),
    ("Maadi Sporting Club Gate", 29.9719, 31.2498, W, True, CupsType.Disposable),
    ("Next to El-Tawheed Mosque", 29.9645, 31.2560, W, True, CupsType.Communal),
    ("Victoria Square", 29.9603, 31.2490, W, False, None),
    ("Road 77 Pharmacy Corner", 29.9568, 31.2643, W, True, CupsType.Disposable),
    ("Degla Square", 29.9590, 31.2790, E, None, None),
    ("Road 233 Bakery", 29.9527, 31.2709, W, True, CupsType.Communal),
    ("Saqr Qoraish Bus Stop", 29.9480, 31.2930, B, None, None),
    ("Maadi Hospital Entrance", 29.9672, 31.2461, W, True, CupsType.Disposable),
    ("Thakanat El Maadi", 29.9697, 31.2563, W, False, None),
    ("Road 13 Garden", 29.9631, 31.2522, W, True, CupsType.Communal),
    ("Zahraa El Maadi Market", 29.9620, 31.2980, E, True, CupsType.Communal),
]


async def seed() -> None:
    if get_settings().is_production:
        raise SystemExit("Refusing to seed a production database.")
    async with SessionLocal() as db:
        if await db.scalar(select(WaterCooler.id).limit(1)):
            print("Database already has coolers; skipping seed.")
            return

        sponsor = Sponsor(
            name="El-Borg Pharmacy",
            sponsor_type=SponsorType.Business,
            contact="+20 2 0000 0000",
            verified=True,
        )
        mosque = Sponsor(name="El-Tawheed Mosque", sponsor_type=SponsorType.Mosque, verified=True)
        db.add_all([sponsor, mosque])
        await db.flush()

        for i, (name, lat, lng, status, has_cups, cups_type) in enumerate(COOLERS):
            db.add(
                WaterCooler(
                    name=name,
                    latitude=lat,
                    longitude=lng,
                    geom=point(lat, lng),
                    status=status,
                    has_cups=has_cups,
                    cups_type=cups_type,
                    is_approved=True,
                    sponsor_id=sponsor.id if i == 7 else mosque.id if i == 5 else None,
                )
            )

        db.add_all(
            [
                User(username="tester", hashed_password=await hash_password("tester1234")),
                User(
                    username="trusted",
                    hashed_password=await hash_password("trusted1234"),
                    trust_score=600,
                ),
            ]
        )
        await db.commit()
        print(f"Seeded {len(COOLERS)} coolers, 2 sponsors and 2 test users.")
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(seed())
