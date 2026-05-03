import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/theme/app_theme.dart';

class ChatBubbleChoice extends StatefulWidget {
  const ChatBubbleChoice({
    super.key,
    required this.data,
    required this.timestamp,
    required this.onSelect,
  });

  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Function(String) onSelect;

  @override
  State<ChatBubbleChoice> createState() => _ChatBubbleChoiceState();
}

class _ChatBubbleChoiceState extends State<ChatBubbleChoice> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final text = widget.data['text'] as String? ?? '';
    final choices =
        (widget.data['choices'] as List?)?.cast<String>() ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (text.isNotEmpty) ...[
              Text(
                text,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: choices.map((choice) {
                final isSelected = _selected == choice;
                final isDisabled = _selected != null && !isSelected;
                return GestureDetector(
                  onTap: (isDisabled || isSelected)
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          setState(() => _selected = choice);
                          widget.onSelect(choice);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDisabled
                            ? AppColors.surfaceBorder
                            : AppColors.primary
                                .withAlpha(isSelected ? 255 : 80),
                      ),
                    ),
                    child: Text(
                      choice,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isDisabled
                                ? AppColors.textMuted
                                : AppColors.primaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  text: 'Kamu memilih: ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: '$_selected ✓',
                      style: const TextStyle(
                        color: AppColors.income,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _fmt(widget.timestamp),
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
