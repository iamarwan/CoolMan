# scripts/seed.py
#
# Inserts 5 sample coolers in Maadi, Cairo so the map is not empty.
# Run from the backend/ folder while the database is running:
#
#     python -m scripts.seed

import asyncio

from geoalchemy2.elements import WKTElement

from sabil.coolers.models import CoolerStatus, WaterCooler
from sabil.core.database import AsyncSessionLocal, init_db

SAMPLE_COOLERS = [
    {"name": "Maadi Metro Station Cooler", "latitude": 29.9596, "longitude": 31.2575, "status": CoolerStatus.Working},
    {"name": "Road 9 Public Cooler", "latitude": 29.9621, "longitude": 31.2601, "status": CoolerStatus.Working},
    {"name": "Maadi Corniche Cooler", "latitude": 29.9558, "longitude": 31.2329, "status": CoolerStatus.Empty},
    {"name": "Maadi Grand Mall Cooler", "latitude": 29.9609, "longitude": 31.2572, "status": CoolerStatus.Broken},
    {"name": "Maadi Sporting Club Cooler", "latitude": 29.9719, "longitude": 31.2498, "status": CoolerStatus.Working},
]


async def seed():
    await init_db()

    async with AsyncSessionLocal() as session:
        for data in SAMPLE_COOLERS:
            geom = WKTElement(f"POINT({data['longitude']} {data['latitude']})", srid=4326)
            cooler = WaterCooler(
                name=data["name"],
                latitude=data["latitude"],
                longitude=data["longitude"],
                geom=geom,
                status=data["status"],
                is_approved=True,
            )
            session.add(cooler)
        await session.commit()


if __name__ == "__main__":
    asyncio.run(seed())
