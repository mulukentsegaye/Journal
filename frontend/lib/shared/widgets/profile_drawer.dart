import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/security_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/reflection/services/reflection_service.dart';
import '../../features/settings/widgets/pdf_export_dialog.dart';

/// Right-side drawer for Profile, Preferences, Privacy, and Keepsakes.
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
                style: TextStyle(
                    color: AppColors.textPrimary, letterSpacing: 8, fontSize: 18),
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
                style: TextStyle(
                    color: AppColors.textPrimary, letterSpacing: 8, fontSize: 18),
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

                await _securityService.setPin(pin);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out?',
            style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        content: Text(
          'Your reflections will remain safely encrypted in local storage and synced with your account.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close drawer
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

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isGuest = _authService.isGuest;

    return Drawer(
      backgroundColor: AppColors.background,
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_settingsService, _securityService]),
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Drawer Header ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile & Settings',
                        style: GoogleFonts.lora(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded,
                            size: 22, color: AppColors.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── User Profile Card ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.15),
                              child: Text(
                                _authService.userName.isNotEmpty
                                    ? _authService.userName[0].toUpperCase()
                                    : 'U',
                                style: AppTextStyles.greeting.copyWith(
                                  fontSize: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _authService.userName,
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _showEditNameDialog,
                                        child: Icon(Icons.edit_outlined,
                                            size: 16, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isGuest
                                        ? (_authService.isLocalGuest
                                            ? 'Local Guest'
                                            : 'Anonymous Guest')
                                        : (user?.email ?? 'Connected'),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // E2EE & Sync Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.calmTagBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isGuest
                                    ? Icons.lock_outline_rounded
                                    : Icons.shield_outlined,
                                size: 13,
                                color: AppColors.calmTagText,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isGuest
                                    ? 'Client AES-256 E2EE (Local)'
                                    : 'Cloud Sync + AES-256 E2EE',
                                style: AppTextStyles.badge.copyWith(
                                  color: AppColors.calmTagText,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Appearance Section ─────────────────────────
                  _DrawerSectionTitle(title: 'APPEARANCE'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme Mode',
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _ThemeOption(
                              label: 'System',
                              icon: Icons.brightness_auto_rounded,
                              isSelected: _settingsService.themeMode ==
                                  ThemeMode.system,
                              onTap: () => _settingsService
                                  .setThemeMode(ThemeMode.system),
                            ),
                            const SizedBox(width: 8),
                            _ThemeOption(
                              label: 'Light',
                              icon: Icons.light_mode_rounded,
                              isSelected: _settingsService.themeMode ==
                                  ThemeMode.light,
                              onTap: () => _settingsService
                                  .setThemeMode(ThemeMode.light),
                            ),
                            const SizedBox(width: 8),
                            _ThemeOption(
                              label: 'Dark',
                              icon: Icons.dark_mode_rounded,
                              isSelected: _settingsService.themeMode ==
                                  ThemeMode.dark,
                              onTap: () => _settingsService
                                  .setThemeMode(ThemeMode.dark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Privacy & Security ─────────────────────────
                  _DrawerSectionTitle(title: 'PRIVACY & SECURITY'),
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
                              const EdgeInsets.symmetric(horizontal: 14),
                          title: Text(
                            'App Lock',
                            style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Text(
                            'Biometric & PIN security',
                            style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                          activeThumbColor: AppColors.primary,
                          activeTrackColor:
                              AppColors.primary.withValues(alpha: 0.4),
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
                          Divider(height: 1, color: AppColors.divider),
                          SwitchListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            title: Text(
                              'Biometric Unlock',
                              style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            subtitle: Text(
                              'Face ID / Fingerprint',
                              style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                            activeThumbColor: AppColors.primary,
                            activeTrackColor:
                                AppColors.primary.withValues(alpha: 0.4),
                            value: _securityService.isBiometricsEnabled,
                            onChanged: (val) =>
                                _securityService.setBiometricsEnabled(val),
                          ),
                          Divider(height: 1, color: AppColors.divider),
                          ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            title: Text(
                              'Change PIN Code',
                              style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            trailing: Icon(Icons.chevron_right_rounded,
                                size: 18, color: AppColors.textHint),
                            onTap: _showSetPinDialog,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Data & Keepsakes ───────────────────────────
                  _DrawerSectionTitle(title: 'DATA & KEEPSAKES'),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          leading: Icon(Icons.menu_book_rounded,
                              color: AppColors.primary, size: 20),
                          title: Text(
                            'Export Keepsake PDF Book',
                            style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Text(
                            'Printable digital book with photos',
                            style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                          trailing: Icon(Icons.chevron_right_rounded,
                              size: 18, color: AppColors.textHint),
                          onTap: () {
                            Navigator.pop(context);
                            PdfExportDialog.show(context);
                          },
                        ),
                        Divider(height: 1, color: AppColors.divider),
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          leading: Icon(Icons.download_rounded,
                              color: AppColors.primary, size: 20),
                          title: Text(
                            'Backup All (Markdown)',
                            style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Text(
                            'Copy plain text reflections',
                            style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                          trailing: Icon(Icons.copy_rounded,
                              size: 16, color: AppColors.textHint),
                          onTap: _exportMarkdownBackup,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Sign Out Button ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _confirmSignOut,
                      icon: const Icon(Icons.logout_rounded,
                          size: 16, color: Color(0xFFE02424)),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(
                            color: Color(0xFFE02424),
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFF8B4B4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DrawerSectionTitle extends StatelessWidget {
  final String title;
  const _DrawerSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.badge.copyWith(
          color: AppColors.textHint,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
