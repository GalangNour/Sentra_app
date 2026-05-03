import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/formatters.dart';

class ChatBubbleChart extends StatefulWidget {
  const ChatBubbleChart({
    super.key,
    required this.data,
    required this.timestamp,
    required this.onActionTap,
  });

  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Function(String) onActionTap;

  @override
  State<ChatBubbleChart> createState() => _ChatBubbleChartState();
}

class _ChatBubbleChartState extends State<ChatBubbleChart> {
  int _touchedIndex = -1;

  static const List<Color> _palette = [
    Color(0xFF00C896),
    Color(0xFFFF8C42),
    Color(0xFF38BDF8),
    Color(0xFFFF6B9D),
    Color(0xFFFFB547),
    Color(0xFFB06EF7),
    Color(0xFF00E5FF),
    Color(0xFFFF6B6B),
  ];

  List<Color> get _colors => [AppColors.primary, ..._palette];

  @override
  Widget build(BuildContext context) {
    final introText = widget.data['text'] as String? ?? '';
    final chart = widget.data['chart'] as Map<String, dynamic>? ?? {};
    final items = (chart['items'] as List?) ?? [];
    final total = (chart['total'] as num?)?.toDouble() ?? 0.0;
    final actions = (widget.data['actions'] as List?)?.cast<String>() ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.92,
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
            if (introText.isNotEmpty) ...[
              Text(
                introText,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (items.isNotEmpty) ...[
              SizedBox(
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: items.asMap().entries.map((e) {
                          final idx = e.key;
                          final item = e.value as Map<String, dynamic>;
                          final value = (item['value'] as num).toDouble();
                          final color = _colors[idx % _colors.length];
                          final touched = idx == _touchedIndex;
                          return PieChartSectionData(
                            color: color,
                            value: value,
                            radius: touched ? 72 : 60,
                            title: touched
                                ? '${item['percentage']}%'
                                : '',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            setState(() {
                              if (response?.touchedSection != null &&
                                  event.isInterestedForInteractions) {
                                _touchedIndex = response!
                                    .touchedSection!.touchedSectionIndex;
                                HapticFeedback.lightImpact();
                              } else {
                                _touchedIndex = -1;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          Fmt.compact(total),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: items.asMap().entries.map((e) {
                  final idx = e.key;
                  final item = e.value as Map<String, dynamic>;
                  final color = _colors[idx % _colors.length];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${item['label']}  ${Fmt.compact((item['value'] as num).toDouble())}  (${item['percentage']}%)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: actions.asMap().entries.map((e) {
                  final isFirst = e.key == 0;
                  return isFirst
                      ? ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            widget.onActionTap(e.value);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            widget.onActionTap(e.value);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                }).toList(),
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
