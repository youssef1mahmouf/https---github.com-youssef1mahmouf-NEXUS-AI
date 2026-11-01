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

- main.py: FastAPI entrypoint.
- ai/: providers, orchestrator, engine, ollama provider, llm types.
- api/: routes.
- memory/: memory manager.
- tasks/: task manager.
- tools/: tool manager.
- integrations/: n8n client.
- internet/: search.
- backup/: backup manager.
- config/: settings, runtime config.

## Frontend (Flutter)

- lib/main.dart: entrypoint.
- lib/app.dart: app widget.
- lib/core/: constants, services, theme.
- lib/features/: feature screens.
- lib/shared/: shared widgets.

## Communication

Flutter HTTP client <-> FastAPI REST API.

## Data

Local memory store + optional sync. Databases never deleted during rebuild.

## Security

Secrets in .env (gitignored). No keys in Flutter code.
