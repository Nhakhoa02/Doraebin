import 'package:flutter/material.dart';
import '../../home/domain/category_assets.dart';

class WordItem {
  final String text;
  final String imageUrl;
  final String? lottieUrl;
  final String categoryId;

  const WordItem({
    required this.text,
    required this.imageUrl,
    this.lottieUrl,
    this.categoryId = 'custom',
  });

  factory WordItem.fromDatabase(Map<String, dynamic> data) {
    final text = data['text'] as String;
    final categoryId = data['category_id'] as String? ?? 'custom';
    final dbImageUrl = data['image_url'] as String?;
    
    // Fallback to static mapping if database URL is missing or empty
    final resolvedUrl = (dbImageUrl != null && dbImageUrl.isNotEmpty)
        ? dbImageUrl
        : CategoryAssets.getWordAsset(categoryId, text) ?? '';

    return WordItem(
      text: text,
      imageUrl: resolvedUrl,
      categoryId: categoryId,
    );
  }
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
