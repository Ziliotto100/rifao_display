import 'package:flutter/material.dart';

class DevCredit extends StatelessWidget {
  const DevCredit({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 8,
      child: Text(
        'Desenvolvido por Ziliotto SmartDev',
        style: TextStyle(color: Colors.white.withOpacity(0.18), fontSize: 12),
      ),
    );
  }
}
