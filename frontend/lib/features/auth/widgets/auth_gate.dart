import 'package:flutter/material.dart';
import '../../../app.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/pages/onboarding_page.dart';
import '../pages/auth_page.dart';
import '../services/auth_service.dart';

/// Listens to onboarding and auth state changes and conditionally renders
/// the onboarding flow, main app shell, or authentication screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, _) {
        // While checking initial persisted settings
        if (!SettingsService().isInitialized) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        // If first-time user, present the onboarding walkthrough
        if (!SettingsService().hasCompletedOnboarding) {
          return const OnboardingPage();
        }

        // Once onboarding is completed, check authentication state
        return StreamBuilder<bool>(
          stream: AuthService().isLoggedInStream,
          initialData: AuthService().isLoggedIn,
          builder: (context, snapshot) {
            // While checking initial persisted session state
            if (!AuthService().isSessionLoaded &&
                snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              );
            }

            // If user is authenticated (Cloud user or Local Guest), show main app
            if (AuthService().isLoggedIn) {
              return const AppShell();
            }

            // Otherwise show the auth screen
            return const AuthPage();
          },
        );
      },
    );
  }
}
