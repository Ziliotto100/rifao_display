import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerField extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  const ColorPickerField({
    super.key,
    required this.label,
    required this.color,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    Color tempColor = color;
    final result = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(label, style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (c) => tempColor = c,
              enableAlpha: false,
              labelTypes: const [],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(tempColor),
              child: const Text('Selecionar'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 2),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
