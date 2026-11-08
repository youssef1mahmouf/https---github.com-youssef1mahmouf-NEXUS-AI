from ollama_provider import OllamaProvider
from config import OLLAMA_BASE_URL, DEFAULT_MODEL, REQUEST_TIMEOUT

_provider = OllamaProvider(
    base_url=OLLAMA_BASE_URL,
    model=DEFAULT_MODEL,
    timeout=REQUEST_TIMEOUT,
)


def list_models():
    return _provider.list_models()


def chat(messages, model=None):
    return _provider.chat(messages, model=model)


def chat_stream(messages, model=None):
    return _provider.chat_stream(messages, model=model)
