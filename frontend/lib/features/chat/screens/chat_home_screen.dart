import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/attachment_service.dart';
import '../../../core/services/live_voice_service.dart';
import '../../../core/services/speech_service.dart';
import '../../../core/theme/theme_provider.dart';
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
  });

  final SpeechService speech;
  final AttachmentService attachments;
  final LiveVoiceService liveVoice;

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(chat.activeConversation?.title ?? 'Nexus AI'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(
              theme.mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => theme.toggle(),
          ),
        ],
      ),
      drawer: MediaQuery.of(context).size.width < 900
          ? Drawer(child: SafeArea(child: ConversationSidebar()))
          : null,
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 900)
            GlassSidebar(child: const ConversationSidebar()),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: chat.activeConversation == null
                      ? const WelcomeView()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: chat.activeConversation!.messages.length,
                          itemBuilder: (ctx, i) => MessageBubble(
                            message: chat.activeConversation!.messages[i],
                          ),
                        ),
                ),
                Composer(
                  speech: speech,
                  attachments: attachments,
                  liveVoice: liveVoice,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlassSidebar extends StatelessWidget {
  const GlassSidebar({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: child,
    );
  }
}
