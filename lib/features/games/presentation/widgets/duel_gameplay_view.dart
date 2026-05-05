import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/speed_duel_models.dart';

class DuelGameplayView extends StatelessWidget {
  final DuelGameState state;
  final Function(String) onOptionTap;
  final VoidCallback onToggleMic;
  final VoidCallback onResume;
  final VoidCallback onRepeatWord;
  final VoidCallback onReplay;
  final VoidCallback onBackToMenu;

  const DuelGameplayView({
    super.key,
    required this.state,
    required this.onOptionTap,
    required this.onToggleMic,
    required this.onResume,
    required this.onRepeatWord,
    required this.onReplay,
    required this.onBackToMenu,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state.phase) {
      GamePhase.loading => _buildLoading(context),
      GamePhase.countdown => _buildCountdown(context),
      GamePhase.paused => _buildPaused(context),
      GamePhase.finished => _buildFinished(context),
      GamePhase.playing || GamePhase.roundResult => _buildPlaying(context),
      _ => const SizedBox.shrink(),
    };
  }

  // ─────────────────────────────────────────────
  // Loading
  // ─────────────────────────────────────────────
  Widget _buildLoading(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Đang chuẩn bị...",
            style: GoogleFonts.handlee(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Chờ một chút xíu thôi nhé!",
            style: GoogleFonts.inter(
              fontSize: 16,
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Countdown
  // ─────────────────────────────────────────────

  Widget _buildCountdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: Text(
          state.countdownValue > 0 ? "${state.countdownValue}" : "BẮT ĐẦU!",
          key: ValueKey(state.countdownValue),
          style: GoogleFonts.inter(
            fontSize: state.countdownValue > 0 ? 120 : 60,
            fontWeight: FontWeight.w900,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Paused
  // ─────────────────────────────────────────────

  Widget _buildPaused(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pause_circle_filled, size: 64, color: colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              "ĐANG TẠM DỪNG",
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Lượt ${state.currentRound}/${state.totalRounds}",
              style: TextStyle(fontSize: 16, color: colorScheme.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text("TIẾP TỤC"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Finished
  // ─────────────────────────────────────────────

  Widget _buildFinished(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isKidWinner = state.kidScore >= state.leaderScore;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isKidWinner ? "🏆" : "😊",
              style: const TextStyle(fontSize: 64), // Reduced from 72
            ),
            const SizedBox(height: 12),
            Text(
              state.gameMessage,
              style: GoogleFonts.inter(
                fontSize: 24, // Reduced from 28
                fontWeight: FontWeight.bold,
                color: isKidWinner ? Colors.amber.shade700 : colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Scoreboard
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Wrap( // Changed from Row to Wrap to handle horizontal overflow
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  _finalScore("👶 Bé", state.kidScore, Colors.blue),
                  ...state.selectedBots.map((b) => _finalScore(
                        "${b.avatar} ${b.name}",
                        state.botScores[b.name] ?? 0,
                        b.color,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onBackToMenu,
                  icon: const Icon(Icons.home_rounded),
                  label: const Text("Về Menu"),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text("Chơi Lại"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _finalScore(String label, int score, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$score",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Playing / Round Result
  // ─────────────────────────────────────────────

  Widget _buildPlaying(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFinalResult = state.phase == GamePhase.roundResult && state.roundWinners.contains("Bé");
    final isPractice = state.phase == GamePhase.roundResult && !state.roundWinners.contains("Bé");

    return Column(
      children: [
        // Game message banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: (isFinalResult || isPractice)
                ? (state.roundWinners.contains("Bé")
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            state.gameMessage,
            style: GoogleFonts.handlee(
              fontSize: 20,
              color: (isFinalResult || isPractice)
                  ? (state.roundWinners.contains("Bé") ? Colors.green.shade700 : Colors.orange.shade800)
                  : colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: IgnorePointer(
            ignoring: isFinalResult, // Disable taps only when round is officially over
            child: AnimatedOpacity(
              opacity: isFinalResult ? 0.6 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: state.mode == DuelMode.recognize
                  ? _buildRecognizeGrid(colorScheme)
                  : _buildReadZone(colorScheme),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Recognize mode ───

  Widget _buildRecognizeGrid(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Repeat button
          TextButton.icon(
            onPressed: onRepeatWord,
            icon: const Icon(Icons.volume_up_rounded, size: 20),
            label: const Text("Nghe lại", style: TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _answerButton(state.options.isNotEmpty ? state.options[0] : "", colorScheme)),
                          const SizedBox(width: 16),
                          Expanded(child: _answerButton(state.options.length > 1 ? state.options[1] : "", colorScheme)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _answerButton(state.options.length > 2 ? state.options[2] : "", colorScheme)),
                          const SizedBox(width: 16),
                          Expanded(child: _answerButton(state.options.length > 3 ? state.options[3] : "", colorScheme)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _answerButton(String text, ColorScheme colorScheme) {
    if (text.isEmpty) return const SizedBox.shrink();

    final isCorrect = state.phase == GamePhase.roundResult && text == state.targetWord;
    final isWrong = state.phase == GamePhase.roundResult && text != state.targetWord;

    return ElevatedButton(
      onPressed: () => onOptionTap(text),
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: isCorrect
            ? Colors.green.shade100
            : isWrong
                ? Colors.red.shade50
                : Colors.white,
        foregroundColor: isCorrect
            ? Colors.green.shade900
            : isWrong
                ? Colors.red.shade900
                : colorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isCorrect
                ? Colors.green
                : isWrong
                    ? Colors.red
                    : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ─── Read mode ───

  Widget _buildReadZone(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          // Left: word card
          Expanded(
            flex: 3,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20),
                  ],
                ),
                child: FittedBox(
                  child: Text(
                    state.targetWord ?? "",
                    style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right: mic controls
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mic button with countdown
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (state.phase == GamePhase.playing && state.roundWinners.isEmpty)
                        SizedBox(
                          width: 84,
                          height: 84,
                          child: CircularProgressIndicator(
                            value: state.timeRemainingSeconds / 10,
                            strokeWidth: 6,
                            color: state.timeRemainingSeconds <= 3 ? Colors.red : Colors.orange,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      GestureDetector(
                        onTap: onToggleMic,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: state.isListening ? Colors.red : colorScheme.primary,
                            boxShadow: state.isListening
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                          ),
                          child: Icon(
                            state.isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.isListening ? "Đang lắng nghe..." : "Chạm để đọc",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: state.isListening ? Colors.red : colorScheme.onSurface,
                    ),
                  ),
                  if (state.recognizedWords.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "\"${state.recognizedWords}\"",
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
