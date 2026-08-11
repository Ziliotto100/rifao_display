/// Dados do projeto Firebase usado pra transmitir o rifão ao vivo pros
/// celulares da plateia, e também pro login de quem publica os números
/// (organizador/comunidade).
///
/// COMO PREENCHER:
/// 1. Crie um projeto no https://console.firebase.google.com (ou use um
///    que você já tenha).
/// 2. Ative o "Cloud Firestore" (Build > Firestore Database > Criar banco).
/// 3. Ative o "Authentication" (Build > Authentication > Get started) e
///    habilite o provedor "E-mail/senha".
/// 4. Crie uma conta pra cada comunidade em Authentication > Users >
///    Add user (e-mail + senha). Copie o UID gerado de cada uma.
/// 5. Pra cada UID, crie um documento em Firestore > operators/{UID} com
///    os campos: community (string), role ("admin" ou "community"),
///    active (boolean, true pra liberar).
/// 6. Cole as regras de segurança do arquivo docs/firestore.rules em
///    Firestore Database > Regras.
/// 7. Vá em Configurações do projeto (ícone de engrenagem) > Geral, e
///    copie o "ID do projeto" e a "Chave de API da Web".
/// 8. Cole os dois valores abaixo, entre aspas.
class FirebaseConfig {
  FirebaseConfig._();

  /// Ex.: 'rifao-eventos-12345'
  static const projectId = 'rifao-eventos';

  /// Ex.: 'AIzaSyB1a2C3d4E5f6G7h8I9j0K...'
  static const apiKey = 'AIzaSyCHVXPaawNE_QV_3tzAzCNwyTj0mHAJ8tc';

  /// Nome da coleção/documento usados no Firestore pra guardar o estado
  /// do sorteio. Só precisa mudar se você já usar esse mesmo projeto
  /// Firebase pra outra coisa e quiser evitar conflito de nomes.
  static const collection = 'rifao_live';
  static const document = 'estado_atual';
}
