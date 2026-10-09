import 'package:flutter_test/flutter_test.dart';
import 'package:healtnest_app/data/data.dart';

void main() {
  group('MockAuthRepository Tests', () {
    late MockAuthRepository authRepo;

    setUp(() {
      authRepo = MockAuthRepository();
    });

    test('login succeeds with correct credentials', () async {
      final user = await authRepo.login(
        email: 'worker@healthnest.com',
        password: 'password123',
      );
      expect(user, isNotNull);
      expect(user!.email, 'worker@healthnest.com');
      expect(user.role, 'EMPLOYEE');
      expect(await authRepo.isAuthenticated(), isTrue);
    });

    test('login fails with wrong password', () async {
      final user = await authRepo.login(
        email: 'worker@healthnest.com',
        password: 'wrong_password',
      );
      expect(user, isNull);
      expect(await authRepo.isAuthenticated(), isFalse);
    });

    test('logout clears current user', () async {
      await authRepo.login(
        email: 'worker@healthnest.com',
        password: 'password123',
      );
      expect(await authRepo.isAuthenticated(), isTrue);

      await authRepo.logout();
      expect(await authRepo.isAuthenticated(), isFalse);
      expect(await authRepo.getCurrentUser(), isNull);
    });

    test('forgot password validates email format', () async {
      final valid = await authRepo.forgotPassword(email: 'worker@test.com');
      final invalid = await authRepo.forgotPassword(email: 'not-an-email');
      expect(valid, isTrue);
      expect(invalid, isFalse);
    });
  });

  group('MockWearableSource Tests', () {
    late MockWearableSource wearable;

    setUp(() {
      wearable = MockWearableSource();
    });

    tearDown(() {
      wearable.dispose();
    });

    test('connect and stream calm packets', () async {
      expect(wearable.currentState, WearableConnectionState.disconnected);

      final stateFuture = expectLater(
        wearable.connectionStateStream,
        emitsInOrder([
          WearableConnectionState.connecting,
          WearableConnectionState.connected,
        ]),
      );

      await wearable.connect();
      await stateFuture;
      expect(wearable.currentState, WearableConnectionState.connected);

      // Verify packet stream emits valid calm packet
      final packet = await wearable.sensorStream.first;
      expect(packet.spo2, inInclusiveRange(95.0, 100.0));
      expect(packet.localHeartRate, inInclusiveRange(60.0, 85.0));
      expect(packet.ppgRaw, isNotEmpty);
    });

    test('trigger stress spike scenario updates data profile', () async {
      await wearable.connect();
      wearable.triggerStressSpikeScenario();
      expect(wearable.currentScenario, MockScenario.stressSpike);

      final packet = await wearable.sensorStream.first;
      expect(packet.localHeartRate, greaterThanOrEqualTo(100.0));
    });

    test('trigger low SpO2 scenario drops SpO2 below 95%', () async {
      await wearable.connect();
      wearable.triggerLowSpo2Scenario();
      expect(wearable.currentScenario, MockScenario.lowSpo2);

      final packet = await wearable.sensorStream.first;
      expect(packet.spo2, lessThan(95.0));
    });
  });

  group('MockDataRepository Tests', () {
    late MockDataRepository dataRepo;

    setUp(() {
      dataRepo = MockDataRepository();
    });

    test('getActiveShiftSession returns active session', () async {
      final session = await dataRepo.getActiveShiftSession(userId: 1);
      expect(session, isNotNull);
      expect(session!.isActive, isTrue);
      expect(session.startMethod, 'MANUAL');
    });

    test('start and end shift session updates state', () async {
      final session = await dataRepo.startShiftSession(userId: 1);
      expect(session.status, 'ACTIVE');

      final endedSession = await dataRepo.endShiftSession(sessionId: session.id);
      expect(endedSession.status, 'CLOSED');
      expect(endedSession.endedAt, isNotNull);
    });

    test('getRecentClassifications returns 24h history containing Calm & Stressed', () async {
      final history = await dataRepo.getRecentClassifications(userId: 1);
      expect(history, isNotEmpty);
      expect(history.any((c) => c.isCalm), isTrue);
      expect(history.any((c) => c.isStressed), isTrue);
    });

    test('alerts can be fetched and acknowledged', () async {
      final alerts = await dataRepo.getActiveAlerts(userId: 1);
      expect(alerts, isNotEmpty);

      final alertId = alerts.first.id;
      await dataRepo.acknowledgeAlert(alertId: alertId);

      final updatedAlerts = await dataRepo.getActiveAlerts(userId: 1);
      expect(updatedAlerts.any((a) => a.id == alertId), isFalse);
    });

    test('submitCheckIn records self report', () async {
      final checkIn = CheckIn(
        sessionId: 101,
        userId: 1,
        feeling: 1,
        pain: 1,
        stressSelf: 1,
        submittedAt: DateTime.now(),
      );

      await expectLater(dataRepo.submitCheckIn(checkIn), completes);
    });
  });

  group('PacketParser Tests', () {
    test('DefaultPacketParser parses raw byte stream correctly', () {
      final parser = DefaultPacketParser();

      // Mock bytes:
      // Accel X = 500 (0x01F4 -> low: 0xF4, high: 0x01) => 0.5 g
      // Accel Y = 1000 (0x03E8 -> low: 0xE8, high: 0x03) => 1.0 g
      // Accel Z = 0 (low: 0x00, high: 0x00) => 0.0 g
      // SpO2 = 98 (0x62)
      // Temp = 65 => 30.0 + 6.5 = 36.5 C
      // PPG = [10, 20, 30]
      final rawBytes = [0xF4, 0x01, 0xE8, 0x03, 0x00, 0x00, 98, 65, 10, 20, 30];

      final packet = parser.parse(rawBytes);
      expect(packet.accelX, closeTo(0.5, 0.01));
      expect(packet.accelY, closeTo(1.0, 0.01));
      expect(packet.accelZ, closeTo(0.0, 0.01));
      expect(packet.spo2, 98.0);
      expect(packet.temperature, closeTo(36.5, 0.01));
      expect(packet.ppgRaw, [10, 20, 30]);
    });

    test('DefaultPacketParser throws FormatException on truncated bytes', () {
      final parser = DefaultPacketParser();
      expect(() => parser.parse([1, 2, 3]), throwsFormatException);
    });
  });
}
