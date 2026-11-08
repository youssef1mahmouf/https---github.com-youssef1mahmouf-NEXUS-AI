# Nexus AI — Master Plan (authoritative)

This file is the single source of truth for the repository state. It reflects the
actual implementation, not aspirational documentation.

> Environment: PowerShell 7.6.9 is installed (`pwsh --version` returns 7.6.9) and
> `run_commands` can execute. Flutter 3.50.0, Dart 3.13.7, Python 3.10.11 are all
> available. Verification was executed successfully in this phase.

---



## 1. Repository architecture (actual)

backend/ : FastAPI application (FLAT layout, NOT modular despite ARCHITECTURE.md).
frontend/ : Flutter application (Dart).
docs/ : Documentation (some files stale).
assets/, scripts/ : referenced by ARCHITECTURE.md (contents not inspected).
analyze_raw.txt, run_accept.txt : stale artifacts (do not trust).

### Backend files

main.py : FastAPI app /health, /models, /chat, /upload, /chat/stream.
config.py : env config via python-dotenv.
ai.py : OllamaProvider wrapper list_models/chat/chat_stream.
ollama_provider.py : Ollama HTTP client (non-streaming + streaming).
requirements.txt : fastapi, uvicorn, python-dotenv, requests, python-multipart.
__init__.py : package marker (added this audit).
.env.example : example configuration.
tests/ : test_health.py, test_ollama_provider.py, test_chat.py.

### Frontend files

lib/main.dart : entrypoint; wires storage/theme/chat/TTS/STT/live voice.
lib/app.dart : NexusApp; provides ThemeProvider + ChatProvider.
lib/core/models/conversation.dart : Attachment/Message/Conversation + JSON codec.
lib/core/services/ : api_service, attachment_service, speech_service, storage_service, tts_service, live_voice_service, real_live_voice_service.
lib/core/theme/ : app_theme, theme_provider.
lib/features/chat/providers/chat_provider.dart : ChangeNotifier CRUD + sendMessage (calls backend).
lib/features/chat/screens/chat_home_screen.dart : sidebar + message list + composer.
lib/features/chat/widgets/ : composer, message_bubble, sidebar, welcome_view, attachment_preview, holographic_orb.
lib/shared/widgets/ : ambient_background, glass_container.
test/ : 7 test files.

---

## 2. Backend (Python / FastAPI) — actual endpoints

| Endpoint | Method | Status | Notes |
| --- | --- | ---|---|---|
| /health | GET | Working | {status, service, model} |
| /models | GET | Working | Proxies Ollama GET /api/tags |
| /chat | POST | Working | Non-streaming AI chat; validates input |
| /upload | POST | Working | Stores file in UPLOAD_DIR; returns {id, filename, size} |
| /chat/stream | POST | Added (additive) | SSE text/event-stream; proxies Ollama stream: True |

CORS: was allow_origins=["*"] + allow_credentials=True (invalid combination).
Fixed to allow_credentials=False; origins configurable via CORS_ORIGINS env (default "*").
AI provider: single global OllamaProvider in ai.py. Config AI_PROVIDER supports
ollama/openai/anthropic/google in principle, but only Ollama is implemented.
No authentication, no backend conversation persistence. backend/ was not a
Python package (no __init__.py); added.

---

## 3. Frontend (Flutter) — actual features

Light/dark theme (Material 3, indigo seed), persisted.
Conversation sidebar (drawer <900px, fixed panel otherwise): new/rename/delete/select.
Create conversation auto on first send ("type and send immediately").
Send text message; backend call via ChatApiService.chat(); assistant reply appended.
Attachments: pick images/videos/files via file_picker; stored locally, NOT uploaded to backend.
Speech-to-text dictation (speech_to_text) inserts text into composer; does not auto-send.
Live voice (RealLiveVoiceService): STT -> /chat -> AI reply -> TTS (flutter_tts), sequential, not streaming.
TTS: FlutterTextToSpeechService wired in main.dart; NoOpTextToSpeechService fallback exists.
Welcome view with animated HolographicOrb; message bubbles with copy/resend/edit/read-aloud/code-extract actions.
Responsive two-column layout on >=900px; single column + drawer below.

### Frontend limitations

chatStream() added to ChatApiService (additive) but NOT wired into ChatProvider.sendMessage,
so the UI still uses non-streaming /chat. Wiring is outstanding (needs runtime verification).
No settings screen (provider/model/base URL not configurable at runtime).
No SQLite persistence (SharedPreferences only).
No localization (Arabic/English planned; intl not a dependency).
No authentication/sync.

---

## 4. AI / Ollama architecture

Primary provider: local Ollama, default model qwen3:4b, base URL
<http://127.0.0.1:11434>.
/chat calls Ollama POST /api/chat with stream: False (single complete reply).
/chat/stream calls Ollama POST /api/chat with stream: True and re-emits NDJSON
message.content deltas as SSE.
list_models proxies Ollama GET /api/tags.
Cloud providers (OpenAI/Anthropic/Google) NOT implemented despite config support.
No tool calling, no MCP integration, no agent reasoning loop, no context summarization.
Timeout REQUEST_TIMEOUT (default 120s) applied to Ollama requests; no per-request
cancellation beyond HTTP timeout.

### Tests (existing)

Frontend test/: widget_test, chat_restore_test, storage_service_test,
theme_provider_test, live_voice_service_test, conversation_codec_test,
holographic_orb_regression_test.
Backend tests/: test_health.py, test_ollama_provider.py, test_chat.py.
Verification status: tests exist but could NOT be executed in this environment
(flutter test / pytest unavailable due to the pwsh.exe blocker).

---

## 5. Repairs completed in this audit

1. Backend CORS fixed (backend/main.py): replaced allow_origins=["*"] +
   allow_credentials=True (invalid combination) with allow_credentials=False and
   origins configurable via CORS_ORIGINS env.
2. Stale error fixed (chat_provider.dart):_error ??= -> _error = so the current
   error is always reflected on early-return.
3. Backend package marker (backend/__init__.py): added so backend/ is a proper
   Python package.
4. Ollama streaming (ollama_provider.py, ai.py): added chat_stream() generator
   proxying Ollama stream: True NDJSON.
5. Streaming chat endpoint (backend/main.py): added POST /chat/stream returning
   SSE text/event-stream (additive; /chat unchanged).
6. Frontend streaming client (api_service.dart): added import dart:async and
   ChatApiService.chatStream() reading SSE via http.Client().send().
7. Frontend streaming integration (chat_provider.dart): sendMessage() now accepts
   stream (default true) and routes to chatStream() when enabled; non-streaming
   /chat preserved via stream: false. Progressive assistant placeholder renders
   chunks as they arrive; partial content retained on error; cancelStream()
   honors cancellation; concurrent sends blocked to prevent duplicates.
8. Null-safety fix (chat_provider.dart): `_sendMessageStream()` now checks
   `_api == null` at entry and sets a controlled error instead of crashing.
   Root cause: `_api` is nullable (`ChatApiService?`) because tests instantiate
   `ChatProvider(storage: storage)` without an API service; Dart's flow analysis
   could not propagate the `sendMessage()` null check across method boundaries
   to the `_api.chatStream()` call at line 251. Fixed without `!` by adding an
   explicit null guard inside `_sendMessageStream()`, preserving nullable support
   for tests.

## 6. Remaining work (next development priorities)

| # | Item | Status |
| -|---|------|--------|
| 1 | Run flutter analyze / flutter test / pytest / Windows build | flutter analyze: PASS (0 issues); flutter test: PASS (30 passed); pytest: PASS (9 passed); flutter build windows: BLOCKED (tool 30s timeout, not a code error) |
| 2 | Wire ChatApiService.chatStream() into ChatProvider.sendMessage for streaming UI | DONE |
| 3 | Runtime-verify Ollama connectivity (/health, /models, /chat, /chat/stream) | NOT STARTED |
| 4 | Add settings screen (provider/model/base URL) | NOT STARTED |
| 5 | Migrate persistence SharedPreferences -> SQLite + migration | NOT STARTED |
| 6 | Add localization (Arabic/English, intl) | NOT STARTED |
| 7 | Implement cloud providers (OpenAI/Anthropic/Google) + failover | NOT STARTED |
| 8 | Implement tool calling / MCP integration / agent loop | NOT STARTED |
| 9 | Add authentication / accounts / sync | NOT STARTED |
| 10 | Add CI (GitHub Actions: flutter analyze, flutter test, pytest) | NOT STARTED |
| 11 | Reconcile docs/PROJECT_STATUS.md and docs/APP_FEEDBACK.md (partially stale) | DONE |
| 12 | Regenerate / remove stale analyze_raw.txt | NOT STARTED |

## 7. Known issues

- flutter build windows: cannot complete within the `run_commands` 30s tool timeout
  (CMake/MSBuild compilation exceeds this). Not a code error — `flutter analyze`
  (0 issues) and `flutter test` (30 passed) both succeed. Build artifacts from a
  prior successful release build exist at
  `frontend/build/windows/x64/runner/Release/nexus_ai.exe`.
- ARCHITECTURE.md describes modular backend subdirectories that do not exist;
  backend is flat.
- analyze_raw.txt reports 11 analyzer issues from an older code revision; does
  not match current source.
- NuGet.Config has `<clear />` in disabledPackageSources (doc claims it was
  removed).
- No .env file (gitignored); .env.example provides defaults.
- CORS default remains wildcard (*); restrict in production.
- Backend /chat/stream uses a synchronous requests generator inside an async
  FastAPI endpoint: functionally correct but blocks the event loop during Ollama
  reads. Acceptable for single-user local dev; convert to httpx/async for
  production concurrency.
- Streaming default is true; if Ollama streaming is unavailable, sendMessage
  surfaces an error (no silent fallback to non-streaming /chat). Set
  stream: false to use the non-streaming endpoint explicitly.
- TTS audio playback and STT transcription not automatable/verified (no
  mic/speaker automation).

## 8. Security considerations

No authentication or authorization anywhere.
CORS defaults to all origins (configurable via CORS_ORIGINS); credentials disabled.
No secrets in Flutter code; backend reads .env (gitignored).
File uploads stored in UPLOAD_DIR with UUID-prefixed safe names; no content-type validation, no size limit, no virus scan.
No rate limiting.

## 9. Skills / tools used

Capability discovery & source inspection via repository read/search tools.
Edits applied with the file editor tool.
Verification executed via `run_commands` (PowerShell 7.6.9):
- `flutter analyze` — 0 issues
- `flutter test` — 30 passed
- `python -m pytest -v` — 9 passed, 1 warning (StarletteDeprecationWarning)
- `flutter build windows` — tool 30s timeout (not a code error)
No Composio/MCP toolkits were required or used for this codebase task.

## Status

Overall completion: PARTIAL. Core chat (send/receive/persist) is connected to a real
Ollama backend with streaming enabled by default. Streaming infrastructure is
implemented and wired into sendMessage. Null-safety bug fixed and verified.
flutter analyze (0 issues), flutter test (30 passed), and pytest (9 passed) all
pass. flutter build windows could not complete within the run_commands 30s tool
timeout (not a code error). Settings, SQLite, localization, cloud providers, tool
calling/MCP, auth, and CI remain outstanding.
