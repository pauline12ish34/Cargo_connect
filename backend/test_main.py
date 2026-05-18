from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_send_notification_unauthorized():
    response = client.post("/send-notification", json={}, headers={"x-api-key": "wrong"})
    assert response.status_code == 401