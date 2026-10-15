import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/data_repository.dart';
import 'data/repositories/mock_auth_repository.dart';
import 'data/repositories/mock_data_repository.dart';
import 'data/sources/mock_wearable_source.dart';
import 'data/sources/wearable_source.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/state/auth_provider.dart';
import 'features/checkin/presentation/checkin_screen.dart';
import 'features/connection/presentation/band_screen.dart';
import 'features/connection/state/connection_provider.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/home/state/home_provider.dart';
import 'features/settings/presentation/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Choose repository implementation based on USE_MOCKS flag.
  final AuthRepository authRepository =
      AppConfig.useMocks ? MockAuthRepository() : MockAuthRepository(); // Real impl in T-11
  final WearableSource wearableSource =
      AppConfig.useMocks ? MockWearableSource() : MockWearableSource(); // Real impl in T-10
  final DataRepository dataRepository =
      AppConfig.useMocks ? MockDataRepository() : MockDataRepository(); // Real impl in T-11

  runApp(HealthNestApp(
    authRepository: authRepository,
    wearableSource: wearableSource,
    dataRepository: dataRepository,
  ));
}

class HealthNestApp extends StatelessWidget {
  HealthNestApp({
    super.key,
    required this.authRepository,
    WearableSource? wearableSource,
    DataRepository? dataRepository,
  })  : wearableSource = wearableSource ?? MockWearableSource(),
        dataRepository = dataRepository ?? MockDataRepository();

  final AuthRepository authRepository;
  final WearableSource wearableSource;
  final DataRepository dataRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DataRepository>.value(value: dataRepository),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepository: authRepository)
            ..tryRestoreSession(),
        ),
        ChangeNotifierProvider<HomeProvider>(
          create: (context) => HomeProvider(
            wearableSource: wearableSource,
            dataRepository: dataRepository,
            userId: context.read<AuthProvider>().currentUser?.id ?? 1,
          ),
        ),
        ChangeNotifierProvider<ConnectionProvider>(
          create: (_) => ConnectionProvider(
            wearableSource: wearableSource,
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppConstants.routeLogin,
        routes: {
          AppConstants.routeLogin: (context) => const LoginScreen(),
          AppConstants.routeForgotPassword: (context) =>
              const ForgotPasswordScreen(),
          AppConstants.routeHome: (context) => const _AuthGate(
                child: HomeScreen(),
              ),
          AppConstants.routeBand: (context) => const _AuthGate(
                child: BandScreen(),
              ),
          AppConstants.routeCheckIn: (context) => const _AuthGate(
                child: CheckInScreen(),
              ),
          AppConstants.routeHistory: (context) => const _AuthGate(
                child: HistoryScreen(),
              ),
          AppConstants.routeSettings: (context) => const _AuthGate(
                child: SettingsScreen(),
              ),
        },
      ),
    );
  }
}

/// Wrapper widget that guards routes behind authentication.
///
/// If the user is not authenticated, they are redirected to the login screen.
/// This satisfies the T-03 requirement: "unauthenticated user cannot reach home screen".
class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthProvider>().status;

    if (authStatus == AuthStatus.unauthenticated) {
      // Schedule navigation after the current build frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppConstants.routeLogin,
            (route) => false,
          );
        }
      });
      // Return empty scaffold while redirecting.
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authStatus == AuthStatus.unknown) {
      // Still checking session — show a loading indicator.
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return child;
  }
}
