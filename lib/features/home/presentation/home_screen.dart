import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/sources/mock_wearable_source.dart';
import '../state/home_provider.dart';

/// The primary Home Screen of the HealthNest application.
///
/// Implements FR-7.1, FR-7.2, FR-7.5, FR-6.3, NFR-4.1, NFR-4.2, NFR-4.4.
/// Designed according to docs/ai/07_UI_GUIDE.md and ui_design/home_calm_connected.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: _HomeAppBar(home: home),
      body: home.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Connection Status Banner
                    _ConnectionBanner(home: home),
                    const SizedBox(height: 14),

                    // 2. Shift Status Line
                    _ShiftStatusLine(shiftText: home.shiftStartTimeFormatted),
                    const SizedBox(height: 16),

                    // 3. Primary State Card (Calm or Stressed)
                    _PrimaryStateCard(home: home),
                    const SizedBox(height: 14),

                    // 4. Passive Tip Card (When Stressed - D-24)
                    if (home.isStressed && !home.tipDismissed) ...[
                      _PassiveTipCard(onDismiss: () => home.dismissTip()),
                      const SizedBox(height: 14),
                    ],

                    // 5. Low SpO2 Warning Card (Separate from ML State - FR-6.3)
                    if (home.isSpo2Low) ...[
                      const _LowSpo2Card(),
                      const SizedBox(height: 14),
                    ],

                    // 6. Two Metric Tiles Side-by-Side (Live HR + SpO2)
                    _VitalsGrid(home: home),
                    const SizedBox(height: 24),

                    // 7. Footer Disclaimer
                    const Text(
                      AppConfig.medicalDisclaimer,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: 0,
        onTap: (index) => _handleNavigation(context, index),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == 0) return; // Already on Home
    if (index == 1) {
      // Band Connection route placeholder or settings
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wristband is managed via Bluetooth.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (index == 2) {
      Navigator.pushNamed(context, AppConstants.routeHistory);
    } else if (index == 3) {
      Navigator.pushNamed(context, AppConstants.routeSettings);
    }
  }
}

// =============================================================================
// App Bar
// =============================================================================

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar({required this.home});

  final HomeProvider home;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.canvasBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            AppConfig.appTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        // Scenario Switcher (for demo and manual verification)
        PopupMenuButton<MockScenario>(
          icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
          tooltip: 'Simulate Scenario',
          onSelected: (scenario) => home.simulateScenario(scenario),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: MockScenario.calm,
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.stateCalm, size: 20),
                  SizedBox(width: 8),
                  Text('Scenario: Calm'),
                ],
              ),
            ),
            PopupMenuItem(
              value: MockScenario.stressSpike,
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppColors.stateStressed, size: 20),
                  SizedBox(width: 8),
                  Text('Scenario: Stress Spike'),
                ],
              ),
            ),
            PopupMenuItem(
              value: MockScenario.lowSpo2,
              child: Row(
                children: [
                  Icon(Icons.water_drop, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text('Scenario: Low SpO2 (<95%)'),
                ],
              ),
            ),
            PopupMenuItem(
              value: MockScenario.disconnected,
              child: Row(
                children: [
                  Icon(Icons.link_off, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Text('Scenario: Auto-Reconnect'),
                ],
              ),
            ),
          ],
        ),
        // Profile Avatar Button (Navigates to Settings)
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.pushNamed(context, AppConstants.routeSettings),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 1. Connection Status Banner (FR-3.6, NFR-4.4)
// =============================================================================

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.home});

  final HomeProvider home;

  @override
  Widget build(BuildContext context) {
    if (home.isConnected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF15803D),
              size: 22,
            ),
            const SizedBox(width: 10),
            const Text(
              'Wristband Connected',
              style: TextStyle(
                color: Color(0xFF15803D),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF15803D),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Live',
                    style: TextStyle(
                      color: Color(0xFF15803D),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (home.isReconnecting || home.isConnecting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Color(0xFFB45309),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Reconnecting to Wristband...',
              style: TextStyle(
                color: Color(0xFFB45309),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Disconnected state
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => home.retryConnection(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.link_off_rounded,
              color: Color(0xFFB91C1C),
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Disconnected - Tap to retry',
                style: TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.refresh_rounded,
              color: Color(0xFFB91C1C),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 2. Shift Status Line
// =============================================================================

class _ShiftStatusLine extends StatelessWidget {
  const _ShiftStatusLine({required this.shiftText});

  final String shiftText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              shiftText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 1, color: Color(0xFFD8DFEB)),
      ],
    );
  }
}

// =============================================================================
// 3. Primary State Card (FR-7.1, NFR-4.4 - Colour + Icon + Text)
// =============================================================================

class _PrimaryStateCard extends StatelessWidget {
  const _PrimaryStateCard({required this.home});

  final HomeProvider home;

  @override
  Widget build(BuildContext context) {
    if (home.isStressed) {
      return _buildStressedCard();
    }
    return _buildCalmCard();
  }

  Widget _buildCalmCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9DFEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Calm Circle Badge
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFD1F7DE),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA7E8C1)),
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF15803D),
                size: 46,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Heading (Text + Colour)
          const Text(
            'You are Calm',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          // Direct Reassurance
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Your heart and vitals are steady. Keep doing what you are doing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Zone Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sentiment_satisfied_rounded,
                  color: Color(0xFF15803D),
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Optimal Vitals Zone',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressedCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14C2410C),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Stressed Icon Badge
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDD5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: const Center(
              child: Icon(
                Icons.warning_rounded,
                color: Color(0xFFC2410C),
                size: 46,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Physical Monitor Tag
          const Text(
            'PHYSICAL MONITOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Color(0xFFC2410C),
            ),
          ),
          const SizedBox(height: 4),
          // Heading
          const Text(
            'You are Stressed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC2410C),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          // Plain Language Status Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              'Your wristband notices higher physical stress right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. Passive Tip Card (D-24, FR-9.1 - No haptic alerts)
// =============================================================================

class _PassiveTipCard extends StatelessWidget {
  const _PassiveTipCard({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14C2410C),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFFFEDD5),
                child: Icon(
                  Icons.local_cafe_rounded,
                  color: Color(0xFF9A3412),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stress has been high for a while',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Take a short break and drink some water.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7C2D12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: onDismiss,
              icon: const Icon(Icons.check, size: 20),
              label: const Text(
                'Got it',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. Low SpO2 Warning Card (FR-6.3 - Separate from ML stress)
// =============================================================================

class _LowSpo2Card extends StatelessWidget {
  const _LowSpo2Card();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFFEE2E2),
            child: Icon(
              Icons.air_rounded,
              color: Color(0xFFB91C1C),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blood Oxygen Low (< 95%)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB91C1C),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Sit down and rest if you feel lightheaded. Inform your supervisor if symptoms persist.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF991B1B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 6. Vitals Grid (FR-7.2, FR-7.5 - Live HR + Live SpO2)
// =============================================================================

class _VitalsGrid extends StatelessWidget {
  const _VitalsGrid({required this.home});

  final HomeProvider home;

  @override
  Widget build(BuildContext context) {
    final hrValue = home.heartRate > 0 ? home.heartRate.round().toString() : '--';
    final spo2Value = home.spo2 > 0 ? home.spo2.round().toString() : '--';
    final isHrElevated = home.heartRate > 100;
    final isSpo2Low = home.isSpo2Low;

    return Row(
      children: [
        // Heart Rate Tile
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(minHeight: 144),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD9DFEC)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080F172A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isHrElevated
                            ? const Color(0xFFFFEDD5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isHrElevated
                              ? const Color(0xFFFED7AA)
                              : const Color(0xFFD9DFEC),
                        ),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: isHrElevated
                            ? const Color(0xFFC2410C)
                            : const Color(0xFF475569),
                        size: 22,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isHrElevated
                            ? const Color(0xFFFFEDD5)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isHrElevated
                              ? const Color(0xFFFED7AA)
                              : const Color(0xFFBBF7D0),
                        ),
                      ),
                      child: Text(
                        home.hrStatusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isHrElevated
                              ? const Color(0xFFC2410C)
                              : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Heart Rate',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          hrValue,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'bpm',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Blood Oxygen (SpO2) Tile
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(minHeight: 144),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD9DFEC)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080F172A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSpo2Low
                            ? const Color(0xFFFEE2E2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSpo2Low
                              ? const Color(0xFFFECACA)
                              : const Color(0xFFD9DFEC),
                        ),
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        color: isSpo2Low
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF475569),
                        size: 22,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isSpo2Low
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSpo2Low
                              ? const Color(0xFFFECACA)
                              : const Color(0xFFBBF7D0),
                        ),
                      ),
                      child: Text(
                        home.spo2StatusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSpo2Low
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Blood Oxygen',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          spo2Value,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 7. Bottom Navigation Bar (Home, Band, History, Menu)
// =============================================================================

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFD),
        border: Border(
          top: BorderSide(color: Color(0xFFD8DFEB), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.watch_rounded, 'Band'),
              _buildNavItem(2, Icons.history_rounded, 'History'),
              _buildNavItem(3, Icons.menu_rounded, 'Menu'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = index == currentIndex;
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
