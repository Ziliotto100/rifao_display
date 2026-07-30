import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

class NumberDisplay extends StatelessWidget {
  final String? number;
  final String typing;
  final bool warning;
  final Color color;
  final Color typingColor;

  const NumberDisplay({
    super.key,
    required this.number,
    required this.typing,
    this.warning = false,
    this.color = BrandColors.gold,
    this.typingColor = BrandColors.olive,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = typing.isNotEmpty ? typing : (number ?? '--');
    final isTyping = typing.isNotEmpty;

    Color textColor;
    if (warning) {
      textColor = Colors.redAccent;
    } else if (isTyping) {
      textColor = typingColor;
    } else {
      textColor = color;
    }

    return Text(
      displayText,
      style: TextStyle(
        fontSize: 260,
        fontWeight: FontWeight.w900,
        color: textColor,
        height: 1,
      ),
    );
  }
}
