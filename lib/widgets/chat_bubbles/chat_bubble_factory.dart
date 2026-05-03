import 'package:flutter/material.dart';
import 'chat_bubble_chart.dart';
import 'chat_bubble_choice.dart';
import 'chat_bubble_slider.dart';
import 'chat_bubble_text.dart';

class ChatBubbleFactory extends StatelessWidget {
  const ChatBubbleFactory({
    super.key,
    required this.parsed,
    required this.timestamp,
    required this.onSendMessage,
    required this.onSaveData,
  });

  final Map<String, dynamic> parsed;
  final DateTime timestamp;
  final Function(String) onSendMessage;
  final Function(Map<String, dynamic>) onSaveData;

  @override
  Widget build(BuildContext context) {
    switch (parsed['type']) {
      case 'chart':
      case 'mixed':
        return ChatBubbleChart(
          data: parsed,
          timestamp: timestamp,
          onActionTap: onSendMessage,
        );
      case 'input_slider':
        return ChatBubbleSlider(
          data: parsed,
          timestamp: timestamp,
          onConfirm: (value) =>
              onSendMessage('Budget yang saya pilih: ${value.toInt()}'),
        );
      case 'input_choice':
        return ChatBubbleChoice(
          data: parsed,
          timestamp: timestamp,
          onSelect: (choice) => onSendMessage('Saya memilih: $choice'),
        );
      case 'text':
      default:
        return ChatBubbleText(
          text: parsed['text'] as String? ?? '',
          timestamp: timestamp,
          isUser: false,
        );
    }
  }
}
