import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final baseColor = widget.lesson.color;
    final darkColor = HSLColor.fromColor(baseColor).withLightness(0.2).toColor();
    final deepShadowColor = HSLColor.fromColor(baseColor).withLightness(0.4).toColor();
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          children: [
            // Bottom "3D" depth layer
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: deepShadowColor,
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            // Top layer (the actual card)
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    HSLColor.fromColor(baseColor).withLightness(0.95).toColor(),
                    HSLColor.fromColor(baseColor).withLightness(0.85).toColor(),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon: Lottie animation or fallback
                    Expanded(
                      flex: 3,
                      child: Center(child: _buildIcon()),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Flexible(
                      flex: 1,
                      child: Text(
                        widget.lesson.title,
                        style: GoogleFonts.itim(
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            color: darkColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders a visual asset (Lottie, SVG, or Image)
  Widget _buildIcon() {
    final lottieAsset = CategoryAssets.getLottieAsset(widget.lesson.id);
    if (lottieAsset != null) {
      return DotLottieIcon(
        assetPath: lottieAsset,
        size: 100,
        fallback: _emojiIcon(),
      );
    }

    final svgAsset = CategoryAssets.getSvgAsset(widget.lesson.id);
    if (svgAsset != null) {
      return SvgPicture.asset(
        svgAsset,
        width: 80,
        height: 80,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => _emojiIcon(),
      );
    }

    final imageAsset = CategoryAssets.getImageAsset(widget.lesson.id);
    if (imageAsset != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            )
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            imageAsset,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => _emojiIcon(),
          ),
        ),
      );
    }

    return _emojiIcon();
  }

  Widget _emojiIcon() {
    return Text(
      widget.lesson.emoji, 
      style: const TextStyle(fontSize: 64),
    );
  }
}
