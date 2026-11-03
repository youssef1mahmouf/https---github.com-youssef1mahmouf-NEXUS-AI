import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

import 'api_service.dart';
import 'live_voice_service.dart';
import 'tts_service.dart';
import '../../features/chat/providers/chat_provider.dart';

class RealLiveVoiceService implements LiveVoiceService {
  RealLiveVoiceService({
    required this.api,
    required this.chatProvider,
    required this.tts,
  });

  final ChatApiService api;
  final ChatProvider chatProvider;
  final TextToSpeechService tts;

  final SpeechToText _stt = SpeechToText();
  final StreamController<LiveVoiceState> _controller =
      StreamController<LiveVoiceState>.broadcast();
  LiveVoiceState _state = LiveVoiceState.idle;
  bool _running = false;

  @override
  LiveVoiceState get state => _state;

  @override
  Stream<LiveVoiceState> get stateStream => _controller.stream;

  void _emit(LiveVoiceState s) {
    _state = s;
    _controller.add(s);
  }

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    _emit(LiveVoiceState.connecting);
    final ok = await _stt.initialize();
    if (!ok) {
      _emit(LiveVoiceState.error);
      _running = false;
      return;
    }
    while (_running) {
      _emit(LiveVoiceState.listening);
      String transcript = '';
      try {
        transcript = await _listenOnce();
      } catch (_) {
        transcript = '';
      }
      if (!_running) break;
      if (transcript.trim().isEmpty) continue;
      _emit(LiveVoiceState.thinking);
      await chatProvider.sendMessage(transcript);
      if (!_running) break;
      final messages = chatProvider.activeConversation?.messages ?? [];
      String reply = '';
      if (messages.isNotEmpty && !messages.last.isUser) {
        reply = messages.last.content;
      }
      if (reply.trim().isNotEmpty) {
        _emit(LiveVoiceState.speaking);
        await tts.speak(reply);
      }
    }
    _emit(LiveVoiceState.idle);
  }

  Future<String> _listenOnce() async {
    final completer = Completer<String>();
    String last = '';
    await _stt.listen(
      onResult: (result) {
        last = result.recognizedWords;
        if (result.finalResult) {
          if (!completer.isCompleted) completer.complete(last);
        }
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _stt.stop();
        return last;
      },
    );
  }

  @override
  Future<void> stop() async {
    _running = false;
    try {
      await _stt.stop();
    } catch (_) {}
    try {
      await tts.stop();
    } catch (_) {}
    _emit(LiveVoiceState.idle);
  }
}
