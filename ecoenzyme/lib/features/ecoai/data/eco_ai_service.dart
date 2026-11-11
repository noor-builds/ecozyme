import 'dart:convert';
import 'dart:typed_data';

import 'package:ecoenzyme/core/network/api_client.dart';

class EcoChatExchange {
  const EcoChatExchange({required this.prompt, required this.reply});

  final String prompt;
  final String reply;

  factory EcoChatExchange.fromJson(Map<String, dynamic> json) {
    final prompt = json['user_message'];
    final reply = json['assistant_message'];
    if (prompt is! String || reply is! String) {
      throw const FormatException(
        'The EcoAI server returned an invalid chat history entry.',
      );
    }
    return EcoChatExchange(prompt: prompt, reply: reply);
  }
}

class EcoAiService {
  EcoAiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<EcoChatExchange>> getChatHistory() async {
    final payload = await _apiClient.request('/api/ecoai/history');
    final messages = payload['messages'];
    if (messages is! List) {
      throw const FormatException(
        'The EcoAI server returned an invalid chat history.',
      );
    }
    return messages.map((message) {
      if (message is! Map<String, dynamic>) {
        throw const FormatException(
          'The EcoAI server returned an invalid chat history entry.',
        );
      }
      return EcoChatExchange.fromJson(message);
    }).toList();
  }

  Future<String> analyzeCrop({
    required String prompt,
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    final payload = await _apiClient.request(
      '/api/ecoai/chat',
      method: 'POST',
      body: {
        'prompt': prompt,
        'imageBase64': base64Encode(imageBytes),
        'mimeType': mimeType,
      },
    );
    final reply = payload['reply'];
    if (reply is! String || reply.trim().isEmpty) {
      throw const FormatException('The EcoAI server returned an empty reply.');
    }
    return reply.trim();
  }
}
