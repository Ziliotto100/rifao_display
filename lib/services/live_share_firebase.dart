import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/drawn_entry.dart';
import 'firebase_config.dart';

/// Manda o estado atual do sorteio (número em destaque + últimos 5) pro
/// Firestore, usando a API REST direta — sem precisar do SDK nativo do
/// Firebase (que tem suporte limitado pra Windows desktop).
///
/// Os celulares da plateia leem esse mesmo documento em tempo real através
/// da página web pública (veja o arquivo docs/index.html do repositório).
class LiveShareFirebase {
  static Uri get _docUri => Uri.parse(
    'https://firestore.googleapis.com/v1/projects/${FirebaseConfig.projectId}'
    '/databases/(default)/documents/${FirebaseConfig.collection}/${FirebaseConfig.document}'
    '?key=${FirebaseConfig.apiKey}',
  );

  static bool get isConfigured =>
      FirebaseConfig.projectId != 'COLE_AQUI_O_PROJECT_ID' &&
      FirebaseConfig.apiKey != 'COLE_AQUI_A_API_KEY' &&
      FirebaseConfig.projectId.isNotEmpty &&
      FirebaseConfig.apiKey.isNotEmpty;

  /// Envia o estado atual. Chamado toda vez que um número é confirmado,
  /// editado, excluído ou o rifão é reiniciado. Falha silenciosamente se
  /// não tiver internet no momento — a próxima atualização bem-sucedida
  /// corrige o que a plateia vê.
  static Future<void> updateState(List<DrawnEntry> entries) async {
    if (!isConfigured) return;

    try {
      final total = entries.length;
      final history = <Map<String, dynamic>>[];
      for (var i = 1; i < total && history.length < 5; i++) {
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
            _docUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Sem internet no momento, ou Firebase fora do ar — não trava o app.
      // A próxima chamada bem-sucedida sincroniza a plateia de novo.
    }
  }
}
