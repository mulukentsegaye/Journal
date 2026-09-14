import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Mindful 3-slide Onboarding flow introducing core features to first-time users.
class OnboardingPage extends StatefulWidget {
  final bool isStandaloneTour;
  const OnboardingPage({super.key, this.isStandaloneTour = false});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<_OnboardingSlideData> _slides = const [
    _OnboardingSlideData(
      badge: 'SIMPLE & DISTRACTION-FREE',
      title: 'Write Freely, Anytime.',
      description:
          'Capture your thoughts with distraction-free journaling, optional mood tagging, and daily streaks.',
      emoji: '📝',
      features: [
        '✨ Freeform Journaling',
        '🎙️ Voice Dictation',
        '🔥 Daily Streaks',
      ],
      glowColor: Color(0xFF2D6A4F),
    ),
    _OnboardingSlideData(
      badge: 'ZERO-KNOWLEDGE PRIVACY',
      title: 'Your Private Space.',
      description:
          'Your thoughts belong strictly to you. Protected by client-side AES-256 encryption, hardware Keystore, and biometric App Lock.',
      emoji: '🔒',
      features: [
        '🛡️ End-to-End Encrypted',
        '👆 Biometric & PIN Lock',
        '📴 100% Offline First',
      ],
      glowColor: Color(0xFF1B4332),
    ),
    _OnboardingSlideData(
      badge: 'BACKUPS & REMINDERS',
      title: 'Track Your Journey.',
      description:
          'Export clean PDF backups of your entries, receive daily reminders, and track your mood trends over time.',
      emoji: '📖',
      features: [
        '📚 Printable PDF Export',
        '🔔 Daily Reminders',
        '📊 Mood Analytics',
      ],
      glowColor: Color(0xFF52B788),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    HapticFeedback.selectionClick();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    HapticFeedback.mediumImpact();
    await SettingsService().completeOnboarding();
    if (mounted) {
      if (widget.isStandaloneTour) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121514) : AppColors.background;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.textSecondary;

    return PopScope(
      canPop: widget.isStandaloneTour,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar (Skip Button) ─────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('🌿', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Daily Reflection',
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _finishOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: textSecondary,
                        textStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(
                          _currentPage == _slides.length - 1 ? 'Done' : 'Skip'),
                    ),
                  ],
                ),
              ),

              // ── Main PageView Slider ──────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),

                          // Floating Animated Hero Visual
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: slide.glowColor.withValues(alpha: 0.12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        slide.glowColor.withValues(alpha: 0.18),
                                    blurRadius: 36,
                                    spreadRadius: 8,
                                  ),
                                ],
                                border: Border.all(
                                  color: slide.glowColor.withValues(alpha: 0.25),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  slide.emoji,
                                  style: const TextStyle(fontSize: 64),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Badge Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              slide.badge,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lora(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.5,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Feature Tag Chips
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: slide.features.map((feat) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E2321)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF2D3632)
                                        : AppColors.divider,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  feat,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const Spacer(flex: 2),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Bottom Navigation Controls ────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
                child: Column(
                  children: [
                    // Page Indicator Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white24
                                    : AppColors.divider),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Primary Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _slides.length - 1
                                  ? 'Begin My Journey 🌿'
                                  : 'Continue',
                              style: AppTextStyles.button.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_currentPage < _slides.length - 1) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  final String badge;
  final String title;
  final String description;
  final String emoji;
  final List<String> features;
  final Color glowColor;

  const _OnboardingSlideData({
    required this.badge,
    required this.title,
    required this.description,
    required this.emoji,
    required this.features,
    required this.glowColor,
  });
}
