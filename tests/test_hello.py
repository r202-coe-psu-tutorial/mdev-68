from fastapi.testclient import TestClient

from flasx.main import app

client = TestClient(app)


def test_hello() -> None:
    """Test the hello endpoint."""
    response = client.get("/v1/hello")
    assert response.status_code == 200
    assert response.json() == "Hello, World!"
