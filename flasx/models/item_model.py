from decimal import Decimal
from typing import Optional, TYPE_CHECKING
import datetime
from sqlmodel import SQLModel, Field, Relationship

from ..schemas import item_schema

if TYPE_CHECKING:
    from .customer_model import Customer


class Item(SQLModel, item_schema.ItemBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime.datetime = Field(default_factory=datetime.datetime.now)
    updated_at: datetime.datetime = Field(default_factory=datetime.datetime.now)

    # Foreign key and relationship
    customer_id: Optional[int] = Field(default=None, foreign_key="customer.id")
    customer: Optional["Customer"] = Relationship()
