import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app.dart';
import '../../../core/theme/app_colors.dart';
import '../pages/auth_page.dart';
import '../services/auth_service.dart';

/// Listens to auth state changes and conditionally renders
/// either the main app shell or the authentication screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // While checking initial auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        // If user is authenticated, show the main app
        if (snapshot.hasData && snapshot.data != null) {
          return const AppShell();
        }

        // Otherwise show the auth screen
        return const AuthPage();
      },
    );
  }
}
