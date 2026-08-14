import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_config.dart';

/// Resultado de tentar restaurar (ou fazer) o login.
enum SessionResult {
  /// Pode usar o app — seja porque validou com o servidor agora, seja
  /// porque está dentro do prazo de tolerância offline.
  ok,

  /// A comunidade foi bloqueada pelo administrador (ex: assinatura não
  /// paga). Não pode usar o app, nem offline.
  blocked,

  /// Já logou nesse computador antes, mas faz tempo demais sem internet
  /// pra confirmar que a conta continua ativa — precisa reconectar.
  expiredOffline,

  /// Nunca logou nesse computador (ou fez logout). Precisa preencher o
  /// formulário de login.
  needsLogin,
}

class AuthSession {
  final String uid;
  final String email;
  final String community;
  final String role;

  const AuthSession({
    required this.uid,
    required this.email,
    required this.community,
    required this.role,
  });
}

/// Cuida do login de quem vai PUBLICAR o sorteio (organizador/comunidade),
/// usando a API REST do Firebase Authentication — mesmo motivo de usarmos
/// REST no Firestore (lib/services/live_share_firebase.dart): o SDK nativo
/// do Firebase tem suporte limitado pra Windows desktop.
///
/// Guarda a sessão em disco (SharedPreferences) pra:
/// 1) não pedir login toda vez que o app abre;
/// 2) permitir uso OFFLINE por até [graceDays] dias desde a última vez que
///    conseguiu confirmar com o servidor que a conta está ativa — pensado
///    pra comunidades sem internet no dia do evento, desde que já tenham
///    logado nesse mesmo computador antes com internet.
class AuthService {
  AuthService._();

  static const graceDays = 30;

  static const _kUid = 'auth_uid';
  static const _kEmail = 'auth_email';
  static const _kCommunity = 'auth_community';
  static const _kRole = 'auth_role';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kActive = 'auth_active_last_check';
  static const _kLastVerifiedAt = 'auth_last_verified_at';
  static const _kRememberEmail = 'auth_remember_email';
  static const _kRememberPassword = 'auth_remember_password';

  static String? _idToken;
  static AuthSession? _session;

  /// Token da conta logada, pra mandar junto nas escritas do Firestore
  /// (ver live_share_firebase.dart) — sem ele, as regras de segurança
  /// recusam a escrita. Fica nulo quando está em modo offline (sem token
  /// novo pra oferecer — mas também não precisa, porque publicar no
  /// Firestore exige internet de qualquer jeito).
  static String? get idToken => _idToken;

  /// Dados de quem está logado agora. Também é a "sala" do Firestore onde
  /// o sorteio dessa comunidade é publicado (uid == ID do documento) — o
  /// link/QR da plateia usa esse mesmo ID.
  static AuthSession? get currentSession => _session;

  static Uri get _signInUri => Uri.parse(
    'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword'
    '?key=${FirebaseConfig.apiKey}',
  );

  static Uri get _refreshUri => Uri.parse(
    'https://securetoken.googleapis.com/v1/token?key=${FirebaseConfig.apiKey}',
  );

  static Uri _operatorDocUri(String uid) => Uri.parse(
    'https://firestore.googleapis.com/v1/projects/${FirebaseConfig.projectId}'
    '/databases/(default)/documents/operators/$uid',
  );

  static Uri _rifaoLiveDocUri(String uid) => Uri.parse(
    'https://firestore.googleapis.com/v1/projects/${FirebaseConfig.projectId}'
    '/databases/(default)/documents/rifao_live/$uid',
  );

  static Uri get _operatorsCollectionUri => Uri.parse(
    'https://firestore.googleapis.com/v1/projects/${FirebaseConfig.projectId}'
    '/databases/(default)/documents/operators',
  );

  static Uri get _signUpUri => Uri.parse(
    'https://identitytoolkit.googleapis.com/v1/accounts:signUp'
    '?key=${FirebaseConfig.apiKey}',
  );

  /// Tenta abrir a sessão salva do último login. Chamado ao abrir o app
  /// (ver login_screen.dart), antes de mostrar o formulário.
  static Future<SessionResult> resolveSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_kUid);
    final refreshToken = prefs.getString(_kRefreshToken);
    if (uid == null || refreshToken == null) return SessionResult.needsLogin;

    _session = AuthSession(
      uid: uid,
      email: prefs.getString(_kEmail) ?? '',
      community: prefs.getString(_kCommunity) ?? '',
      role: prefs.getString(_kRole) ?? 'community',
    );

    try {
      // Com internet: renova o token e confere no servidor se a conta
      // continua ativa — é a fonte da verdade. Também atualiza community
      // e role em cache, pra não ficar com dados velhos se algo mudar no
      // Firestore (ex: você promover alguém a admin).
      final newIdToken = await _refreshIdToken(refreshToken);
      final operatorData = await _fetchOperatorDoc(uid, newIdToken);
      final active = operatorData != null && _hasAccess(operatorData);
      final community =
          (operatorData?['community'] as String?) ?? _session!.community;
      final role = (operatorData?['role'] as String?) ?? _session!.role;

      _idToken = newIdToken;
      _session = AuthSession(
        uid: uid,
        email: _session!.email,
        community: community,
        role: role,
      );

      await prefs.setString(_kCommunity, community);
      await prefs.setString(_kRole, role);
      await prefs.setBool(_kActive, active);
      await prefs.setString(
        _kLastVerifiedAt,
        DateTime.now().toUtc().toIso8601String(),
      );
      return active ? SessionResult.ok : SessionResult.blocked;
    } catch (_) {
      // Sem internet (ou Firebase fora do ar): cai pro modo offline.
      final wasActive = prefs.getBool(_kActive) ?? false;
      final lastVerifiedRaw = prefs.getString(_kLastVerifiedAt);
      if (!wasActive || lastVerifiedRaw == null) return SessionResult.blocked;

      final lastVerified = DateTime.tryParse(lastVerifiedRaw);
      if (lastVerified == null) return SessionResult.blocked;

      final elapsed = DateTime.now().toUtc().difference(lastVerified);
      if (elapsed.inDays > graceDays) {
        return SessionResult.expiredOffline;
      }
      return SessionResult.ok;
    }
  }

  /// Login manual (formulário). Precisa de internet.
  static Future<SessionResult> signIn(String email, String password) async {
    final response = await http
        .post(
          _signInUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
            'returnSecureToken': true,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw AuthException(_extractErrorMessage(response.body));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final uid = data['localId'] as String;
    final newIdToken = data['idToken'] as String;
    final refreshToken = data['refreshToken'] as String;

    final operatorData = await _fetchOperatorDoc(uid, newIdToken);
    if (operatorData == null) {
      throw const AuthException(
        'Essa conta ainda não foi liberada. Fale com o suporte.',
      );
    }

    final active = _hasAccess(operatorData);
    final community = (operatorData['community'] as String?) ?? '';
    final role = (operatorData['role'] as String?) ?? 'community';
    final expiresAt = operatorData['expiresAt'] as DateTime?;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUid, uid);
    await prefs.setString(_kEmail, email.trim());
    await prefs.setString(_kCommunity, community);
    await prefs.setString(_kRole, role);
    await prefs.setString(_kRefreshToken, refreshToken);
    await prefs.setBool(_kActive, active);
    await prefs.setString(
      _kLastVerifiedAt,
      DateTime.now().toUtc().toIso8601String(),
    );

    _idToken = newIdToken;
    _session = AuthSession(
      uid: uid,
      email: email.trim(),
      community: community,
      role: role,
    );

    if (!active) {
      final expirou =
          operatorData['active'] == true &&
          expiresAt != null &&
          DateTime.now().toUtc().isAfter(expiresAt);
      throw AuthException(
        expirou
            ? 'O acesso dessa comunidade venceu. Fale com o suporte pra '
                  'renovar.'
            : 'Sua conta está bloqueada no momento. Fale com o suporte '
                  'pra regularizar o acesso.',
      );
    }

    return SessionResult.ok;
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUid);
    await prefs.remove(_kEmail);
    await prefs.remove(_kCommunity);
    await prefs.remove(_kRole);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kActive);
    await prefs.remove(_kLastVerifiedAt);
    _idToken = null;
    _session = null;
  }

  /// Guarda e-mail e senha neste computador, pra pré-preencher o
  /// formulário de login da próxima vez (checkbox "Lembrar-me" na tela
  /// de login). Fica salvo em texto simples, no mesmo nível de proteção
  /// que já usamos pra guardar a sessão — não é criptografado, então só
  /// use isso em computadores de confiança da comunidade.
  static Future<void> saveRememberedCredentials(
    String email,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRememberEmail, email);
    await prefs.setString(_kRememberPassword, password);
  }

  /// Retorna (e-mail, senha) salvos, ou null se nada foi guardado ainda.
  static Future<(String, String)?> getRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kRememberEmail);
    final password = prefs.getString(_kRememberPassword);
    if (email == null || password == null) return null;
    return (email, password);
  }

  static Future<void> clearRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRememberEmail);
    await prefs.remove(_kRememberPassword);
  }

  static Future<String> _refreshIdToken(String refreshToken) async {
    final response = await http
        .post(
          _refreshUri,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'grant_type': 'refresh_token', 'refresh_token': refreshToken},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw const AuthException('Sessão expirada, faça login novamente.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['id_token'] as String;
  }

  /// Busca o documento operators/{uid}, que só o dono (ou o admin, via
  /// console) consegue ler — é onde ficam os campos "active" e
  /// "expiresAt" usados pra liberar/bloquear cada comunidade.
  static Future<Map<String, dynamic>?> _fetchOperatorDoc(
    String uid,
    String idToken,
  ) async {
    final response = await http
        .get(
          _operatorDocUri(uid),
          headers: {'Authorization': 'Bearer $idToken'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw const AuthException('Não foi possível confirmar sua conta agora.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = json['fields'] as Map<String, dynamic>? ?? {};
    final expiresAtRaw = fields['expiresAt']?['timestampValue'] as String?;
    return {
      'active': fields['active']?['booleanValue'] ?? false,
      'community': fields['community']?['stringValue'] ?? '',
      'role': fields['role']?['stringValue'] ?? 'community',
      'expiresAt': expiresAtRaw != null
          ? DateTime.tryParse(expiresAtRaw)
          : null,
    };
  }

  /// Combina o campo "active" (liga/desliga manual) com a data de
  /// validade "expiresAt" (se existir) — os dois precisam estar OK pra
  /// conta ter acesso. Sem "expiresAt" = acesso sem prazo definido.
  static bool _hasAccess(Map<String, dynamic> operatorData) {
    if (operatorData['active'] != true) return false;
    final expiresAt = operatorData['expiresAt'] as DateTime?;
    if (expiresAt == null) return true;
    return DateTime.now().toUtc().isBefore(expiresAt);
  }

  static String _extractErrorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final code = json['error']?['message'] as String? ?? '';
      if (code.contains('EMAIL_NOT_FOUND') ||
          code.contains('INVALID_LOGIN_CREDENTIALS') ||
          code.contains('INVALID_PASSWORD')) {
        return 'E-mail ou senha incorretos.';
      }
      if (code.contains('USER_DISABLED')) return 'Essa conta foi desativada.';
      if (code.contains('EMAIL_EXISTS'))
        return 'Já existe uma conta com esse e-mail.';
      if (code.contains('WEAK_PASSWORD'))
        return 'Senha fraca — use pelo menos 6 caracteres.';
      if (code.contains('TOO_MANY_ATTEMPTS')) {
        return 'Muitas tentativas. Espere um pouco e tente de novo.';
      }
      return 'Não foi possível concluir. Confira os dados.';
    } catch (_) {
      return 'Não foi possível concluir. Confira os dados.';
    }
  }

  // ---------------- Painel de admin ----------------
  // Só funciona pra quem estiver logado como role == 'admin' — as regras
  // do Firestore (docs/firestore.rules) também impõem isso do lado do
  // servidor, então mesmo que alguém adultere o app, não consegue burlar.

  static bool get isAdmin => _session?.role == 'admin';

  /// Lista todas as comunidades cadastradas (menos a conta admin em si).
  static Future<List<OperatorInfo>> listOperators() async {
    final token = _idToken;
    if (token == null) throw const AuthException('Sessão expirada.');

    final response = await http
        .get(
          _operatorsCollectionUri,
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw const AuthException('Não foi possível carregar as comunidades.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = (json['documents'] as List?) ?? [];
    final result = <OperatorInfo>[];
    for (final d in docs) {
      final map = d as Map<String, dynamic>;
      final name = (map['name'] as String).split('/').last;
      final fields = map['fields'] as Map<String, dynamic>? ?? {};
      final role = fields['role']?['stringValue'] ?? 'community';
      if (role == 'admin') continue;
      final expiresAtRaw = fields['expiresAt']?['timestampValue'] as String?;
      result.add(
        OperatorInfo(
          uid: name,
          community: fields['community']?['stringValue'] ?? '(sem nome)',
          active: fields['active']?['booleanValue'] ?? false,
          expiresAt: expiresAtRaw != null
              ? DateTime.tryParse(expiresAtRaw)
              : null,
        ),
      );
    }
    result.sort(
      (a, b) => a.community.toLowerCase().compareTo(b.community.toLowerCase()),
    );
    return result;
  }

  /// Liga/desliga o acesso de uma comunidade (ex: assinatura em dia ou
  /// não). Some da lista de comunidades ativas na hora — a próxima vez
  /// que o app dessa comunidade tentar validar (com internet) já barra.
  static Future<void> setOperatorActive(String uid, bool active) async {
    final token = _idToken;
    if (token == null) throw const AuthException('Sessão expirada.');

    final uri = _operatorDocUri(
      uid,
    ).replace(queryParameters: {'updateMask.fieldPaths': 'active'});

    final response = await http
        .patch(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'fields': {
              'active': {'booleanValue': active},
            },
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw const AuthException('Não foi possível salvar a alteração.');
    }
  }

  /// Define (ou renova) a validade de acesso de uma comunidade, contando
  /// [days] dias a partir de AGORA. Passe null pra tirar o prazo (acesso
  /// sem data de validade, só o "active" manual controla).
  static Future<void> setOperatorExpiry(String uid, int? days) async {
    final token = _idToken;
    if (token == null) throw const AuthException('Sessão expirada.');

    final uri = _operatorDocUri(
      uid,
    ).replace(queryParameters: {'updateMask.fieldPaths': 'expiresAt'});

    final expiresAt = days == null
        ? null
        : DateTime.now().toUtc().add(Duration(days: days));

    final response = await http
        .patch(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'fields': {
              'expiresAt': expiresAt == null
                  ? {'nullValue': null}
                  : {'timestampValue': expiresAt.toIso8601String()},
            },
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw const AuthException('Não foi possível salvar a validade.');
    }
  }

  /// Força o fim da transmissão ao vivo de uma comunidade (campo
  /// rifao_live/{uid}.liveNow = false), pro caso dela esquecer de
  /// desligar. As regras do Firestore só deixam o admin mexer nesse
  /// campo específico — não dá pra inventar números sorteados de
  /// ninguém por aqui.
  static Future<void> forceEndLive(String uid) async {
    final token = _idToken;
    if (token == null) throw const AuthException('Sessão expirada.');

    final uri = _rifaoLiveDocUri(
      uid,
    ).replace(queryParameters: {'updateMask.fieldPaths': 'liveNow'});

    final response = await http
        .patch(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'fields': {
              'liveNow': {'booleanValue': false},
            },
          }),
        )
        .timeout(const Duration(seconds: 10));

    // 404 é ok aqui — significa que essa comunidade nunca publicou nada,
    // então não tem o que encerrar.
    if (response.statusCode != 200 && response.statusCode != 404) {
      throw const AuthException('Não foi possível encerrar a transmissão.');
    }
  }

  /// Cria a conta de login (Firebase Auth) + o cadastro (Firestore) de
  /// uma comunidade nova, tudo de uma vez. Precisa estar logado como
  /// admin — a criação da conta em si usa o endpoint público de
  /// cadastro do Firebase (accounts:signUp), mas quem grava o documento
  /// em operators/ é o admin, com o próprio token, então a comunidade
  /// nova nasce sem poder se auto-promover.
  static Future<void> createOperator({
    required String community,
    required String email,
    required String password,
    int? days,
  }) async {
    final adminToken = _idToken;
    if (adminToken == null) throw const AuthException('Sessão expirada.');

    final signUpResponse = await http
        .post(
          _signUpUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
            'returnSecureToken': true,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (signUpResponse.statusCode != 200) {
      throw AuthException(_extractErrorMessage(signUpResponse.body));
    }

    final data = jsonDecode(signUpResponse.body) as Map<String, dynamic>;
    final newUid = data['localId'] as String;

    final expiresAt = days == null
        ? null
        : DateTime.now().toUtc().add(Duration(days: days));

    final docResponse = await http
        .patch(
          _operatorDocUri(newUid),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $adminToken',
          },
          body: jsonEncode({
            'fields': {
              'community': {'stringValue': community.trim()},
              'role': {'stringValue': 'community'},
              'active': {'booleanValue': true},
              if (expiresAt != null)
                'expiresAt': {'timestampValue': expiresAt.toIso8601String()},
            },
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (docResponse.statusCode != 200) {
      throw const AuthException(
        'A conta de login foi criada, mas houve um erro ao cadastrar a '
        'comunidade. Tente de novo ou crie manualmente pelo Console.',
      );
    }
  }
}

class OperatorInfo {
  final String uid;
  final String community;
  final bool active;
  final DateTime? expiresAt;

  const OperatorInfo({
    required this.uid,
    required this.community,
    required this.active,
    this.expiresAt,
  });

  /// true quando tem prazo definido e ele já passou.
  bool get isExpired =>
      expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt!);

  int? get daysRemaining {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now().toUtc()).inDays;
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
