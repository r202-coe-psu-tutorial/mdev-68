from fastapi import APIRouter


router = APIRouter(prefix="/hello", tags=["hello"])


@router.get(
    "",
    summary="Say Hello",
    description="Returns a simple greeting message.",
    response_model=str,
)
async def say_hello() -> str:
    """Endpoint to say hello."""
    return "Hello, World!"
