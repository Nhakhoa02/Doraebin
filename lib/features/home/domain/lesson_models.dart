import 'package:flutter/material.dart';

class WordItem {
  final String text;
  final String imageUrl;
  final String? lottieUrl;

  const WordItem({
    required this.text,
    required this.imageUrl,
    this.lottieUrl,
  });
}

class Lesson {
  final String id;
  final String title;
  final String emoji;
  final Color color;
  final List<WordItem> words;

  const Lesson({
    required this.id,
    required this.title,
    required this.emoji,
    required this.color,
    required this.words,
  });
}

// The static curatedLessons list has been removed as lessons are now 
// loaded dynamically from the database in app_signals.dart.
