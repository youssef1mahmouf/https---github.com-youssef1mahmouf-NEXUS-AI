import 'package:speech_to_text/speech_to_text.dart';

abstract class SpeechService {
  bool get isListening;
  Future<bool> initialize();
  Future<void> startListening({required void Function(String text) onResult});
  Future<void> stopListening();
}

class SpeechToTextService implements SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _listening = false;

  @override
  bool get isListening => _listening;

  @override
  Future<bool> initialize() async {
    try {
      return await _stt.initialize();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> startListening({
    required void Function(String text) onResult,
  }) async {
    _listening = true;
    await _stt.listen(onResult: (r) => onResult(r.recognizedWords));
  }

  @override
  Future<void> stopListening() async {
    _listening = false;
    await _stt.stop();
  }
}
