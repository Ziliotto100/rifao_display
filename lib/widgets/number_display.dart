import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

class NumberDisplay extends StatelessWidget {
  final String? number;
  final String typing;
  final bool warning;
  final Color color;
  final Color typingColor;
  final int sizeLevel; // 3..7 — quanto maior, maior o número em tela

  const NumberDisplay({
    super.key,
    required this.number,
    required this.typing,
    this.warning = false,
    this.color = BrandColors.gold,
    this.typingColor = BrandColors.olive,
    this.sizeLevel = 3,
  });

  // Pensado pra telões grandes vistos de longe (eventos com centenas ou
  // milhares de pessoas): removemos os níveis pequenos, que não se
  // justificam nesse tipo de exibição.
  double get _fontSize {
    switch (sizeLevel) {
      case 4:
        return 340; // Gigante
      case 5:
        return 420; // Extra grande
      case 6:
        return 520; // Enorme
      case 7:
        return 640; // Colossal
      case 3:
      default:
        return 260; // Grande (padrão)
    }
  }

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

    return FittedBox(
      // Rede de segurança: se o tamanho escolhido não couber na largura da
      // tela (telas menores ou números com muitos dígitos), encolhe em vez
      // de cortar ou estourar pra fora da tela.
      fit: BoxFit.scaleDown,
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: _fontSize,
          fontWeight: FontWeight.w900,
          color: textColor,
          height: 0.72,
        ),
      ),
    );
  }
}
