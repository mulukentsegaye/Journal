import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/error_formatter.dart';
import '../../auth/services/auth_service.dart';
import '../../reflection/services/database_service.dart';
import '../../reflection/services/reflection_service.dart';
import '../widgets/pdf_export_dialog.dart';

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
  bool _isExportingMd = false;

  Future<void> _exportMarkdownBackup() async {
    setState(() => _isExportingMd = true);
    try {
      final markdown = await _settingsService.exportAllReflectionsMarkdown();
      await Clipboard.setData(ClipboardData(text: markdown));

      String? savedPath;
      try {
        final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final file = File('${dir.path}/daily_reflection_backup_$timestamp.md');
        await file.writeAsString(markdown);
        savedPath = file.path;
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.snackBarBackground,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            savedPath != null
                ? 'Backup saved to Downloads.'
                : 'Backup copied to clipboard.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE02424),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            ErrorFormatter.format(e),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExportingMd = false);
    }
  }

  Future<void> _toggleReminder(bool enabled) async {
    await _settingsService.setReminderEnabled(enabled);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.snackBarBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          enabled
              ? 'Evening reminder enabled.'
              : 'Evening reminder disabled.',
          style: const TextStyle(color: Colors.white),
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
            backgroundColor: AppColors.snackBarBackground,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Evening reminder set to ${_settingsService.formattedReminderTime}.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleMorningReminder(bool enabled) async {
    await _settingsService.setMorningReminderEnabled(enabled);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.snackBarBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          enabled
              ? 'Morning reminder enabled.'
              : 'Morning reminder disabled.',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _selectMorningReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _settingsService.morningReminderTime,
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
      await _settingsService.setMorningReminderTime(picked);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.snackBarBackground,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Morning reminder set to ${_settingsService.formattedMorningReminderTime}.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _optimizeCache() async {
    final recovered = await DatabaseService().recoverAllHistoricalEntries();
    _reflectionService.refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.snackBarBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          recovered > 0
              ? 'Found and recovered $recovered past reflection${recovered == 1 ? '' : 's'}!'
              : 'Storage verified: All reflections are healthy and up to date.',
          style: const TextStyle(color: Colors.white),
        ),
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
                // ── Section 1: Morning & Evening Reminders ──────────
                const _SectionTitle(title: 'DAILY REMINDERS'),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      // --- Morning Intention Reminder ---
                      SwitchListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.wb_sunny_rounded,
                              color: Color(0xFFD97706), size: 20),
                        ),
                        title: Text(
                          'Morning Intention',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Start your day with clarity and focus',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        activeThumbColor: const Color(0xFFD97706),
                        activeTrackColor:
                            const Color(0xFFD97706).withValues(alpha: 0.3),
                        value: _settingsService.morningReminderEnabled,
                        onChanged: _toggleMorningReminder,
                      ),
                      if (_settingsService.morningReminderEnabled) ...[
                        Divider(height: 1, color: AppColors.divider),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          leading: const Icon(Icons.access_time_rounded,
                              color: Color(0xFFD97706), size: 20),
                          title: Text(
                            'Morning Reminder Time',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD97706).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _settingsService.formattedMorningReminderTime,
                              style: const TextStyle(
                                color: Color(0xFFB45309),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          onTap: _selectMorningReminderTime,
                        ),
                      ],

                      Divider(height: 1, color: AppColors.divider),

                      // --- Evening Reflection Reminder ---
                      SwitchListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.nights_stay_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          'Evening Reflection',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Gentle pause to unwind and journal your thoughts',
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
                            'Evening Reminder Time',
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
                            ? 'Local Offline Storage'
                            : 'Cloud Sync',
                        icon: _authService.isLocalGuest
                            ? Icons.phone_android_rounded
                            : Icons.cloud_done_rounded,
                      ),
                      const Divider(height: 20),
                      _DiagnosticRow(
                        label: 'Privacy Status',
                        value: 'Protected & Private',
                        icon: Icons.shield_outlined,
                      ),
                      const Divider(height: 20),
                      _DiagnosticRow(
                        label: 'Total Stored Entries',
                        value: '${_reflectionService.entries.length} entries stored',
                        icon: Icons.folder_open_rounded,
                      ),
                      const Divider(height: 20),
                      _DiagnosticRow(
                        label: 'Longest Streak',
                        value:
                            '${_reflectionService.longestStreakCount} ${_reflectionService.longestStreakCount == 1 ? 'day' : 'days'}',
                        icon: Icons.emoji_events_outlined,
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

                // ── Section 4: Data Export & Backups ─────────────────
                const _SectionTitle(title: 'DATA EXPORT & BACKUPS'),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          'Keepsake PDF Book',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        subtitle: Text(
                          'Printable collection with photos, quotes & stats',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                        onTap: () => PdfExportDialog.show(context),
                      ),
                      Divider(height: 1, color: AppColors.divider),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.article_outlined, color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          'Export Markdown (.md)',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        subtitle: Text(
                          'Formatted text backup with tags, photos & prompts',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                        trailing: _isExportingMd
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 18),
                        onTap: _isExportingMd ? null : _exportMarkdownBackup,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Section 5: About & Mission ───────────────────────
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
                            'Journal',
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
                        'A private, simple journaling app to record your thoughts, track your moods, and reflect on your days.',
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
