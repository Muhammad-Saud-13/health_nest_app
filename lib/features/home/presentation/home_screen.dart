import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../data/models/alert.dart';
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
                    _ShiftStatusLine(
                      shiftText: home.shiftStartTimeFormatted,
                      onCheckInTap: () => Navigator.pushNamed(
                        context,
                        AppConstants.routeCheckIn,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Shift Self Report Prompt Banner (FR-8.1 - Once per shift)
                    if (!home.shiftCheckInDone) ...[
                      _ShiftCheckInPromptCard(
                        onCheckIn: () => Navigator.pushNamed(
                          context,
                          AppConstants.routeCheckIn,
                        ),
                        onDismiss: () => home.markShiftCheckInDone(),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 3. Primary State Card (Calm or Stressed)
                    _PrimaryStateCard(home: home),
                    const SizedBox(height: 14),

                    // 4. Sustained Stress Alert Card (FR-6.2, FR-9.1, D-24)
                    if (!home.tipDismissed) ...[
                      if (home.hasSustainedStressAlert) ...[
                        _SustainedStressAlertCard(
                          alert: home.sustainedStressAlert!,
                          onAcknowledge: () => home.acknowledgeAlert(
                            home.sustainedStressAlert!.id,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ] else if (home.isStressed) ...[
                        _PassiveTipCard(onDismiss: () => home.dismissTip()),
                        const SizedBox(height: 14),
                      ],
                    ],

                    // 5. Low SpO2 Alert Card (Separate from ML State - FR-6.3)
                    if (!home.spo2AlertDismissed) ...[
                      if (home.hasLowSpo2Alert) ...[
                        _LowSpo2AlertCard(
                          alert: home.lowSpo2Alert!,
                          onAcknowledge: () =>
                              home.acknowledgeAlert(home.lowSpo2Alert!.id),
                        ),
                        const SizedBox(height: 14),
                      ] else if (home.isSpo2Low) ...[
                        const _LowSpo2Card(),
                        const SizedBox(height: 14),
                      ],
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
      Navigator.pushNamed(context, AppConstants.routeBand);
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
      title: const Row(
        children: [
          HealthNestLogo(size: 34, borderRadius: 8),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              AppConfig.appTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // Scenario Switcher (for demo and manual verification)
        PopupMenuButton<MockScenario>(
          icon: const Icon(
            Icons.tune_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          tooltip: 'Simulate Scenario',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onSelected: (scenario) => home.simulateScenario(scenario),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: MockScenario.calm,
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.stateCalm,
                    size: 20,
                  ),
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
        const SizedBox(width: 4),
        // Profile Avatar Button (Navigates to Settings)
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () =>
                Navigator.pushNamed(context, AppConstants.routeSettings),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
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
            const Icon(Icons.check_circle, color: Color(0xFF15803D), size: 22),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Wristband Connected',
                style: TextStyle(
                  color: Color(0xFF15803D),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
            Flexible(
              child: Text(
                'Reconnecting to Wristband...',
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
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
            Icon(Icons.link_off_rounded, color: Color(0xFFB91C1C), size: 22),
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
            Icon(Icons.refresh_rounded, color: Color(0xFFB91C1C), size: 20),
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
  const _ShiftStatusLine({required this.shiftText, this.onCheckInTap});

  final String shiftText;
  final VoidCallback? onCheckInTap;

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
            Expanded(
              child: Text(
                shiftText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (onCheckInTap != null)
              InkWell(
                onTap: onCheckInTap,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fact_check_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Self Report',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
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

/// Gentle, dismissible self-report prompt card shown once per shift (FR-8.1).
class _ShiftCheckInPromptCard extends StatelessWidget {
  const _ShiftCheckInPromptCard({
    required this.onCheckIn,
    required this.onDismiss,
  });

  final VoidCallback onCheckIn;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Self report ready',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Takes 30 seconds • 3 quick taps',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF4338CA).withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCheckIn,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Start',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Color(0xFF6B7280),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onDismiss,
          ),
        ],
      ),
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
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
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
                      style: TextStyle(fontSize: 13, color: Color(0xFF7C2D12)),
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
            child: Icon(Icons.air_rounded, color: Color(0xFFB91C1C), size: 20),
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
// 5a. Sustained Stress Alert Card (FR-6.2, FR-9.1, D-24 — Backend-driven)
// =============================================================================

class _SustainedStressAlertCard extends StatelessWidget {
  const _SustainedStressAlertCard({
    required this.alert,
    required this.onAcknowledge,
  });

  final Alert alert;
  final VoidCallback onAcknowledge;

  String _timeSinceAlert() {
    final diff = DateTime.now().difference(alert.createdAt);
    if (diff.inHours >= 1) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AC2410C),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Alert Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Icon Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFC2410C),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sustained Stress Detected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9A3412),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Alert raised ${_timeSinceAlert()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Plain Language Wellness Message (NFR-4.1)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFEDEB0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your body has been showing higher stress signals for a while.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7C2D12),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'This is a wellness observation, not a medical diagnosis.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9A3412),
                    height: 1.3,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Recommendation Tips
          const _RecommendationItem(
            icon: Icons.local_cafe_rounded,
            text: 'Take a short break if safe to do so',
          ),
          const SizedBox(height: 8),
          const _RecommendationItem(
            icon: Icons.water_drop_rounded,
            text: 'Drink some water and hydrate',
          ),
          const SizedBox(height: 8),
          const _RecommendationItem(
            icon: Icons.air_rounded,
            text: 'Take a few slow, deep breaths',
          ),
          const SizedBox(height: 18),

          // Acknowledge Button
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
              onPressed: onAcknowledge,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text(
                'I Understand',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small reusable row for recommendation tips.
class _RecommendationItem extends StatelessWidget {
  const _RecommendationItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEDD5),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF9A3412)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7C2D12),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 5b. Low SpO2 Backend Alert Card (FR-6.3, FR-9.1 — Backend-driven)
// =============================================================================

class _LowSpo2AlertCard extends StatelessWidget {
  const _LowSpo2AlertCard({required this.alert, required this.onAcknowledge});

  final Alert alert;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14B91C1C),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Icon(
                  Icons.air_rounded,
                  color: Color(0xFFB91C1C),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blood Oxygen Low',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB91C1C),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your SpO2 reading has dropped below 95%.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF991B1B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Recommendation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.health_and_safety_rounded,
                  color: Color(0xFFB91C1C),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sit down and rest. Inform your supervisor if you feel lightheaded or unwell.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF991B1B),
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Acknowledge Button
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
              onPressed: onAcknowledge,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text(
                'I Understand',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalsGrid extends StatelessWidget {
  const _VitalsGrid({required this.home});

  final HomeProvider home;

  @override
  Widget build(BuildContext context) {
    final hrValue = home.heartRate > 0
        ? home.heartRate.round().toString()
        : '--';
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
  const _BottomNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFD),
        border: Border(top: BorderSide(color: Color(0xFFD8DFEB), width: 1)),
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
