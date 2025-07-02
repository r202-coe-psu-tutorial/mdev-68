from decimal import Decimal
from typing import Optional
from datetime import datetime
from sqlmodel import SQLModel, Field, Relationship

from ..schemas import item_schema


class Item(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)

    # Relationship
    # receiver: Optional["receiver_model.Receiver"] = Relationship(back_populates="items")
