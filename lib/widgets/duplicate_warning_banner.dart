import 'package:flutter/material.dart';

class DuplicateWarningBanner extends StatelessWidget {
  final String number;

  const DuplicateWarningBanner({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Text(
        'O número $number já foi sorteado! Aperte Enter de novo pra confirmar mesmo assim.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
