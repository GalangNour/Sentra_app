import 'package:flutter/material.dart';
import 'package:sentra_app/core/models/transaction.dart';

class CustomCategory {
  final String id;
  final String name;
  final int iconCode;
  final String fontFamily;
  final int colorValue;
  final TransactionType type;

  const CustomCategory({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.fontFamily,
    required this.colorValue,
    this.type = TransactionType.expense,
  });

  IconData get icon => IconData(iconCode, fontFamily: fontFamily);
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'iconCode': iconCode,
    'fontFamily': fontFamily,
    'colorValue': colorValue,
    'type': type.name,
  };

  factory CustomCategory.fromMap(Map<String, dynamic> m) => CustomCategory(
    id: m['id'] as String,
    name: m['name'] as String,
    iconCode: m['iconCode'] as int,
    fontFamily: m['fontFamily'] as String,
    colorValue: m['colorValue'] as int,
    type: TransactionType.values.firstWhere(
      (e) => e.name == m['type'],
      orElse: () => TransactionType.expense,
    ),
  );

  static const iconChoices = [
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.school_rounded,
    Icons.sports_soccer_rounded,
    Icons.music_note_rounded,
    Icons.pets_rounded,
    Icons.flight_rounded,
    Icons.computer_rounded,
    Icons.smartphone_rounded,
    Icons.book_rounded,
    Icons.sports_esports_rounded,
    Icons.local_gas_station_rounded,
    Icons.child_care_rounded,
    Icons.fitness_center_rounded,
    Icons.local_cafe_rounded,
    Icons.videogame_asset_rounded,
  ];

  static const colorChoices = [
    Color(0xFF6C63FF),
    Color(0xFFFF6B6B),
    Color(0xFF00C896),
    Color(0xFFFFB547),
    Color(0xFF38BDF8),
    Color(0xFFFF6B9D),
    Color(0xFFB06EF7),
    Color(0xFF00E5FF),
    Color(0xFFFF8C42),
    Color(0xFF4CAF50),
    Color(0xFFE91E63),
    Color(0xFF795548),
  ];
}
