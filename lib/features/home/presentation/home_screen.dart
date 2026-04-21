import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signals_flutter/signals_flutter.dart';

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
  List<WordItem> _words = [];
  bool _isLoading = false;

  void _onLessonTap(Lesson lesson) async {
    setState(() => _isLoading = true);
    
    try {
      final words = await getWordsForLesson(lesson.id);
      setState(() {
        _selectedLesson = lesson;
        _words = words;
        _viewIndex = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải bài học: $e')),
        );
      }
    }
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
        _words = [];
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
    final lessons = lessonsSignal.watch(context);

    // Dynamic background color based on selection
    final bgColor = _selectedLesson != null 
        ? HSLColor.fromColor(_selectedLesson!.color).withLightness(0.95).toColor()
        : const Color(0xFFF0F9FF); // Soft blue for "Lessons" view

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Background Decorations (Modern Cartoon Style)
            Positioned(
              top: -50,
              right: -50,
              child: _CircularDecoration(color: colorScheme.primary.withOpacity(0.05), size: 300),
            ),
            Positioned(
              bottom: 40,
              left: -30,
              child: _CircularDecoration(color: colorScheme.tertiary.withOpacity(0.05), size: 200),
            ),
            
            // Random floating "clouds" or icons for kids vibe
            if (_viewIndex == 0) ...[
              const Positioned(
                top: 100,
                left: 100,
                child: Opacity(opacity: 0.3, child: Text("☁️", style: TextStyle(fontSize: 40))),
              ),
              const Positioned(
                top: 150,
                right: 120,
                child: Opacity(opacity: 0.3, child: Text("✨", style: TextStyle(fontSize: 30))),
              ),
              const Positioned(
                bottom: 100,
                right: 150,
                child: Opacity(opacity: 0.3, child: Text("🎈", style: TextStyle(fontSize: 40))),
              ),
            ],

            // Body Content
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              IndexedStack(
                index: _viewIndex,
                children: [
                  _buildLessonGrid(theme, colorScheme, lessons),
                  _buildWordGrid(theme, colorScheme),
                ],
              ),

            // Top Header (Title)
            Positioned(
              top: 0,
              left: 80,
              right: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: (_selectedLesson?.color ?? colorScheme.primary).withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _viewIndex == 0 
                        ? "Chọn bài học để bắt đầu nhé!" 
                        : (_selectedLesson?.title ?? "Chọn từ để học"),
                      style: GoogleFonts.itim(
                        textStyle: theme.textTheme.headlineSmall?.copyWith(
                          color: _selectedLesson != null 
                            ? HSLColor.fromColor(_selectedLesson!.color).withLightness(0.2).toColor()
                            : colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Back Button
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: colorScheme.primary,
                  iconSize: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonGrid(ThemeData theme, ColorScheme colorScheme, List<Lesson> lessons) {
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
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              return LessonCard(
                lesson: lessons[index],
                onTap: () => _onLessonTap(lessons[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWordGrid(ThemeData theme, ColorScheme colorScheme) {
    if (_selectedLesson == null) return const SizedBox.shrink();

    if (_words.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🐆", style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              "Chưa có từ nào trong bài này nè!",
              style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      );
    }

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
            itemCount: _words.length,
            itemBuilder: (context, index) {
              final word = _words[index];
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

class _CircularDecoration extends StatelessWidget {
  final Color color;
  final double size;

  const _CircularDecoration({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
