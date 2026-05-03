import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/formatters.dart';

class ChatBubbleSlider extends StatefulWidget {
  const ChatBubbleSlider({
    super.key,
    required this.data,
    required this.timestamp,
    required this.onConfirm,
  });

  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Function(double) onConfirm;

  @override
  State<ChatBubbleSlider> createState() => _ChatBubbleSliderState();
}

class _ChatBubbleSliderState extends State<ChatBubbleSlider> {
  late double _value;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _value = (widget.data['default'] as num).toDouble();
  }

  int get _divisions {
    final range =
        (widget.data['max'] as num) - (widget.data['min'] as num);
    final step = (widget.data['step'] as num);
    if (step <= 0) return 100;
    return (range / step).round().clamp(1, 500);
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.data['text'] as String? ?? '';
    final label = widget.data['confirm_label'] as String? ?? 'Konfirmasi';
    final min = (widget.data['min'] as num).toDouble();
    final max = (widget.data['max'] as num).toDouble();

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
              const SizedBox(height: 16),
            ],
            Center(
              child: Text(
                Fmt.full(_value),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surfaceElevated,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withAlpha(30),
              ),
              child: Slider(
                value: _value,
                min: min,
                max: max,
                divisions: _divisions,
                onChanged: _confirmed
                    ? null
                    : (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _value = v);
                      },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Fmt.compact(min),
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                Text(
                  Fmt.compact(max),
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_confirmed)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.income,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Tersimpan ✓',
                    style: TextStyle(
                      color: AppColors.income,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _confirmed = true);
                    widget.onConfirm(_value);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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
