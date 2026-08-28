import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/pages/onboarding_page.dart';
import '../pages/auth_page.dart';
import '../pages/update_password_page.dart';
import '../services/auth_service.dart';

/// Listens to onboarding, auth state changes, and Supabase deep link events (password recovery / email confirmation)
/// and conditionally renders the onboarding flow, main app shell, authentication screen, or password update screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isPasswordRecovery = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = AuthService().authStateChanges.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          setState(() {
            _isPasswordRecovery = true;
          });
        }
      } else if (state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.userUpdated) {
        if (mounted && _isPasswordRecovery) {
          setState(() {
            _isPasswordRecovery = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If deep link opened password recovery flow, show UpdatePasswordPage
    if (_isPasswordRecovery) {
      return const UpdatePasswordPage();
    }

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
