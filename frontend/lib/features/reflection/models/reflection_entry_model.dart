import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../journal/models/journal_entry.dart';
import '../../history/pages/history_page.dart';

/// Full model for a saved daily reflection stored in Cloud Firestore.
class ReflectionEntryModel {
  final String id;
  final DateTime date;
  final String mood;
  final String moodEmoji;
  final Map<int, String> answers;
  final String? freeformTitle;
  final String? freeformNote;
  final bool isBookmarked;
  final DateTime createdAt;

  const ReflectionEntryModel({
    required this.id,
    required this.date,
    this.mood = 'Calm',
    this.moodEmoji = '🌿',
    this.answers = const {},
    this.freeformTitle,
    this.freeformNote,
    this.isBookmarked = false,
    required this.createdAt,
  });

  /// Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'mood': mood,
      'moodEmoji': moodEmoji,
      'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
      'freeformTitle': freeformTitle,
      'freeformNote': freeformNote,
      'isBookmarked': isBookmarked,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from Firestore Map
  factory ReflectionEntryModel.fromMap(Map<String, dynamic> map, String docId) {
    Map<int, String> parsedAnswers = {};
    if (map['answers'] != null && map['answers'] is Map) {
      (map['answers'] as Map).forEach((k, v) {
        final parsedKey = int.tryParse(k.toString());
        if (parsedKey != null) {
          parsedAnswers[parsedKey] = v.toString();
        }
      });
    }

    return ReflectionEntryModel(
      id: docId,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      mood: map['mood']?.toString() ?? 'Calm',
      moodEmoji: map['moodEmoji']?.toString() ?? '🌿',
      answers: parsedAnswers,
      freeformTitle: map['freeformTitle']?.toString(),
      freeformNote: map['freeformNote']?.toString(),
      isBookmarked: map['isBookmarked'] == true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Convenience method to convert to JournalEntry
  JournalEntry toJournalEntry() {
    Color bg = AppColors.calmTagBg;
    Color text = AppColors.calmTagText;

    if (mood.toLowerCase().contains('grateful')) {
      bg = const Color(0xFFF4EDFA);
      text = const Color(0xFF8B6BA8);
    } else if (mood.toLowerCase().contains('happy') ||
        mood.toLowerCase().contains('energized')) {
      bg = const Color(0xFFFEF4DC);
      text = const Color(0xFFC78B2A);
    } else if (mood.toLowerCase().contains('reflective')) {
      bg = const Color(0xFFF0EBE5);
      text = const Color(0xFF8A7A6E);
    }

    String snippet = freeformNote ?? '';
    if (snippet.isEmpty && answers.isNotEmpty) {
      snippet = answers.values.first;
    }
    if (snippet.isEmpty) {
      snippet = 'Evening mindful reflection captured.';
    }

    return JournalEntry(
      id: id,
      date: date,
      title: freeformTitle?.isNotEmpty == true
          ? freeformTitle!
          : 'Reflection on ${_formatDate(date)}',
      contentSnippet: snippet,
      mood: mood,
      moodEmoji: moodEmoji,
      moodBgColor: bg,
      moodTextColor: text,
      questionsCount: answers.length,
      isBookmarked: isBookmarked,
    );
  }

  /// Convenience method to convert to HistoryPage ReflectionEntry
  ReflectionEntry toHistoryEntry() {
    String summaryText = freeformNote ?? '';
    if (summaryText.isEmpty && answers.isNotEmpty) {
      summaryText = answers.values.join(' ');
    }
    if (summaryText.isEmpty) {
      summaryText = 'Gentle moments and reflections captured.';
    }

    return ReflectionEntry(
      id: id,
      mood: mood,
      moodEmoji: moodEmoji,
      summary: summaryText,
      questionsAnswered: answers.length,
      minutesSpent: (answers.length * 1.2).round().clamp(3, 15),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  ReflectionEntryModel copyWith({
    bool? isBookmarked,
  }) {
    return ReflectionEntryModel(
      id: id,
      date: date,
      mood: mood,
      moodEmoji: moodEmoji,
      answers: answers,
      freeformTitle: freeformTitle,
      freeformNote: freeformNote,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt,
    );
  }
}
