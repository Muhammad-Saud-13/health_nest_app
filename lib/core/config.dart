/// Core configuration constants for HealthNest.
class AppConfig {
  /// Toggle to switch between Mock implementation and Real implementations (BLE / REST API).
  static const bool useMocks = true;

  /// Default stress alert threshold (85% probability).
  static const double defaultStressThreshold = 0.85;

  /// Default low SpO2 threshold (95%).
  static const double lowSpo2Threshold = 95.0;

  /// App Title
  static const String appTitle = 'HealthNest';

  /// Disclaimer required by NFR-4.1 / FR-7.5
  static const String medicalDisclaimer =
      'HealthNest is a wellness monitoring tool and does not provide medical diagnosis or treatment.';
}
