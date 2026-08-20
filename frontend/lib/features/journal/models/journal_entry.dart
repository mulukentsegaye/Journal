import 'package:flutter/material.dart';

/// Represents a saved reflection or journal entry.
class JournalEntry {
  final String id;
  final DateTime date;
  final String title;
  final String contentSnippet;
  final String mood;
  final String moodEmoji;
  final Color moodBgColor;
  final Color moodTextColor;
  final int questionsCount;
  final bool isBookmarked;
  final String entryType;
  final List<String> tags;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.contentSnippet,
    required this.mood,
    required this.moodEmoji,
    required this.moodBgColor,
    required this.moodTextColor,
    required this.questionsCount,
    this.isBookmarked = false,
    this.entryType = 'guided',
    this.tags = const [],
  });

  JournalEntry copyWith({
    bool? isBookmarked,
    String? entryType,
  }) {
    return JournalEntry(
      id: id,
      date: date,
      title: title,
      contentSnippet: contentSnippet,
      mood: mood,
      moodEmoji: moodEmoji,
      moodBgColor: moodBgColor,
      moodTextColor: moodTextColor,
      questionsCount: questionsCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      entryType: entryType ?? this.entryType,
      tags: tags,
    );
  }
}
