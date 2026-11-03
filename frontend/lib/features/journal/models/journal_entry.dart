import 'package:flutter/material.dart';

/// Represents a saved reflection or journal entry.
class JournalEntry {
  final String id;
  final DateTime date;
  final DateTime? createdAt;
  final String title;
  final String contentSnippet;
  final String mood;
  final String moodEmoji;
  final Color moodBgColor;
  final Color moodTextColor;
  final int questionsCount;
  final bool isBookmarked;
  final String entryType;
  final List<String> photoUrls;
  final List<String> tags;

  String? get photoUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  /// Returns the creation timestamp when available, falling back to the entry date.
  DateTime get effectiveCreatedAt => (createdAt ?? date).toLocal();

  JournalEntry({
    required this.id,
    required this.date,
    this.createdAt,
    required this.title,
    required this.contentSnippet,
    required this.mood,
    required this.moodEmoji,
    required this.moodBgColor,
    required this.moodTextColor,
    required this.questionsCount,
    this.isBookmarked = false,
    this.entryType = 'guided',
    String? photoUrl,
    List<String>? photoUrls,
    this.tags = const [],
  }) : photoUrls = photoUrls ?? (photoUrl != null && photoUrl.isNotEmpty ? [photoUrl] : const []);

  JournalEntry copyWith({
    bool? isBookmarked,
    String? entryType,
    String? photoUrl,
    List<String>? photoUrls,
    DateTime? createdAt,
  }) {
    return JournalEntry(
      id: id,
      date: date,
      createdAt: createdAt ?? this.createdAt,
      title: title,
      contentSnippet: contentSnippet,
      mood: mood,
      moodEmoji: moodEmoji,
      moodBgColor: moodBgColor,
      moodTextColor: moodTextColor,
      questionsCount: questionsCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      entryType: entryType ?? this.entryType,
      photoUrls: photoUrls ?? (photoUrl != null ? [photoUrl] : this.photoUrls),
      tags: tags,
    );
  }
}
