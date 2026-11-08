import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ChatApiException implements Exception {
  ChatApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'ChatApiException($statusCode): $message';
}

class ChatApiService {
  ChatApiService({String? baseUrl})
      : baseUrl = baseUrl ??
            (Platform.isAndroid
                ? 'http://10.0.2.2:8001'
                : 'http://127.0.0.1:8001');

  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<bool> health() async {
    try {
      final res = await http.get(_uri('/health')).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> models() async {
    try {
      final res = await http.get(_uri('/models')).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['models'] as List<dynamic>? ?? []).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<String> chat({
    required String message,
    String? conversationId,
    List<Map<String, String>> history = const [],
    String? model,
  }) async {
    final res = await http
        .post(
          _uri('/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': message,
            'conversation_id': conversationId,
            'history': history,
            'model': model,
          }),
        )
        .timeout(const Duration(seconds: 120));
    if (res.statusCode != 200) {
      throw ChatApiException(res.body, statusCode: res.statusCode);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['reply'] as String;
  }

  Stream<String> chatStream({
    required String message,
    String? conversationId,
    List<Map<String, String>> history = const [],
    String? model,
  }) async* {
    final client = http.Client();
    try {
      final request = http.Request(
        'POST',
        _uri('/chat/stream'),
      )
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'message': message,
          'conversation_id': conversationId,
          'history': history,
          'model': model,
        });
      final streamed = await client.send(request).timeout(const Duration(seconds: 120));
      if (streamed.statusCode != 200) {
        final body = await utf8.decoder.bind(streamed.stream).join();
        throw ChatApiException(body, statusCode: streamed.statusCode);
      }
      await for (final line in utf8.decoder
          .bind(streamed.stream)
          .transform(const LineSplitter())) {
        if (line.isEmpty) continue;
        final payload = line.startsWith('data: ') ? line.substring(6) : line;
        if (payload == '[DONE]') break;
        try {
          final decoded = jsonDecode(payload) as Map<String, dynamic>;
          if (decoded.containsKey('error')) {
            throw ChatApiException(decoded['error'].toString());
          }
          final reply = decoded['reply'];
          if (reply != null) yield reply as String;
        } on FormatException {
          continue;
        }
      }
    } finally {
      client.close();
    }
  }
}
