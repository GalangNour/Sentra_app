import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/models/ai_insight.dart';
import 'package:sentra_app/core/theme/app_theme.dart';

class InsightCard extends StatelessWidget {
  final AiInsight insight;
  final VoidCallback onTap;
  final int index;

  const InsightCard({
    super.key,
    required this.insight,
    required this.onTap,
    required this.index,
  });

  Color _typeColor() {
    return switch (insight.type) {
      'warning' => AppColors.expense,
      'tip' => AppColors.income,
      _ => AppColors.primary,
    };
  }

  String _typeLabel() {
    return switch (insight.type) {
      'warning' => 'Perhatian',
      'tip' => 'Tips',
      _ => 'Aksi',
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 100),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(20 * (1 - v), 0), child: child),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.icon, style: const TextStyle(fontSize: 22)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _typeLabel(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                insight.title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                insight.subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary.withAlpha(179),
                  fontSize: 11,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
