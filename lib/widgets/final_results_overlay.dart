import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/drawn_entry.dart';
import '../services/pdf_report.dart';

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
    final labels = List.generate(total, (index) {
      final prizeNumber = (index + 1).toString().padLeft(2, '0');
      return 'Prêmio $prizeNumber: ${ordered[index].number}';
    });

    return Positioned.fill(
      child: Stack(
        children: [
          Container(
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
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 22,
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final labelWidths = labels
                                .map(_measureWidth)
                                .toList();
                            final lineHeight =
                                _measureLineHeight() + _lineVerticalPadding * 2;

                            var bestColumns = 1;
                            var bestScale = 0.0;

                            // Testa cada quantidade de colunas possível e
                            // mede de verdade o quanto o bloco de texto
                            // precisaria de largura e altura, guardando a
                            // opção que permite o maior "zoom" (maior fonte
                            // final) cabendo inteira na tela.
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
                            final columnWidgets = List.generate(bestColumns, (
                              col,
                            ) {
                              final start = col * rowsPerColumn;
                              final end = math.min(
                                start + rowsPerColumn,
                                total,
                              );
                              if (start >= end) {
                                return const SizedBox.shrink();
                              }

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
          Positioned(
            top: 10,
            right: 14,
            child: _DownloadReportButton(entries: entries, color: numberColor),
          ),
        ],
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

/// Botão que gera o PDF e mostra feedback (carregando / salvo / erro) sem
/// precisar de um Scaffold por perto — a tela de resultado final é um
/// overlay solto, sem Material scaffolding ao redor.
class _DownloadReportButton extends StatefulWidget {
  final List<DrawnEntry> entries;
  final Color color;

  const _DownloadReportButton({required this.entries, required this.color});

  @override
  State<_DownloadReportButton> createState() => _DownloadReportButtonState();
}

class _DownloadReportButtonState extends State<_DownloadReportButton> {
  bool _loading = false;
  String? _feedback;

  Future<void> _download() async {
    setState(() {
      _loading = true;
      _feedback = null;
    });

    final result = await PdfReportService.generateAndSave(widget.entries);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _feedback = switch (result) {
        PdfReportResult.saved => 'PDF salvo!',
        PdfReportResult.cancelled => null, // usuário cancelou, sem aviso
        PdfReportResult.error => 'Erro ao salvar',
      };
    });

    if (_feedback != null) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _feedback = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_feedback != null) ...[
          Text(
            _feedback!,
            style: TextStyle(
              color: _feedback == 'Erro ao salvar'
                  ? Colors.redAccent
                  : widget.color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          onPressed: _loading ? null : _download,
          tooltip: 'Baixar relatório em PDF',
          icon: _loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.color,
                  ),
                )
              : Icon(
                  Icons.picture_as_pdf_rounded,
                  color: widget.color.withOpacity(0.85),
                  size: 26,
                ),
        ),
      ],
    );
  }
}
