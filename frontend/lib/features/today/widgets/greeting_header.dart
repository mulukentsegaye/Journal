import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/services/auth_service.dart';
import '../../reflection/services/reflection_service.dart';
import '../../settings/pages/settings_page.dart';

/// Top section of the Today page:
///   "Good evening, User"  🔥 X Day Streak + Profile/SignOut
///   "Welcome back to your quiet space."
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key});

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showStreakSheet(BuildContext context, int streak) {
    final title =
        streak == 1 ? '1 Day of Reflection' : '$streak Days of Reflection';
    final description = streak > 0
        ? 'You\'ve taken time for peace and mindful presence every evening. Keep this gentle rhythm alive.'
        : 'Take a quiet moment tonight to begin your mindful reflection streak.';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(streak > 0 ? '🔥' : '🌱',
                style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.greeting.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23),
                  ),
                ),
                child: Text(streak > 0 ? 'Continue Journey' : 'Start Today'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // User avatar circle
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'U',
                style: AppTextStyles.greeting.copyWith(
                  fontSize: 26,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // User Name & Email
            Text(
              auth.userName,
              style: AppTextStyles.greeting.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'Connected',
              style: AppTextStyles.subtitle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),

            // Cloud Sync Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.calmTagBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_done_rounded,
                    size: 14,
                    color: AppColors.calmTagText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Cloud Sync Active',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.calmTagText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text(
                  'Settings & Preferences',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sign out button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await auth.signOut();
                },
                icon: const Icon(Icons.logout_rounded,
                    size: 18, color: Color(0xFFE02424)),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Color(0xFFE02424),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF8B4B4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final name = auth.userName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Greeting row with Profile Avatar ───────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${_greetingText()}, $name',
                    style: AppTextStyles.greeting,
                  ),
                  // Dynamic Streak badge (interactive, shared state)
                  ListenableBuilder(
                    listenable: ReflectionService(),
                    builder: (context, _) {
                      final streak = ReflectionService().streakCount;
                      final streakText = '$streak Day Streak';
                      final emoji = streak > 0 ? '🔥' : '🌱';

                      return GestureDetector(
                        onTap: () => _showStreakSheet(context, streak),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.streakBadgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                streakText,
                                style: AppTextStyles.badge.copyWith(
                                  color: AppColors.streakBadgeText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Profile icon button
            GestureDetector(
              onTap: () => _showProfileSheet(context),
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // ── Subtitle ──────────────────────────────────────────
        Text(
          'Welcome back to your quiet space.',
          style: AppTextStyles.subtitle,
        ),
      ],
    );
  }
}

