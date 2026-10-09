import 'package:flutter/material.dart';
import '../../../core/config.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppConstants.routeSettings),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              color: AppColors.surfaceWhite,
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 48, color: AppColors.stateCalm),
                    SizedBox(height: 8),
                    Text(
                      'Status: Calm',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.stateCalm,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Live heart rate: 72 BPM | SpO2: 98.5%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppConstants.routeCheckIn),
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Start Shift Check-in'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppConstants.routeHistory),
              icon: const Icon(Icons.history_rounded),
              label: const Text('View 24h History'),
            ),
            const Spacer(),
            const Text(
              AppConfig.medicalDisclaimer,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
