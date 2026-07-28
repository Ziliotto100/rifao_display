import 'package:flutter/material.dart';

class EditingBanner extends StatelessWidget {
  final int prizeNumber;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const EditingBanner({
    super.key,
    required this.prizeNumber,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.lightBlueAccent),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Editando o número do Prêmio Nº ${prizeNumber.toString().padLeft(2, '0')}. '
            'Digite o número certo.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                icon: const Icon(Icons.check),
                label: const Text('Salvar'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: onCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                ),
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
