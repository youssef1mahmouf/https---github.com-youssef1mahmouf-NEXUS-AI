# Nexus AI — Project Guide

Main reference document for all future development.

## What Nexus AI Is

Nexus AI is a cross-platform AI assistant application with a Flutter frontend and a
Python (FastAPI) backend. It provides text chat, question answering, mathematical
problem solving, English learning and conversation correction, voice input and
text-to-speech, persistent memory, internet search, task management, and optional
LMS (n8n) integration. It is local-first: a local Ollama runtime (Qwen3 4B) is the
primary AI provider; cloud providers (OpenAI, Anthropic, Google) are optional.

## Primary Purpose

Provide a single, privacy-respecting AI assistant that works offline using local
models while optionally leveraging cloud models and web search, with persistent
memory and conversation history.

## Who Will Use It

Individual users who want an AI assistant for learning, problem solving, and daily
tasks, with control over data and model selection. Supports Arabic and English.

## Main Application Features

- Text chat and question answering.
- Mathematical problem solving and explanations.
- English learning and conversation correction.
- Arabic and English language support.
- Voice input (speech recognition) and text-to-speech.
- Local and online AI models with model switching.
- Persistent memory and conversation history.
- Internet / web search.
- Task management.
- Backup and restore.
- Settings and application management.
- Optional n8n LMS integration.

## AI Model Integration and Model Switching

Backend supports multiple providers: ollama (default, local), openai, anthropic,
google, auto, none. Provider and model are configurable via environment variables
and runtime settings without code changes. Failover between providers is
implemented in the backend (legacy).

## Text Chat and Question Answering

FastAPI routes handle chat sessions, conversation history, and responses. Flutter
frontend communicates via HTTP API service.

## Mathematical Problem Solving and Explanations

Intended feature; backend orchestrator handles reasoning. Status: planned/partial
in legacy code; to be reimplemented and tested.

## English Learning and Conversation Correction

Intended feature via learning module and task manager. Status: planned/partial.

## Arabic and English Language Support

Frontend uses intl; backend handles text. Status: planned.

## Voice Input, Speech Recognition, and Text-to-Speech

Flutter uses stts plugin for TTS/STT; voice_service and voice_assistant_service in
legacy code. Status: partial; needs reimplementation.

## Local and Online AI Models

Local: Ollama (Qwen3 4B). Online: OpenAI, Anthropic, Google. Provider switching
via config.

## Backend Responsibilities

FastAPI app: routing, AI orchestration, memory management, task management, backup,
internet search, settings, integrations (n8n), security guards.

## Database and Synchronization Requirements

Local memory store (file/SQLite planned). Cloud sync planned. User data preserved
during rebuild; databases must never be deleted.

## Offline Functionality

Local-first: Ollama primary; cloud optional. App must function without internet
for local model chat.

## Supported Platforms

Flutter targets: Android, iOS, Web, Windows, macOS, Linux (per legacy project).
Rebuild focuses on structure first; platform builds are not generated during
reconstruction per restrictions.

## Security and Privacy Requirements

- Never expose API keys in Flutter code.
- Never hardcode credentials.
- .env and runtime settings with private data are gitignored.
- Validate inputs, handle errors.
- Security guards in backend.

## Future Expansion Goals

- Mobile/web builds, installers.
- Additional AI providers.
- Advanced LMS integrations.
- Automated tests and CI.

## Status Legend

- DONE: implemented and tested.
- PARTIAL: implemented but unverified/incomplete.
- PLANNED: intended, not yet implemented.

Legacy code was recovered from git history; the working tree was gutted. This
rebuild starts from a clean structure.
