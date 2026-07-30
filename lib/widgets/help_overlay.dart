import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

class HelpOverlay extends StatelessWidget {
  const HelpOverlay({super.key});

  static const _shortcuts = [
    ('0-9', 'Digitar número'),
    ('Enter', 'Confirmar número sorteado'),
    ('Backspace', 'Apagar último dígito digitado'),
    ('Esc', 'Limpar digitação atual / fechar telas'),
    ('E', 'Editar o número do prêmio atual (corrige sem criar novo prêmio)'),
    ('F1', 'Abrir ou fechar esta ajuda'),
    (
      'H',
      'Ver histórico completo (clique num número pra corrigir, no X pra excluir)',
    ),
    (
      'R',
      'Tela de resultado final — todos os números, sem edição, pro público conferir',
    ),
    ('N', 'Iniciar novo rifão (zera o histórico)'),
    ('C', 'Configurar patrocinadores, cores e tamanhos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.92),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Atalhos do Rifão',
                  style: TextStyle(
                    color: BrandColors.gold,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                // Largura fixa garante que a coluna da tecla e a coluna da
                // descrição fiquem sempre alinhadas, não importa o tamanho do texto.
                SizedBox(
                  width: 640,
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(150),
                      1: FlexColumnWidth(),
                    },
                    children: _shortcuts.map((s) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  s.$1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              top: 8,
                              bottom: 8,
                            ),
                            child: Text(
                              s.$2,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Aperte F1 ou Esc pra fechar',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
