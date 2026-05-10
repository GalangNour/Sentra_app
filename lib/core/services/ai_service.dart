import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sentra_app/core/config/api_config.dart';

class ChatMessage {
  final String role; // 'user', 'assistant', atau 'error'
  final String text;
  final Map<String, dynamic>? parsed; // hasil parse JSON, hanya untuk assistant
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.text,
    this.parsed,
    required this.timestamp,
  });
}

class AiService {
  static const String _model = 'gemini-2.5-flash';

  static Future<String> sendMessage({
    required String systemContext,
    required List<ChatMessage> history,
    required String userMessage,
    int maxOutputTokens = 8192,
  }) async {
    final model = GenerativeModel(
      model: _model,
      apiKey: ApiConfig.geminiApiKey,
      systemInstruction: Content.text(systemContext),
      generationConfig: GenerationConfig(
        maxOutputTokens: maxOutputTokens,
      ),
    );

    // Gemini SDK menggunakan 'model' bukan 'assistant' untuk role AI
    final geminiHistory = history
        .map((m) => Content(
              m.role == 'user' ? 'user' : 'model',
              [TextPart(m.text)],
            ))
        .toList();

    final chat = model.startChat(history: geminiHistory);

    debugPrint('[SentraBrain] === SENDING TO GEMINI ===');
    debugPrint('[SentraBrain] USER: $userMessage');
    for (int i = 0; i < geminiHistory.length; i++) {
      final role = geminiHistory[i].role;
      final part = geminiHistory[i].parts.isNotEmpty ? (geminiHistory[i].parts.first as TextPart).text : 'NO TEXT';
      debugPrint('[SentraBrain] HISTORY $i ($role): $part');
    }

    try {
      final response = await chat
          .sendMessage(Content.text(userMessage))
          .timeout(const Duration(seconds: 30));

      final text = response.text;
      debugPrint('[SentraBrain] === RECEIVED ===');
      debugPrint('[SentraBrain] FINISH REASON: ${response.candidates.first.finishReason}');
      debugPrint('[SentraBrain] RAW TEXT: $text');
      
      if (text == null || text.isEmpty) {
        return 'Maaf, tidak ada respons dari AI. Coba lagi ya 🙏';
      }
      return text;
    } catch (e, st) {
      debugPrint('[SentraBrain] sendMessage error: $e');
      debugPrint('[SentraBrain] stacktrace: $st');
      rethrow;
    }
  }

  /// Parse raw string dari AI → Map JSON.
  static Map<String, dynamic> parseResponse(String raw) {
    try {
      String clean = raw.trim();
      if (clean.startsWith('```json')) {
        clean = clean.replaceFirst('```json', '');
      } else if (clean.startsWith('```')) {
        clean = clean.replaceFirst('```', '');
      }
      if (clean.endsWith('```')) {
        clean = clean.substring(0, clean.length - 3);
      }
      return jsonDecode(clean.trim()) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[SentraBrain] parse error: $e');
      debugPrint('[SentraBrain] failed string: $raw');
    }
    return {'type': 'text', 'text': raw};
  }

  static bool get isConfigured =>
      ApiConfig.geminiApiKey != 'MASUKKAN_API_KEY_DISINI' &&
      ApiConfig.geminiApiKey.isNotEmpty;
}
