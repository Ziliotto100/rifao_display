import 'package:flutter/material.dart';
import 'screens/display_screen.dart';

void main() {
  runApp(const RifaoApp());
}

class RifaoApp extends StatelessWidget {
  const RifaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rifão da Festa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        useMaterial3: true,
      ),
      home: const DisplayScreen(),
    );
  }
}