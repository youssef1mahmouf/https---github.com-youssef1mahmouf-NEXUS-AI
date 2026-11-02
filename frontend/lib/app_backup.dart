import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/attachment_service.dart';
import 'core/services/live_voice_service.dart';
import 'core/services/speech_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/tts_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/chat/screens/chat_home_screen.dart';

class NexusApp extends StatelessWidget {
  const NexusApp({
    super.key,
    required this.storage,
    required this.speech,
    required this.attachments,
    required this.liveVoice,
    required this.themeProvider,
    required this.tts,
    this.chatProvider,
  });

  final StorageService storage;
  final SpeechService speech;
  final AttachmentService attachments;
  final LiveVoiceService liveVoice;
  final ThemeProvider themeProvider;
  final TextToSpeechService? tts;
  final ChatProvider? chatProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<ChatProvider>(
          create: (context) => chatProvider ?? ChatProvider(storage: storage),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (ctx, theme, _) => MaterialApp(
          title: 'Nexus AI',
          theme: NexusTheme.light(),
          darkTheme: NexusTheme.dark(),
          themeMode: theme.mode,
          debugShowCheckedModeBanner: false,
          home: ChatHomeScreen(
            speech: speech,
            attachments: attachments,
            liveVoice: liveVoice,
            tts: tts,
          ),
        ),
      ),
    );
  }
}
