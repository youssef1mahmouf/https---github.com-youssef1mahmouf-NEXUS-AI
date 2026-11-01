import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexus_ai/app.dart';
import 'package:nexus_ai/core/services/attachment_service.dart';
import 'package:nexus_ai/core/models/conversation.dart';
import 'package:nexus_ai/core/services/live_voice_service.dart';

import 'package:nexus_ai/core/services/speech_service.dart';
import 'package:nexus_ai/core/services/storage_service.dart';
import 'package:nexus_ai/core/services/tts_service.dart';
import 'package:nexus_ai/core/theme/theme_provider.dart';
import 'package:nexus_ai/features/chat/providers/chat_provider.dart';

class _FakeAttachmentService implements AttachmentService {
  @override
  Future<List<Attachment>> pickImages() async => [];
  @override
  Future<List<Attachment>> pickFiles() async => [];
  @override
  Future<List<Attachment>> pickVideos() async => [];
  @override
  Future<List<Attachment>> pickAny() async => [];
}

class _FakeSpeechService implements SpeechService {
  @override
  bool get isListening => false;
  @override
  Future<bool> initialize() async => false;
  @override
  Future<void> startListening({
    required void Function(String text) onResult,
  }) async {}
  @override
  Future<void> stopListening() async {}
}

void main() {
  testWidgets('app builds', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = SharedPreferencesStorageService(prefs: prefs);
    final themeProvider = ThemeProvider(prefs: prefs);
    await themeProvider.load();
    final chatProvider = ChatProvider(storage: storage);
    await chatProvider.load();
    await tester.pumpWidget(
      NexusApp(
        storage: storage,
        speech: _FakeSpeechService(),
        attachments: _FakeAttachmentService(),
        liveVoice: SimulatedLiveVoiceService(),
        themeProvider: themeProvider,
        chatProvider: chatProvider,
        tts: NoOpTextToSpeechService(),
      ),
    );
    await tester.pump();
    expect(find.text('Nexus AI'), findsOneWidget);
  });
}
