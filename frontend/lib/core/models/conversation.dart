import 'dart:convert';

enum AttachmentType { image, video, file }

class Attachment {
  const Attachment({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    this.size,
  });

  final String id;
  final String name;
  final String path;
  final AttachmentType type;
  final int? size;

  bool get isImage => type == AttachmentType.image;
  bool get isVideo => type == AttachmentType.video;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'type': type.name,
    'size': size,
  };

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    id: _asString(json['id'], ''),
    name: _asString(json['name'], ''),
    path: _asString(json['path'], ''),
    type: AttachmentType.values.firstWhere(
      (e) => e.name == _asString(json['type'], ''),
      orElse: () => AttachmentType.file,
    ),
    size: json['size'] is int ? json['size'] as int : null,
  );
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.isUser,
    required this.createdAt,
    this.attachments = const [],
    this.sources = const [],
    this.isEdited = false,
  });

  final String id;
  final String conversationId;
  final String content;
  final bool isUser;
  final DateTime createdAt;
  final List<Attachment> attachments;
  final List<String> sources;
  final bool isEdited;

  Message copyWith({
    String? content,
    bool? isUser,
    DateTime? createdAt,
    List<Attachment>? attachments,
    List<String>? sources,
    bool? isEdited,
  }) => Message(
    id: id,
    conversationId: conversationId,
    content: content ?? this.content,
    isUser: isUser ?? this.isUser,
    createdAt: createdAt ?? this.createdAt,
    attachments: attachments ?? this.attachments,
    sources: sources ?? this.sources,
    isEdited: isEdited ?? this.isEdited,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'content': content,
    'isUser': isUser,
    'createdAt': createdAt.toIso8601String(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'sources': sources,
    'isEdited': isEdited,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: _asString(json['id'], ''),
    conversationId: _asString(json['conversationId'], ''),
    content: _asString(json['content'], ''),
    isUser: _asBool(json['isUser'], false),
    createdAt: _parseDateTime(json['createdAt'], DateTime.now()),
    attachments: (json['attachments'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => Attachment.fromJson(e))
        .toList(),
    sources: (json['sources'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList(),
    isEdited: _asBool(json['isEdited'], false),
  );
}

class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Message> messages;

  Conversation copyWith({
    String? title,
    DateTime? updatedAt,
    List<Message>? messages,
  }) => Conversation(
    id: id,
    title: title ?? this.title,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    messages: messages ?? this.messages,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: _asString(json['id'], ''),
    title: _asString(json['title'], 'Untitled'),
    createdAt: _parseDateTime(json['createdAt'], DateTime.now()),
    updatedAt: _parseDateTime(json['updatedAt'], DateTime.now()),
    messages: (json['messages'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => Message.fromJson(e))
        .toList(),
  );
}

// Defensive parsing helpers for backward-compatible storage migration.
String _asString(dynamic value, String fallback) =>
    value is String ? value : fallback;

bool _asBool(dynamic value, bool fallback) => value is bool ? value : fallback;

DateTime _parseDateTime(dynamic value, DateTime fallback) {
  if (value is! String) return fallback;
  try {
    return DateTime.parse(value);
  } catch (_) {
    return fallback;
  }
}

// helper to avoid unused import warning
String encodeConversations(List<Conversation> list) =>
    jsonEncode(list.map((c) => c.toJson()).toList());

List<Conversation> decodeConversations(String raw) {
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .whereType<Map<dynamic, dynamic>>()
      .map((e) => Conversation.fromJson(e.cast<String, dynamic>()))
      .where((c) => c.id.isNotEmpty && c.title.isNotEmpty)
      .toList();
}
