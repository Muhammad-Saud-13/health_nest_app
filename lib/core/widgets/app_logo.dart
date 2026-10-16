import 'package:flutter/material.dart';

import '../theme.dart';

/// Reusable HealthNest App Logo component.
/// Displays the official app icon with rounded corners and an automatic
/// graceful fallback to the branded icon if the image asset is loading or unavailable.
class HealthNestLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool hasShadow;

  const HealthNestLogo({
    super.key,
    this.size = 34,
    this.borderRadius = 8,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.asset(
      'assets/HealthNest_App_Icon.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Graceful fallback to prevent red error box / overflow when running before a fresh build
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: size * 0.55,
          ),
        );
      },
    );

    Widget clipped = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: imageWidget,
      ),
    );

    if (hasShadow) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: clipped,
      );
    }

    return clipped;
  }
}
