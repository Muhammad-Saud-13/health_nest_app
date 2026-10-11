import 'package:flutter_test/flutter_test.dart';
import 'package:healtnest_app/data/repositories/mock_auth_repository.dart';
import 'package:healtnest_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      HealthNestApp(authRepository: MockAuthRepository()),
    );

    // Verify that the login screen title is rendered.
    expect(find.text('HealthNest'), findsOneWidget);
  });
}
