import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sentra_app/core/config/api_config.dart';

class ChatMessage {
  final String role; // 'user', 'assistant', atau 'error'
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}

class AiService {
  static const String _model = 'gemini-2.5-flash';

  static Future<String> sendMessage({
    required String systemContext,
    required List<ChatMessage> history,
    required String userMessage,
  }) async {
    final model = GenerativeModel(
      model: _model,
      apiKey: ApiConfig.geminiApiKey,
      systemInstruction: Content.text(systemContext),
      generationConfig: GenerationConfig(maxOutputTokens: 1024),
    );

    // Gemini SDK menggunakan 'model' bukan 'assistant' untuk role AI
    final geminiHistory = history
        .map((m) => Content(
              m.role == 'user' ? 'user' : 'model',
              [TextPart(m.text)],
            ))
        .toList();

    final chat = model.startChat(history: geminiHistory);

    try {
      final response = await chat
          .sendMessage(Content.text(userMessage))
          .timeout(const Duration(seconds: 30));

      final text = response.text;
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

  static bool get isConfigured =>
      ApiConfig.geminiApiKey != 'MASUKKAN_API_KEY_DISINI' &&
      ApiConfig.geminiApiKey.isNotEmpty;
}
