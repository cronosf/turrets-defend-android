import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turrets_defend/main.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    // LoginScreen checks SharedPreferences for a remembered API session
    // before rendering the login form; without mock values that call never
    // resolves under `flutter test` (no platform channel to answer it).
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MergeTurretsApp());
    // LoginScreen briefly shows a spinner (itself an indefinite animation,
    // so pumpAndSettle would never converge) while it checks for a
    // remembered API session — there is none in a fresh test environment —
    // before rendering the actual login form.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
  });
}
