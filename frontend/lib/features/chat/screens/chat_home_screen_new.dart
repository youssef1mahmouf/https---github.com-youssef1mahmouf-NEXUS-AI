import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/attachment_service.dart';
import '../../../core/services/live_voice_service.dart';
import '../../../core/services/speech_service.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/ambient_background.dart';
import '../../../shared/widgets/glass_container.dart';
import '../providers/chat_provider.dart';
import '../widgets/composer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/sidebar.dart';
import '../widgets/welcome_view.dart';

class ChatHomeScreen extends StatelessWidget {
  const ChatHomeScreen({
    super.key,
    required this.speech,
    required this.attachments,
    required this.liveVoice,
    this.tts,
  });

  final SpeechService speech;
  final AttachmentService attachments;
  final LiveVoiceService liveVoice;
  final TextToSpeechService? tts;

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final conversation = chat.activeConversation;
    final theme = context.watch<ThemeProvider>();
    final isDark =
        theme.mode == ThemeMode.dark ||
        (theme.mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return AmbientBackground(
      isDark: isDark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            conversation?.title ?? 'Nexus AI',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              tooltip: 'Toggle theme',
              icon: Icon(
                theme.mode == ThemeMode.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              onPressed: theme.toggle,
            ),
          ],
        ),
        drawer: MediaQuery.sizeOf(context).width < 900
            ? Drawer(
                backgroundColor: Colors.transparent,
                child: GlassContainer(
                  borderRadius: 0,
                  blur: 24,
                  child: SafeArea(child: ConversationSidebar()),
                ),
              )
            : null,
        body: Row(
          children: [
            if (MediaQuery.sizeOf(context).width >= 900)
              GlassContainer(
                borderRadius: 0,
                blur: 20,
                opacity: isDark ? 0.08 : 0.45,
                padding: EdgeInsets.zero,
                child: const ConversationSidebar(),
              ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child:
                          conversation == null || conversation.messages.isEmpty
                          ? const WelcomeView(key: ValueKey('welcome'))
                          : ListView.builder(
                              key: const ValueKey('messages'),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: conversation.messages.length,
                              itemBuilder: (context, index) => MessageBubble(
                                message: conversation.messages[index],
                                tts: tts,
                              ),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: GlassContainer(
                      borderRadius: 28,
                      blur: 22,
                      opacity: isDark ? 0.10 : 0.6,
                      child: Composer(
                        speech: speech,
                        attachments: attachments,
                        liveVoice: liveVoice,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
