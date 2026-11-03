import json
from unittest.mock import patch, MagicMock

from ollama_provider import OllamaProvider


def test_list_models_mocked():
    provider = OllamaProvider(base_url="http://example", timeout=5)
    resp = MagicMock()
    resp.json.return_value = {"models": [{"name": "qwen3:4b"}, {"name": "qwen3:0.6b"}]}
    resp.raise_for_status.return_value = None
    with patch("ollama_provider.requests.get", return_value=resp):
        assert provider.list_models() == ["qwen3:4b", "qwen3:0.6b"]


def test_chat_mocked():
    provider = OllamaProvider(base_url="http://example", timeout=5)
    resp = MagicMock()
    resp.json.return_value = {"message": {"content": "hi there"}}
    resp.raise_for_status.return_value = None
    with patch("ollama_provider.requests.post", return_value=resp):
        reply, model = provider.chat([{"role": "user", "content": "hi"}])
    assert reply == "hi there"
    assert model == provider.default_model
