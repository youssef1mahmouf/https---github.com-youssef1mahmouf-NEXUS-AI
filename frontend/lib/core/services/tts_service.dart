import 'package:flutter_tts/flutter_tts.dart';
abstract class TextToSpeechService {
  Future<bool> speak(String text);
  Future<void> stop();
}

class NoOpTextToSpeechService implements TextToSpeechService {
  @override
  Future<bool> speak(String text) async => false;

  @override
  Future<void> stop() async {}
}

class FlutterTextToSpeechService implements TextToSpeechService {
  final FlutterTts _tts = FlutterTts();

  @override
  Future<bool> speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
