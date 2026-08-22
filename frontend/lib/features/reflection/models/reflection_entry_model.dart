import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../journal/models/journal_entry.dart';
import '../../history/pages/history_page.dart';

/// Distinguishes between guided step reflections and standalone freeform notes.
enum ReflectionType {
  guided,
  freeform,
}

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
  final ReflectionType type;
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
    this.type = ReflectionType.guided,
    required this.createdAt,
  });

  /// Convert to local/JSON Map
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'mood': mood,
      'moodEmoji': moodEmoji,
      'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
      'freeformTitle': freeformTitle,
      'freeformNote': freeformNote,
      'isBookmarked': isBookmarked,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert to Supabase PostgreSQL table row format (snake_case)
  Map<String, dynamic> toSupabaseMap({String? userId}) {
    final map = <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'mood_emoji': moodEmoji,
      'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
      'freeform_title': freeformTitle,
      'freeform_note': freeformNote,
      'is_bookmarked': isBookmarked,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
    };
    if (userId != null && userId.isNotEmpty) {
      map['user_id'] = userId;
    }
    return map;
  }

  /// Create from JSON Map (supports both camelCase and snake_case keys)
  factory ReflectionEntryModel.fromMap(Map<String, dynamic> map, String docId) {
    Map<int, String> parsedAnswers = {};
    final rawAnswers = map['answers'];
    if (rawAnswers != null && rawAnswers is Map) {
      rawAnswers.forEach((k, v) {
        final parsedKey = int.tryParse(k.toString());
        if (parsedKey != null) {
          parsedAnswers[parsedKey] = v.toString();
        }
      });
    }

    final typeStr = (map['type'] ?? map['entry_type'])?.toString();
    final parsedType = typeStr == 'freeform'
        ? ReflectionType.freeform
        : ReflectionType.guided;

    final dateStr = map['date']?.toString();
    final createdStr = (map['createdAt'] ?? map['created_at'])?.toString();

    return ReflectionEntryModel(
      id: docId,
      date: dateStr != null
          ? DateTime.tryParse(dateStr) ?? DateTime.now()
          : DateTime.now(),
      mood: map['mood']?.toString() ?? 'Calm',
      moodEmoji: (map['moodEmoji'] ?? map['mood_emoji'])?.toString() ?? '🌿',
      answers: parsedAnswers,
      freeformTitle: (map['freeformTitle'] ?? map['freeform_title'])?.toString(),
      freeformNote: (map['freeformNote'] ?? map['freeform_note'])?.toString(),
      isBookmarked: (map['isBookmarked'] ?? map['is_bookmarked']) == true,
      type: parsedType,
      createdAt: createdStr != null
          ? DateTime.tryParse(createdStr) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Create from Supabase row
  factory ReflectionEntryModel.fromSupabase(Map<String, dynamic> row) {
    return ReflectionEntryModel.fromMap(row, row['id']?.toString() ?? '');
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
          : (type == ReflectionType.freeform
              ? 'Freeform Note — ${_formatDate(date)}'
              : 'Reflection on ${_formatDate(date)}'),
      contentSnippet: snippet,
      mood: mood,
      moodEmoji: moodEmoji,
      moodBgColor: bg,
      moodTextColor: text,
      questionsCount: answers.length,
      isBookmarked: isBookmarked,
      entryType: type.name,
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
    ReflectionType? type,
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
      type: type ?? this.type,
      createdAt: createdAt,
    );
  }
}
