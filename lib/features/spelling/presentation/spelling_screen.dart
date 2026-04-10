import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/signals/app_signals.dart';

class SpellingScreen extends StatefulWidget {
  const SpellingScreen({super.key});

  @override
  State<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends State<SpellingScreen> with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late AnimationController _emojiController;
  late Animation<double> _emojiScale;
  
  final Set<int> _revealedIndices = {};
  
  // Candy Color Palette for Stickers
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
    await _tts.setSpeechRate(0.5);
  }

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

  void _speak(String text, {bool isFinal = false}) async {
    await _tts.stop();
    await _tts.speak(text);
    if (isFinal) {
      _emojiController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = currentWordSignal.watch(context);

    if (result == null) {
      return const Scaffold(body: Center(child: Text("No word selected")));
    }

    final ttsParts = result.ttsString.split(' ');
    final displayParts = result.spellString.split(' ');

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  // Top Section: Word & Graphic Side-by-Side
                  Expanded(
                    flex: 5,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Word Card
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF776300).withOpacity(0.1),
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
                                        result.original,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 100,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF776300),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _speak(result.ttsString, isFinal: true),
                                  icon: const Icon(Icons.volume_up_rounded, size: 24),
                                  label: Text(
                                    "Nghe đánh vần",
                                    style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFDD400),
                                    foregroundColor: const Color(0xFF433700),
                                    elevation: 0,
                                    minimumSize: const Size(180, 44),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Graphic Illustration Card (Bouncing Emoji)
                        Expanded(
                          flex: 2,
                          child: ScaleTransition(
                            scale: _emojiScale,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF6A5).withOpacity(0.4),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Center(
                                    child: Text(
                                      _getEmojiForWord(result.original),
                                      style: TextStyle(fontSize: constraints.maxHeight * 0.5),
                                    ),
                                  );
                                }
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Spelling Components Section (Discovery Mode)
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _revealedIndices.length == displayParts.length 
                            ? "Giỏi quá! Chạm lại để nghe tiếp nha!"
                            : "Chạm vào các ô để khám phá nào!",
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF776300).withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 12,
                                children: List.generate(displayParts.length, (index) {
                                  final part = displayParts[index];
                                  final ttsPart = ttsParts.length > index ? ttsParts[index] : part;
                                  final rotation = (index % 2 == 0 ? 1 : -1) * (index % 3 + 1) * math.pi / 180 * 1.5;
                                  final isRevealed = _revealedIndices.contains(index);
                                  final color = _stickerPalette[index % _stickerPalette.length];

                                  return Transform.rotate(
                                    angle: rotation,
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: 160),
                                      child: _StickerCard(
                                        text: part,
                                        isRevealed: isRevealed,
                                        backgroundColor: color,
                                        onTap: () {
                                          setState(() {
                                            _revealedIndices.add(index);
                                          });
                                          _speak(ttsPart);
                                        },
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Close Button - Top Left
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF776300).withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Color(0xFF776300), size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _emojiController.dispose();
    super.dispose();
  }
}

class _StickerCard extends StatefulWidget {
  final String text;
  final bool isRevealed;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _StickerCard({
    super.key, 
    required this.text, 
    required this.isRevealed,
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
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            color: widget.isRevealed ? widget.backgroundColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isRevealed ? Colors.white : const Color(0xFFE0E0E0), 
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3D3905).withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: widget.isRevealed 
              ? Text(
                  widget.text,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF006C95),
                  ),
                )
              : const Icon(Icons.help_outline_rounded, size: 48, color: Color(0xFFBDBDBD)),
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
