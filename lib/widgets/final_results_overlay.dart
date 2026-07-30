import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/drawn_entry.dart';

/// Tela final de conferência: mostra TODOS os números sorteados de uma vez,
/// em ordem de prêmio, organizados em colunas (estilo jornal: preenche a
/// coluna 1 de cima a baixo, depois a coluna 2, e assim por diante).
///
/// A quantidade de colunas é escolhida testando várias opções e MEDINDO de
/// verdade (com TextPainter) o tamanho que o texto de cada uma ocuparia —
/// não é uma estimativa por contagem de caracteres — pra escolher a opção
/// que aproveita melhor o espaço da tela (largura E altura), sem sobrar
/// faixas vazias nem precisar rolar.
class FinalResultsOverlay extends StatelessWidget {
  /// Lista completa, mais recente primeiro (mesma convenção do resto do app).
  final List<DrawnEntry> entries;
  final Color numberColor;

  const FinalResultsOverlay({
    super.key,
    required this.entries,
    required this.numberColor,
  });

  static const _textStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: 40,
  );
  static const _lineVerticalPadding = 3.0; // topo + baixo, ver Padding abaixo
  static const _columnSpacing = 28.0;

  double _measureWidth(String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final total = entries.length;
    // Ordem crescente de prêmio — é assim que quem for conferir vai procurar.
    final ordered = entries.reversed.toList();
    final padWidth = math.max(2, total.toString().length);

    final labels = List.generate(total, (index) {
      final prizeNumber = (index + 1).toString().padLeft(padWidth, '0');
      return 'Prêmio $prizeNumber: ${ordered[index].number}';
    });

    return Positioned.fill(
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              total == 0
                  ? 'Resultado Final'
                  : 'Resultado Final · $total números',
              style: TextStyle(
                color: numberColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: labels.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum número sorteado ainda',
                        style: TextStyle(color: Colors.white54, fontSize: 22),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final labelWidths = labels.map(_measureWidth).toList();
                        final lineHeight =
                            _measureLineHeight() + _lineVerticalPadding * 2;

                        var bestColumns = 1;
                        var bestScale = 0.0;

                        // Testa cada quantidade de colunas possível e mede
                        // de verdade o quanto o bloco de texto precisaria
                        // de largura e altura, guardando a opção que permite
                        // o maior "zoom" (maior fonte final) cabendo inteira
                        // na tela.
                        for (var c = 1; c <= total; c++) {
                          final rows = (total / c).ceil();
                          var blockWidth = 0.0;
                          for (var col = 0; col < c; col++) {
                            final start = col * rows;
                            final end = math.min(start + rows, total);
                            if (start >= end) continue;
                            var colWidth = 0.0;
                            for (var i = start; i < end; i++) {
                              colWidth = math.max(colWidth, labelWidths[i]);
                            }
                            blockWidth += colWidth;
                          }
                          blockWidth += _columnSpacing * (c - 1);
                          final blockHeight = rows * lineHeight;

                          final scale = math.min(
                            constraints.maxWidth / blockWidth,
                            constraints.maxHeight / blockHeight,
                          );
                          if (scale > bestScale) {
                            bestScale = scale;
                            bestColumns = c;
                          }
                        }

                        final rowsPerColumn = (total / bestColumns).ceil();
                        final columnWidgets = List.generate(bestColumns, (col) {
                          final start = col * rowsPerColumn;
                          final end = math.min(start + rowsPerColumn, total);
                          if (start >= end) return const SizedBox.shrink();

                          return Padding(
                            padding: EdgeInsets.only(
                              right: col == bestColumns - 1
                                  ? 0
                                  : _columnSpacing,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var i = start; i < end; i++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: _lineVerticalPadding,
                                    ),
                                    child: Text(
                                      labels[i],
                                      maxLines: 1,
                                      softWrap: false,
                                      style: _textStyle,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        });

                        return Center(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: columnWidgets,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _measureLineHeight() {
    final painter = TextPainter(
      text: const TextSpan(text: 'Prêmio 000: 0000', style: _textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.height;
  }
}
