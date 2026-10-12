# seed.py
import asyncio
from sqlalchemy import text
from geoalchemy2.elements import WKTElement
from database import engine, Base, AsyncSessionLocal
from models import WaterCooler, CoolerStatus

SAMPLE_COOLERS = [
    {"name": "Maadi Metro Station Cooler", "latitude": 29.9596, "longitude": 31.2575, "status": CoolerStatus.Working},
    {"name": "Road 9 Public Cooler", "latitude": 29.9621, "longitude": 31.2601, "status": CoolerStatus.Working},
    {"name": "Maadi Corniche Cooler", "latitude": 29.9558, "longitude": 31.2329, "status": CoolerStatus.Empty},
    {"name": "Maadi Grand Mall Cooler", "latitude": 29.9609, "longitude": 31.2572, "status": CoolerStatus.Broken},
    {"name": "Maadi Sporting Club Cooler", "latitude": 29.9719, "longitude": 31.2498, "status": CoolerStatus.Working},
]

async def seed():
    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        await conn.run_sync(Base.metadata.create_all)

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
