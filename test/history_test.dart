import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:healtnest_app/core/theme.dart';
import 'package:healtnest_app/data/repositories/mock_data_repository.dart';
import 'package:healtnest_app/features/history/presentation/history_screen.dart';
import 'package:healtnest_app/features/history/state/history_provider.dart';

void main() {
  group('HistoryProvider Unit Tests (T-08, FR-7.6)', () {
    late MockDataRepository mockRepo;
    late HistoryProvider provider;

    setUp(() {
      mockRepo = MockDataRepository();
      provider = HistoryProvider(dataRepository: mockRepo, userId: 1);
    });

    test('Initializes with default empty values', () {
      expect(provider.classifications, isEmpty);
      expect(provider.totalRecords, 0);
      expect(provider.calmCount, 0);
      expect(provider.stressedCount, 0);
      expect(provider.calmPercentage, 100);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('loadHistory populates classifications and active session', () async {
      await provider.loadHistory();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.classifications, isNotEmpty);
      expect(provider.totalRecords, greaterThan(0));
      expect(provider.calmCount, greaterThan(0));
      expect(provider.stressedCount, greaterThan(0));
      expect(provider.calmPercentage, inInclusiveRange(0, 100));
      expect(provider.hasActiveShift, isTrue);
      expect(provider.shiftBadgeLabel, contains('Line'));
    });

    test('computes calmPercentage fallback accurately', () {
      final customProvider = HistoryProvider(dataRepository: mockRepo, userId: 1);
      expect(customProvider.calmPercentage, 100);
    });
  });

  group('HistoryScreen Widget Tests (T-08, FR-7.6, 07_UI_GUIDE)', () {
    Widget buildTestApp(HistoryProvider historyProvider) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: ChangeNotifierProvider<HistoryProvider>.value(
          value: historyProvider,
          child: const HistoryScreen(),
        ),
      );
    }

    testWidgets('Renders all required elements: Header, Metric Card, Timeline, and Footer',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockDataRepository();
      final historyProvider = HistoryProvider(dataRepository: mockRepo, userId: 1);

      // Pre-load data inside runAsync to handle Future.delayed in MockDataRepository
      await tester.runAsync(() async {
        await historyProvider.loadHistory();
      });

      await tester.pumpWidget(buildTestApp(historyProvider));
      await tester.pump();

      // 1. App Bar
      expect(find.text('HealthNest'), findsOneWidget);
      expect(find.text('| History'), findsOneWidget);

      // 2. Dynamic Shift Header
      expect(find.text('History'), findsNWidgets(2)); // Header title + Bottom nav label
      expect(find.text('Your wellbeing over the last 24 hours'), findsOneWidget);
      expect(find.text('Auto-synced'), findsOneWidget);
      expect(find.textContaining('Active Shift'), findsOneWidget);

      // 3. Summary Metric Card
      expect(find.textContaining('records'), findsOneWidget);
      expect(find.text("Logged during today's shift"), findsOneWidget);
      expect(find.textContaining('% Calm'), findsOneWidget);

      // 4. Timeline Entries: Calm and Stressed states (FR-7.6)
      expect(find.text('Calm'), findsWidgets);
      expect(find.text('Stressed'), findsWidgets);
      expect(find.textContaining('bpm'), findsWidgets);
      expect(find.text('Shift started'), findsOneWidget);
      expect(find.text('Badge Tap In'), findsOneWidget);

      // 5. Automatic Sync Reassurance Footer
      expect(
        find.text('Entries are recorded automatically by your wristband.'),
        findsOneWidget,
      );

      // 6. Bottom Navigation Bar
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Band'), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);
    });

    testWidgets('Renders empty state when history is empty',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockDataRepository();
      final historyProvider = HistoryProvider(dataRepository: mockRepo, userId: 999);

      // Build widget with 0 records
      await tester.pumpWidget(buildTestApp(historyProvider));
      await tester.pump();

      expect(find.text('No History Yet'), findsOneWidget);
    });
  });
}
