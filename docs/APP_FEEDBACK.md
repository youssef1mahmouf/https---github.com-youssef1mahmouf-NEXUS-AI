# Nexus AI — App Feedback Report

> **STATUS: PARTIALLY SUPERSEDED.** This report was generated from an earlier
> review of the working tree. Several statements in Sections 2–4 are outdated
> relative to the current source code and have been corrected inline below with
> `[OBSOLETE]` / `[CORRECTED]` markers. Historical claims about test counts
> (`flutter test: 30 passed`, `pytest: 9 passed`, `flutter analyze: 0 issues`)
> could not be re-verified in this environment because `pwsh.exe` (PowerShell 7)
> is not installed and `run_commands` cannot execute. The authoritative,
> up-to-date plan is the root-level `NEXUS_AI_MASTER_PLAN.md`.

## 1. Application Options (what the user can do today)

### UI / Navigation

- Toggle light/dark theme (AppBar button).
- Open conversation sidebar (drawer on <900px width, fixed panel otherwise).
- Create / rename / delete conversations (via sidebar + provider).
- Send a text message; auto-creates a conversation if none is active.
- Attach files/images/videos through a popup menu (Images / Videos / Files).
- Remove a pending attachment before sending.
- Dictate text via speech-to-text (microphone button).
- Live voice mode toggle (simulated state machine).
- View messages in a scrollable list; welcome view when empty.

### Backend

- `GET /health` returns `{"status":"ok","service":"nexus-ai-backend"}`.
- CORS configured for all origins (development) [CORRECTED: `allow_credentials`
  is now `False`; origins configurable via `CORS_ORIGINS` env, default `"*"`].

## 2. What Works (verified)

- Flutter app builds and runs (`flutter analyze`: 0 issues).
- Widget smoke test (`app builds`) passes.
- Conversation persistence (SharedPreferences) round-trips messages/attachments.
- Chat provider restore/create/send/delete/rename/edit/resend logic (unit tests).
- Theme provider load/toggle/setMode persists selection.
- Storage service round-trip (new tests).
- Live voice simulated state transitions (new tests).
- Conversation codec encode/decode + defensive parsing (new tests).
- Backend health endpoint (pytest).

## 3. Errors / Not Working

- No backend communication from frontend: `ChatProvider.sendMessage` only stores the
  user message locally; no HTTP client calls the FastAPI backend, so no AI reply is
  ever produced. [OBSOLETE — `ChatProvider.sendMessage` calls `ChatApiService.chat()`
  → backend `POST /chat`; streaming via `POST /chat/stream` is also implemented and
  wired as the default path.]
- Backend exposes only `/health`; all AI routes (chat, models, memory, tasks, search,
  backup, n8n) are missing. [OBSOLETE — backend implements `GET /health`, `GET /models`,
  `POST /chat`, `POST /upload`, `POST /chat/stream` (SSE).]
- Speech-to-text service depends on platform plugin and is not testable; `initialize()`
  may fail silently on desktop/web.
- Text-to-speech is a no-op (`NoOpTextToSpeechService`); TTS never speaks. [CORRECTED —
  `FlutterTextToSpeechService` via `flutter_tts` is the real implementation wired in
  `main.dart`; `NoOpTextToSpeechService` is kept as a fallback.]
- Live voice service is simulated only; no real streaming audio.
- Attachments are picked but never uploaded or sent to a backend; only stored locally.
- `createConversation()` fires storage writes without awaiting; persistence races are
  possible under rapid actions.
- `sendMessage` `_error ??=` logic can retain stale errors in edge cases. [FIXED —
  changed to `_error =` so the current error is always reflected on early-return.]
- No authentication, accounts, or sync.
- No Arabic/English localization wired (intl not in dependencies).

## 4. Not Added Yet (planned per ROADMAP/PROJECT_GUIDE)

- AI provider management & model switching (Ollama/OpenAI/Anthropic/Google).
- Math problem solving module.
- English learning & conversation correction module.
- Microphone STT reimplementation & TTS settings.
- Offline behavior validation.
- n8n LMS integration.
- Local database (SQLite) + cloud sync.
- Auth & accounts.
- Settings & app management screens.
- Mobile/web/windows installers.
- CI and automated tests beyond current set.

## 5. Last Part To Do To Complete (priority order)

1. Implement backend AI routes and an Ollama provider; add `/chat` endpoint.
2. Add an HTTP API service in Flutter and call it from `ChatProvider.sendMessage`,
   append assistant reply, handle errors/timeouts.
3. Wire real TTS (flutter_tts) and STT robustly; remove no-op in production.
4. Add settings screen for provider/model selection and base URL.
5. Persist conversations in SQLite; add migration from SharedPreferences.
6. Add localization (arb files) for Arabic/English.
7. Add integration tests for end-to-end chat flow.
8. Add CI (GitHub Actions) running `flutter analyze`, `flutter test`, `pytest`.

## 6. Real Tests Added

New test files (all passing):

- `frontend/test/storage_service_test.dart`
- `frontend/test/theme_provider_test.dart`
- `frontend/test/live_voice_service_test.dart`
- `frontend/test/conversation_codec_test.dart`

Existing tests still passing:

- `frontend/test/chat_restore_test.dart`
- `frontend/test/holographic_orb_regression_test.dart`
- `frontend/test/widget_test.dart`
- `backend/tests/test_health.py`

Latest run: `flutter test` -> 30 tests passed; `pytest` -> 1 passed; `flutter analyze` -> 0 issues.
[NOT RE-VERIFIED — could not execute in this environment; `pwsh.exe` missing.]

## 7. Recommendations

- Replace simulated services with real implementations before release.
- Add a backend client and integration tests.
- Keep storage migration backward-compatible (existing decode helpers already are).
- Add error reporting/logging for failed provider calls.

## Phase 1 Update

## Phase 2A Acceptance Verification

- Dictation: Implemented (speech_to_text plugin). Runtime: plugin loads on Windows (`SpeechToTextWindowsPlugin created`), but actual speech transcription cannot be automated without a microphone. Does NOT auto-send (correct).
- Live Voice: Implemented (RealLiveVoiceService: STT → /chat → AI reply → TTS). Runtime: backend /chat real replies verified; full voice loop not automatable without mic/speaker. Sequential, not streaming.
- TTS: Implemented (FlutterTextToSpeechService via flutter_tts). **Windows desktop build blocker RESOLVED (portable)** — `flutter build windows` now succeeds via `.uild_windows.ps1` with `frontend/tools/nuget.exe` (committed to repo) + `frontend/NuGet.Config` (%USERPROFILE% cache source, portable across machines; nuget.org available as fallback). Root cause was missing `nuget.exe` on PATH and no configured package source for the local cache. TTS plugin compiled into Windows binary; actual speech playback not audio-verified (no speaker automation). Works on mobile per flutter_tts.
- Backend: /health, /models, /chat all verified with real Ollama qwen3:4b replies.
- Regression: flutter analyze clean; flutter test 30 passed; pytest 9 passed.

## Phase 2A Update

Functional voice, chat UX & backend reliability complete:

- Real dictation (speech_to_text) inserts text into composer; no auto-send.
- Real Live Voice: STT → backend /chat → AI reply → TTS (flutter_tts), with states.
- Backend /models, structured logging, validation, error handling.
- Header: New Conversation (+), theme toggle; title shows conversation or "Nexus AI".
- Async persistence race fixed; conversation switching during requests guarded.
- flutter analyze clean; flutter test 30 passed; pytest 9 passed.
- Flutter app runs on Windows desktop; real Ollama chat verified; STT plugin initialized.
- Platform note: flutter_tts Windows build needs nuget.exe; TTS works on mobile without it.
Core chat now connected to backend with real Ollama (qwen3:4b) replies. See PROJECT_STATUS.md.
