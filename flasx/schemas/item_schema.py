from unicodedata import decimal
from pydantic import BaseModel
from . import receiver_schema


class Item(BaseModel):
    name: str
    delivery_price: decimal.Decimal = 0.0
    receiver: receiver_schema.Receiver
