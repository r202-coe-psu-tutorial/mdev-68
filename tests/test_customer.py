import pytest
from fastapi.testclient import TestClient
from flasx.main import app
from sqlmodel import SQLModel, Session, create_engine
from sqlalchemy.pool import StaticPool
from flasx.models import get_session


# Use synchronous engine and session for compatibility with TestClient
@pytest.fixture(name="session")
def session_fixture():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    SQLModel.metadata.drop_all(engine)
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session


@pytest.fixture(name="client")
def client_fixture(session):
    def get_session_override():
        return session

    app.dependency_overrides[get_session] = get_session_override

    client = TestClient(app)
    yield client
    app.dependency_overrides.clear()


@pytest.fixture
def customer_data():
    return {"name": "John Doe", "email": "john@example.com", "phone": "1234567890"}


def test_create_customer(client, customer_data):
    response = client.post("/v1/customers", json=customer_data)

    assert response.status_code == 202
    data = response.json()
    assert data["name"] == customer_data["name"]
    assert data["email"] == customer_data["email"]
    assert "id" in data


# def test_get_customers(client):
#     response = client.get("/v1/customers")
#     assert response.status_code == 200
#     assert isinstance(response.json(), list)


# def test_get_customer_by_id(client, customer_data):
#     # Create a customer first
#     create_resp = client.post("/v1/customers", json=customer_data)
#     print(create_resp.json())
#     customer_id = create_resp.json()["id"]
#     # Retrieve the customer
#     response = client.get(f"/v1/customers/{customer_id}")
#     assert response.status_code == 200
#     data = response.json()
#     print(data)
#     assert data["id"] == customer_id


# def test_update_customer(client, customer_data):
#     # Create a customer first
#     create_resp = client.post("/v1/customers", json=customer_data)
#     customer_id = create_resp.json()["id"]
#     updated_data = customer_data.copy()
#     updated_data["name"] = "Jane Doe"
#     response = client.put(f"/v1/customers/{customer_id}", json=updated_data)
#     assert response.status_code == 200
#     assert response.json()["name"] == "Jane Doe"


# def test_delete_customer(client, customer_data):
#     # Create a customer first
#     create_resp = client.post("/v1/customers", json=customer_data)
#     customer_id = create_resp.json()["id"]
#     response = client.delete(f"/v1/customers/{customer_id}")
#     assert response.status_code == 204
#     # Ensure customer is deleted
#     get_resp = client.get(f"/v1/customers/{customer_id}")
#     assert get_resp.status_code == 404
