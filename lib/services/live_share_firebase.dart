import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/drawn_entry.dart';
import 'auth_service.dart';
import 'firebase_config.dart';

/// Manda o estado atual do sorteio (número em destaque + histórico
/// completo) pro Firestore, usando a API REST direta — sem precisar do
/// SDK nativo do Firebase (que tem suporte limitado pra Windows desktop).
///
/// Os celulares da plateia leem esse mesmo documento em tempo real através
/// da página web pública (veja o arquivo docs/index.html do repositório).
///
/// Cada comunidade logada publica no SEU PRÓPRIO documento
/// (rifao_live/{uid da comunidade}) — por isso a escrita só funciona com
/// alguém logado (ver lib/services/auth_service.dart) e o link/QR da
/// plateia carrega esse mesmo uid (veja lib/widgets/live_share_overlay.dart).
class LiveShareFirebase {
  static Uri? get _docUri {
    final uid = AuthService.currentSession?.uid;
    if (uid == null) return null;
    return Uri.parse(
      'https://firestore.googleapis.com/v1/projects/${FirebaseConfig.projectId}'
      '/databases/(default)/documents/${FirebaseConfig.collection}/$uid',
    );
  }

  static bool get isConfigured =>
      FirebaseConfig.projectId != 'COLE_AQUI_O_PROJECT_ID' &&
      FirebaseConfig.apiKey != 'COLE_AQUI_A_API_KEY' &&
      FirebaseConfig.projectId.isNotEmpty &&
      FirebaseConfig.apiKey.isNotEmpty &&
      AuthService.currentSession != null;

  /// Envia o estado atual. Chamado toda vez que um número é confirmado,
  /// editado, excluído ou o rifão é reiniciado. Falha silenciosamente se
  /// não tiver internet no momento, ou se estiver em modo offline (sem
  /// token válido) — a próxima atualização bem-sucedida corrige o que a
  /// plateia vê.
  static Future<void> updateState(List<DrawnEntry> entries) async {
    final docUri = _docUri;
    final idToken = AuthService.idToken;
    if (!isConfigured || docUri == null || idToken == null) return;

    try {
      final total = entries.length;
      // Manda o histórico INTEIRO (não só os últimos 5): a página da
      // plateia usa essa lista completa pra avisar quando um número
      // cadastrado tiver saído em qualquer prêmio anterior, não só nos
      // mais recentes. A tela já corta pra mostrar só os 5 últimos
      // visualmente — ver docs/index.html.
      final history = <Map<String, dynamic>>[];
      for (var i = 1; i < total; i++) {
        history.add({'prize': total - i, 'number': entries[i].number});
      }

      final body = {
        'fields': {
          'prizeNumber': {'integerValue': total.toString()},
          'currentNumber': total > 0
              ? {'stringValue': entries.first.number}
              : {'nullValue': null},
          'updatedAt': {
            'timestampValue': DateTime.now().toUtc().toIso8601String(),
          },
          'history': {
            'arrayValue': {
              'values': history
                  .map(
                    (h) => {
                      'mapValue': {
                        'fields': {
                          'prize': {'integerValue': h['prize'].toString()},
                          'number': {'stringValue': h['number']},
                        },
                      },
                    },
                  )
                  .toList(),
            },
          },
        },
      };

      await http
          .patch(
            docUri,
            headers: {
              'Content-Type': 'application/json',
              // Sem esse token, as regras de segurança do Firestore
              // recusam a escrita — só a própria comunidade logada (ou o
              // admin) pode publicar no documento dela.
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Sem internet no momento, ou Firebase fora do ar — não trava o app.
      // A próxima chamada bem-sucedida sincroniza a plateia de novo.
    }
  }
}
