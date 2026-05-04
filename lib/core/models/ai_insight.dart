class AiInsight {
  final String icon;
  final String title;
  final String subtitle;
  final String type; // "warning" | "tip" | "action"
  final String tapPrompt;
  final DateTime generatedAt;

  const AiInsight({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.tapPrompt,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() => {
    'icon': icon,
    'title': title,
    'subtitle': subtitle,
    'type': type,
    'tapPrompt': tapPrompt,
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory AiInsight.fromMap(Map<String, dynamic> m) => AiInsight(
    icon: m['icon'] as String? ?? '💡',
    title: m['title'] as String? ?? '',
    subtitle: m['subtitle'] as String? ?? '',
    type: m['type'] as String? ?? 'tip',
    tapPrompt: m['tapPrompt'] as String? ?? '',
    generatedAt: DateTime.parse(m['generatedAt'] as String),
  );
}
