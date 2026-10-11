import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healtnest_app/core/config.dart';
import 'package:healtnest_app/core/constants.dart';
import 'package:healtnest_app/core/theme.dart';
import 'package:healtnest_app/data/repositories/mock_data_repository.dart';
import 'package:healtnest_app/data/sources/mock_wearable_source.dart';
import 'package:healtnest_app/features/home/presentation/home_screen.dart';
import 'package:healtnest_app/features/home/state/home_provider.dart';
import 'package:provider/provider.dart';

void main() {
  group('HomeProvider Tests', () {
    test('Initializes with connected state and loads initial data', () async {
      final wearableSource = MockWearableSource();
      final dataRepository = MockDataRepository();
      final provider = HomeProvider(
        wearableSource: wearableSource,
        dataRepository: dataRepository,
        userId: 1,
      );

      // Wait for connect (600ms) and initial loads
      await Future<void>.delayed(const Duration(milliseconds: 900));

      expect(provider.isConnected, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.stateLabel, 'Calm');
      expect(provider.isCalm, isTrue);
      expect(provider.isStressed, isFalse);

      provider.dispose();
      await wearableSource.disconnect();
    });

    test('Simulate stress spike scenario updates state to Stressed', () async {
      final wearableSource = MockWearableSource();
      final dataRepository = MockDataRepository();
      final provider = HomeProvider(
        wearableSource: wearableSource,
        dataRepository: dataRepository,
        userId: 1,
      );

      await Future<void>.delayed(const Duration(milliseconds: 900));

      provider.simulateScenario(MockScenario.stressSpike);

      expect(provider.isStressed, isTrue);
      expect(provider.isCalm, isFalse);
      expect(provider.stateLabel, 'Stressed');
      expect(provider.tipDismissed, isFalse);

      provider.dismissTip();
      expect(provider.tipDismissed, isTrue);

      provider.dispose();
      await wearableSource.disconnect();
    });

    test('SpO2 threshold correctly marks low SpO2 (< 95%)', () async {
      final wearableSource = MockWearableSource();
      final dataRepository = MockDataRepository();
      final provider = HomeProvider(
        wearableSource: wearableSource,
        dataRepository: dataRepository,
        userId: 1,
      );

      await Future<void>.delayed(const Duration(milliseconds: 900));

      provider.simulateScenario(MockScenario.lowSpo2);
      // Wait for 1 sensor packet ticker (1000ms)
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      expect(provider.isSpo2Low, isTrue);
      expect(provider.spo2StatusLabel, 'Low');

      provider.dispose();
      await wearableSource.disconnect();
    });
  });

  group('HomeScreen Widget Tests', () {
    Widget buildTestApp(HomeProvider provider) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        routes: {
          AppConstants.routeHistory: (context) => const Scaffold(body: Text('History Route')),
          AppConstants.routeSettings: (context) => const Scaffold(body: Text('Settings Route')),
        },
        home: ChangeNotifierProvider<HomeProvider>.value(
          value: provider,
          child: const HomeScreen(),
        ),
      );
    }

    testWidgets('Renders all required elements in Calm state', (tester) async {
      final wearableSource = MockWearableSource();
      final dataRepository = MockDataRepository();
      final provider = HomeProvider(
        wearableSource: wearableSource,
        dataRepository: dataRepository,
        userId: 1,
      );

      await tester.pumpWidget(buildTestApp(provider));

      // Pump past wearable auto-connect delayed future
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 100));

      // Header and title
      expect(find.text(AppConfig.appTitle), findsOneWidget);

      // Connection banner with "Live" and "Wristband Connected"
      expect(find.text('Wristband Connected'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);

      // Calm state text & icon (FR-7.1, NFR-4.4)
      expect(find.text('You are Calm'), findsOneWidget);
      expect(find.text('Optimal Vitals Zone'), findsOneWidget);

      // Vitals grid (FR-7.2, FR-7.5)
      expect(find.text('Heart Rate'), findsOneWidget);
      expect(find.text('Blood Oxygen'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);

      // Medical disclaimer (FR-6.3)
      expect(find.text(AppConfig.medicalDisclaimer), findsOneWidget);

      // Bottom navigation bar
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Band'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);

      provider.dispose();
      await wearableSource.disconnect();
    });

    testWidgets('Renders Stressed card and dismissible tip in Stressed state',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final wearableSource = MockWearableSource();
      final dataRepository = MockDataRepository();
      final provider = HomeProvider(
        wearableSource: wearableSource,
        dataRepository: dataRepository,
        userId: 1,
      );

      await tester.pumpWidget(buildTestApp(provider));

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 100));

      provider.simulateScenario(MockScenario.stressSpike);
      await tester.pump(const Duration(milliseconds: 100));

      // Stressed state text (FR-7.1, NFR-4.4)
      expect(find.text('You are Stressed'), findsOneWidget);
      expect(find.text('PHYSICAL MONITOR'), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsWidgets);

      // Passive tip card (D-24, FR-9.1)
      expect(find.text('Stress has been high for a while'), findsOneWidget);
      expect(find.text('Take a short break and drink some water.'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);

      // Dismiss tip
      await tester.ensureVisible(find.text('Got it'));
      await tester.tap(find.text('Got it'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Stress has been high for a while'), findsNothing);

      provider.dispose();
      await wearableSource.disconnect();
    });
  });
}
