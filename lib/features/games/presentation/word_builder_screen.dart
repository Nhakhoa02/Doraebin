import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../../spelling/domain/vi_spelling.dart';
import 'package:google_fonts/google_fonts.dart';

class WordBuilderScreen extends StatefulWidget {
  const WordBuilderScreen({super.key});

  @override
  State<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends State<WordBuilderScreen> with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScale;

  // Vocabulary
  final List<String> _vocabulary = [
    'mèo', 'chó', 'gà', 'lợn', 'bò', 'vịt', 'ếch', 'cá', 'tôm', 'cua',
    'ngựa', 'voi', 'khỉ', 'hổ', 'táo', 'chuối', 'cam', 'xoài', 'nho',
    'bánh', 'cơm', 'nước', 'sao', 'mưa', 'mây', 'hoa', 'cây', 'nhà', 'xe',
  ];

  late String _targetWord;
  late List<PuzzlePiece> _sourcePieces;
  late List<PuzzlePiece?> _answerSlots;
  bool _isSuccess = false;
  int? _activeSpellingIndex;
  List<String> _spellingDisplayTokens = [];

  @override
  void initState() {
    super.initState();
    _initTts();
    
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _celebrationScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 50),
    ]).animate(_celebrationController);

    _loadNewWord();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("vi-VN");
    await _tts.setPitch(1.1);
  }

  @override
  void dispose() {
    _tts.stop();
    _celebrationController.dispose();
    super.dispose();
  }

  void _loadNewWord() {
    _isSuccess = false;
    _activeSpellingIndex = null;
    _spellingDisplayTokens = [];
    _celebrationController.reset();

    final rand = Random();
    _targetWord = _vocabulary[rand.nextInt(_vocabulary.length)];

    // Decompose into pieces: [initial, ...nucleus_and_ending_chars]
    final decomp = decomposeVietnameseSyllable(_targetWord);
    
    List<String> textPieces = [];
    if (decomp.initial != "(none)") {
      textPieces.add(decomp.initial);
    }
    
    // We want the rest of the word exactly as it was, maintaining original tones.
    // The original word string without the initial part:
    String remaining = decomp.original;
    if (decomp.initial != "(none)" && remaining.startsWith(decomp.initial)) {
      remaining = remaining.substring(decomp.initial.length);
    }
    
    // Add each remaining character as a piece
    for (int i = 0; i < remaining.length; i++) {
        textPieces.add(remaining[i]);
    }

    // Now wrap in PuzzlePiece objects, giving them unique IDs in case of duplicates
     _sourcePieces = textPieces.asMap().entries.map((e) => PuzzlePiece(id: e.key, text: e.value)).toList();
    
    // Shuffle source
    _sourcePieces.shuffle();

    // Init empty answers
    _answerSlots = List.filled(textPieces.length, null);

    _tts.speak(_targetWord);
  }

  void _onSourcePieceTap(PuzzlePiece piece) {
    if (_isSuccess) return;
    
    // Find first empty slot
    int emptyIndex = _answerSlots.indexWhere((s) => s == null);
    if (emptyIndex != -1) {
      setState(() {
        _sourcePieces.remove(piece);
        _answerSlots[emptyIndex] = piece;
      });
      // Removed: _tts.speak(piece.text); - Audio now only plays on success
      _checkWinCondition();
    }
  }

  void _onAnswerSlotTap(int index) {
    if (_isSuccess) return;
    
    if (_answerSlots[index] != null) {
      setState(() {
        final piece = _answerSlots[index]!;
        _answerSlots[index] = null;
        _sourcePieces.add(piece);
      });
    }
  }

  void _checkWinCondition() {
    // Check if slots are full
    if (_answerSlots.contains(null)) return;

    // Check if correct order
    String assembled = _answerSlots.map((p) => p!.text).join();
    if (assembled.toLowerCase() == _targetWord.toLowerCase()) {
      _handleWin();
    } else {
      // Incorrect! Shake or clear
      _tts.speak("Thử lại nhé!");
      // Simple clear for now
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_isSuccess) {
          setState(() {
            _sourcePieces.addAll(_answerSlots.whereType<PuzzlePiece>());
            _answerSlots = List.filled(_answerSlots.length, null);
            _sourcePieces.shuffle(); // Reshuffle for fun
          });
        }
      });
    }
  }

  Future<void> _handleWin() async {
    final decomp = decomposeVietnameseSyllable(_targetWord);
    final ttsTokens = decomp.ttsString.split(' ');
    final displayTokens = decomp.spellString.split(' ');
    
    setState(() {
      _isSuccess = true;
      _activeSpellingIndex = null;
      _spellingDisplayTokens = displayTokens;
    });
    
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      
      for (int i = 0; i < ttsTokens.length; i++) {
        if (!mounted) return;
        
        setState(() => _activeSpellingIndex = i);
        
        await _tts.speak(ttsTokens[i]);
        // Duration based on token length
        await Future.delayed(Duration(milliseconds: ttsTokens[i].length > 5 ? 900 : 700));
      }
      
      setState(() => _activeSpellingIndex = null);
      
    } catch (e) {
      debugPrint("Spelling TTS Error: $e");
    }

    _celebrationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() => _loadNewWord());
        }
      });
    });
  }

  String _getEmojiForWord(String word) {
    final lowerWord = word.toLowerCase();
    const map = {
      'mèo': '🐱', 'chó': '🐶', 'gà': '🐔', 'lợn': '🐷', 'bò': '🐮',
      'vịt': '🦆', 'ếch': '🐸', 'cá': '🐟', 'tôm': '🦐', 'cua': '🦀',
      'ngựa': '🐴', 'voi': '🐘', 'khỉ': '🐵', 'hổ': '🐯', 'táo': '🍎', 
      'chuối': '🍌', 'cam': '🍊', 'xoài': '🥭', 'nho': '🍇', 'bánh': '🍰', 
      'cơm': '🍚', 'nước': '💧', 'sao': '⭐', 'mưa': '🌧️', 'mây': '☁️',
      'hoa': '🌸', 'cây': '🌳', 'nhà': '🏠', 'xe': '🚗',
    };
    return map[lowerWord] ?? '✨';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                // Left: Word building section (Answer Slots + Source Pieces)
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      // Answer Slots (Top of the Left section)
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 8, 8, 8),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_answerSlots.length, (index) {
                                  final piece = _answerSlots[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: GestureDetector(
                                      onTap: () => _onAnswerSlotTap(index),
                                      child: Container(
                                        width: 65,
                                        height: 65,
                                        decoration: BoxDecoration(
                                          color: piece != null ? colorScheme.secondary : colorScheme.surfaceContainer,
                                          borderRadius: BorderRadius.circular(16),
                                          border: piece == null ? Border.all(color: colorScheme.outlineVariant, width: 2, style: BorderStyle.solid) : null,
                                          boxShadow: piece != null 
                                            ? [BoxShadow(color: colorScheme.secondary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))]
                                            : null,
                                        ),
                                        child: piece != null
                                          ? Center(
                                              child: Text(
                                                piece.text,
                                                style: theme.textTheme.headlineMedium?.copyWith(
                                                  color: colorScheme.onSecondary,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          : null,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Source Pieces (Bottom of the Left section)
                      Expanded(
                        flex: 4, // Increased flex to give more room for many pieces
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 4, 8, 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3), width: 1.5),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                                    child: Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      alignment: WrapAlignment.center,
                                      children: _isSuccess 
                                        ? _spellingDisplayTokens.asMap().entries.map((e) => _SpellingSticker(
                                            text: e.value, 
                                            isActive: _activeSpellingIndex == e.key,
                                            color: [
                                              const Color(0xFFFFE0E0),
                                              const Color(0xFFE0FFE0),
                                              const Color(0xFFE0E0FF),
                                              const Color(0xFFFFF6E0),
                                              const Color(0xFFF0E0FF),
                                            ][e.key % 5],
                                          )).toList()
                                        : _sourcePieces.map((piece) {
                                        return GestureDetector(
                                          onTap: () => _onSourcePieceTap(piece),
                                          child: Container(
                                            width: 65,
                                            height: 65,
                                            decoration: BoxDecoration(
                                              color: colorScheme.tertiaryContainer,
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colorScheme.onSurface.withOpacity(0.08),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4)
                                                )
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                piece.text,
                                                style: theme.textTheme.headlineMedium?.copyWith(
                                                  color: colorScheme.onTertiaryContainer,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              );
                            }
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Emoji & Listen Button
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.only(right: 16), // A little space on the right side
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ScaleTransition(
                          scale: _celebrationScale,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(35),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: colorScheme.primary.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 20)),
                                  ],
                                ),
                                child: Text(
                                  _getEmojiForWord(_targetWord),
                                  style: const TextStyle(fontSize: 120),
                                ),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: () => _tts.speak(_targetWord),
                                icon: const Icon(Icons.volume_up_rounded, size: 32),
                                label: const Text("Nghe", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.secondaryContainer,
                                  foregroundColor: colorScheme.onSecondaryContainer,
                                  minimumSize: const Size(200, 70),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  elevation: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Back Button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton.filled(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface,
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

class PuzzlePiece {
  final int id;
  final String text;

  PuzzlePiece({required this.id, required this.text});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PuzzlePiece && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class _SpellingSticker extends StatefulWidget {
  final String text;
  final bool isActive;
  final Color color;

  const _SpellingSticker({required this.text, required this.isActive, required this.color});

  @override
  State<_SpellingSticker> createState() => _SpellingStickerState();
}

class _SpellingStickerState extends State<_SpellingSticker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_SpellingSticker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (widget.isActive ? Colors.orange : Colors.black).withOpacity(0.1),
              blurRadius: widget.isActive ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: widget.isActive ? Border.all(color: Colors.orangeAccent, width: 3) : null,
        ),
        child: Text(
          widget.text,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
