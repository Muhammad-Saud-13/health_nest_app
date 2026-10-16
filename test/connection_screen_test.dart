import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healtnest_app/core/constants.dart';
import 'package:healtnest_app/core/theme.dart';
import 'package:healtnest_app/data/sources/mock_wearable_source.dart';
import 'package:healtnest_app/features/connection/presentation/band_screen.dart';
import 'package:healtnest_app/features/connection/state/connection_provider.dart';
import 'package:provider/provider.dart';

void main() {
  group('ConnectionProvider Unit Tests', () {
    late MockWearableSource mockSource;
    late ConnectionProvider provider;

    setUp(() {
      mockSource = MockWearableSource(autoConnect: false);
      provider = ConnectionProvider(wearableSource: mockSource);
    });

    tearDown(() {
      provider.dispose();
      mockSource.dispose();
    });

    test('Initializes with disconnected state when wearableSource is not connected', () {
      expect(provider.isConnected, isFalse);
      expect(provider.isDisconnected, isTrue);
      expect(provider.badgeLabel, equals('Disconnected'));
      expect(provider.hasFailure, isFalse);
    });

    test('Connect updates state to connected', () async {
      await provider.connect();
      expect(provider.isConnected, isTrue);
      expect(provider.isDisconnected, isFalse);
      expect(provider.badgeLabel, equals('Connected'));
      expect(provider.stateTitle, contains('Connected to'));
    });

    test('Disconnect updates state to disconnected', () async {
      await provider.connect();
      expect(provider.isConnected, isTrue);

      await provider.disconnect();
      expect(provider.isConnected, isFalse);
      expect(provider.isDisconnected, isTrue);
      expect(provider.badgeLabel, equals('Disconnected'));
    });

    test('simulateDeviceNotFound sets failure message (FR-3.9)', () async {
      await provider.simulateDeviceNotFound();
      expect(provider.hasFailure, isTrue);
      expect(provider.failureMessage, contains('not found'));
      expect(provider.isDisconnected, isTrue);

      provider.clearFailure();
      expect(provider.hasFailure, isFalse);
      expect(provider.failureMessage, isNull);
    });

    test('simulateConnectionFailure sets failure message (FR-3.9)', () async {
      await provider.simulateConnectionFailure();
      expect(provider.hasFailure, isTrue);
      expect(provider.failureMessage, contains('Unable to connect'));
    });

    test('simulateAutoReconnect initiates auto-reconnect cycle (T-05, NFR-2.1)', () async {
      await provider.connect();
      expect(provider.isConnected, isTrue);

      // Trigger cycle with short durations for fast test execution
      provider.simulateAutoReconnect(
        disconnectDuration: const Duration(milliseconds: 60),
        reconnectDuration: const Duration(milliseconds: 100),
      );

      // 1. First state: disconnected
      expect(provider.isDisconnected, isTrue);

      // 2. Second state: reconnecting
      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(provider.isReconnecting, isTrue);
      expect(provider.badgeLabel, equals('Reconnecting...'));

      // 3. Third state: connected
      await Future<void>.delayed(const Duration(milliseconds: 140));
      expect(provider.isConnected, isTrue);
      expect(provider.badgeLabel, equals('Connected'));
    });
  });

  group('BandScreen Widget Tests', () {
    late MockWearableSource mockSource;
    late ConnectionProvider provider;

    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        routes: {
          AppConstants.routeHome: (_) => const Scaffold(body: Text('Home Screen')),
          AppConstants.routeHistory: (_) => const Scaffold(body: Text('History Screen')),
          AppConstants.routeSettings: (_) => const Scaffold(body: Text('Settings Screen')),
        },
        home: ChangeNotifierProvider<ConnectionProvider>.value(
          value: provider,
          child: const BandScreen(animatePulse: false),
        ),
      );
    }

    setUp(() {
      mockSource = MockWearableSource(autoConnect: false);
      provider = ConnectionProvider(wearableSource: mockSource);
    });

    tearDown(() {
      provider.dispose();
      mockSource.dispose();
    });

    testWidgets('Renders Disconnected visual state with color, icon, and text (NFR-4.4)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Title & Subheader
      expect(find.text('Band Connection'), findsOneWidget);
      expect(find.text('Manage your HealthNest device'), findsOneWidget);

      // Disconnected Badge & Text
      expect(find.text('Disconnected'), findsOneWidget);
      expect(find.textContaining('Disconnected'), findsWidgets);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);

      // Pair Band button (56px)
      expect(find.text('Pair Band'), findsOneWidget);
      expect(find.byIcon(Icons.link_rounded), findsOneWidget);

      // Safety Notice Note
      expect(
        find.text('Keep your wristband on during your shift for accurate fatigue and stress tracking.'),
        findsOneWidget,
      );
    });

    testWidgets('Renders Connected visual state with pulse disc and disconnect button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      unawaited(provider.connect());
      await tester.pump(const Duration(milliseconds: 700));

      // Connected badge
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Connected to HealthNest Band A12'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Device specs
      expect(find.textContaining('Battery'), findsOneWidget);
      expect(find.textContaining('Strong Signal'), findsOneWidget);

      // Disconnect Button
      expect(find.text('Disconnect band'), findsOneWidget);
      expect(find.byIcon(Icons.link_off_rounded), findsOneWidget);

      // Tap disconnect once -> prompt confirmation
      await tester.ensureVisible(find.text('Disconnect band'));
      await tester.tap(find.text('Disconnect band'));
      await tester.pump();
      expect(find.text('Tap again to confirm disconnect'), findsOneWidget);

      // Tap second time -> disconnects
      await tester.ensureVisible(find.text('Tap again to confirm disconnect'));
      await tester.tap(find.text('Tap again to confirm disconnect'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(provider.isDisconnected, isTrue);

      await mockSource.disconnect();
    });

    testWidgets('Renders Reconnecting state with spinner and amber theme',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      mockSource.simulateDisconnectAndReconnect(
        disconnectDuration: Duration.zero,
        reconnectDuration: const Duration(milliseconds: 100),
      );
      await tester.pump(const Duration(milliseconds: 20));

      // Reconnecting text & progress indicator
      expect(find.text('Reconnecting...'), findsOneWidget);
      expect(find.text('Reconnecting to HealthNest Band A12...'), findsOneWidget);
      expect(find.textContaining('Trying again automatically'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Advance clock past the reconnect timer and cancel stream ticker
      await tester.pump(const Duration(milliseconds: 200));
      await mockSource.disconnect();
    });

    testWidgets('Renders Failure Alert Card when error occurs (FR-3.9)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await provider.simulateDeviceNotFound();

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Error alert banner
      expect(find.text('Connection Issue'), findsOneWidget);
      expect(find.textContaining('HealthNest Band not found'), findsOneWidget);
      expect(find.text('Retry Now'), findsOneWidget);

      // Retry button taps retry
      await tester.ensureVisible(find.text('Retry Now'));
      await tester.tap(find.text('Retry Now'));
      await tester.pump();
      // Tapping retry clears previous message and attempts connect
      expect(find.text('Connection Issue'), findsNothing);

      // Flush connect() delay to prevent pending timer assertion
      await tester.pump(const Duration(milliseconds: 700));
      await mockSource.disconnect();
    });
  });
}
