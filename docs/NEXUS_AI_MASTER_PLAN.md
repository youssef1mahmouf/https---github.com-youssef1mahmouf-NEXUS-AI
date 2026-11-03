# Nexus AI Master Plan

## Phase 1 (Core Chat) — DONE
- Backend FastAPI with /health, /chat, /upload.
- Ollama provider (qwen3:4b) real AI responses.
- Flutter ChatApiService with configurable base URL.
- ChatProvider integrated with backend; loading/error states; history sent.
- Conversation management & persistence verified.
- Upload endpoint implemented.

## Phase 2A (Functional Voice, Chat UX & Backend Reliability) — DONE (acceptance-verified)
- Real Speech-to-Text dictation (speech_to_text) → inserts into composer, no auto-send; start/stop/cancel/permission via plugin.
- Real Live Voice conversation (RealLiveVoiceService): STT → /chat → AI reply → TTS (flutter_tts); sequential (not streaming).
- FlutterTextToSpeechService (real TTS); NoOp fallback. **Windows TTS build blocker RESOLVED** — `frontend/tools/nuget.exe` + `frontend/NuGet.Config` (local cache source) enable `flutter build windows` to succeed; TTS plugin compiled into binary. Actual speech playback not audio-verified (no speaker automation).
- Backend /models endpoint; structured logging; input validation + error handling.
- Header: New Conversation (+) button, theme toggle, title.
- Async persistence race fixed; conversation switching during requests guarded.
- Configurable API base URL (desktop 127.0.0.1:8001, Android 10.0.2.2:8001).
- Model-role architecture prepared (extensible, not faked).
- Tests: flutter analyze clean; flutter test 30 passed; pytest 9 passed.
- Runtime: backend /health, /models, /chat real Ollama replies verified; SpeechToTextWindowsPlugin initialized on Windows; Windows release build succeeds.

## Phase 2B / 3 (Next)
- Settings screen for provider/model/base URL.
- SQLite persistence + migration (off current SharedPreferences).
- Localization (Arabic/English).
- Streaming live voice (currently sequential).
- n8n LMS integration.
- CI.


