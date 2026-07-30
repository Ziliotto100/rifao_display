import 'package:flutter/material.dart';
import '../models/drawn_entry.dart';
import '../theme/brand_colors.dart';

class FullHistoryOverlay extends StatelessWidget {
  /// Lista completa, mais recente primeiro.
  final List<DrawnEntry> entries;
  final ValueChanged<String> onDelete; // recebe o id do registro a excluir
  final void Function(String id, String newNumber) onEdit;

  const FullHistoryOverlay({
    super.key,
    required this.entries,
    required this.onDelete,
    required this.onEdit,
  });

  Future<void> _openEditDialog(
    BuildContext context,
    DrawnEntry entry,
    int prizeNumber,
  ) async {
    final controller = TextEditingController(text: entry.number);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            'Corrigir Prêmio ${prizeNumber.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 5,
            style: const TextStyle(color: Colors.white, fontSize: 24),
            decoration: const InputDecoration(
              labelText: 'Número correto',
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      onEdit(entry.id, result);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DrawnEntry entry,
    int prizeNumber,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              SizedBox(width: 10),
              Text('Excluir número?', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'Tem certeza que quer excluir o número ${entry.number} '
            '(Prêmio ${prizeNumber.toString().padLeft(2, '0')})?\n\n'
            'Essa ação não pode ser desfeita.',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      onDelete(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = entries.length;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.94),
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Text(
              'Números já sorteados ($total)',
              style: const TextStyle(
                color: BrandColors.gold,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Clique no número pra corrigir · Clique no X pra excluir (com confirmação)',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum número sorteado ainda',
                        style: TextStyle(color: Colors.white54, fontSize: 24),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 150,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.3,
                          ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final prizeNumber = total - index;
                        final isCurrent = index == 0;
                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  _openEditDialog(context, entry, prizeNumber),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? BrandColors.gold.withOpacity(0.15)
                                      : Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCurrent
                                        ? BrandColors.gold
                                        : Colors.white24,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Prêmio ${prizeNumber.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      entry.number,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: GestureDetector(
                                onTap: () =>
                                    _confirmDelete(context, entry, prizeNumber),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.redAccent,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aperte H ou Esc pra fechar',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
