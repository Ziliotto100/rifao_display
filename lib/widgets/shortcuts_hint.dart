import 'package:flutter/material.dart';

class ShortcutsHint extends StatelessWidget {
  const ShortcutsHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Text(
        'F1 = Ajuda dos atalhos',
        style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
      ),
    );
  }
}
