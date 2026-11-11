import 'package:ecoenzyme/core/router/app_router.dart';
import 'package:ecoenzyme/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts on login route when signed out', (
    WidgetTester tester,
  ) async {
    final router = createAppRouter(isAuthenticated: () => false);
    addTearDown(router.dispose);

    await tester.pumpWidget(MyApp(router: router));
    await tester.pump();

    expect(find.text('Login,'), findsOneWidget);
  });
}
