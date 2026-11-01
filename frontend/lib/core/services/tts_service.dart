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
