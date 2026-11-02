import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/conversation.dart';
import '../../../core/services/attachment_service.dart';
import '../../../core/services/live_voice_service.dart';
import '../../../core/services/speech_service.dart';
import '../providers/chat_provider.dart';
import 'attachment_preview.dart';

class Composer extends StatefulWidget {
  const Composer({
    super.key,
    required this.speech,
    required this.attachments,
    required this.liveVoice,
  });
  final SpeechService speech;
  final AttachmentService attachments;
  final LiveVoiceService liveVoice;
  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _ctrl = TextEditingController();
  final List<Attachment> _pending = [];
  bool _listening = false;
  bool _isSending = false;
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _toggleDictation() async {
    if (_listening) {
      await widget.speech.stopListening();
      setState(() => _listening = false);
      return;
    }
    final ok = await widget.speech.initialize();
    if (!ok) return;
    setState(() => _listening = true);
    await widget.speech.startListening(
      onResult: (text) {
        _ctrl.text = text;
        _ctrl.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
      },
    );
  }

  Future<void> _send() async {
    final text = _ctrl.text;
    final atts = List<Attachment>.from(_pending);
    _ctrl.clear();
    _pending.clear();
    setState(() => _isSending = true);
    await context.read<ChatProvider>().sendMessage(text, attachments: atts);
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pending.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _pending.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) => Stack(
                  children: [
                    AttachmentPreview(attachment: _pending[i]),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _pending.removeAt(i)),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.attach_file),
                onSelected: (v) async {
                  if (v == 'image') {
                    final r = await widget.attachments.pickImages();
                    if (r.isNotEmpty) setState(() => _pending.addAll(r));
                  } else if (v == 'video') {
                    final r = await widget.attachments.pickVideos();
                    if (r.isNotEmpty) setState(() => _pending.addAll(r));
                  } else {
                    final r = await widget.attachments.pickFiles();
                    if (r.isNotEmpty) setState(() => _pending.addAll(r));
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'image', child: Text('Images')),
                  PopupMenuItem(value: 'video', child: Text('Videos')),
                  PopupMenuItem(value: 'file', child: Text('Files')),
                ],
              ),
              StreamBuilder<LiveVoiceState>(
                stream: widget.liveVoice.stateStream,
                initialData: widget.liveVoice.state,
                builder: (ctx, snap) {
                  final st = snap.data ?? LiveVoiceState.idle;
                  final active =
                      st == LiveVoiceState.listening ||
                      st == LiveVoiceState.connecting;
                  return IconButton(
                    tooltip: 'Live voice',
                    icon: Icon(active ? Icons.graphic_eq : Icons.mic_none),
                    color: active ? Colors.redAccent : null,
                    onPressed: () async {
                      if (active) {
                        await widget.liveVoice.stop();
                      } else {
                        await widget.liveVoice.start();
                      }
                      setState(() {});
                    },
                  );
                },
              ),
              IconButton(
                tooltip: 'Dictate',
                icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                color: _listening ? Colors.redAccent : null,
                onPressed: _toggleDictation,
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  minLines: 1,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Message Nexus AI...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isSending ? null : _send,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(14),
                ),
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
