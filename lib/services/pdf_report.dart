import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/drawn_entry.dart';

/// O que aconteceu ao tentar gerar/salvar o relatório.
enum PdfReportResult { saved, cancelled, error }

/// Monta um PDF com todos os números sorteados (em ordem de prêmio) e deixa
/// o usuário escolher onde salvar — pensado pra ser usado ao final do
/// rifão, como um comprovante/relatório pra conferência posterior.
class PdfReportService {
  static Future<PdfReportResult> generateAndSave(
    List<DrawnEntry> entries, // mais recente primeiro
  ) async {
    try {
      // Ordem crescente de prêmio — é assim que faz sentido conferir depois.
      final ordered = entries.reversed.toList();

      const darkGreen = PdfColor.fromInt(0xFF2F3A2E);
      const gold = PdfColor.fromInt(0xFFC7A26A);
      const grey = PdfColor.fromInt(0xFF6B6B6B);

      pw.MemoryImage? logo;
      try {
        final data = await rootBundle.load('assets/images/logo.png');
        logo = pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {
        // Sem logo disponível ainda — o relatório sai sem ela, sem problema.
      }

      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final dateStr =
          '${two(now.day)}/${two(now.month)}/${now.year} ${two(now.hour)}:${two(now.minute)}';

      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
          header: (context) {
            if (context.pageNumber > 1) return pw.SizedBox();
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null) pw.Image(logo, height: 70),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Resultado Final do Rifão',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Gerado em $dateStr  ·  ${ordered.length} número${ordered.length == 1 ? '' : 's'} sorteado${ordered.length == 1 ? '' : 's'}',
                  style: const pw.TextStyle(fontSize: 10, color: grey),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: gold, thickness: 1.2),
                pw.SizedBox(height: 6),
              ],
            );
          },
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: grey),
            ),
          ),
          build: (context) => [
            if (ordered.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 40),
                child: pw.Center(
                  child: pw.Text(
                    'Nenhum número foi sorteado.',
                    style: const pw.TextStyle(fontSize: 14, color: grey),
                  ),
                ),
              )
            else
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(),
                  1: pw.FlexColumnWidth(),
                  2: pw.FlexColumnWidth(),
                },
                children: _buildRows(ordered, darkGreen),
              ),
          ],
        ),
      );

      final Uint8List bytes = await doc.save();

      final fileName =
          'resultado_rifao_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}.pdf';

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar relatório do rifão',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (savePath == null) return PdfReportResult.cancelled;

      var finalPath = savePath;
      if (!finalPath.toLowerCase().endsWith('.pdf')) {
        finalPath = '$finalPath.pdf';
      }
      await File(finalPath).writeAsBytes(bytes);

      return PdfReportResult.saved;
    } catch (_) {
      return PdfReportResult.error;
    }
  }

  /// Monta as linhas da tabela, 3 números por linha, na ordem de prêmio.
  static List<pw.TableRow> _buildRows(
    List<DrawnEntry> ordered,
    PdfColor darkGreen,
  ) {
    const columns = 3;
    final rows = <pw.TableRow>[];
    for (var i = 0; i < ordered.length; i += columns) {
      final cells = <pw.Widget>[];
      for (var c = 0; c < columns; c++) {
        final idx = i + c;
        if (idx < ordered.length) {
          final prizeLabel = (idx + 1).toString().padLeft(2, '0');
          cells.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 6,
              ),
              child: pw.Text(
                'Prêmio $prizeLabel: ${ordered[idx].number}',
                style: pw.TextStyle(fontSize: 11, color: darkGreen),
              ),
            ),
          );
        } else {
          cells.add(pw.SizedBox());
        }
      }
      rows.add(pw.TableRow(children: cells));
    }
    return rows;
  }
}
