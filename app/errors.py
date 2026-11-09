"""API errors with stable machine-readable codes.

Responses look like: {"detail": "Human message", "code": "cooler_not_found"}.
The app translates `code` (English/Arabic); `detail` stays as a fallback.
"""

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class ApiError(Exception):
    def __init__(self, status_code: int, code: str, detail: str, **extra):
        self.status_code = status_code
        self.code = code
        self.detail = detail
        self.extra = extra


def not_found(what: str) -> ApiError:
    return ApiError(404, f"{what}_not_found", f"{what.capitalize()} not found.")


def install_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(ApiError)
    async def _api_error(_: Request, exc: ApiError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": exc.detail, "code": exc.code, **exc.extra},
        )
