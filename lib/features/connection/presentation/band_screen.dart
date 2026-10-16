import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../data/sources/wearable_source.dart';
import '../state/connection_provider.dart';

/// The Band Connection Screen (FR-3.6, FR-3.7, FR-3.9, NFR-2.1, NFR-4.4).
///
/// Implements the visual stage card from ui_design/band_connected/
/// with support for Connected, Reconnecting, and Disconnected states,
/// failure alerts, auto-reconnect cycle, and disconnect actions.
class BandScreen extends StatefulWidget {
  const BandScreen({super.key, this.animatePulse = true});

  final bool animatePulse;

  @override
  State<BandScreen> createState() => _BandScreenState();
}

class _BandScreenState extends State<BandScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _confirmingDisconnect = false;
  Timer? _confirmResetTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.animatePulse) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 0.5;
    }

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _confirmResetTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleDisconnectTap(ConnectionProvider provider) {
    if (!_confirmingDisconnect) {
      setState(() {
        _confirmingDisconnect = true;
      });
      _confirmResetTimer?.cancel();
      _confirmResetTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _confirmingDisconnect = false;
          });
        }
      });
    } else {
      _confirmResetTimer?.cancel();
      setState(() {
        _confirmingDisconnect = false;
      });
      provider.disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: _BandAppBar(connection: connection),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Subheader
              const _BandSubheader(),
              const SizedBox(height: 16),

              // Failure Notification Alert (FR-3.9)
              if (connection.hasFailure) ...[
                _FailureAlertCard(
                  message: connection.failureMessage!,
                  onRetry: () => connection.retryConnection(),
                  onDismiss: () => connection.clearFailure(),
                ),
                const SizedBox(height: 16),
              ],

              // Hero Visual Stage Card (Pulse Rings + Watch + Badge)
              _DeviceStageCard(
                connection: connection,
                pulseAnimation: _pulseAnimation,
              ),
              const SizedBox(height: 20),

              // Primary Action Button (Disconnect / Connect / Reconnecting)
              _ActionButton(
                connection: connection,
                confirmingDisconnect: _confirmingDisconnect,
                onDisconnectTap: () => _handleDisconnectTap(connection),
                onConnectTap: () {
                  setState(() => _confirmingDisconnect = false);
                  connection.connect();
                },
                onCancelTap: () {
                  connection.disconnect();
                },
              ),
              const SizedBox(height: 16),

              // Safety Notice Note
              const _SafetyNoticeCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: 1,
        onTap: (index) => _handleNavigation(context, index),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == 1) return; // Already on Band screen
    if (index == 0) {
      Navigator.pushReplacementNamed(context, AppConstants.routeHome);
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

class _BandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _BandAppBar({required this.connection});

  final ConnectionProvider connection;

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
          Text(
            'HealthNest',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(width: 6),
          Text(
            '| Band',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        // Scenario Switcher for quick manual verification & grading
        PopupMenuButton<String>(
          icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
          tooltip: 'Simulate Connection Scenarios',
          onSelected: (action) {
            if (action == 'connect') {
              connection.connect();
            } else if (action == 'auto_reconnect') {
              connection.simulateAutoReconnect();
            } else if (action == 'disconnect') {
              connection.disconnect();
            } else if (action == 'not_found') {
              connection.simulateDeviceNotFound();
            } else if (action == 'fail_connect') {
              connection.simulateConnectionFailure();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'connect',
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF15803D), size: 18),
                  SizedBox(width: 8),
                  Text('State: Connected (Green)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'auto_reconnect',
              child: Row(
                children: [
                  Icon(Icons.sync_rounded, color: Color(0xFFB45309), size: 18),
                  SizedBox(width: 8),
                  Text('Simulate Auto-Reconnect Cycle (5s)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'disconnect',
              child: Row(
                children: [
                  Icon(Icons.link_off_rounded, color: Color(0xFFB91C1C), size: 18),
                  SizedBox(width: 8),
                  Text('State: Disconnected (Red)'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'not_found',
              child: Row(
                children: [
                  Icon(Icons.search_off_rounded, color: Color(0xFFB91C1C), size: 18),
                  SizedBox(width: 8),
                  Text('Error: Wristband Not Found (FR-3.9)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'fail_connect',
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Color(0xFFB91C1C), size: 18),
                  SizedBox(width: 8),
                  Text('Error: Connection Failed (FR-3.9)'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

// =============================================================================
// Page Subheader
// =============================================================================

class _BandSubheader extends StatelessWidget {
  const _BandSubheader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Band Connection',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
            height: 1.2,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Manage your HealthNest device',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Failure Alert Card (FR-3.9)
// =============================================================================

class _FailureAlertCard extends StatelessWidget {
  const _FailureAlertCard({
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFB91C1C),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Issue',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB91C1C),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFB91C1C)),
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Retry Now',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Hero Device Visual Stage Card (Pulse Rings + Watch + Badge)
// =============================================================================

class _DeviceStageCard extends StatelessWidget {
  const _DeviceStageCard({
    required this.connection,
    required this.pulseAnimation,
  });

  final ConnectionProvider connection;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9DFEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pulse Ring Stage
          _buildPulseStage(),
          const SizedBox(height: 20),

          // Status Badge Pill (Colour + Icon + Text - NFR-4.4)
          _buildStatusBadge(),
          const SizedBox(height: 12),

          // Device Title
          Text(
            connection.stateTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),

          // Subtext / Metadata
          const SizedBox(height: 8),
          _buildDeviceMetadata(),
        ],
      ),
    );
  }

  Widget _buildPulseStage() {
    final state = connection.connectionState;

    Color ringOuterColor;
    Color ringMidColor;
    Color ringInnerColor;
    Color iconColor;

    switch (state) {
      case WearableConnectionState.connected:
        ringOuterColor = AppColors.primarySoft.withValues(alpha: 0.7);
        ringMidColor = AppColors.primarySoft.withValues(alpha: 0.4);
        ringInnerColor = const Color(0xFFE4EAF8);
        iconColor = AppColors.primary;
        break;
      case WearableConnectionState.reconnecting:
      case WearableConnectionState.connecting:
        ringOuterColor = const Color(0xFFFEF3C7).withValues(alpha: 0.7);
        ringMidColor = const Color(0xFFFEF3C7).withValues(alpha: 0.4);
        ringInnerColor = const Color(0xFFFDF6B2);
        iconColor = const Color(0xFFB45309);
        break;
      case WearableConnectionState.disconnected:
        ringOuterColor = const Color(0xFFFEE2E2).withValues(alpha: 0.5);
        ringMidColor = const Color(0xFFFEE2E2).withValues(alpha: 0.3);
        ringInnerColor = const Color(0xFFF1F5F9);
        iconColor = const Color(0xFF94A3B8);
        break;
    }

    final isAnimated = state == WearableConnectionState.connected ||
        state == WearableConnectionState.reconnecting ||
        state == WearableConnectionState.connecting;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final scale = isAnimated ? 1.0 + (pulseAnimation.value * 0.08) : 1.0;
        final outerOpacity =
            isAnimated ? (0.5 + pulseAnimation.value * 0.4) : 0.4;

        return SizedBox(
          width: 176,
          height: 176,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Radiating Ring
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ringOuterColor.withValues(alpha: outerOpacity),
                  ),
                ),
              ),

              // Middle Soft Ring
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ringMidColor,
                ),
              ),

              // Inner Stage Ring
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ringInnerColor,
                  border: Border.all(
                    color: const Color(0xFFCFD7EB),
                    width: 1,
                  ),
                ),
              ),

              // Central Device Disc
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFD9DFEC),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x141C27D6),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.watch_rounded,
                  size: 52,
                  color: iconColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge() {
    final state = connection.connectionState;

    Color bg;
    Color border;
    Color textColor;
    IconData icon;
    Widget leadingWidget;

    switch (state) {
      case WearableConnectionState.connected:
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFFBBF7D0);
        textColor = const Color(0xFF15803D);
        icon = Icons.check_circle_rounded;
        leadingWidget = Icon(icon, size: 18, color: textColor);
        break;
      case WearableConnectionState.reconnecting:
      case WearableConnectionState.connecting:
        bg = const Color(0xFFFEF3C7);
        border = const Color(0xFFFDE68A);
        textColor = const Color(0xFFB45309);
        leadingWidget = SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: textColor,
          ),
        );
        break;
      case WearableConnectionState.disconnected:
        bg = const Color(0xFFFEE2E2);
        border = const Color(0xFFFECACA);
        textColor = const Color(0xFFB91C1C);
        icon = Icons.cancel_rounded;
        leadingWidget = Icon(icon, size: 18, color: textColor);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leadingWidget,
          const SizedBox(width: 6),
          Text(
            connection.badgeLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceMetadata() {
    final state = connection.connectionState;

    if (state == WearableConnectionState.connected) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.battery_5_bar_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            '${connection.batteryLevel}% Battery',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 14),
          const Text('•', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 14),
          const Icon(
            Icons.bluetooth_connected_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          const Text(
            'Strong Signal',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (state == WearableConnectionState.reconnecting) {
      return const Text(
        'Trying again automatically every 5 seconds',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFFB45309),
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      return const Text(
        'Wristband is disconnected from this terminal',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      );
    }
  }
}

// =============================================================================
// Action Button (Disconnect / Pair / Reconnecting)
// =============================================================================

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.connection,
    required this.confirmingDisconnect,
    required this.onDisconnectTap,
    required this.onConnectTap,
    required this.onCancelTap,
  });

  final ConnectionProvider connection;
  final bool confirmingDisconnect;
  final VoidCallback onDisconnectTap;
  final VoidCallback onConnectTap;
  final VoidCallback onCancelTap;

  @override
  Widget build(BuildContext context) {
    final state = connection.connectionState;

    if (state == WearableConnectionState.connected) {
      // Disconnect Button (56px touch target - NFR-4.1)
      return SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: onDisconnectTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: confirmingDisconnect
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFFEF2F2),
            foregroundColor: const Color(0xFFB91C1C),
            side: BorderSide(
              color: confirmingDisconnect
                  ? const Color(0xFFB91C1C)
                  : const Color(0xFFFECACA),
              width: confirmingDisconnect ? 1.5 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                confirmingDisconnect
                    ? Icons.warning_rounded
                    : Icons.link_off_rounded,
                size: 22,
                color: const Color(0xFFB91C1C),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  confirmingDisconnect
                      ? 'Tap again to confirm disconnect'
                      : 'Disconnect band',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (state == WearableConnectionState.reconnecting ||
        state == WearableConnectionState.connecting) {
      // Reconnecting State Action
      return SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: onCancelTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFFEF3C7),
            foregroundColor: const Color(0xFFB45309),
            side: const BorderSide(color: Color(0xFFFDE68A)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFB45309),
                ),
              ),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Reconnecting... Tap to cancel',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Disconnected State Action -> Pair / Connect Band (56px)
      return SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: onConnectTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.link_rounded, size: 22),
              SizedBox(width: 8),
              Text(
                'Pair Band',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

// =============================================================================
// Safety Notice Card
// =============================================================================

class _SafetyNoticeCard extends StatelessWidget {
  const _SafetyNoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keep your wristband on during your shift for accurate fatigue and stress tracking.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Bottom Navigation Bar
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
