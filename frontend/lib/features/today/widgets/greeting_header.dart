import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/services/auth_service.dart';
import '../../reflection/services/reflection_service.dart';

/// Top section of the Today page:
///   "Good evening, User"  🔥 X Day Streak + 3-Line Menu Drawer Button
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
    final longest = ReflectionService().longestStreakCount;
    final title =
        streak == 1 ? '1 Day Journal Streak' : '$streak Days Journal Streak';
    final description = streak > 0
        ? 'You\'ve consistently journaled! Keep up your daily habit.'
        : 'Write an entry today to start your journal streak.';

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
            const Text('🔥', style: TextStyle(fontSize: 40)),
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
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🔥 $streak',
                          style:
                              AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Current Streak',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '⭐ $longest',
                          style:
                              AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Longest Streak',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final name = auth.userName;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting row with 3-Line Menu Button ───────────────
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
                              const Text('🔥', style: TextStyle(fontSize: 13)),
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
            // 3-Line Hamburger Menu button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                AppShell.openDrawer();
              },
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.divider,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.menu_rounded,
                    size: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // ── Subtitle ──────────────────────────────────────────
        Text(
          'Your private journal is ready whenever you are.',
          style: AppTextStyles.subtitle,
        ),
      ],
    );
      },
    );
  }
}

