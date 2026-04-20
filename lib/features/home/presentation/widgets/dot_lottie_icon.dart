import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A reusable widget that renders a .lottie animation from an asset path.
///
/// Shows a shimmer placeholder while loading, and falls back to [fallback]
/// widget on error.
class DotLottieIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Widget? fallback;
  final bool animate;

  const DotLottieIcon({
    super.key,
    required this.assetPath,
    this.size = 64,
    this.fallback,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DotLottieLoader.fromAsset(
        assetPath,
        frameBuilder: (BuildContext ctx, DotLottie? dotlottie) {
          if (dotlottie != null) {
            return Lottie.memory(
              dotlottie.animations.values.single,
              animate: animate,
              repeat: true,
              fit: BoxFit.contain,
              width: size,
              height: size,
            );
          }
          // Loading state — subtle pulsing placeholder
          return _buildLoadingPlaceholder();
        },
        errorBuilder: (ctx, error, stack) {
          debugPrint('DotLottieIcon error for $assetPath: $error');
          return fallback ?? const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Center(
      child: SizedBox(
        width: size * 0.4,
        height: size * 0.4,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
