from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def read_root() -> dict:
    return {"Hello": "World"}


@app.get("/items/{item_id}")
async def read_item(item_id: int, q: str | None = None) -> dict:
    return {"item_id": item_id, "q": q}


@app.post("/items")
async def create_item(item: dict) -> dict:
    return {"item": item}


@app.put("/items/{item_id}")
async def update_item(item_id: int, item: dict) -> dict:
    return {"item_id": item_id, "item": item}


@app.delete("/items/{item_id}")
async def delete_item(item_id: int) -> dict:
    return {"message": f"Item with id {item_id} deleted successfully."}
