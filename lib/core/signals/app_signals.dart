import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../data/database_service.dart';
import '../../features/spelling/domain/vi_spelling.dart';
import '../../features/home/domain/lesson_models.dart';

final dbService = DatabaseService();

// Signals
final historySignal = signal<List<Map<String, dynamic>>>([]);
final lessonsSignal = signal<List<Lesson>>([]);
final currentWordSignal = signal<DecomposedSyllable?>(null);
final currentWordItemSignal = signal<WordItem?>(null);

// Actions
Future<void> initAppSignals() async {
  await dbService.init();
  refreshHistory();
  refreshLessons();
}

void refreshHistory() {
  historySignal.value = dbService.getAllWords();
}

void refreshLessons() {
  final cats = dbService.getAllCategories();
  final List<Lesson> lessons = [];
  
  for (final cat in cats) {
    lessons.add(Lesson(
      id: cat['id'] as String,
      title: cat['title'] as String,
      emoji: cat['emoji'] as String? ?? '📚',
      color: _hexToColor(cat['color_hex'] as String? ?? '#2196F3'),
      words: const [], // Load words on demand for better performance
    ));
  }
  
  lessonsSignal.value = lessons;
}

Future<List<WordItem>> getWordsForLesson(String lessonId) async {
  final wordsData = dbService.getWordsByCategory(lessonId);
  return wordsData.map((w) => WordItem.fromDatabase(w)).toList();
}

Color _hexToColor(String hex) {
  return Color(int.parse(hex.replaceFirst('#', '0xFF')));
}

void selectWord(String text) {
  final result = getSpellingForText(text);
  currentWordSignal.value = result;
  
  // Try to find the full word item in the database for images/category info
  final allWords = dbService.getAllWords();
  final matchingWord = allWords.firstWhere(
    (w) => w['text'] == text,
    orElse: () => <String, dynamic>{},
  );

  if (matchingWord.isNotEmpty) {
    currentWordItemSignal.value = WordItem.fromDatabase(matchingWord);
  } else {
    // Create a temporary WordItem for custom words
    currentWordItemSignal.value = WordItem(text: text, imageUrl: '');
  }
  
  // Add to history if not there
  dbService.addWord(text);
  refreshHistory();
}

void selectWordItem(WordItem item) {
  final result = getSpellingForText(item.text);
  currentWordSignal.value = result;
  currentWordItemSignal.value = item;
  
  // Add to history if not there
  dbService.addWord(item.text, categoryId: 'custom', imageUrl: item.imageUrl);
  refreshHistory();
}

void deleteFromHistory(int id) {
  dbService.deleteWord(id);
  refreshHistory();
}
