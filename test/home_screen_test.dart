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

      // Wait for connect (600ms) and initial loads (up to 400ms)
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      expect(provider.isConnected, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.stateLabel, 'Calm');
      expect(provider.isCalm, isTrue);
      expect(provider.isStressed, isFalse);
      expect(provider.hasSustainedStressAlert, isFalse);

      provider.dispose();
      await wearableSource.disconnect();
    });

    test('Simulate stress spike scenario updates state to Stressed and raises alert', () async {
      final wearableSource = MockWearableSource();
      final dataRepository = MockDataRepository();
      final provider = HomeProvider(
        wearableSource: wearableSource,
        dataRepository: dataRepository,
        userId: 1,
      );

      await Future<void>.delayed(const Duration(milliseconds: 1200));

      provider.simulateScenario(MockScenario.stressSpike);
      // Wait for async _loadAlerts() to complete
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(provider.isStressed, isTrue);
      expect(provider.isCalm, isFalse);
      expect(provider.stateLabel, 'Stressed');
      expect(provider.hasSustainedStressAlert, isTrue);
      expect(provider.sustainedStressAlert, isNotNull);

      await provider.acknowledgeAlert(provider.sustainedStressAlert!.id);
      expect(provider.hasSustainedStressAlert, isFalse);

      provider.dispose();
      await wearableSource.disconnect();
    });

    test('SpO2 threshold correctly marks low SpO2 (< 95%) and generates alert', () async {
      final wearableSource = MockWearableSource();
      final dataRepository = MockDataRepository();
      final provider = HomeProvider(
        wearableSource: wearableSource,
        dataRepository: dataRepository,
        userId: 1,
      );

      await Future<void>.delayed(const Duration(milliseconds: 1200));

      provider.simulateScenario(MockScenario.lowSpo2);
      // Wait for 1 sensor packet ticker (1000ms)
      await Future<void>.delayed(const Duration(milliseconds: 1400));

      expect(provider.isSpo2Low, isTrue);
      expect(provider.spo2StatusLabel, 'Low');
      expect(provider.hasLowSpo2Alert, isTrue);

      await provider.acknowledgeAlert(provider.lowSpo2Alert!.id);
      expect(provider.hasLowSpo2Alert, isFalse);

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

      // Pump past wearable auto-connect and initial loads
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 200));

      // Header and title
      expect(find.text(AppConfig.appTitle), findsOneWidget);

      // Connection banner with "Live" and "Wristband Connected"
      expect(find.text('Wristband Connected'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);

      // Calm state text & icon (FR-7.1, NFR-4.4)
      expect(find.text('You are Calm'), findsOneWidget);
      expect(find.text('Optimal Vitals Zone'), findsOneWidget);

      // Sustained stress alert should not be visible in calm state
      expect(find.text('Sustained Stress Detected'), findsNothing);

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

    testWidgets('Renders Sustained Stress Alert Card and handles acknowledgement (T-06, FR-6.2, FR-9.1, D-24)',
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

      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 200));

      provider.simulateScenario(MockScenario.stressSpike);
      await tester.pump(const Duration(milliseconds: 200));

      // Stressed state text (FR-7.1, NFR-4.4)
      expect(find.text('You are Stressed'), findsOneWidget);
      expect(find.text('PHYSICAL MONITOR'), findsOneWidget);

      // Sustained Stress Alert Card (T-06, FR-6.2, FR-9.1)
      expect(find.text('Sustained Stress Detected'), findsOneWidget);
      expect(
        find.text('Your body has been showing higher stress signals for a while.'),
        findsOneWidget,
      );
      expect(find.text('Take a short break if safe to do so'), findsOneWidget);
      expect(find.text('Drink some water and hydrate'), findsOneWidget);
      expect(find.text('Take a few slow, deep breaths'), findsOneWidget);
      expect(find.text('I Understand'), findsOneWidget);

      // Acknowledge alert
      await tester.ensureVisible(find.text('I Understand'));
      await tester.tap(find.text('I Understand'));
      await tester.pump(const Duration(milliseconds: 200));

      // After acknowledgement, sustained stress alert disappears
      expect(find.text('Sustained Stress Detected'), findsNothing);

      provider.dispose();
      await wearableSource.disconnect();
    });

    testWidgets('Renders Low SpO2 Alert Card and handles acknowledgement (T-06, FR-6.3, FR-9.1)',
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

      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 200));

      provider.simulateScenario(MockScenario.lowSpo2);
      await tester.pump(const Duration(milliseconds: 200));

      // Low SpO2 Alert Card (T-06, FR-6.3)
      expect(find.text('Blood Oxygen Low'), findsOneWidget);
      expect(
        find.text('Your SpO2 reading has dropped below 95%.'),
        findsOneWidget,
      );
      expect(find.text('I Understand'), findsOneWidget);

      // Acknowledge alert
      await tester.ensureVisible(find.text('I Understand'));
      await tester.tap(find.text('I Understand'));
      await tester.pump(const Duration(milliseconds: 200));

      // After acknowledgement, low SpO2 alert card disappears
      expect(find.text('Blood Oxygen Low'), findsNothing);

      provider.dispose();
      await wearableSource.disconnect();
    });
  });
}
