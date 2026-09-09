import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/voice_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/error_formatter.dart';

/// 1-Tap Voice Dictation button with pulsing animation and live sound-wave feedback.
class VoiceInputButton extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onTextChanged;
  final String label;
  final bool compact;

  const VoiceInputButton({
    super.key,
    required this.controller,
    this.onTextChanged,
    this.label = 'Speak your reflection',
    this.compact = false,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  String _baseText = '';
  bool _isThisButtonActive = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _voiceService.addListener(_onVoiceServiceUpdate);
  }

  void _onVoiceServiceUpdate() {
    if (!_voiceService.isListening && _isThisButtonActive) {
      if (mounted) {
        setState(() {
          _isThisButtonActive = false;
        });
        _animController.stop();
        _animController.reset();
      }
    }
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceUpdate);
    _animController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    HapticFeedback.lightImpact();

    if (_voiceService.isListening) {
      await _voiceService.stopListening();
      if (mounted) {
        setState(() {
          _isThisButtonActive = false;
        });
        _animController.stop();
        _animController.reset();
      }
      return;
    }

    _baseText = widget.controller.text.trim();
    setState(() {
      _isThisButtonActive = true;
    });

    _animController.repeat(reverse: true);

    final success = await _voiceService.startListening(
      onResult: (recognizedWords, isFinal) {
        if (!mounted) return;
        final formatted = _baseText.isEmpty
            ? recognizedWords
            : '$_baseText $recognizedWords';

        widget.controller.text = formatted;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );

        if (widget.onTextChanged != null) {
          widget.onTextChanged!(formatted);
        }

        if (isFinal) {
          _baseText = formatted;
        }
      },
    );

    if (!success && mounted) {
      setState(() {
        _isThisButtonActive = false;
      });
      _animController.stop();
      _animController.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.snackBarBackground,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.mic_off_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _voiceService.lastError != null
                      ? ErrorFormatter.format(_voiceService.lastError)
                      : 'Microphone permission needed or voice input unavailable.',
                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _voiceService.isListening && _isThisButtonActive;

    if (widget.compact) {
      return GestureDetector(
        onTap: _toggleListening,
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isListening
                    ? const Color(0xFFDEF7EC)
                    : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isListening
                      ? const Color(0xFF03543F)
                      : AppColors.divider,
                  width: isListening ? 1.5 : 1,
                ),
                boxShadow: isListening
                    ? [
                        BoxShadow(
                          color: const Color(0xFF03543F).withValues(alpha: 0.25),
                          blurRadius: 10 * _pulseAnimation.value,
                          spreadRadius: 2 * _pulseAnimation.value,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: isListening
                    ? const Color(0xFF03543F)
                    : AppColors.primary,
                size: 20,
              ),
            );
          },
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isListening
                  ? const Color(0xFFDEF7EC)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isListening
                    ? const Color(0xFF03543F)
                    : AppColors.divider,
                width: isListening ? 1.5 : 1,
              ),
              boxShadow: isListening
                  ? [
                      BoxShadow(
                        color: const Color(0xFF03543F).withValues(alpha: 0.2),
                        blurRadius: 8 * _pulseAnimation.value,
                        spreadRadius: 1 * _pulseAnimation.value,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: isListening ? _pulseAnimation.value : 1.0,
                  child: Icon(
                    isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: 17,
                    color: isListening
                        ? const Color(0xFF03543F)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isListening ? 'Listening… speak freely' : widget.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isListening
                        ? const Color(0xFF03543F)
                        : AppColors.textSecondary,
                    fontWeight:
                        isListening ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                if (isListening) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF03543F),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
