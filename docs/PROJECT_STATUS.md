# Project Status

## Phase 1 (Core Chat) — DONE
## Phase 2A (Functional Voice, Chat UX & Backend Reliability) — DONE (acceptance-verified, with platform caveats)

### Implemented
- Backend /health, /models, /chat (Ollama qwen3:4b), /upload.
- Flutter ChatApiService + ChatProvider real integration (loading/error/history/duplicate guard).
- Conversation create/select/rename/delete/persist; async persistence race fixed.
- Real Speech-to-Text dictation (speech_to_text) — inserts text into composer; does NOT auto-send; start/stop/cancel/permission handled via plugin.
- Real Live Voice conversation (RealLiveVoiceService): STT → backend /chat → AI reply → TTS (flutter_tts), with connecting/listening/thinking/speaking states; sequential (not streaming).
- FlutterTextToSpeechService (real TTS via flutter_tts); NoOp kept as fallback.
- Header: New Conversation (+) button added; theme toggle preserved; title shows active conversation or "Nexus AI".
- Configurable API base URL (desktop 127.0.0.1:8001, Android emulator 10.0.2.2:8001).
- Backend structured logging; extensible OllamaProvider; input validation + HTTP error handling.

### Test Results
- flutter analyze: No issues found.
- flutter test: 30 passed.
- pytest: 9 passed.

### Runtime Verification (verified)
- Backend /health: `{"status":"ok",...}` ✓
- Backend /models: 4 models incl. `qwen3:4b` ✓
- Real /chat reply via Ollama qwen3:4b: `"Hello! I'm here to help. 😊 How can I assist you today?"` ✓
- Flutter app previously built & ran on Windows; `SpeechToTextWindowsPlugin` initialized (dictation supported) ✓

### Windows TTS Blocker — RESOLVED
**Root cause:** `flutter_tts` (4.2.5) Windows plugin runs `nuget install Microsoft.Windows.CppWinRT` during CMake configure and imports `Microsoft.Windows.CppWinRT.props`. The build failed because `nuget.exe` was not on PATH and no package source pointed to the local NuGet cache where `Microsoft.Windows.CppWinRT 2.0.210503.1` was cached.

**Fix applied (project-level, non-destructive):**
1. `frontend/tools/nuget.exe` — nuget.exe added to the project.
2. `frontend/NuGet.Config` — package source pointing to the local NuGet cache.
3. `nuget.exe` must be on PATH for `flutter build windows` / `flutter run -d windows`.

**Verification:** `flutter build windows` now succeeds (`√ Built build\windows\x64\runner\Release\nxus_ai.exe`). The app launches on Windows desktop and `SpeechToTextWindowsPlugin` initializes. TTS plugin code is compiled into the binary; actual speech playback requires speakers/audio output and was not automated in this environment.

### Remaining Limitations
- **TTS actual speech playback:** Not audio-verified (no speaker/microphone automation available). Manual test: run the app, trigger Live Voice or TTS, confirm audio is heard.
- **Live Voice full loop:** Sequential (not streaming). Cannot be fully automated without microphone/speaker.
- **Dictation actual transcription:** Plugin loads but speech transcription cannot be automated without a microphone.
- No settings screen; SharedPreferences only (no SQLite); no localization; no CI.

### External Requirements
- Ollama running locally with `qwen3:4b` (available).
- Windows desktop build: nuget.exe on PATH + NuGet.Config with local cache source (both now in project). Visual Studio C++ toolchain must be installed (present in this environment).
- Optional cloud provider API keys not configured.

### Next Phase
Phase 2B/3: Settings screen, SQLite migration, localization, CI, streaming live voice.

