# Nexus AI — Architecture

## Overview

Clean separation between Flutter frontend and Python backend.

## Components

- frontend/ : Flutter application (Dart).
- backend/ : FastAPI application (Python).
- docs/ : Documentation.
- assets/ : Application assets.
- scripts/ : Development and maintenance scripts.
- tests/ : Automated tests (cross-component).

## Backend (Python)

FastAPI application with a FLAT layout (not modular subdirectories):

- main.py: FastAPI entrypoint. Endpoints: GET /health, GET /models, POST /chat,
  POST /upload, POST /chat/stream (SSE).
- config.py: env-based settings via python-dotenv (AI_PROVIDER, DEFAULT_MODEL,
  OLLAMA_BASE_URL, API_HOST, API_PORT, REQUEST_TIMEOUT, UPLOAD_DIR, CORS_ORIGINS).
- ai.py: OllamaProvider wrapper (list_models, chat, chat_stream).
- ollama_provider.py: Ollama HTTP client (non-streaming chat + streaming chat_stream).
- requirements.txt: fastapi, uvicorn, python-dotenv, requests, python-multipart.
- __init__.py: package marker.
- .env.example: example configuration (no secrets committed).
- tests/: test_health.py, test_ollama_provider.py, test_chat.py.

Note: the modular subdirectories ai/, api/, memory/, tasks/, tools/, integrations/,
internet/, backup/, config/ described in older revisions do not exist; logic lives
in the flat files above. Only the Ollama provider is implemented.

## Frontend (Flutter)

- lib/main.dart: entrypoint.
- lib/app.dart: app widget.
- lib/core/: constants, services, theme.
- lib/features/: feature screens.
- lib/shared/: shared widgets.

## Communication

Flutter HTTP client <-> FastAPI REST API.

## Data

Conversations persisted locally in Flutter SharedPreferences
(nexus_conversations_v1, nexus_active_conversation_id_v1). The backend does NOT
persist conversations (it only echoes/generates conversation_id). No SQLite, no
sync. Databases are never deleted during rebuild.

## Security

Secrets in .env (gitignored). No keys in Flutter code.
