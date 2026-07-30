import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/drawn_entry.dart';

/// Salva os números sorteados no disco a cada alteração (confirmar, editar,
/// excluir ou zerar), pra que uma queda de energia, um travamento ou um
/// fechamento acidental do programa não faça o rifão perder o que já foi
/// sorteado. Na próxima vez que o app abrir, tudo volta de onde parou.
class EntriesStorage {
  static const _entriesKey = 'raffle_entries';
  static const _idCounterKey = 'raffle_id_counter';

  static Future<List<DrawnEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_entriesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => DrawnEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Se o dado salvo estiver corrompido por algum motivo, é mais seguro
      // começar vazio do que travar o app na abertura.
      return [];
    }
  }

  static Future<void> saveEntries(List<DrawnEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_entriesKey, raw);
  }

  static Future<int> loadIdCounter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_idCounterKey) ?? 0;
  }

  static Future<void> saveIdCounter(int counter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_idCounterKey, counter);
  }

  /// Apaga o progresso salvo. Usado quando o usuário confirma que quer
  /// mesmo começar um rifão novo do zero (tecla N), não apenas quando a
  /// tela é reaberta.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_entriesKey);
    await prefs.remove(_idCounterKey);
  }
}
