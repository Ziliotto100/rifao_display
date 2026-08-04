import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/live_share_firebase.dart';
import '../theme/brand_colors.dart';

/// URL pública da página que a plateia acessa pelo celular. Por padrão
/// aponta pro GitHub Pages do repositório — troque aqui se você hospedar
/// em outro lugar (ou usar um domínio próprio).
const String liveShareUrl = 'https://ziliotto100.github.io/rifao_display/';

/// Tela com o QR Code pra plateia escanear e acompanhar o sorteio ao vivo
/// pelo celular. Aberta com a tecla Q.
class LiveShareOverlay extends StatelessWidget {
  const LiveShareOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final configured = LiveShareFirebase.isConfigured;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.96),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_2_rounded,
                color: BrandColors.gold,
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'Acompanhe pelo celular',
                style: TextStyle(
                  color: BrandColors.gold,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Aponte a câmera do celular pro QR Code abaixo\n'
                'pra ver o número sorteado e o histórico ao vivo.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              if (!configured)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: const Text(
                    'A transmissão ainda não foi configurada.\n'
                    'Preencha lib/services/firebase_config.dart com os '
                    'dados do seu projeto Firebase.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: liveShareUrl,
                    size: 260,
                    backgroundColor: Colors.white,
                  ),
                ),
              const SizedBox(height: 20),
              SelectableText(
                liveShareUrl,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'Esc para fechar',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
