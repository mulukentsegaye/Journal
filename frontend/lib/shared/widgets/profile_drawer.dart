import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/security_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/smooth_page_route.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/reflection/services/reflection_service.dart';
import '../../features/onboarding/pages/onboarding_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/settings/widgets/pdf_export_dialog.dart';

/// Clean, professional right-side navigation drawer with instant reactive theme updates.
class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({super.key});

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  final _authService = AuthService();
  final _settingsService = SettingsService();
  final _securityService = SecurityService();
  final _reflectionService = ReflectionService();

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Warm Light';
      case ThemeMode.dark:
        return 'Night Sky Dark';
    }
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ListenableBuilder(
        listenable: _settingsService,
        builder: (context, _) {
          final isDark = _settingsService.isDarkMode;
          final user = _authService.currentUser;
          final isGuest = _authService.isGuest;
          final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
          final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
          final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
          final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

          return Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  child: Text(
                    _authService.userName.isNotEmpty
                        ? _authService.userName[0].toUpperCase()
                        : 'U',
                    style: GoogleFonts.lora(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _authService.userName,
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGuest
                      ? (_authService.isLocalGuest
                          ? 'Local Guest Account'
                          : 'Anonymous Guest')
                      : (user?.email ?? 'Connected'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCalmTagBg : AppColors.lightCalmTagBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGuest ? Icons.phone_android_rounded : Icons.cloud_done_rounded,
                        size: 14,
                        color: isDark ? AppColors.darkCalmTagText : AppColors.lightCalmTagText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isGuest ? 'Client AES-256 E2EE (Local)' : 'Cloud Synced & Encrypted',
                        style: GoogleFonts.inter(
                          color: isDark ? AppColors.darkCalmTagText : AppColors.lightCalmTagText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditNameDialog();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Display Name',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmDeleteAccount();
                  },
                  icon: const Icon(Icons.delete_forever_rounded,
                      size: 16, color: Color(0xFFE02424)),
                  label: const Text(
                    'Delete Account & Wipe Data',
                    style: TextStyle(
                      color: Color(0xFFE02424),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ListenableBuilder(
        listenable: _settingsService,
        builder: (context, _) {
          final isDark = _settingsService.isDarkMode;
          final currentMode = _settingsService.themeMode;
          final sheetBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
          final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
          final dividerColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

          return Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Theme & Appearance',
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how Daily Reflection looks for your quiet space.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                _ThemeSelectionTile(
                  title: 'System Default',
                  subtitle: 'Match your device light / dark setting',
                  icon: Icons.brightness_auto_rounded,
                  isSelected: currentMode == ThemeMode.system,
                  isDark: isDark,
                  onTap: () {
                    _settingsService.setThemeMode(ThemeMode.system);
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 10),
                _ThemeSelectionTile(
                  title: 'Warm Light',
                  subtitle: 'Paper texture and soothing morning tones',
                  icon: Icons.light_mode_rounded,
                  isSelected: currentMode == ThemeMode.light,
                  isDark: isDark,
                  onTap: () {
                    _settingsService.setThemeMode(ThemeMode.light);
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 10),
                _ThemeSelectionTile(
                  title: 'Night Sky Dark',
                  subtitle: 'Gentle charcoal shades for peaceful evening reflection',
                  icon: Icons.dark_mode_rounded,
                  isSelected: currentMode == ThemeMode.dark,
                  isDark: isDark,
                  onTap: () {
                    _settingsService.setThemeMode(ThemeMode.dark);
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPrivacySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ListenableBuilder(
        listenable: Listenable.merge([_settingsService, _securityService]),
        builder: (context, _) {
          final isDark = _settingsService.isDarkMode;
          final sheetBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
          final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
          final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
          final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
          final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

          return Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Privacy & Security',
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your journal is encrypted and protected with biometric security.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: divider),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(
                          'App Lock',
                          style: GoogleFonts.inter(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Require biometrics or PIN on resume',
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        activeThumbColor: primary,
                        activeTrackColor: primary.withValues(alpha: 0.4),
                        value: _securityService.isLockEnabled,
                        onChanged: (val) {
                          if (val) {
                            if (!_securityService.hasPin) {
                              Navigator.pop(ctx);
                              _showSetPinDialog();
                            } else {
                              _securityService.setLockEnabled(true);
                              if (mounted) setState(() {});
                            }
                          } else {
                            _securityService.setLockEnabled(false);
                            if (mounted) setState(() {});
                          }
                        },
                      ),
                      if (_securityService.isLockEnabled) ...[
                        Divider(height: 1, color: divider),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          title: Text(
                            'Biometric Unlock',
                            style: GoogleFonts.inter(
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Face ID / Fingerprint recognition',
                            style: GoogleFonts.inter(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          activeThumbColor: primary,
                          activeTrackColor: primary.withValues(alpha: 0.4),
                          value: _securityService.isBiometricsEnabled,
                          onChanged: (val) {
                            _securityService.setBiometricsEnabled(val);
                            if (mounted) setState(() {});
                          },
                        ),
                        Divider(height: 1, color: divider),
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          title: Text(
                            'Change PIN Code',
                            style: GoogleFonts.inter(
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          trailing: Icon(Icons.chevron_right_rounded,
                              size: 18, color: textSecondary),
                          onTap: () {
                            Navigator.pop(ctx);
                            _showSetPinDialog();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showKeepsakesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ListenableBuilder(
        listenable: _settingsService,
        builder: (context, _) {
          final isDark = _settingsService.isDarkMode;
          final sheetBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
          final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
          final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
          final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
          final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

          return Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Keepsakes & Data Export',
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Preserve your reflections as physical books or digital text.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: divider),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.menu_book_rounded,
                              color: primary, size: 20),
                        ),
                        title: Text(
                          'Export Keepsake PDF Book',
                          style: GoogleFonts.inter(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Printable layout with photos & quotes',
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right_rounded,
                            size: 18, color: textSecondary),
                        onTap: () {
                          Navigator.pop(ctx);
                          PdfExportDialog.show(context);
                        },
                      ),
                      Divider(height: 1, color: divider),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.download_rounded,
                              color: primary, size: 20),
                        ),
                        title: Text(
                          'Backup All (Markdown)',
                          style: GoogleFonts.inter(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Copy entire text history to clipboard',
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(Icons.copy_rounded,
                            size: 16, color: textSecondary),
                        onTap: () {
                          Navigator.pop(ctx);
                          _exportMarkdownBackup();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditNameDialog() {
    final isDark = _settingsService.isDarkMode;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final controller = TextEditingController(text: _authService.userName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Display Name',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            hintText: 'Your name',
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: divider),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _authService.updateDisplayName(newName);
                if (mounted) setState(() {});
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSetPinDialog() {
    final isDark = _settingsService.isDarkMode;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('🔒', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                _securityService.hasPin ? 'Change Security PIN' : 'Set Security PIN',
                style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter a 4-digit code to protect your reflections.',
                style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: TextStyle(
                    color: textPrimary, letterSpacing: 8, fontSize: 18),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'PIN',
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: divider),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: TextStyle(
                    color: textPrimary, letterSpacing: 8, fontSize: 18),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Confirm PIN',
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: divider),
                  ),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorText!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = pinController.text.trim();
                final confirm = confirmController.text.trim();

                if (pin.length != 4) {
                  setDialogState(() => errorText = 'PIN must be exactly 4 digits');
                  return;
                }
                if (pin != confirm) {
                  setDialogState(() => errorText = 'PINs do not match');
                  return;
                }

                await _securityService.setPin(pin);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Save PIN'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportMarkdownBackup() {
    final entries = _reflectionService.entries;
    final buffer = StringBuffer();
    buffer.writeln('# Daily Reflection Journal Backup');
    buffer.writeln('Exported on: ${DateTime.now().toLocal()}\n');

    for (final e in entries) {
      buffer.writeln('## ${e.date.toIso8601String().substring(0, 10)} — Mood: ${e.mood} ${e.moodEmoji}');
      if (e.freeformTitle?.isNotEmpty == true) {
        buffer.writeln('### ${e.freeformTitle}');
      }
      if (e.freeformNote?.isNotEmpty == true) {
        buffer.writeln('${e.freeformNote}\n');
      }
      if (e.answers.isNotEmpty) {
        buffer.writeln('**Reflections:**');
        e.answers.forEach((k, v) {
          buffer.writeln('- Q$k: $v');
        });
      }
      buffer.writeln('\n---\n');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Exported ${entries.length} reflections to clipboard!'),
      ),
    );
  }

  void _confirmSignOut() {
    final isDark = _settingsService.isDarkMode;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out?',
            style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary)),
        content: Text(
          'Your reflections will remain safely encrypted in local storage and synced with your account.',
          style: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await _authService.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE02424),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    final isDark = _settingsService.isDarkMode;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFE02424), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Account & Data?',
                style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This action is irreversible. All your reflections, attached photos, and account data will be permanently wiped.',
          style: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await _reflectionService.clearAllReflections();
              await _securityService.removePin();
              await _authService.deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE02424),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_settingsService, _securityService]),
      builder: (context, _) {
        final isDark = _settingsService.isDarkMode;
        final user = _authService.currentUser;
        final isGuest = _authService.isGuest;

        final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
        final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
        final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

        return Drawer(
          backgroundColor: bg,
          width: MediaQuery.of(context).size.width * 0.82,
          child: SafeArea(
            child: Column(
              children: [
                // ── Drawer Header & Profile Card ─────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Menu',
                            style: GoogleFonts.lora(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded,
                                size: 22, color: textSecondary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Tappable Mini User Profile Banner
                      InkWell(
                        onTap: _showProfileSheet,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: divider),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: primary.withValues(alpha: 0.15),
                                child: Text(
                                  _authService.userName.isNotEmpty
                                      ? _authService.userName[0].toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.lora(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _authService.userName,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                        color: textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isGuest
                                          ? (_authService.isLocalGuest
                                              ? 'Local Guest'
                                              : 'Guest Mode')
                                          : (user?.email ?? 'Connected'),
                                      style: GoogleFonts.inter(
                                        color: textSecondary,
                                        fontSize: 11.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  size: 18, color: textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: divider),

                // ── Main Menu Options List ───────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _DrawerMenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Profile',
                        subtitle: 'Name & Account Details',
                        isDark: isDark,
                        onTap: _showProfileSheet,
                      ),
                      const SizedBox(height: 6),
                      _DrawerMenuItem(
                        icon: Icons.palette_outlined,
                        title: 'Theme',
                        subtitle: _getThemeName(_settingsService.themeMode),
                        isDark: isDark,
                        onTap: _showThemeSheet,
                      ),
                      const SizedBox(height: 6),
                      _DrawerMenuItem(
                        icon: Icons.shield_outlined,
                        title: 'Privacy & Security',
                        subtitle: _securityService.isLockEnabled
                            ? 'App Lock Active'
                            : 'Biometrics & Encryption',
                        isDark: isDark,
                        onTap: _showPrivacySheet,
                      ),
                      const SizedBox(height: 6),
                      _DrawerMenuItem(
                        icon: Icons.menu_book_rounded,
                        title: 'Keepsakes & Export',
                        subtitle: 'PDF Book & Backup',
                        isDark: isDark,
                        onTap: _showKeepsakesSheet,
                      ),
                      const SizedBox(height: 6),
                      _DrawerMenuItem(
                        icon: Icons.explore_outlined,
                        title: 'App Tour & Guide',
                        subtitle: 'Mindful features walkthrough',
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(
                                builder: (_) =>
                                    const OnboardingPage(isStandaloneTour: true)),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      _DrawerMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        subtitle: 'Reminders & Preferences',
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(
                                builder: (_) => const SettingsPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Drawer Footer with Sign Out ──────────────
                Divider(height: 1, color: divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.logout_rounded,
                              size: 16, color: Color(0xFFE02424)),
                        ),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Color(0xFFE02424),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        onTap: _confirmSignOut,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Daily Reflection · Peaceful Mind',
                        style: GoogleFonts.inter(
                          color: textSecondary.withValues(alpha: 0.7),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: divider.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: isDark ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primary, size: 19),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            color: textSecondary,
            fontSize: 11,
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded,
            size: 18, color: textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      ),
    );
  }
}

class _ThemeSelectionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeSelectionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: isDark ? 0.18 : 0.09)
              : surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primary : divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withValues(alpha: isDark ? 0.25 : 0.15)
                    : cardBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 18,
                  color: isSelected ? primary : textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13.5,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: primary, size: 20),
          ],
        ),
      ),
    );
  }
}
