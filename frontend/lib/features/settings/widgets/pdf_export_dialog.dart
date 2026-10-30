import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_formatter.dart';
import '../../reflection/models/reflection_entry_model.dart';
import '../../reflection/services/reflection_service.dart';

enum ExportScope {
  currentMonth,
  allTime,
  customMonth,
}

/// Modal dialog allowing users to configure and export a beautiful PDF Keepsake Book.
class PdfExportDialog extends StatefulWidget {
  final DateTime? initialMonth;

  const PdfExportDialog({
    super.key,
    this.initialMonth,
  });

  static Future<void> show(BuildContext context, {DateTime? initialMonth}) {
    return showDialog(
      context: context,
      builder: (ctx) => PdfExportDialog(initialMonth: initialMonth),
    );
  }

  @override
  State<PdfExportDialog> createState() => _PdfExportDialogState();
}

class _PdfExportDialogState extends State<PdfExportDialog> {
  final ReflectionService _reflectionService = ReflectionService();
  final PdfExportService _pdfService = PdfExportService();

  ExportScope _selectedScope = ExportScope.currentMonth;
  late DateTime _targetMonth;
  bool _includePhotos = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _targetMonth = widget.initialMonth ?? DateTime(now.year, now.month);
  }

  List<ReflectionEntryModel> _getFilteredEntries() {
    final all = _reflectionService.entries;
    if (_selectedScope == ExportScope.allTime) {
      return all;
    }
    return all.where((e) {
      return e.date.year == _targetMonth.year &&
          e.date.month == _targetMonth.month;
    }).toList();
  }

  String _getExportTitle() {
    if (_selectedScope == ExportScope.allTime) {
      return 'Journal — Keepsake Collection';
    }
    final monthName = DateFormat('MMMM yyyy').format(_targetMonth);
    return 'Journal — $monthName';
  }

  String _getExportSubtitle() {
    if (_selectedScope == ExportScope.allTime) {
      return 'Full Journal Keepsake';
    }
    return DateFormat('MMMM yyyy').format(_targetMonth);
  }

  Future<void> _handlePreviewAndPrint() async {
    final entries = _getFilteredEntries();
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No entries found to export.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.snackBarBackground,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);
    try {
      if (mounted) Navigator.pop(context);
      await _pdfService.previewAndPrint(
        context: context,
        entries: entries,
        title: _getExportTitle(),
        subtitle: _getExportSubtitle(),
        includePhotos: _includePhotos,
      );
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
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _handleShare() async {
    final entries = _getFilteredEntries();
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No entries found to export.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.snackBarBackground,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);
    try {
      await _pdfService.sharePdf(
        entries: entries,
        title: _getExportTitle(),
        subtitle: _getExportSubtitle(),
        includePhotos: _includePhotos,
      );
      if (mounted) Navigator.pop(context);
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
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _getFilteredEntries();

    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Export Keepsake PDF',
              style: GoogleFonts.lora(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate an elegant printable book of your reflections for personal archiving or physical printing.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 18),

            // Scope Selector
            Text(
              'EXPORT PERIOD',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 8),

            // Current Month Choice
            InkWell(
              onTap: () => setState(() => _selectedScope = ExportScope.currentMonth),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedScope == ExportScope.currentMonth
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedScope == ExportScope.currentMonth
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedScope == ExportScope.currentMonth
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: _selectedScope == ExportScope.currentMonth
                          ? AppColors.primary
                          : AppColors.textHint,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This Month (${DateFormat('MMMM yyyy').format(_targetMonth)})',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          fontWeight: _selectedScope == ExportScope.currentMonth
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // All Time Choice
            InkWell(
              onTap: () => setState(() => _selectedScope = ExportScope.allTime),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedScope == ExportScope.allTime
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedScope == ExportScope.allTime
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedScope == ExportScope.allTime
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: _selectedScope == ExportScope.allTime
                          ? AppColors.primary
                          : AppColors.textHint,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'All Time / Full Journal History',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          fontWeight: _selectedScope == ExportScope.allTime
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Include Photos Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Include Moment Photos',
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Render photos attached to reflections in the book',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              value: _includePhotos,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
              onChanged: (val) => setState(() => _includePhotos = val),
            ),
            const SizedBox(height: 12),

            // Summary badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.calmTagBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.calmTagText, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${entries.length} reflections selected for this keepsake.',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.calmTagText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        OutlinedButton.icon(
          onPressed: _isGenerating ? null : _handleShare,
          icon: const Icon(Icons.share_outlined, size: 16),
          label: const Text('Share PDF'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : _handlePreviewAndPrint,
          icon: _isGenerating
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.print_outlined, size: 16),
          label: const Text('Print / Preview'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}
