import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/security_service.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/pdf_export_dialog.dart';

/// Full-featured Settings & Profile customization screen.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsService = SettingsService();
  final _securityService = SecurityService();
  final _authService = AuthService();

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _authService.userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Display Name',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Your name',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
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
              backgroundColor: AppColors.primary,
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
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
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
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter a 4-digit code to protect your reflections.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: TextStyle(color: AppColors.textPrimary, letterSpacing: 8, fontSize: 18),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'PIN',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: TextStyle(color: AppColors.textPrimary, letterSpacing: 8, fontSize: 18),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Confirm PIN',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
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
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
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

                final messenger = ScaffoldMessenger.of(context);
                await _securityService.setPin(pin);
                if (ctx.mounted) Navigator.pop(ctx);
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    content: const Text(
                      'Security PIN set successfully! App Lock is now active.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Auto-Lock Timeout',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimeoutTile(ctx, title: 'Immediately', seconds: 0),
            _buildTimeoutTile(ctx, title: 'After 1 minute', seconds: 60),
            _buildTimeoutTile(ctx, title: 'After 5 minutes', seconds: 300),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutTile(BuildContext ctx, {required String title, required int seconds}) {
    final isSelected = _securityService.lockTimeoutSeconds == seconds;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
          : null,
      onTap: () {
        _securityService.setLockTimeout(seconds);
        Navigator.pop(ctx);
      },
    );
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _settingsService.reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Evening reminder scheduled for ${_settingsService.formattedReminderTime}.',
              style: TextStyle(color: AppColors.cardBackground),
            ),
          ),
        );
      }
    }
  }

  Future<void> _exportBackup() async {
    final markdown = await _settingsService.exportAllReflectionsMarkdown();
    await Clipboard.setData(ClipboardData(text: markdown));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Journal backup copied to clipboard as Markdown!',
                  style: TextStyle(color: AppColors.cardBackground),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Account Permanently?',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFE02424),
          ),
        ),
        content: Text(
          'This action cannot be undone. All your reflections, journals, and history will be permanently deleted.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _authService.deleteAccount();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFE02424),
                      content: Text('Failed to delete account: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete Forever',
              style: TextStyle(color: Color(0xFFE02424), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final name = _authService.userName;

    return ListenableBuilder(
      listenable: Listenable.merge([_settingsService, _securityService]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Settings & Preferences',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Center(
                child: InkWell(
                  onTap: () => Navigator.maybePop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: InkWell(
                    onTap: () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            physics: const BouncingScrollPhysics(),
            children: [
              // ── Profile Header Card ────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: GoogleFonts.lora(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: AppTextStyles.greeting.copyWith(fontSize: 18),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _showEditNameDialog,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _authService.isGuest
                                ? (_authService.isLocalGuest ? 'Guest Mode (Local)' : 'Guest Mode (Anonymous)')
                                : (user?.email ?? 'Connected'),
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.calmTagBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _authService.isLocalGuest
                                      ? Icons.phone_android_rounded
                                      : Icons.cloud_done_rounded,
                                  size: 12,
                                  color: AppColors.calmTagText,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _authService.isLocalGuest
                                      ? 'Local Storage Active'
                                      : 'Cloud Sync Active',
                                  style: AppTextStyles.badge.copyWith(
                                    color: AppColors.calmTagText,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Appearance Section (Dark Theme) ────────────
              const _SectionHeader(title: 'APPEARANCE'),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _ThemeOptionTile(
                      title: 'System Default',
                      icon: Icons.brightness_auto_rounded,
                      isSelected: _settingsService.themeMode == ThemeMode.system,
                      onTap: () => _settingsService.setThemeMode(ThemeMode.system),
                    ),
                    Divider(height: 1, color: AppColors.divider),
                    _ThemeOptionTile(
                      title: 'Light (Warm Cream)',
                      icon: Icons.wb_sunny_outlined,
                      isSelected: _settingsService.themeMode == ThemeMode.light,
                      onTap: () => _settingsService.setThemeMode(ThemeMode.light),
                    ),
                    Divider(height: 1, color: AppColors.divider),
                    _ThemeOptionTile(
                      title: 'Dark (Night Sky)',
                      icon: Icons.nightlight_round,
                      isSelected: _settingsService.themeMode == ThemeMode.dark,
                      onTap: () => _settingsService.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Reflection Reminders Section ───────────────
              const _SectionHeader(title: 'EVENING REMINDERS'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Daily Reflection Reminder',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Gentle prompt to ground your thoughts before sleep',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                      value: _settingsService.reminderEnabled,
                      onChanged: (val) => _settingsService.setReminderEnabled(val),
                    ),
                    if (_settingsService.reminderEnabled) ...[
                      Divider(color: AppColors.divider),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Reminder Time',
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _settingsService.formattedReminderTime,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
                          ],
                        ),
                        onTap: _pickReminderTime,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Privacy & Security Section ─────────────────
              const _SectionHeader(title: 'PRIVACY & SECURITY'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'App Lock',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Protect reflections with Biometrics & PIN code',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                      value: _securityService.isLockEnabled,
                      onChanged: (val) {
                        if (val) {
                          if (!_securityService.hasPin) {
                            _showSetPinDialog();
                          } else {
                            _securityService.setLockEnabled(true);
                          }
                        } else {
                          _securityService.setLockEnabled(false);
                        }
                      },
                    ),
                    if (_securityService.isLockEnabled) ...[
                      Divider(color: AppColors.divider),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Biometric Unlock',
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Use Face ID, Touch ID, or Fingerprint scan',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                        value: _securityService.isBiometricsEnabled,
                        onChanged: (val) => _securityService.setBiometricsEnabled(val),
                      ),
                      Divider(color: AppColors.divider),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _securityService.hasPin ? 'Change PIN Code' : 'Set 4-Digit PIN',
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                        ),
                        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
                        onTap: _showSetPinDialog,
                      ),
                      Divider(color: AppColors.divider),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Auto-Lock Timeout',
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _securityService.lockTimeoutSeconds == 0
                                  ? 'Immediately'
                                  : (_securityService.lockTimeoutSeconds == 60
                                      ? '1 minute'
                                      : '5 minutes'),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
                          ],
                        ),
                        onTap: _showTimeoutDialog,
                      ),
                    ],
                    Divider(color: AppColors.divider),
                    // E2EE Indicator Tile
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEF7EC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF03543F),
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            'End-to-End Encryption',
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDEF7EC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AES-256 Active',
                              style: TextStyle(
                                color: Color(0xFF03543F),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Your reflection notes, answers, and memories are encrypted on-device before cloud synchronization.',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Data & Backup Section ──────────────────────
              const _SectionHeader(title: 'DATA & BACKUP'),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        'Export Keepsake Journal (PDF Book)',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Generate an elegant printable PDF book for archiving or printing',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
                      onTap: () => PdfExportDialog.show(context),
                    ),
                    Divider(height: 1, color: AppColors.divider),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        'Export All Reflections (Markdown)',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Backup entire journal history as plain text',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      trailing: Icon(Icons.copy_rounded, size: 18, color: AppColors.textHint),
                      onTap: _exportBackup,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Account Actions ────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _authService.signOut();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFE02424)),
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _confirmDeleteAccount,
                  child: const Text(
                    'Delete Account & Data',
                    style: TextStyle(
                      color: Color(0xFFE02424),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
