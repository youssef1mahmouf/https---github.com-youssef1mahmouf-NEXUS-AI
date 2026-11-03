import os
from dotenv import load_dotenv

load_dotenv()

AI_PROVIDER = os.getenv("AI_PROVIDER", "ollama").lower()
DEFAULT_MODEL = os.getenv("DEFAULT_MODEL", "qwen3:4b")
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://127.0.0.1:11434")
API_HOST = os.getenv("API_HOST", "127.0.0.1")
API_PORT = int(os.getenv("API_PORT", "8001"))
REQUEST_TIMEOUT = int(os.getenv("REQUEST_TIMEOUT", "120"))
UPLOAD_DIR = os.getenv("UPLOAD_DIR", "uploads")
