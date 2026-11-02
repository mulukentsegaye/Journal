import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Mindful 3-slide Onboarding flow introducing core features with interactive scroll-linked animations.
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
      badge: 'MINDFUL JOURNALING',
      title: 'Write Freely, Speak Freely.',
      description:
          'Capture your thoughts effortlessly with freeform writing, fast voice dictation, and photo moments.',
      emoji: '✍️',
      features: [
        _OnboardingFeature('✍️', 'Freeform'),
        _OnboardingFeature('🎙️', 'Voice'),
        _OnboardingFeature('📸', 'Photos'),
      ],
      glowColor: Color(0xFF2D6A4F),
    ),
    _OnboardingSlideData(
      badge: '100% PRIVATE & SECURE',
      title: 'Your Private Sanctuary.',
      description:
          'Your reflections belong strictly to you. Protected by Biometric & PIN lock, with complete offline storage.',
      emoji: '🔒',
      features: [
        _OnboardingFeature('🛡️', 'Private'),
        _OnboardingFeature('👆', 'App Lock'),
        _OnboardingFeature('📴', 'Offline'),
      ],
      glowColor: Color(0xFF1B4332),
    ),
    _OnboardingSlideData(
      badge: 'CHERISH YOUR JOURNEY',
      title: 'Remember Every Moment.',
      description:
          'Export printable Keepsake PDF books, revisit calendar memories, and build daily writing streaks.',
      emoji: '📖',
      features: [
        _OnboardingFeature('📚', 'PDF Book'),
        _OnboardingFeature('🔥', 'Streaks'),
        _OnboardingFeature('🔔', 'Reminders'),
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
                          'Journal',
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
                    return AnimatedBuilder(
                      animation: Listenable.merge(
                          [_pageController, _pulseAnimation]),
                      builder: (context, _) {
                        double page = _currentPage.toDouble();
                        if (_pageController.hasClients &&
                            _pageController.position.haveDimensions &&
                            _pageController.page != null) {
                          page = _pageController.page!;
                        }

                        // Normalized scroll distance from center for this slide
                        final diff = page - index;
                        final distance = diff.abs().clamp(0.0, 1.0);
                        final progress = (1.0 - distance).clamp(0.0, 1.0);

                        // Smooth interpolation curves
                        final easeProgress =
                            Curves.easeOutCubic.transform(progress);
                        final exitDrop =
                            Curves.easeInQuad.transform(distance);

                        // Hero Icon Motion:
                        // Drops down by up to 52px when sliding away, with slight tilt and scale
                        final iconTranslateY = exitDrop * 52.0;
                        final iconScale =
                            (0.78 + (0.22 * easeProgress)) * _pulseAnimation.value;
                        final iconOpacity =
                            (progress * 1.35 - 0.35).clamp(0.0, 1.0);
                        final iconRotation = (-diff * 0.12).clamp(-0.25, 0.25);

                        // Typography Motion:
                        // Gentle horizontal depth parallax and vertical drift
                        final textParallaxX = -diff * 28.0;
                        final textTranslateY = distance * 18.0;
                        final textOpacity =
                            (progress * 1.25 - 0.25).clamp(0.0, 1.0);

                        // Feature Chips Motion:
                        // Follows the downward glide with slight scale damping
                        final chipsTranslateY = distance * 32.0;
                        final chipsOpacity =
                            (progress * 1.35 - 0.35).clamp(0.0, 1.0);

                        return Center(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Interactive Hero Visual (Icon + Glowing Orb)
                                Transform.translate(
                                  offset: Offset(0, iconTranslateY),
                                  child: Transform.rotate(
                                    angle: iconRotation,
                                    child: Transform.scale(
                                      scale: iconScale,
                                      child: Opacity(
                                        opacity: iconOpacity,
                                        child: Container(
                                          width: 130,
                                          height: 130,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: slide.glowColor
                                                .withValues(alpha: 0.12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: slide.glowColor
                                                    .withValues(alpha: 0.18),
                                                blurRadius: 36,
                                                spreadRadius: 8,
                                              ),
                                            ],
                                            border: Border.all(
                                              color: slide.glowColor
                                                  .withValues(alpha: 0.25),
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              slide.emoji,
                                              style:
                                                  const TextStyle(fontSize: 58),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Badge Pill (with subtle parallax)
                                Transform.translate(
                                  offset: Offset(
                                      textParallaxX * 0.6, textTranslateY),
                                  child: Opacity(
                                    opacity: textOpacity,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.2),
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
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Title & Description (with horizontal parallax and fade)
                                Transform.translate(
                                  offset: Offset(textParallaxX, textTranslateY),
                                  child: Opacity(
                                    opacity: textOpacity,
                                    child: Column(
                                      children: [
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
                                        Text(
                                          slide.description,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            height: 1.5,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),

                                // Feature Tag Chips (interactive downward glide & fade)
                                Transform.translate(
                                  offset: Offset(0, chipsTranslateY),
                                  child: Opacity(
                                    opacity: chipsOpacity,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            for (int i = 0;
                                                i < slide.features.length;
                                                i++) ...[
                                              if (i > 0)
                                                const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 7),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(0xFF1E2321)
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF2D3632)
                                                        : AppColors.divider,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.02),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      slide.features[i].emoji,
                                                      style: const TextStyle(
                                                          fontSize: 13),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      slide.features[i].label,
                                                      style:
                                                          GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: textPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Bottom Navigation Controls ────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
                child: Column(
                  children: [
                    // Interactive Page Indicator Dots (smooth real-time interpolation)
                    AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, _) {
                        double page = _currentPage.toDouble();
                        if (_pageController.hasClients &&
                            _pageController.position.haveDimensions &&
                            _pageController.page != null) {
                          page = _pageController.page!;
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_slides.length, (index) {
                            final dist = (page - index).abs().clamp(0.0, 1.0);
                            final activeWeight = (1.0 - dist).clamp(0.0, 1.0);
                            final width = 8.0 + (20.0 * activeWeight);
                            final dotColor = Color.lerp(
                              isDark ? Colors.white24 : AppColors.divider,
                              AppColors.primary,
                              activeWeight,
                            );

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: width,
                              height: 8,
                              decoration: BoxDecoration(
                                color: dotColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        );
                      },
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

class _OnboardingFeature {
  final String emoji;
  final String label;

  const _OnboardingFeature(this.emoji, this.label);
}

class _OnboardingSlideData {
  final String badge;
  final String title;
  final String description;
  final String emoji;
  final List<_OnboardingFeature> features;
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
