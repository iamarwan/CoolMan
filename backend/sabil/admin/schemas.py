# admin/schemas.py

from pydantic import BaseModel


class AdminLoginRequest(BaseModel):
    username: str
    password: str
