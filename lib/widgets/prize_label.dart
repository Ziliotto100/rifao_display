import 'package:flutter/material.dart';

class PrizeLabel extends StatelessWidget {
  final int prizeNumber;
  final Color color;

  const PrizeLabel({super.key, required this.prizeNumber, required this.color});

  @override
  Widget build(BuildContext context) {
    if (prizeNumber <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'PRÊMIO Nº ${prizeNumber.toString().padLeft(2, '0')}',
        style: TextStyle(
          color: color.withOpacity(0.85),
          fontSize: 36,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
