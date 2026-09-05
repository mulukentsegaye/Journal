import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/security_service.dart';

/// Full-screen mindful lock screen prompting for Biometric or PIN code.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final _securityService = SecurityService();
  String _enteredPin = '';
  String? _errorMessage;
  bool _isCheckingBiometrics = false;
  Timer? _countdownTimer;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 12)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Auto-prompt biometrics when screen opens if not rate-limited
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_securityService.isRateLimited) {
        _triggerBiometrics();
      } else {
        _startLockoutCountdown();
      }
    });
  }

  void _startLockoutCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_securityService.isRateLimited) {
        timer.cancel();
        setState(() {
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage =
              'Too many failed attempts. Try again in ${_securityService.lockoutSecondsRemaining}s';
        });
      }
    });
  }

  Future<void> _triggerBiometrics() async {
    if (_isCheckingBiometrics || _securityService.isRateLimited) return;
    setState(() => _isCheckingBiometrics = true);
    await _securityService.authenticateWithBiometrics();
    if (mounted) {
      setState(() => _isCheckingBiometrics = false);
    }
  }

  void _onDigitPressed(String digit) {
    if (_securityService.isRateLimited) {
      setState(() {
        _errorMessage =
            'Locked out. Please wait ${_securityService.lockoutSecondsRemaining}s';
      });
      return;
    }

    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();

    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isEmpty || _securityService.isRateLimited) return;
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _verifyPin() async {
    final success = await _securityService.verifyPin(_enteredPin);
    if (!mounted) return;

    if (!success) {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      setState(() {
        if (_securityService.isRateLimited) {
          _errorMessage =
              'Too many failed attempts. Try again in ${_securityService.lockoutSecondsRemaining}s';
          _startLockoutCountdown();
        } else {
          _errorMessage = 'Incorrect PIN code';
        }
        _enteredPin = '';
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF141716) : AppColors.background;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.backspace ||
              key == LogicalKeyboardKey.delete) {
            _onDeletePressed();
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
            _onDigitPressed('0');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
            _onDigitPressed('1');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
            _onDigitPressed('2');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
            _onDigitPressed('3');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
            _onDigitPressed('4');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
            _onDigitPressed('5');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
            _onDigitPressed('6');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
            _onDigitPressed('7');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
            _onDigitPressed('8');
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
            _onDigitPressed('9');
            return KeyEventResult.handled;
          } else if (event.character != null && RegExp(r'^[0-9]$').hasMatch(event.character!)) {
            _onDigitPressed(event.character!);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: PopScope(
        canPop: false, // Prevent back navigation while locked
        child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Mindful Icon & Title
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '🌿',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Daily Reflection',
                  style: GoogleFonts.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your PIN to open your mindful space',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // PIN Indicator Dots with Shake Animation
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final offset = _shakeController.isAnimating
                        ? (_shakeAnimation.value *
                            (_shakeController.value.isNegative ? -1 : 1))
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? AppColors.primary
                              : AppColors.divider.withValues(alpha: 0.6),
                          border: Border.all(
                            color:
                                isFilled ? AppColors.primary : AppColors.divider,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const Spacer(flex: 3),

                // Numeric Keypad
                Column(
                  children: [
                    _buildKeypadRow(['1', '2', '3']),
                    const SizedBox(height: 16),
                    _buildKeypadRow(['4', '5', '6']),
                    const SizedBox(height: 16),
                    _buildKeypadRow(['7', '8', '9']),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Biometrics button
                        _buildActionButton(
                          icon: Icons.fingerprint_rounded,
                          onTap: _triggerBiometrics,
                          tooltip: 'Use Biometrics',
                        ),
                        // 0 Digit
                        _buildDigitButton('0'),
                        // Backspace button
                        _buildActionButton(
                          icon: Icons.backspace_outlined,
                          onTap: _onDeletePressed,
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildDigitButton(d)).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    final isLockedOut = _securityService.isRateLimited;
    return InkWell(
      onTap: isLockedOut ? null : () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isLockedOut
              ? AppColors.cardBackground.withValues(alpha: 0.5)
              : AppColors.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.lora(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: isLockedOut
                  ? AppColors.textHint
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Center(
          child: Icon(
            icon,
            size: 28,
            color: _securityService.isRateLimited
                ? AppColors.textHint
                : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
