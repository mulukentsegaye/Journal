import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../journal/models/journal_entry.dart';
import '../../history/widgets/day_detail_card.dart';

/// Distinguishes between guided step reflections and standalone freeform notes.
enum ReflectionType {
  guided,
  freeform,
}

/// Full model for a saved daily reflection stored in local cache and Supabase.
class ReflectionEntryModel {
  final String id;
  final DateTime date;
  final String mood;
  final String moodEmoji;
  final Map<int, String> answers;
  final String? freeformTitle;
  final String? freeformNote;
  final List<String> photoUrls;
  final bool isBookmarked;
  final ReflectionType type;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final List<String> tags;

  /// Returns the first photo URL for backward compatibility.
  String? get photoUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  ReflectionEntryModel({
    required this.id,
    required this.date,
    this.mood = 'Calm',
    this.moodEmoji = '🌿',
    this.answers = const {},
    this.freeformTitle,
    this.freeformNote,
    String? photoUrl,
    List<String>? photoUrls,
    this.isBookmarked = false,
    this.type = ReflectionType.freeform,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    this.tags = const [],
  }) : photoUrls = photoUrls ?? (photoUrl != null && photoUrl.isNotEmpty ? [photoUrl] : const []);

  /// Convert to local/JSON Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'moodEmoji': moodEmoji,
      'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
      'freeformTitle': freeformTitle,
      'freeformNote': freeformNote,
      'photoUrl': photoUrl,
      'photoUrls': photoUrls,
      'isBookmarked': isBookmarked,
      'type': type.name,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
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
      'photo_url': photoUrls.length > 1 ? jsonEncode(photoUrls) : photoUrl,
      'is_bookmarked': isBookmarked,
      'type': type.name,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'tags': tags,
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

    List<String> parsedTags = [];
    final rawTags = map['tags'];
    if (rawTags is List) {
      parsedTags = rawTags.map((t) => t.toString()).toList();
    } else if (rawTags is String && rawTags.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTags);
        if (decoded is List) {
          parsedTags = decoded.map((t) => t.toString()).toList();
        }
      } catch (_) {
        parsedTags = rawTags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      }
    }

    // Parse photoUrls list (supports list, json array string, or single legacy string)
    List<String> parsedPhotos = [];
    final rawPhotos = map['photoUrls'] ?? map['photo_urls'];
    if (rawPhotos is List) {
      parsedPhotos = rawPhotos.map((p) => p.toString()).toList();
    } else if (rawPhotos is String && rawPhotos.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPhotos);
        if (decoded is List) {
          parsedPhotos = decoded.map((p) => p.toString()).toList();
        }
      } catch (_) {}
    }
    if (parsedPhotos.isEmpty) {
      final single = (map['photoUrl'] ?? map['photo_url'])?.toString();
      if (single != null && single.isNotEmpty) {
        if (single.startsWith('[') && single.endsWith(']')) {
          try {
            final decoded = jsonDecode(single);
            if (decoded is List) {
              parsedPhotos = decoded.map((p) => p.toString()).toList();
            }
          } catch (_) {
            parsedPhotos = [single];
          }
        } else {
          parsedPhotos = [single];
        }
      }
    }

    final typeStr = (map['type'] ?? map['entry_type'])?.toString();
    final parsedType = typeStr == 'freeform'
        ? ReflectionType.freeform
        : ReflectionType.guided;

    final dateStr = map['date']?.toString();
    final createdStr = (map['createdAt'] ?? map['created_at'])?.toString();
    final deletedStr = (map['deletedAt'] ?? map['deleted_at'])?.toString();

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
      photoUrls: parsedPhotos,
      isBookmarked: (map['isBookmarked'] ?? map['is_bookmarked']) == true,
      type: parsedType,
      isDeleted: (map['isDeleted'] ?? map['is_deleted']) == true,
      deletedAt: deletedStr != null ? DateTime.tryParse(deletedStr) : null,
      createdAt: createdStr != null
          ? DateTime.tryParse(createdStr) ?? DateTime.now()
          : DateTime.now(),
      tags: parsedTags,
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

    String snippet = freeformNote?.trim() ?? '';
    if (snippet.isEmpty && answers.isNotEmpty) {
      snippet = answers.values.first;
    }
    if (snippet.isEmpty) {
      snippet = photoUrl != null && photoUrl!.isNotEmpty
          ? 'Photo entry'
          : 'Journal entry';
    }

    final defaultTitle = photoUrl != null && (freeformNote == null || freeformNote!.trim().isEmpty)
        ? 'Photo Entry'
        : 'Journal Entry';

    return JournalEntry(
      id: id,
      date: date,
      createdAt: createdAt,
      title: freeformTitle?.trim().isNotEmpty == true
          ? freeformTitle!.trim()
          : defaultTitle,
      contentSnippet: snippet,
      mood: mood,
      moodEmoji: moodEmoji,
      moodBgColor: bg,
      moodTextColor: text,
      questionsCount: answers.length,
      isBookmarked: isBookmarked,
      entryType: type.name,
      photoUrls: photoUrls,
      tags: tags,
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
      photoUrl: photoUrl,
    );
  }


  ReflectionEntryModel copyWith({
    String? id,
    DateTime? date,
    String? mood,
    String? moodEmoji,
    Map<int, String>? answers,
    String? freeformTitle,
    String? freeformNote,
    String? photoUrl,
    List<String>? photoUrls,
    bool? isBookmarked,
    ReflectionType? type,
    bool? isDeleted,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return ReflectionEntryModel(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      answers: answers ?? this.answers,
      freeformTitle: freeformTitle ?? this.freeformTitle,
      freeformNote: freeformNote ?? this.freeformNote,
      photoUrls: photoUrls ?? (photoUrl != null ? [photoUrl] : this.photoUrls),
      isBookmarked: isBookmarked ?? this.isBookmarked,
      type: type ?? this.type,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }
}
