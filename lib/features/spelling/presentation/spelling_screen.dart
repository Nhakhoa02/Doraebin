import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;
import '../../../core/signals/app_signals.dart';

/// A landscape-oriented spelling screen that guides children through 
/// Vietnamese syllable decomposition with interactive animations.
class SpellingScreen extends StatefulWidget {
  const SpellingScreen({super.key});

  @override
  State<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends State<SpellingScreen> with TickerProviderStateMixin {
  // TTS & Animations
  final FlutterTts _tts = FlutterTts();
  late AnimationController _emojiController;
  late Animation<double> _emojiScale;
  
  // State Tracking
  final Set<int> _revealedIndices = {};
  int _activeSpellingIndex = -1;
  bool _isAutoSpelling = false;
  
  // Design Tokens
  final List<Color> _stickerPalette = [
    const Color(0xFFFFE0E0), // Mint Pink
    const Color(0xFFE0FFE0), // Mint Green
    const Color(0xFFE0E0FF), // Mint Blue
    const Color(0xFFFFF6E0), // Mint Yellow
    const Color(0xFFF0E0FF), // Mint Purple
    const Color(0xFFE0FFFF), // Mint Cyan
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _initAnimations();
  }

  // --- Initialization & Lifecycle ---

  void _initAnimations() {
    _emojiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _emojiScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 50),
    ]).animate(_emojiController);
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("vi-VN");
    await _tts.setPitch(1.1);
    await _tts.setSpeechRate(0.3);
  }

  @override
  void dispose() {
    _tts.stop();
    _emojiController.dispose();
    super.dispose();
  }

  // --- Logic & Actions ---

  Future<void> _startAutoSpelling(String originalWord, List<String> displayParts, List<String> ttsParts) async {
    if (_isAutoSpelling) return;
    
    setState(() {
      _isAutoSpelling = true;
      _revealedIndices.addAll(Iterable.generate(displayParts.length));
    });

    for (int i = 0; i < displayParts.length; i++) {
      if (!mounted) break;
      setState(() => _activeSpellingIndex = i);
      await _tts.speak(ttsParts[i]);
      await Future.delayed(const Duration(milliseconds: 400)); 
    }

    if (mounted) {
      setState(() {
        _activeSpellingIndex = -1;
      });
      
      // Wait a small gap and read the whole word again
      await Future.delayed(const Duration(milliseconds: 500));
      await _tts.speak(originalWord);
      
      setState(() {
        _isAutoSpelling = false;
      });
      _emojiController.forward(from: 0);
    }
  }

  void _speak(String text, {bool isFinal = false}) async {
    await _tts.stop();
    await _tts.speak(text);
    if (isFinal) _emojiController.forward(from: 0);
  }

  // --- Utility Helpers ---

  String _getEmojiForWord(String word) {
    final lowerWord = word.toLowerCase();
    const map = {
      'mèo': '🐱', 'chó': '🐶', 'gà': '🐔', 'lợn': '🐷', 'bò': '🐮',
      'vịt': '🦆', 'ếch': '🐸', 'cá': '🐟', 'tôm': '🦐', 'cua': '🦀',
      'ngựa': '🐴', 'voi': '🐘', 'khỉ': '🐵', 'hổ': '🐯', 'sư tử': '🦁',
      'táo': '🍎', 'chuối': '🍌', 'cam': '🍊', 'xoài': '🥭', 'nho': '🍇',
      'dưa hấu': '🍉', 'kem': '🍦', 'bánh': '🍰', 'cơm': '🍚', 'nước': '💧',
      'mặt trời': '☀️', 'mặt trăng': '🌙', 'sao': '⭐', 'mưa': '🌧️', 'mây': '☁️',
      'hoa': '🌸', 'cây': '🌳', 'nhà': '🏠', 'xe': '🚗', 'máy bay': '✈️',
      'tàu': '🚢', 'giường': '🛏️', 'bàn': '🪑', 'ghế': '🪑', 'sách': '📚',
      'bút': '✏️', 'giếng': '💧',
    };
    return map[lowerWord] ?? '✨';
  }

  // --- UI Builders ---

  Widget _buildTopSection(BuildContext context, dynamic result, List<String> displayParts, List<String> ttsParts) {
    return Expanded(
      flex: 5,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Word Display Card
          Expanded(
            flex: 3,
            child: _buildWordDisplayCard(context, result.original, displayParts, ttsParts),
          ),
          const SizedBox(width: 16),
          // Illustration Card
          Expanded(
            flex: 2,
            child: _buildEmojiIllustration(context, result.original),
          ),
        ],
      ),
    );
  }

  Widget _buildWordDisplayCard(BuildContext context, String original, List<String> displayParts, List<String> ttsParts) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  unorm.nfc(original),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 100, // keep the large override
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isAutoSpelling ? null : () => _startAutoSpelling(original, displayParts, ttsParts),
            icon: _isAutoSpelling 
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimaryContainer))
              : const Icon(Icons.play_arrow_rounded, size: 24),
            label: Text(
              _isAutoSpelling ? "Đang đánh vần..." : "Đánh vần cho bé",
              style: theme.textTheme.titleMedium?.copyWith(
                color: _isAutoSpelling ? colorScheme.onPrimaryContainer : colorScheme.onPrimary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAutoSpelling ? colorScheme.primaryContainer : colorScheme.primary,
              foregroundColor: _isAutoSpelling ? colorScheme.onPrimaryContainer : colorScheme.onPrimary,
              elevation: 0,
              minimumSize: const Size(200, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiIllustration(BuildContext context, String original) {
    final colorScheme = Theme.of(context).colorScheme;
    final wordItem = currentWordItemSignal.watch(context);
    
    return ScaleTransition(
      scale: _emojiScale,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: colorScheme.surfaceContainerLowest, width: 4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (wordItem != null && wordItem.imageUrl.startsWith('assets/')) {
                return Image.asset(
                  wordItem.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => _buildEmojiFallback(original, constraints),
                );
              }
              return _buildEmojiFallback(original, constraints);
            }
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiFallback(String original, BoxConstraints constraints) {
    return Center(
      child: Text(
        _getEmojiForWord(original),
        style: TextStyle(fontSize: constraints.maxHeight * 0.5),
      ),
    );
  }

  Widget _buildSpellingSection(BuildContext context, List<String> displayParts, List<String> ttsParts) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Expanded(
      flex: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isAutoSpelling 
              ? "Nghe kỹ nhé..."
              : (_revealedIndices.length == displayParts.length 
                  ? "Giỏi quá! Chạm lại để nghe tiếp nha!"
                  : "Chạm vào các ô để khám phá nào!"),
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 800, // Constrain width to encourage wrapping on wide screens
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 20,
                    children: List.generate(displayParts.length, (index) {
                      return _buildSticker(index, displayParts, ttsParts);
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSticker(int index, List<String> displayParts, List<String> ttsParts) {
    final part = displayParts[index];
    final ttsPart = ttsParts.length > index ? ttsParts[index] : part;
    final rotation = (index % 2 == 0 ? 1 : -1) * (index % 3 + 1) * math.pi / 180 * 1.5;
    final isRevealed = _revealedIndices.contains(index);
    final color = _stickerPalette[index % _stickerPalette.length];
    final isActive = _activeSpellingIndex == index;

    return Transform.rotate(
      angle: rotation,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        child: _StickerCard(
          text: part,
          isRevealed: isRevealed,
          isActive: isActive,
          backgroundColor: color,
          onTap: _isAutoSpelling ? () {} : () {
            setState(() => _revealedIndices.add(index));
            _speak(ttsPart);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = currentWordSignal.watch(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (result == null) {
      return const Scaffold(body: Center(child: Text("No word selected")));
    }

    final ttsParts = result.ttsString.split(' ');
    final displayParts = result.spellString.split(' ');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  _buildTopSection(context, result, displayParts, ttsParts),
                  const SizedBox(height: 8),
                  _buildSpellingSection(context, displayParts, ttsParts),
                ],
              ),
            ),

            // Navigation Helpers
            Positioned(
              top: 16,
              left: 16,
              child: IconButton.filled(
                onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                icon: const Icon(Icons.close),
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


}

// --- Specialized Components ---

class _StickerCard extends StatefulWidget {
  final String text;
  final bool isRevealed;
  final bool isActive;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _StickerCard({
    required this.text, 
    required this.isRevealed,
    this.isActive = false,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  State<_StickerCard> createState() => _StickerCardState();
}

class _StickerCardState extends State<_StickerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_StickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isRevealed ? widget.backgroundColor : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isActive 
                ? colorScheme.errorContainer 
                : (widget.isRevealed ? colorScheme.surfaceContainerLowest : colorScheme.outlineVariant), 
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isActive 
                  ? colorScheme.errorContainer.withOpacity(0.4) 
                  : colorScheme.onSurface.withOpacity(0.08),
                blurRadius: widget.isActive ? 20 : 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: widget.isRevealed 
              ? Text(
                  widget.text,
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: colorScheme.secondary,
                  ),
                )
              : Icon(Icons.help_outline_rounded, size: 48, color: colorScheme.outlineVariant),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
