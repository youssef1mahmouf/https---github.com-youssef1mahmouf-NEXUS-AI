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
    id: json['id'] as String,
    name: json['name'] as String,
    path: json['path'] as String,
    type: AttachmentType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => AttachmentType.file,
    ),
    size: json['size'] as int?,
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
  });

  final String id;
  final String conversationId;
  final String content;
  final bool isUser;
  final DateTime createdAt;
  final List<Attachment> attachments;

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'content': content,
    'isUser': isUser,
    'createdAt': createdAt.toIso8601String(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    conversationId: json['conversationId'] as String,
    content: json['content'] as String,
    isUser: json['isUser'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
    attachments: (json['attachments'] as List<dynamic>? ?? [])
        .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
        .toList(),
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
    id: json['id'] as String,
    title: json['title'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    messages: (json['messages'] as List<dynamic>? ?? [])
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

// helper to avoid unused import warning
String encodeConversations(List<Conversation> list) =>
    jsonEncode(list.map((c) => c.toJson()).toList());

List<Conversation> decodeConversations(String raw) {
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
      .toList();
}
