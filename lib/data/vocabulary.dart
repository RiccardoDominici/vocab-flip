import 'package:flutter/material.dart';

import 'themes_a1.dart';
import 'themes_a2.dart';
import 'themes_b1.dart';
import 'themes_b2.dart';
import 'themes_c1.dart';
import 'themes_c2.dart';

class VocabWord {
  final String italian;
  final String english;
  final String? imageKeyword;

  const VocabWord({
    required this.italian,
    required this.english,
    this.imageKeyword,
  });

  String get imageSearchTerm => imageKeyword ?? english;
}

class VocabTheme {
  final String name;
  final String cefrLevel; // A1, A2, B1, B2, C1, C2
  final IconData icon;
  final int colorValue;
  final List<VocabWord> words;

  const VocabTheme({
    required this.name,
    required this.cefrLevel,
    required this.icon,
    required this.colorValue,
    required this.words,
  });
}

const Map<String, String> cefrLabels = {
  'A1': 'A1 - Principiante',
  'A2': 'A2 - Elementare',
  'B1': 'B1 - Intermedio',
  'B2': 'B2 - Intermedio Superiore',
  'C1': 'C1 - Avanzato',
  'C2': 'C2 - Padronanza',
};

const Map<String, Color> cefrColors = {
  'A1': Color(0xFF4CAF50),
  'A2': Color(0xFF8BC34A),
  'B1': Color(0xFFFFC107),
  'B2': Color(0xFFFF9800),
  'C1': Color(0xFFFF5722),
  'C2': Color(0xFF9C27B0),
};

final List<VocabTheme> allThemes = [
  ...themesA1,
  ...themesA2,
  ...themesB1,
  ...themesB2,
  ...themesC1,
  ...themesC2,
];
