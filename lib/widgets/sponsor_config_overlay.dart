import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'color_picker_field.dart';
import '../theme/brand_colors.dart';

class SponsorConfigOverlay extends StatelessWidget {
  final List<String> imagePaths;
  final int intervalSeconds;
  final int perScreen;
  final int historySize;
  final int numberSize;
  final Color backgroundColor;
  final Color numberColor;
  final Color historyTextColor;
  final Color typingColor;
  final ValueChanged<List<String>> onPathsChanged;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<int> onPerScreenChanged;
  final ValueChanged<int> onHistorySizeChanged;
  final ValueChanged<int> onNumberSizeChanged;
  final ValueChanged<Color> onBackgroundColorChanged;
  final ValueChanged<Color> onNumberColorChanged;
  final ValueChanged<Color> onHistoryTextColorChanged;
  final ValueChanged<Color> onTypingColorChanged;
  final VoidCallback onResetColors;
  final VoidCallback onClose;

  const SponsorConfigOverlay({
    super.key,
    required this.imagePaths,
    required this.intervalSeconds,
    required this.perScreen,
    required this.historySize,
    required this.numberSize,
    required this.backgroundColor,
    required this.numberColor,
    required this.historyTextColor,
    required this.typingColor,
    required this.onPathsChanged,
    required this.onIntervalChanged,
    required this.onPerScreenChanged,
    required this.onHistorySizeChanged,
    required this.onNumberSizeChanged,
    required this.onBackgroundColorChanged,
    required this.onNumberColorChanged,
    required this.onHistoryTextColorChanged,
    required this.onTypingColorChanged,
    required this.onResetColors,
    required this.onClose,
  });

  Future<void> _addSponsor() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return;
    final newPaths = result.paths.whereType<String>().toList();
    onPathsChanged([...imagePaths, ...newPaths]);
  }

  void _removeSponsor(String path) {
    onPathsChanged(imagePaths.where((p) => p != path).toList());
  }

  @override
  Widget build(BuildContext context) {
    const sizeLabels = {
      3: 'Grande',
      4: 'Gigante',
      5: 'Extra grande',
      6: 'Enorme',
      7: 'Colossal',
    };

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.94),
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Text(
              'Configurações',
              style: TextStyle(
                color: BrandColors.gold,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Tempo de cada logo:',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () {
                    if (intervalSeconds > 3)
                      onIntervalChanged(intervalSeconds - 1);
                  },
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Text(
                  '${intervalSeconds}s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (intervalSeconds < 30)
                      onIntervalChanged(intervalSeconds + 1);
                  },
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 20),
                const Text(
                  'Logos juntos:',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(width: 10),
                ...List.generate(6, (i) {
                  final value = i + 1;
                  final selected = perScreen == value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text('$value'),
                      selected: selected,
                      onSelected: (_) => onPerScreenChanged(value),
                      selectedColor: BrandColors.gold,
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.white10,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Tamanho do número atual:',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(width: 10),
                ...sizeLabels.entries.map((entry) {
                  final selected = numberSize == entry.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: selected,
                      onSelected: (_) => onNumberSizeChanged(entry.key),
                      selectedColor: BrandColors.gold,
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.white10,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Tamanho do histórico:',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(width: 10),
                ...sizeLabels.entries.map((entry) {
                  final selected = historySize == entry.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: selected,
                      onSelected: (_) => onHistorySizeChanged(entry.key),
                      selectedColor: BrandColors.gold,
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.white10,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Cores',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ColorPickerField(
                  label: 'Fundo',
                  color: backgroundColor,
                  onChanged: onBackgroundColorChanged,
                ),
                const SizedBox(width: 20),
                ColorPickerField(
                  label: 'Número',
                  color: numberColor,
                  onChanged: onNumberColorChanged,
                ),
                const SizedBox(width: 20),
                ColorPickerField(
                  label: 'Digitação',
                  color: typingColor,
                  onChanged: onTypingColorChanged,
                ),
                const SizedBox(width: 20),
                ColorPickerField(
                  label: 'Histórico',
                  color: historyTextColor,
                  onChanged: onHistoryTextColorChanged,
                ),
                const SizedBox(width: 20),
                TextButton(
                  onPressed: onResetColors,
                  child: const Text('Restaurar padrão'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addSponsor,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Adicionar logo de patrocinador'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: imagePaths.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum patrocinador cadastrado ainda',
                        style: TextStyle(color: Colors.white54, fontSize: 22),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.4,
                          ),
                      itemCount: imagePaths.length,
                      itemBuilder: (context, index) {
                        final path = imagePaths[index];
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(10),
                              child: Image.file(
                                File(path),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.broken_image,
                                      color: Colors.white38,
                                      size: 40,
                                    ),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: GestureDetector(
                                onTap: () => _removeSponsor(path),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onClose,
              child: const Text('Fechar (Esc)'),
            ),
          ],
        ),
      ),
    );
  }
}
