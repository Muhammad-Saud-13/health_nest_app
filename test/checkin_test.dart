import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healtnest_app/core/theme.dart';
import 'package:healtnest_app/data/repositories/mock_auth_repository.dart';
import 'package:healtnest_app/data/repositories/mock_data_repository.dart';
import 'package:healtnest_app/data/sources/mock_wearable_source.dart';
import 'package:healtnest_app/features/auth/state/auth_provider.dart';
import 'package:healtnest_app/features/checkin/presentation/checkin_screen.dart';
import 'package:healtnest_app/features/checkin/state/checkin_provider.dart';
import 'package:healtnest_app/features/home/state/home_provider.dart';
import 'package:provider/provider.dart';

void main() {
  group('CheckInProvider Unit Tests (T-07, FR-8.1–8.4)', () {
    late MockDataRepository dataRepo;
    late CheckInProvider provider;

    setUp(() {
      dataRepo = MockDataRepository();
      provider = CheckInProvider(dataRepository: dataRepo);
    });

    test('Initializes with empty answers and incomplete state', () {
      expect(provider.feeling, isNull);
      expect(provider.pain, isNull);
      expect(provider.stressSelf, isNull);
      expect(provider.answeredCount, 0);
      expect(provider.progressFraction, 0.0);
      expect(provider.isComplete, isFalse);
      expect(provider.isSubmitting, isFalse);
      expect(provider.isSubmitted, isFalse);
    });

    test('Setting answers updates count, progress fraction, and completion', () {
      provider.setFeeling(1); // Fine
      expect(provider.feeling, 1);
      expect(provider.answeredCount, 1);
      expect(provider.progressFraction, closeTo(0.333, 0.01));
      expect(provider.isComplete, isFalse);

      provider.setPain(2); // Mild
      expect(provider.pain, 2);
      expect(provider.answeredCount, 2);
      expect(provider.progressFraction, closeTo(0.666, 0.01));
      expect(provider.isComplete, isFalse);

      provider.setStress(1); // Low
      expect(provider.stressSelf, 1);
      expect(provider.answeredCount, 3);
      expect(provider.progressFraction, 1.0);
      expect(provider.isComplete, isTrue);
    });

    test('Submitting check-in saves to repository (FR-8.4)', () async {
      provider.setFeeling(1);
      provider.setPain(1);
      provider.setStress(2);

      final success = await provider.submit(
        userId: 1,
        sessionId: 101,
        kind: 'SHIFT_START',
      );

      expect(success, isTrue);
      expect(provider.isSubmitted, isTrue);
      expect(provider.isSubmitting, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('Reset clears all selected answers and progress', () {
      provider.setFeeling(2);
      provider.setPain(3);
      provider.setStress(3);
      expect(provider.isComplete, isTrue);

      provider.reset();
      expect(provider.feeling, isNull);
      expect(provider.pain, isNull);
      expect(provider.stressSelf, isNull);
      expect(provider.answeredCount, 0);
      expect(provider.isComplete, isFalse);
    });
  });

  group('CheckInScreen Widget Tests (T-07, NFR-4.1, NFR-4.3)', () {
    late MockDataRepository dataRepo;
    late MockWearableSource wearableSource;
    late HomeProvider homeProvider;

    setUp(() {
      dataRepo = MockDataRepository();
      wearableSource = MockWearableSource(autoConnect: false);
      homeProvider = HomeProvider(
        wearableSource: wearableSource,
        dataRepository: dataRepo,
        userId: 1,
      );
    });

    tearDown(() async {
      homeProvider.dispose();
      await wearableSource.disconnect();
      wearableSource.dispose();
    });

    Widget buildTestApp() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: MultiProvider(
          providers: [
            Provider<MockDataRepository>.value(value: dataRepo),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(authRepository: MockAuthRepository()),
            ),
            ChangeNotifierProvider<HomeProvider>.value(value: homeProvider),
            ChangeNotifierProvider<CheckInProvider>(
              create: (_) => CheckInProvider(dataRepository: dataRepo),
            ),
          ],
          child: const Scaffold(
            body: CheckInModalContent(isModal: false),
          ),
        ),
      );
    }

    testWidgets('Renders all questions and handles 3-tap self report flow',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Header checks
      expect(find.text('Quick self report'), findsOneWidget);
      expect(find.text('0 of 3 answered'), findsOneWidget);

      // Question 1: Feeling
      expect(find.text('How are you feeling right now?'), findsOneWidget);
      expect(find.text('Fine'), findsOneWidget);
      expect(find.text('Tired'), findsOneWidget);
      expect(find.text('Unwell'), findsOneWidget);

      // Question 2: Pain
      expect(find.text('Any physical pain or discomfort?'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(find.text('Mild'), findsOneWidget);
      expect(find.text('Severe'), findsOneWidget);

      // Question 3: Stress
      expect(find.text('Current self-reported stress level?'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);

      // Action buttons
      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);

      // Tap 1: Select Fine
      await tester.tap(find.text('Fine'));
      await tester.pump();
      expect(find.text('1 of 3 answered'), findsOneWidget);

      // Tap 2: Select No pain
      await tester.tap(find.text('No'));
      await tester.pump();
      expect(find.text('2 of 3 answered'), findsOneWidget);

      // Tap 3: Select Low stress
      await tester.tap(find.text('Low'));
      await tester.pump();
      expect(find.text('3 of 3 answered'), findsOneWidget);

      // Tap Submit
      await tester.tap(find.text('Submit'));
      await tester.pump();

      // Wait for repository delay (200ms)
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
