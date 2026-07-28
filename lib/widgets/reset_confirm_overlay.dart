import 'package:flutter/material.dart';

class ResetConfirmOverlay extends StatelessWidget {
  const ResetConfirmOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.92),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orangeAccent,
                size: 64,
              ),
              const SizedBox(height: 20),
              const Text(
                'Iniciar novo rifão?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Isso vai apagar todo o histórico de números sorteados.',
                style: TextStyle(color: Colors.white70, fontSize: 20),
              ),
              const SizedBox(height: 28),
              Text(
                'Enter = confirmar    |    Esc = cancelar',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
