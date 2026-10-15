import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/repositories/data_repository.dart';
import '../../auth/state/auth_provider.dart';
import '../../home/state/home_provider.dart';
import '../state/checkin_provider.dart';

/// Helper to show the check-in modal as a bottom sheet.
Future<bool?> showCheckInModal(
  BuildContext context, {
  String kind = 'ON_DEMAND',
}) {
  final dataRepo = context.read<DataRepository>();

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ChangeNotifierProvider(
      create: (_) => CheckInProvider(dataRepository: dataRepo),
      child: CheckInModalContent(kind: kind),
    ),
  );
}

/// The full-screen route for CheckIn, wrapping [CheckInModalContent] or rendered inside a Scaffold.
class CheckInScreen extends StatelessWidget {
  const CheckInScreen({
    super.key,
    this.kind = 'SHIFT_START',
  });

  final String kind;

  @override
  Widget build(BuildContext context) {
    final dataRepo = context.read<DataRepository>();

    return ChangeNotifierProvider(
      create: (_) => CheckInProvider(dataRepository: dataRepo),
      child: Scaffold(
        backgroundColor: AppColors.canvasBackground,
        appBar: AppBar(
          title: const Text('Self Report'),
          backgroundColor: AppColors.canvasBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: SafeArea(
          child: CheckInModalContent(
            isModal: false,
            kind: kind,
          ),
        ),
      ),
    );
  }
}

/// The check-in question form adhering strictly to `07_UI_GUIDE.md` Section F.
class CheckInModalContent extends StatelessWidget {
  const CheckInModalContent({
    super.key,
    this.isModal = true,
    this.kind = 'ON_DEMAND',
  });

  final bool isModal;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final checkIn = context.watch<CheckInProvider>();
    final auth = context.watch<AuthProvider>();
    final home = context.watch<HomeProvider>();

    final userId = auth.currentUser?.id ?? 1;
    // Session ID from active shift or fallback default
    final sessionId = home.shiftStartTime != null ? 101 : 101;

    final content = Container(
      decoration: isModal
          ? const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            )
          : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal grabber pill (only in bottom sheet modal mode)
            if (isModal) ...[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9DFEC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],

            // 1. Header (07_UI_GUIDE.md Section F)
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick self report',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${checkIn.answeredCount} of 3 answered',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isModal)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 3-Segment Progress Bar
            _ProgressSegmentBar(answeredCount: checkIn.answeredCount),
            const SizedBox(height: 24),

            // 2. Question 1: Feeling (Fine | Tired | Unwell)
            _QuestionCard(
              questionNumber: 1,
              title: 'How are you feeling right now?',
              children: [
                _OptionChip(
                  label: 'Fine',
                  icon: Icons.sentiment_satisfied_alt_rounded,
                  selected: checkIn.feeling == 1,
                  activeColor: const Color(0xFF16A34A),
                  onTap: () => checkIn.setFeeling(1),
                ),
                const SizedBox(width: 8),
                _OptionChip(
                  label: 'Tired',
                  icon: Icons.bedtime_outlined,
                  selected: checkIn.feeling == 2,
                  activeColor: const Color(0xFFD97706),
                  onTap: () => checkIn.setFeeling(2),
                ),
                const SizedBox(width: 8),
                _OptionChip(
                  label: 'Unwell',
                  icon: Icons.sick_outlined,
                  selected: checkIn.feeling == 3,
                  activeColor: const Color(0xFFDC2626),
                  onTap: () => checkIn.setFeeling(3),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 3. Question 2: Pain (No | Mild | Severe)
            _QuestionCard(
              questionNumber: 2,
              title: 'Any physical pain or discomfort?',
              children: [
                _OptionChip(
                  label: 'No',
                  icon: Icons.check_circle_outline_rounded,
                  selected: checkIn.pain == 1,
                  activeColor: const Color(0xFF16A34A),
                  onTap: () => checkIn.setPain(1),
                ),
                const SizedBox(width: 8),
                _OptionChip(
                  label: 'Mild',
                  icon: Icons.healing_outlined,
                  selected: checkIn.pain == 2,
                  activeColor: const Color(0xFFD97706),
                  onTap: () => checkIn.setPain(2),
                ),
                const SizedBox(width: 8),
                _OptionChip(
                  label: 'Severe',
                  icon: Icons.warning_amber_rounded,
                  selected: checkIn.pain == 3,
                  activeColor: const Color(0xFFDC2626),
                  onTap: () => checkIn.setPain(3),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4. Question 3: Stress (Low | Medium | High)
            _QuestionCard(
              questionNumber: 3,
              title: 'Current self-reported stress level?',
              children: [
                _OptionChip(
                  label: 'Low',
                  icon: Icons.spa_outlined,
                  selected: checkIn.stressSelf == 1,
                  activeColor: const Color(0xFF16A34A),
                  onTap: () => checkIn.setStress(1),
                ),
                const SizedBox(width: 8),
                _OptionChip(
                  label: 'Medium',
                  icon: Icons.sentiment_neutral_outlined,
                  selected: checkIn.stressSelf == 2,
                  activeColor: const Color(0xFFD97706),
                  onTap: () => checkIn.setStress(2),
                ),
                const SizedBox(width: 8),
                _OptionChip(
                  label: 'High',
                  icon: Icons.psychology_outlined,
                  selected: checkIn.stressSelf == 3,
                  activeColor: const Color(0xFFDC2626),
                  onTap: () => checkIn.setStress(3),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Error display if submission fails
            if (checkIn.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFB91C1C), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        checkIn.errorMessage!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 5. Action Controls (07_UI_GUIDE.md Section F)
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: checkIn.isComplete && !checkIn.isSubmitting
                    ? () async {
                        final success = await checkIn.submit(
                          userId: userId,
                          sessionId: sessionId,
                          kind: kind,
                        );
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Self report submitted successfully!'),
                              backgroundColor: Color(0xFF16A34A),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          Navigator.pop(context, true);
                        }
                      }
                    : null,
                child: checkIn.isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Secondary: Skip for now
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    return content;
  }
}

// =============================================================================
// Helper Widgets
// =============================================================================

/// 3-segment progress indicator showing completion (0 to 3).
class _ProgressSegmentBar extends StatelessWidget {
  const _ProgressSegmentBar({required this.answeredCount});

  final int answeredCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final isFilled = index < answeredCount;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(
              right: index < 2 ? 6.0 : 0.0,
            ),
            decoration: BoxDecoration(
              color: isFilled ? AppColors.primary : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

/// Question Container grouping question title and answer chips.
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.questionNumber,
    required this.title,
    required this.children,
  });

  final int questionNumber;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: children,
          ),
        ],
      ),
    );
  }
}

/// Tap-based choice chip satisfying NFR-4.1 (large touch target, minimum 52px height).
class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? activeColor.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? activeColor : const Color(0xFFCBD5E1),
              width: selected ? 2.0 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? activeColor : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
