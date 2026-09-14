import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart' show BuildContext;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_strings.dart';
import '../../features/reflection/models/reflection_entry_model.dart';
import '../../features/auth/services/auth_service.dart';

/// Service responsible for generating elegant, printable PDF keepsake books.
class PdfExportService {
  static final PdfExportService _instance = PdfExportService._internal();
  factory PdfExportService() => _instance;
  PdfExportService._internal();

  /// Generates the binary PDF document for a list of reflection entries
  Future<Uint8List> generateKeepsakePdf({
    required List<ReflectionEntryModel> entries,
    required String title,
    required String subtitle,
    bool includePhotos = true,
  }) async {
    final doc = pw.Document(
      title: title,
      author: AuthService().userName,
      creator: 'Daily Reflection App',
    );

    final fontBase = await PdfGoogleFonts.loraRegular();
    final fontBold = await PdfGoogleFonts.loraBold();
    final fontItalic = await PdfGoogleFonts.loraItalic();
    final fontSans = await PdfGoogleFonts.interRegular();
    final fontEmoji = await PdfGoogleFonts.notoColorEmoji();

    final theme = pw.ThemeData.withFont(
      base: fontBase,
      bold: fontBold,
      italic: fontItalic,
      fontFallback: [fontSans, fontEmoji],
    );

    // Sort entries chronologically for the keepsake book
    final sortedEntries = List<ReflectionEntryModel>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Preload valid images into memory if includePhotos is true
    final Map<String, pw.MemoryImage> loadedImages = {};
    if (includePhotos) {
      for (final entry in sortedEntries) {
        final url = entry.photoUrl;
        if (url != null && url.isNotEmpty) {
          try {
            if (url.startsWith('http://') || url.startsWith('https://')) {
              final response = await http.get(Uri.parse(url)).timeout(
                const Duration(seconds: 10),
              );
              if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
                loadedImages[url] = pw.MemoryImage(response.bodyBytes);
              }
            } else {
              final file = File(url);
              if (file.existsSync()) {
                final bytes = await file.readAsBytes();
                loadedImages[url] = pw.MemoryImage(bytes);
              }
            }
          } catch (_) {}
        }
      }
    }

    // ── 1. Cover Page ──────────────────────────────────────────
    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
        ),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: const PdfColor.fromInt(0xFF2C5E43), // Primary calm green
                width: 2,
              ),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.SizedBox(height: 10),
                // Top ornament
                pw.Text(
                  '*  ·  *  ·  *',
                  style: pw.TextStyle(
                    color: const PdfColor.fromInt(0xFF8A9A86),
                    fontSize: 16,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Main Title Block
                pw.Column(
                  children: [
                    pw.Text(
                      'DAILY REFLECTION',
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 3,
                        color: const PdfColor.fromInt(0xFF1E3A2F),
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'A Mindful Keepsake Journal',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontStyle: pw.FontStyle.italic,
                        color: const PdfColor.fromInt(0xFF4A5568),
                      ),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Container(
                      width: 80,
                      height: 1.5,
                      color: const PdfColor.fromInt(0xFF2C5E43),
                    ),
                  ],
                ),

                // Middle Author & Period Info
                pw.Column(
                  children: [
                    pw.Text(
                      subtitle,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF2D3748),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Reflections by ${AuthService().userName}',
                      style: pw.TextStyle(
                        fontSize: 13,
                        color: const PdfColor.fromInt(0xFF718096),
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFF0FDF4),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        '${sortedEntries.length} Mindful Reflections Recorded',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottom Quote
                pw.Column(
                  children: [
                    pw.Text(
                      '“In the gentle rhythm of daily reflection, we rediscover peace and wisdom within ourselves.”',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontStyle: pw.FontStyle.italic,
                        color: const PdfColor.fromInt(0xFF718096),
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 14),
                    pw.Text(
                      'Created with Daily Reflection',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFFA0AEC0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // ── 2. Entries Pages ───────────────────────────────────────
    if (sortedEntries.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          header: (context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.only(bottom: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'DAILY REFLECTION  ·  KEEPSAKE',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      letterSpacing: 1.2,
                      color: const PdfColor.fromInt(0xFF718096),
                    ),
                  ),
                  pw.Text(
                    subtitle,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      color: const PdfColor.fromInt(0xFF718096),
                    ),
                  ),
                ],
              ),
            );
          },
          footer: (context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 20),
              padding: const pw.EdgeInsets.only(top: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '“Peace begins with a pause.”',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontStyle: pw.FontStyle.italic,
                      color: const PdfColor.fromInt(0xFFA0AEC0),
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      color: const PdfColor.fromInt(0xFF718096),
                    ),
                  ),
                ],
              ),
            );
          },
          build: (context) {
            final List<pw.Widget> content = [];

            for (int i = 0; i < sortedEntries.length; i++) {
              final entry = sortedEntries[i];
              final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(entry.date);

              content.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 24),
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFFAFAF9),
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFFE7E5E4),
                      width: 0.8,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Entry Header: Date & Mood Pill
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            dateStr,
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFF1C1917),
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: const PdfColor.fromInt(0xFFF5F5F4),
                              borderRadius: pw.BorderRadius.circular(12),
                              border: pw.Border.all(
                                color: const PdfColor.fromInt(0xFFD6D3D1),
                                width: 0.5,
                              ),
                            ),
                            child: pw.Text(
                              'Mood: ${entry.mood} ${entry.moodEmoji}',
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                                color: const PdfColor.fromInt(0xFF44403C),
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),

                      // Optional Attached Photo
                      if (includePhotos &&
                          entry.photoUrl != null &&
                          loadedImages.containsKey(entry.photoUrl)) ...[
                        pw.ClipRRect(
                          horizontalRadius: 8,
                          verticalRadius: 8,
                          child: pw.Image(
                            loadedImages[entry.photoUrl]!,
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                      ],

                      // Freeform Title if present
                      if (entry.freeformTitle != null &&
                          entry.freeformTitle!.isNotEmpty) ...[
                        pw.Text(
                          entry.freeformTitle!,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF292524),
                          ),
                        ),
                        pw.SizedBox(height: 6),
                      ],

                      // Freeform Note
                      if (entry.freeformNote != null &&
                          entry.freeformNote!.isNotEmpty) ...[
                        pw.Container(
                          padding: const pw.EdgeInsets.only(left: 10),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              left: pw.BorderSide(
                                color: PdfColor.fromInt(0xFF2C5E43),
                                width: 2,
                              ),
                            ),
                          ),
                          child: pw.Text(
                            entry.freeformNote!,
                            style: pw.TextStyle(
                              fontSize: 10.5,
                              fontStyle: pw.FontStyle.italic,
                              color: const PdfColor.fromInt(0xFF44403C),
                              lineSpacing: 1.4,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 10),
                      ],

                      // Guided Q&A Responses
                      if (entry.answers.isNotEmpty) ...[
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: entry.answers.entries.map((ans) {
                            final prompt = AppStrings.questionPrompts[ans.key] ??
                                'Reflection ${ans.key}';
                            return pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 8),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    '${ans.key}. $prompt',
                                    style: pw.TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: const PdfColor.fromInt(0xFF57534E),
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    ans.value,
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      color: const PdfColor.fromInt(0xFF292524),
                                      lineSpacing: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            return content;
          },
        ),
      );
    }

    return doc.save();
  }

  /// Opens native PDF print and preview dialog
  Future<void> previewAndPrint({
    required BuildContext context,
    required List<ReflectionEntryModel> entries,
    required String title,
    required String subtitle,
    bool includePhotos = true,
  }) async {
    await Printing.layoutPdf(
      name: '${title.replaceAll(' ', '_')}.pdf',
      onLayout: (PdfPageFormat format) async {
        return generateKeepsakePdf(
          entries: entries,
          title: title,
          subtitle: subtitle,
          includePhotos: includePhotos,
        );
      },
    );
  }

  /// Directly shares the generated PDF file via system share sheet
  Future<void> sharePdf({
    required List<ReflectionEntryModel> entries,
    required String title,
    required String subtitle,
    bool includePhotos = true,
  }) async {
    final pdfBytes = await generateKeepsakePdf(
      entries: entries,
      title: title,
      subtitle: subtitle,
      includePhotos: includePhotos,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${title.replaceAll(' ', '_')}.pdf',
    );
  }
}
