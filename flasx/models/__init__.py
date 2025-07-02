# Models package
# Import order matters to avoid circular imports

from .receiver_model import *
from .item_model import *
from sqlmodel import SQLModel, create_engine


engine = create_engine("sqlite:///database.db")


def create_db_and_tables():
    """Create the database and tables."""
    SQLModel.metadata.create_all(engine)
    print("Database and tables created successfully.")
