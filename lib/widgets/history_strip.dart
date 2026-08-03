import 'package:flutter/material.dart';
import '../models/drawn_entry.dart';

class HistoryStrip extends StatelessWidget {
  /// Lista completa, mais recente primeiro (índice 0 = número atual em exibição).
  final List<DrawnEntry> entries;
  final int maxItems;
  final int sizeLevel; // 3..7 — quanto maior, maior o texto do histórico
  final Color textColor;

  const HistoryStrip({
    super.key,
    required this.entries,
    this.maxItems = 5,
    this.sizeLevel = 3,
    this.textColor = Colors.white70,
  });

  double get _fontSize {
    switch (sizeLevel) {
      case 4:
        return 62; // Gigante
      case 5:
        return 80; // Extra grande
      case 6:
        return 100; // Enorme
      case 7:
        return 130; // Colossal
      case 3:
      default:
        return 44; // Grande (padrão)
    }
  }

  double get _stripHeight => _fontSize + 62;

  @override
  Widget build(BuildContext context) {
    // Pula o índice 0 (número atual) e pega os próximos "maxItems".
    final total = entries.length;
    final items = <Widget>[];

    for (var i = 1; i < entries.length && items.length < maxItems; i++) {
      final prizeNumber = total - i;
      final entry = entries[i];
      items.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Prêmio ${prizeNumber.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: _fontSize * 0.32,
                  color: textColor.withOpacity(0.7),
                  height: 1.1,
                ),
              ),
              Text(
                entry.number,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 0.85,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) return SizedBox(height: _stripHeight);

    return SizedBox(
      height: _stripHeight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: items,
        ),
      ),
    );
  }
}
