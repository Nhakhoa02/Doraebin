import 'package:flutter/material.dart';
import '../../domain/category_assets.dart';
import '../../domain/lesson_models.dart';
import 'dot_lottie_icon.dart';

class LessonCard extends StatefulWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  @override
  State<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkColor = HSLColor.fromColor(widget.lesson.color).withLightness(0.2).toColor();
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: widget.lesson.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: widget.lesson.color.withOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: widget.lesson.color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon: Lottie animation or emoji fallback
                _buildIcon(),
                const SizedBox(height: 12),
                Text(
                  widget.lesson.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: darkColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Renders a Lottie animation if a .lottie asset is registered for this
  /// category, otherwise falls back to the emoji text.
  Widget _buildIcon() {
    final lottieAsset = CategoryAssets.getLottieAsset(widget.lesson.id);

    if (lottieAsset != null) {
      return DotLottieIcon(
        assetPath: lottieAsset,
        size: 72,
        fallback: _emojiIcon(),
      );
    }

    return _emojiIcon();
  }

  Widget _emojiIcon() {
    return Text(widget.lesson.emoji, style: const TextStyle(fontSize: 56));
  }
}
