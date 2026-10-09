import 'package:flutter/material.dart';
import 'core/config.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/checkin/presentation/checkin_screen.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HealthNestApp());
}

class HealthNestApp extends StatelessWidget {
  const HealthNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppConstants.routeLogin,
      routes: {
        AppConstants.routeLogin: (context) => const LoginScreen(),
        AppConstants.routeHome: (context) => const HomeScreen(),
        AppConstants.routeCheckIn: (context) => const CheckInScreen(),
        AppConstants.routeHistory: (context) => const HistoryScreen(),
        AppConstants.routeSettings: (context) => const SettingsScreen(),
      },
    );
  }
}
