import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healtnest_app/data/repositories/mock_data_repository.dart';
import 'package:healtnest_app/data/sources/mock_wearable_source.dart';
import 'package:healtnest_app/features/home/presentation/home_screen.dart';
import 'package:healtnest_app/features/home/state/home_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Test narrow and short viewport layout', (tester) async {
    tester.view.physicalSize = const Size(360, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final wearableSource = MockWearableSource();
    final dataRepository = MockDataRepository();
    final provider = HomeProvider(
      wearableSource: wearableSource,
      dataRepository: dataRepository,
      userId: 1,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeProvider>.value(value: provider),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1200));
    provider.dispose();
    wearableSource.dispose();
    await tester.pump();
  });
}
