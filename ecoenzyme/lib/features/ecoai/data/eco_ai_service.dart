import 'dart:convert';
import 'dart:typed_data';

import 'package:ecoenzyme/core/network/api_client.dart';

class EcoAiService {
  EcoAiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

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
