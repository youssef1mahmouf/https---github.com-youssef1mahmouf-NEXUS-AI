from fastapi.testclient import TestClient
from unittest.mock import patch

from main import app

client = TestClient(app)


def test_health_includes_model():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_chat_empty_message_rejected():
    r = client.post("/chat", json={"message": "   "})
    assert r.status_code == 400


def test_chat_returns_reply():
    with patch("main.ai.chat", return_value=("Hello from AI", "qwen3:4b")):
        r = client.post("/chat", json={"message": "hi", "conversation_id": "c1"})
    assert r.status_code == 200
    data = r.json()
    assert data["reply"] == "Hello from AI"
    assert data["conversation_id"] == "c1"
    assert data["model"] == "qwen3:4b"


def test_upload_rejects_empty():
    r = client.post("/upload", files={"file": ("empty.txt", b"", "text/plain")})
    assert r.status_code == 400


def test_upload_stores_file():
    r = client.post("/upload", files={"file": ("a.txt", b"hello", "text/plain")})
    assert r.status_code == 200
    data = r.json()
    assert data["filename"] == "a.txt"
    assert data["size"] == 5


def test_models_endpoint():
    with patch("main.ai.list_models", return_value=["qwen3:4b"]):
        r = client.get("/models")
    assert r.status_code == 200
    assert r.json()["models"] == ["qwen3:4b"]
