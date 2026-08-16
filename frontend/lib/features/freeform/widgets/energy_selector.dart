import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Represents a selectable energy/mood state.
class EnergyState {
  final String id;
  final String label;
  final String emoji;
  final Color activeColor;
  final Color activeBgColor;

  const EnergyState({
    required this.id,
    required this.label,
    required this.emoji,
    required this.activeColor,
    required this.activeBgColor,
  });
}

/// Horizontal selector for the user's current energy state.
class EnergySelector extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const EnergySelector({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  static const List<EnergyState> states = [
    EnergyState(
      id: 'anxious',
      label: 'Anxious',
      emoji: '😰',
      activeColor: Color(0xFFC07050),
      activeBgColor: Color(0xFFFDECE6),
    ),
    EnergyState(
      id: 'tired',
      label: 'Tired',
      emoji: '😫',
      activeColor: Color(0xFF8A7A6E),
      activeBgColor: Color(0xFFF0EBE5),
    ),
    EnergyState(
      id: 'calm',
      label: 'Calm',
      emoji: '🌿',
      activeColor: Color(0xFF5A7A52),
      activeBgColor: Color(0xFFE8F0E4),
    ),
    EnergyState(
      id: 'happy',
      label: 'Happy',
      emoji: '☀️',
      activeColor: Color(0xFFC78B2A),
      activeBgColor: Color(0xFFFEF4DC),
    ),
    EnergyState(
      id: 'grateful',
      label: 'Grateful',
      emoji: '🙏',
      activeColor: Color(0xFF8B6BA8),
      activeBgColor: Color(0xFFF4EDFA),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How is your energy right now?',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: states.map((state) {
              final isSelected = selectedId == state.id;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _EnergyChip(
                  state: state,
                  isSelected: isSelected,
                  onTap: () => onSelected(state.id),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _EnergyChip extends StatelessWidget {
  final EnergyState state;
  final bool isSelected;
  final VoidCallback onTap;

  const _EnergyChip({
    required this.state,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? state.activeBgColor : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? state.activeColor.withValues(alpha: 0.8)
                : AppColors.divider,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: state.activeColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.emoji,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 4),
            Text(
              state.label,
              style: AppTextStyles.navLabel.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? state.activeColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
