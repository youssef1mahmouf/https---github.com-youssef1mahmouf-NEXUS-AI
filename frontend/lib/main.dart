import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/attachment_service.dart';
import 'core/services/live_voice_service.dart';
import 'core/services/speech_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/tts_service.dart';
import 'core/theme/theme_provider.dart';
import 'features/chat/providers/chat_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = SharedPreferencesStorageService(prefs: prefs);
  final themeProvider = ThemeProvider(prefs: prefs);
  await themeProvider.load();
  final chatProvider = ChatProvider(storage: storage);
  await chatProvider.load();
  runApp(
    NexusApp(
      storage: storage,
      speech: SpeechToTextService(),
      attachments: FilePickerAttachmentService(),
      liveVoice: SimulatedLiveVoiceService(),
      themeProvider: themeProvider,
      chatProvider: chatProvider,
      tts: NoOpTextToSpeechService(),
    ),
  );
}
