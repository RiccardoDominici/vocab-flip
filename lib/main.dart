import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const VocabFlipApp());
}

class VocabFlipApp extends StatelessWidget {
  const VocabFlipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocab Flip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6C63FF),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
