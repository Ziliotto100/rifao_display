import 'package:flutter/material.dart';
import '../models/drawn_entry.dart';

class HistoryStrip extends StatelessWidget {
  /// Lista completa, mais recente primeiro (índice 0 = número atual em exibição).
  final List<DrawnEntry> entries;
  final int maxItems;
  final int sizeLevel; // 1 = Pequeno, 2 = Médio, 3 = Grande
  final Color textColor;

  const HistoryStrip({
    super.key,
    required this.entries,
    this.maxItems = 5,
    this.sizeLevel = 2,
    this.textColor = Colors.white70,
  });

  double get _fontSize {
    switch (sizeLevel) {
      case 1:
        return 20;
      case 3:
        return 40;
      case 2:
      default:
        return 28;
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
                ),
              ),
              Text(
                entry.number,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                  color: textColor,
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
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: items),
    );
  }
}
