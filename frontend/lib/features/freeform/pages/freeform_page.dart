import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/smooth_page_route.dart';
import '../../../shared/widgets/photo_viewer_dialog.dart';
import '../widgets/energy_selector.dart';
import '../widgets/freeform_editor.dart';
import '../../summary/pages/summary_page.dart';
import '../../reflection/models/reflection_entry_model.dart';
import '../../reflection/services/reflection_service.dart';

/// Freeform Space — an open writing canvas paired with mood selector
/// and daily moment photo attachment.
class FreeformPage extends StatefulWidget {
  final String? id;
  final String? initialTitle;
  final String? initialContent;
  final String? initialMood;
  final String? initialPhotoUrl;
  final DateTime? date;
  final bool isStandalone;
  final VoidCallback? onSaved;
  final Map<int, String>? reflectionAnswers;

  const FreeformPage({
    super.key,
    this.id,
    this.initialTitle,
    this.initialContent,
    this.initialMood,
    this.initialPhotoUrl,
    this.date,
    this.isStandalone = true,
    this.onSaved,
    this.reflectionAnswers,
  });

  @override
  State<FreeformPage> createState() => _FreeformPageState();
}

class _FreeformPageState extends State<FreeformPage> {
  String _selectedEnergy = 'calm';
  bool _isSaving = false;
  String? _photoPath;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedEnergy = widget.initialMood?.toLowerCase() ?? 'calm';
    _photoPath = widget.initialPhotoUrl;
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not attach photo: $e'),
            backgroundColor: const Color(0xFFE02424),
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

    setState(() {
      _isSaving = true;
    });

    final selectedEnergyState = EnergySelector.states.firstWhere(
      (s) => s.id == _selectedEnergy,
      orElse: () => EnergySelector.states[2],
    );

    try {
      final now = widget.date ?? DateTime.now();
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      final docId = widget.id ?? '${DateTime.now().millisecondsSinceEpoch}';

      final entry = ReflectionEntryModel(
        id: docId,
        date: now,
        mood: selectedEnergyState.label,
        moodEmoji: selectedEnergyState.emoji,
        answers: widget.reflectionAnswers ?? const {},
        freeformTitle: title.isNotEmpty ? title : null,
        freeformNote: content.isNotEmpty ? content : null,
        photoUrl: _photoPath,
        type: ReflectionType.freeform,
        createdAt: now,
      );

      await ReflectionService().saveReflection(entry);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.id != null
                      ? 'Reflection updated successfully.'
                      : 'Thought saved to today\'s reflection.',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white,
                    fontSize: 13,
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
      } else if (widget.isStandalone) {
        Navigator.pushReplacement(
          context,
          SmoothPageRoute(
            builder: (_) => SummaryPage(
              id: docId,
              date: widget.date,
              mood: selectedEnergyState.label,
              moodEmoji: selectedEnergyState.emoji,
              freeformTitle: title.isNotEmpty ? title : null,
              freeformNote: content.isNotEmpty ? content : null,
              answers: widget.reflectionAnswers,
              photoUrl: _photoPath,
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
              'Failed to save reflection: $e',
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
        _titleController.text.trim().isEmpty &&
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
                      onPressed: () => setState(() => _photoPath = null),
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
                  'Add Daily Moment Photo',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Capture a sunset, tea, nature, or peaceful moment',
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
                      widget.id != null ? 'Edit Reflection' : 'Freeform Space',
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
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.calmTagText,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Quiet mode',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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
                    // Energy / Mood selector
                    EnergySelector(
                      selectedId: _selectedEnergy,
                      onSelected: (id) => setState(() => _selectedEnergy = id),
                    ),
                    const SizedBox(height: 20),

                    // Editor card
                    FreeformEditor(
                      titleController: _titleController,
                      contentController: _contentController,
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
                                  ? 'Update Reflection'
                                  : 'Save to Today\'s Entry',
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
