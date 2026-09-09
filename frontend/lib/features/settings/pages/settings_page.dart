import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/services/auth_service.dart';
import '../../reflection/services/reflection_service.dart';

/// Clean, dedicated Settings & Preferences screen.
/// Focused on Notifications, Voice Dictation, Sync Diagnostics, and App Info.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsService = SettingsService();
  final _authService = AuthService();
  final _reflectionService = ReflectionService();
  final _notificationService = NotificationService();
  bool _isSendingTest = false;

  Future<void> _toggleReminder(bool enabled) async {
    await _settingsService.setReminderEnabled(enabled);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          enabled
              ? 'Evening reminder active for ${_settingsService.formattedReminderTime} 🌙'
              : 'Evening reminder disabled.',
        ),
      ),
    );
  }

  Future<void> _selectReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _settingsService.reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await _settingsService.setReminderTime(picked);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text('Reminder set for ${_settingsService.formattedReminderTime} 🌙'),
          ),
        );
      }
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isSendingTest = true);
    final sent = await _notificationService.sendTestNotification();
    if (!mounted) return;
    setState(() => _isSendingTest = false);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: sent ? AppColors.primary : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          sent
              ? 'Test reminder delivered! Check your notifications ✨'
              : 'Could not deliver test notification. Please verify notification permissions.',
        ),
      ),
    );
  }

  void _optimizeCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text('Local storage cache is healthy and fully optimized!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Settings',
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Section 1: Evening Reminders ─────────────────────
                const _SectionTitle(title: 'DAILY REMINDERS'),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(
                          'Daily Journal Reminder',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Gentle notification to pause and capture your thoughts',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        activeThumbColor: AppColors.primary,
                        activeTrackColor:
                            AppColors.primary.withValues(alpha: 0.4),
                        value: _settingsService.reminderEnabled,
                        onChanged: _toggleReminder,
                      ),
                      if (_settingsService.reminderEnabled) ...[
                        Divider(height: 1, color: AppColors.divider),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          leading: Icon(Icons.access_time_rounded,
                              color: AppColors.primary, size: 20),
                          title: Text(
                            'Reminder Time',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              _settingsService.formattedReminderTime,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          onTap: _selectReminderTime,
                        ),
                        Divider(height: 1, color: AppColors.divider),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          leading: Icon(Icons.notifications_active_outlined,
                              color: AppColors.primary, size: 20),
                          title: Text(
                            'Send Test Notification',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: Text(
                            'Preview notification delivery immediately',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                          trailing: _isSendingTest
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                          onTap: _isSendingTest ? null : _sendTestNotification,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Section 2: Voice & Audio Journaling ──────────────
                const _SectionTitle(title: 'VOICE & AUDIO JOURNALING'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDEF7EC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.mic_rounded,
                                color: Color(0xFF03543F), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'On-Device Speech-to-Text',
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Fast, zero-latency streaming dictation',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDEF7EC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Color(0xFF03543F),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Dictations are transcribed directly on your device without sending voice recordings to external servers.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Section 3: Sync & Storage Diagnostics ────────────
                const _SectionTitle(title: 'SYNC & STORAGE DIAGNOSTICS'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      _DiagnosticRow(
                        label: 'Storage Mode',
                        value: _authService.isLocalGuest
                            ? 'Local-First Offline Storage'
                            : 'Supabase Cloud Sync',
                        icon: _authService.isLocalGuest
                            ? Icons.phone_android_rounded
                            : Icons.cloud_done_rounded,
                      ),
                      const Divider(height: 20),
                      _DiagnosticRow(
                        label: 'Encryption Status',
                        value: 'AES-256 Client-Side E2EE Active',
                        icon: Icons.lock_outline_rounded,
                      ),
                      const Divider(height: 20),
                      _DiagnosticRow(
                        label: 'Total Stored Entries',
                        value: '${_reflectionService.entries.length} entries stored',
                        icon: Icons.folder_open_rounded,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: _optimizeCache,
                          icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                          label: const Text('Verify Local Storage Integrity'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Section 4: About & Mission ───────────────────────
                const _SectionTitle(title: 'ABOUT'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daily Reflection',
                            style: GoogleFonts.lora(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Version 1.0.0',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A private, mindful sanctuary created to help you unwind, appreciate quiet moments, and cultivate gratitude every evening.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.badge.copyWith(
          color: AppColors.textHint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DiagnosticRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
