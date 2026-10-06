import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/smooth_page_route.dart';
import '../../../core/utils/error_formatter.dart';
import '../../../shared/widgets/photo_viewer_dialog.dart';
import '../widgets/energy_selector.dart';
import '../widgets/freeform_editor.dart';
import '../../summary/pages/summary_page.dart';
import '../../reflection/models/reflection_entry_model.dart';
import '../../reflection/services/database_service.dart';
import '../../reflection/services/reflection_service.dart';

/// Journal entry editor — an open writing canvas paired with an optional mood selector
/// and moment photo attachment.
class FreeformPage extends StatefulWidget {
  final String? id;
  final String? initialTitle;
  final String? initialContent;
  final String? initialMood;
  final String? initialPhotoUrl;
  final DateTime? date;
  final VoidCallback? onSaved;
  final List<String>? initialTags;

  const FreeformPage({
    super.key,
    this.id,
    this.initialTitle,
    this.initialContent,
    this.initialMood,
    this.initialPhotoUrl,
    this.date,
    this.onSaved,
    this.initialTags,
  });

  @override
  State<FreeformPage> createState() => _FreeformPageState();
}

class _FreeformPageState extends State<FreeformPage> {
  static const _keyDraftTitle = 'draft_entry_title';
  static const _keyDraftContent = 'draft_entry_content';
  static const _keyDraftMood = 'draft_entry_mood';
  static const _keyDraftTags = 'draft_entry_tags';
  static const _keyDraftPhoto = 'draft_entry_photo';

  String _selectedEnergy = 'calm';
  bool _isSaving = false;
  String? _photoPath;
  List<String> _tags = [];
  late final TextEditingController _contentController;
  final ImagePicker _picker = ImagePicker();

  Timer? _autoSaveTimer;
  bool _hasDraft = false;
  Map<String, dynamic>? _cachedDraft;

  @override
  void initState() {
    super.initState();
    _selectedEnergy = widget.initialMood?.toLowerCase() ?? 'calm';
    _photoPath = widget.initialPhotoUrl;
    _tags = widget.initialTags != null ? List.from(widget.initialTags!) : [];
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');

    if (widget.id == null) {
      _contentController.addListener(_scheduleAutoSave);

      if ((widget.initialTitle == null || widget.initialTitle!.isEmpty) &&
          (widget.initialContent == null || widget.initialContent!.isEmpty)) {
        _checkForDraft();
      }
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    if (widget.id == null) {
      _contentController.removeListener(_scheduleAutoSave);
    }
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _checkForDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftContent = prefs.getString(_keyDraftContent) ?? '';
      final draftPhoto = prefs.getString(_keyDraftPhoto);
      final draftTags = prefs.getStringList(_keyDraftTags) ?? [];
      final draftMood = prefs.getString(_keyDraftMood);

      final hasValidDraft = draftContent.trim().isNotEmpty ||
          (draftPhoto != null && draftPhoto.isNotEmpty) ||
          draftTags.isNotEmpty;

      if (hasValidDraft && mounted) {
        setState(() {
          _hasDraft = true;
          _cachedDraft = {
            'content': draftContent,
            'mood': draftMood ?? 'calm',
            'photo': draftPhoto,
            'tags': draftTags,
          };
        });
      }
    } catch (_) {}
  }

  void _restoreDraft() {
    if (_cachedDraft == null) return;
    setState(() {
      _contentController.text = _cachedDraft!['content'] ?? '';
      _selectedEnergy = _cachedDraft!['mood'] ?? 'calm';
      _photoPath = _cachedDraft!['photo'];
      _tags = List<String>.from(_cachedDraft!['tags'] ?? []);
      _hasDraft = false;
      _cachedDraft = null;
    });
  }

  Future<void> _discardDraft() async {
    await _clearDraft();
    if (mounted) {
      setState(() {
        _hasDraft = false;
        _cachedDraft = null;
      });
    }
  }

  void _scheduleAutoSave() {
    if (widget.id != null) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (widget.id != null) return;
    try {
      final content = _contentController.text.trim();
      final hasPhoto = _photoPath != null && _photoPath!.isNotEmpty;

      if (content.isEmpty && !hasPhoto && _tags.isEmpty) {
        await _clearDraft();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDraftContent, _contentController.text);
      await prefs.setString(_keyDraftMood, _selectedEnergy);
      await prefs.setStringList(_keyDraftTags, _tags);
      if (_photoPath != null && _photoPath!.isNotEmpty) {
        await prefs.setString(_keyDraftPhoto, _photoPath!);
      } else {
        await prefs.remove(_keyDraftPhoto);
      }
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDraftTitle);
      await prefs.remove(_keyDraftContent);
      await prefs.remove(_keyDraftMood);
      await prefs.remove(_keyDraftTags);
      await prefs.remove(_keyDraftPhoto);
    } catch (_) {}
  }

  Widget _buildDraftBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.history_edu_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unsaved draft found',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Resume writing where you left off?',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _restoreDraft,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Resume',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _discardDraft,
            icon: Icon(Icons.close_rounded, size: 16, color: AppColors.textHint),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Discard draft',
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _photoPath = picked.path;
        });
        _scheduleAutoSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorFormatter.format(e),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFE02424),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Moment Photo',
                style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: const Text('Take a Photo'),
                subtitle: const Text('Capture your current surroundings'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library_outlined, color: AppColors.primary),
                ),
                title: const Text('Choose from Library'),
                subtitle: const Text('Select a memorable moment from today'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    final content = _contentController.text.trim();
    final hasPhoto = _photoPath != null && _photoPath!.isNotEmpty;

    if (content.isEmpty && !hasPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.snackBarBackground,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please write a thought or attach a photo before saving.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final selectedEnergyState = EnergySelector.states.firstWhere(
      (s) => s.id == _selectedEnergy,
      orElse: () => EnergySelector.states[2],
    );

    try {
      final now = widget.date ?? DateTime.now();
      final docId = widget.id ?? DatabaseService.generateUniqueId();

      final entry = ReflectionEntryModel(
        id: docId,
        date: now,
        mood: selectedEnergyState.label,
        moodEmoji: selectedEnergyState.emoji,
        freeformTitle: null,
        freeformNote: content.isNotEmpty ? content : null,
        photoUrl: _photoPath,
        type: ReflectionType.freeform,
        createdAt: now,
        tags: _tags,
      );

      await ReflectionService().saveReflection(entry);
      await _clearDraft();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.snackBarBackground,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.id != null
                      ? 'Journal entry updated.'
                      : 'Journal entry saved.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        Navigator.pushReplacement(
          context,
          SmoothPageRoute(
            builder: (_) => SummaryPage(
              id: docId,
              date: widget.date,
              mood: selectedEnergyState.label,
              moodEmoji: selectedEnergyState.emoji,
              freeformTitle: null,
              freeformNote: content.isNotEmpty ? content : null,
              photoUrl: _photoPath,
              tags: _tags,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _confirmCancel() {
    if (_contentController.text.trim().isEmpty &&
        _photoPath == null) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Discard thoughts?',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Your unwritten thoughts in this space will be cleared.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Writing',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearDraft();
              Navigator.pop(context);
            },
            child: Text('Discard',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoAttachmentCard() {
    if (_photoPath != null && _photoPath!.isNotEmpty) {
      final isNetwork = _photoPath!.startsWith('http://') || _photoPath!.startsWith('https://');
      final imageProvider = isNetwork
          ? NetworkImage(_photoPath!) as ImageProvider
          : FileImage(File(_photoPath!));

      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('📸', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Moment Photo',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.change_circle_outlined, size: 20, color: AppColors.primary),
                      tooltip: 'Change Photo',
                      onPressed: _showPhotoOptions,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFE02424)),
                      tooltip: 'Remove Photo',
                      onPressed: () {
                        setState(() => _photoPath = null);
                        _scheduleAutoSave();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => PhotoViewerDialog.show(context, photoUrl: _photoPath!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Image(
                      image: imageProvider,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('View', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _showPhotoOptions,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Photo',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Attach a photo to this entry',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmCancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  if (canPop)
                    GestureDetector(
                      onTap: _confirmCancel,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  if (canPop) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.id != null ? 'Edit Journal' : 'New Journal Entry',
                      style: GoogleFonts.lora(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (canPop)
                    GestureDetector(
                      onTap: _confirmCancel,
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Scrollable Body ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Draft banner (if unsaved draft was found)
                    if (_hasDraft) _buildDraftBanner(),

                    // Energy / Mood selector
                    EnergySelector(
                      selectedId: _selectedEnergy,
                      onSelected: (id) {
                        setState(() => _selectedEnergy = id);
                        _scheduleAutoSave();
                      },
                    ),
                    const SizedBox(height: 20),

                    // Editor card
                    FreeformEditor(
                      contentController: _contentController,
                      tags: _tags,
                      onTagsChanged: (newTags) {
                        setState(() => _tags = newTags);
                        _scheduleAutoSave();
                      },
                      onContentChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    // Photo Attachment Card
                    _buildPhotoAttachmentCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Bottom Action Button ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.6),
                    elevation: 0,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bookmark_added_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              widget.id != null
                                  ? 'Update Entry'
                                  : 'Save Entry',
                              style: AppTextStyles.button.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
