import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/signals/app_signals.dart';
import '../domain/lesson_models.dart';
import 'widgets/lesson_card.dart';
import 'widgets/word_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _viewIndex = 0; // 0: Lessons, 1: Words
  Lesson? _selectedLesson;

  void _onLessonTap(Lesson lesson) {
    setState(() {
      _selectedLesson = lesson;
      _viewIndex = 1;
    });
  }

  void _onWordTap(String word) {
    selectWord(word);
    context.push('/learn');
  }

  void _onBack() {
    if (_viewIndex == 1) {
      setState(() {
        _viewIndex = 0;
        _selectedLesson = null;
      });
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Body Content
            IndexedStack(
              index: _viewIndex,
              children: [
                _buildLessonGrid(theme, colorScheme),
                _buildWordGrid(theme, colorScheme),
              ],
            ),

            // Top Header (Title)
            Positioned(
              top: 0,
              left: 80,
              right: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    _viewIndex == 0 
                      ? "Chọn bài học để bắt đầu nhé!" 
                      : (_selectedLesson?.title ?? "Chọn từ để học"),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Back Button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton.filled(
                onPressed: _onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerLowest,
                  foregroundColor: colorScheme.primary,
                  elevation: 4,
                  shadowColor: colorScheme.primary.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonGrid(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 100), // Space for header
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(48, 0, 48, 48),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 32,
              mainAxisSpacing: 32,
              childAspectRatio: 1.1,
            ),
            itemCount: curatedLessons.length,
            itemBuilder: (context, index) {
              return LessonCard(
                lesson: curatedLessons[index],
                onTap: () => _onLessonTap(curatedLessons[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWordGrid(ThemeData theme, ColorScheme colorScheme) {
    if (_selectedLesson == null) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 100), // Space for header
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(48, 0, 48, 48),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 0.85,
            ),
            itemCount: _selectedLesson!.words.length,
            itemBuilder: (context, index) {
              final word = _selectedLesson!.words[index];
              return WordCard(
                word: word,
                onTap: () => _onWordTap(word.text),
              );
            },
          ),
        ),
      ],
    );
  }
}
