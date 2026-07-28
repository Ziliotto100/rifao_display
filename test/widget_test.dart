import 'package:flutter_test/flutter_test.dart';
import 'package:rifao_display/main.dart';

void main() {
  testWidgets('App inicializa e mostra tela padrão', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RifaoApp());

    // Como não digitamos nada ainda, deve mostrar o placeholder '--'
    expect(find.text('--'), findsOneWidget);
  });
}
