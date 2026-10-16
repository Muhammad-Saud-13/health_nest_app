import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/models/classification.dart';
import '../../auth/state/auth_provider.dart';
import '../state/history_provider.dart';

/// 24-Hour State History Screen.
///
/// Implements FR-7.6: Displays own state history for the last 24 hours.
/// Follows UI Guide §D (history_last_24_hours) and Google Stitch mockups.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final auth = Provider.of<AuthProvider?>(context);
    final user = auth?.currentUser;

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: _HistoryAppBar(
        userInitial: user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
        onProfileTap: () => Navigator.pushNamed(context, AppConstants.routeSettings),
      ),
      body: history.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : history.errorMessage != null
              ? _HistoryErrorView(
                  message: history.errorMessage!,
                  onRetry: () => history.loadHistory(),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => history.refresh(),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Shift Status Banner & Header
                          _HistoryHeader(history: history),
                          const SizedBox(height: 16),

                          // 2. Summary Metric Card
                          _SummaryMetricCard(history: history),
                          const SizedBox(height: 20),

                          // 3. Timeline Flow
                          if (history.totalRecords == 0)
                            const _EmptyHistoryCard()
                          else
                            _TimelineContainer(history: history),
                          const SizedBox(height: 16),

                          // 4. Automatic Sync Reassurance Footer
                          const _AutoSyncFooter(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: 2,
        onTap: (index) => _handleNavigation(context, index),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == 2) return; // Already on History
    if (index == 0) {
      Navigator.pushNamed(context, AppConstants.routeHome);
    } else if (index == 1) {
      Navigator.pushNamed(context, AppConstants.routeBand);
    } else if (index == 3) {
      Navigator.pushNamed(context, AppConstants.routeSettings);
    }
  }
}

// =============================================================================
// App Bar
// =============================================================================

class _HistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HistoryAppBar({
    required this.userInitial,
    required this.onProfileTap,
  });

  final String userInitial;
  final VoidCallback onProfileTap;

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
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'HealthNest',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '| History',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Center(
                child: Text(
                  userInitial,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Header (Dynamic Shift Context + Page Title)
// =============================================================================

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.history});

  final HistoryProvider history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    history.shiftBadgeLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Auto-synced',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'History',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Your wellbeing over the last 24 hours',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Summary Metric Card
// =============================================================================

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({required this.history});

  final HistoryProvider history;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${history.totalRecords} records',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Logged during today's shift",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              '${history.calmPercentage}% Calm',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Timeline Container & Items
// =============================================================================

class _TimelineSpinePainter extends CustomPainter {
  const _TimelineSpinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 2;
    canvas.drawLine(
      const Offset(14, 24),
      Offset(14, size.height - 24),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TimelineContainer extends StatelessWidget {
  const _TimelineContainer({required this.history});

  final HistoryProvider history;

  @override
  Widget build(BuildContext context) {
    final items = history.classifications;
    final activeSession = history.activeSession;

    final totalEntries = items.length + (activeSession != null ? 1 : 0);

    return CustomPaint(
      painter: const _TimelineSpinePainter(),
      child: Column(
        children: List.generate(totalEntries, (index) {
          if (index < items.length) {
            final classification = items[index];
            return _TimelineEntryRow(
              classification: classification,
              index: index,
            );
          } else {
            return _ShiftStartedRow(
              startedAt: activeSession!.startedAt,
            );
          }
        }),
      ),
    );
  }
}

class _TimelineEntryRow extends StatelessWidget {
  const _TimelineEntryRow({
    required this.classification,
    required this.index,
  });

  final Classification classification;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isStressed = classification.isStressed;
    final isCalibrating = classification.isCalibrating;

    // Node icon & colors
    final Color nodeBg = isStressed
        ? AppColors.stateStressedBg
        : isCalibrating
            ? AppColors.stateGettingReadyBg
            : AppColors.stateCalmBg;

    final Color nodeBorder = isStressed
        ? AppColors.stateStressedBorder
        : isCalibrating
            ? AppColors.stateGettingReadyBorder
            : AppColors.stateCalmBorder;

    final Color iconColor = isStressed
        ? AppColors.stateStressed
        : isCalibrating
            ? AppColors.stateGettingReady
            : AppColors.stateCalm;

    final IconData icon = isStressed
        ? Icons.warning_rounded
        : isCalibrating
            ? Icons.schedule_rounded
            : Icons.check_circle_rounded;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left node circle centered on spine line
        Container(
          margin: const EdgeInsets.only(top: 14),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: nodeBg,
            shape: BoxShape.circle,
            border: Border.all(color: nodeBorder, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Right Content Card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Time & Context note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(classification.windowStart),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _getContextNote(classification, index),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Bottom Row: State Badge + HR Metric
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // State Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: nodeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              color: iconColor,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isStressed
                                  ? 'Stressed'
                                  : isCalibrating
                                      ? 'Getting ready'
                                      : 'Calm',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Metric: Heart Rate
                      if (isCalibrating)
                        const Text(
                          'Calibrating',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${classification.hrMean.toStringAsFixed(0)} ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isStressed
                                    ? AppColors.stateStressed
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'bpm',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.normal,
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
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _getContextNote(Classification c, int index) {
    if (index == 0) return 'Just now';
    final diff = DateTime.now().difference(c.windowStart);
    if (c.isStressed) {
      if (c.windowStart.hour >= 11 && c.windowStart.hour <= 14) {
        return 'Afternoon peak';
      }
      return 'High demand';
    }
    if (c.isCalibrating) {
      return 'Warm-up & Brief';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inMinutes}m ago';
  }
}

class _ShiftStartedRow extends StatelessWidget {
  const _ShiftStartedRow({
    required this.startedAt,
  });

  final DateTime startedAt;

  @override
  Widget build(BuildContext context) {
    final hour = startedAt.hour % 12 == 0 ? 12 : startedAt.hour % 12;
    final minute = startedAt.minute.toString().padLeft(2, '0');
    final period = startedAt.hour >= 12 ? 'PM' : 'AM';
    final formattedTime = '${hour.toString().padLeft(2, '0')}:$minute $period';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 14),
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.login_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Text(
                        'Badge Tap In',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Shift started',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Empty & Error States
// =============================================================================

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 48,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 12),
          Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Classification results from your wristband will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryErrorView extends StatelessWidget {
  const _HistoryErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Automatic Sync Reassurance Footer
// =============================================================================

class _AutoSyncFooter extends StatelessWidget {
  const _AutoSyncFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.watch_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Entries are recorded automatically by your wristband.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
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
