import asyncio
from database import engine
from sqlalchemy import text

async def fix_db():
    async with engine.begin() as conn:
        # Original fix: is_rejected column
        try:
            await conn.execute(text("ALTER TABLE water_coolers ADD COLUMN is_rejected BOOLEAN DEFAULT FALSE;"))
            print("SUCCESS: Added 'is_rejected' column to 'water_coolers' table.")
        except Exception as e:
            print(f"NOTE: Could not add 'is_rejected' column. It might already exist.\nDetails: {e}")

        # FIX: Add pending_status_user_id column for tracking who submitted a status update
        try:
            await conn.execute(text(
                "ALTER TABLE water_coolers ADD COLUMN pending_status_user_id UUID REFERENCES users(id) ON DELETE SET NULL;"
            ))
            print("SUCCESS: Added 'pending_status_user_id' column to 'water_coolers' table.")
        except Exception as e:
            print(f"NOTE: Could not add 'pending_status_user_id' column. It might already exist.\nDetails: {e}")

if __name__ == "__main__":
    asyncio.run(fix_db())
