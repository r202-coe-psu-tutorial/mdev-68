from fastapi import APIRouter
from . import v1
from . import health

router = APIRouter()
router.include_router(v1.router)
router.include_router(health.router)
