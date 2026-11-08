import json

import requests

from config import OLLAMA_BASE_URL, DEFAULT_MODEL, REQUEST_TIMEOUT


class OllamaProvider:
    def __init__(self, base_url=None, model=None, timeout=None):
        self.base_url = (base_url or OLLAMA_BASE_URL).rstrip("/")
        self.default_model = model or DEFAULT_MODEL
        self.timeout = timeout or REQUEST_TIMEOUT

    def list_models(self):
        url = f"{self.base_url}/api/tags"
        response = requests.get(url, timeout=self.timeout)
        response.raise_for_status()
        data = response.json()
        models = []
        for item in data.get("models", []):
            name = item.get("name")
            if name:
                models.append(name)
        return models

    def chat(self, messages, model=None):
        selected = model or self.default_model
        url = f"{self.base_url}/api/chat"
        payload = {"model": selected, "messages": messages, "stream": False}
        response = requests.post(url, json=payload, timeout=self.timeout)
        response.raise_for_status()
        data = response.json()
        message = data.get("message") or {}
        content = message.get("content")
        if not content:
            raise RuntimeError("Empty response from Ollama")
        return content, selected

    def chat_stream(self, messages, model=None):
        selected = model or self.default_model
        url = f"{self.base_url}/api/chat"
        payload = {"model": selected, "messages": messages, "stream": True}
        response = requests.post(url, json=payload, timeout=self.timeout, stream=True)
        response.raise_for_status()
        for line in response.iter_lines():
            if not line:
                continue
            text = line.decode("utf-8").strip()
            if not text:
                continue
            if text.startswith("data: "):
                text = text[6:]
            if text == "[DONE]":
                break
            try:
                data = json.loads(text)
            except json.JSONDecodeError:
                continue
            message = data.get("message") or {}
            content = message.get("content")
            if content:
                yield content
