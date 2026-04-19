import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../domain/speed_duel_models.dart';
import '../domain/speed_duel_controller.dart';
import 'widgets/duel_lobby_view.dart';
import 'widgets/duel_gameplay_view.dart';

class SpeedDuelScreen extends StatefulWidget {
  const SpeedDuelScreen({super.key});

  @override
  State<SpeedDuelScreen> createState() => _SpeedDuelScreenState();
}

class _SpeedDuelScreenState extends State<SpeedDuelScreen> {
  late final SpeedDuelController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SpeedDuelController(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DuelGameState get _s => _controller.state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: NetworkImage(
              "https://img.freepik.com/free-vector/hand-drawn-childish-background-with-clouds-stars_23-2148906362.jpg",
            ),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
          color: colorScheme.surface,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(colorScheme),
              Expanded(child: _buildBody(colorScheme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_s.phase == GamePhase.setup) {
      return DuelLobbyView(
        setupStep: _s.setupStep,
        selectedMode: _s.mode,
        difficulty: _s.difficulty,
        allBots: _controller.allBots,
        selectedBots: _s.selectedBots,
        onModeSelected: _controller.selectMode,
        onDifficultySelected: _controller.selectDifficulty,
        onBotToggled: _controller.toggleBot,
        onPrevStep: _controller.prevStep,
        onNextStep: () async {
          final error = await _controller.startGame();
          if (error != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error)),
            );
          }
        },
      );
    }

    return DuelGameplayView(
      state: _s,
      onOptionTap: _controller.onOptionTap,
      onToggleMic: _controller.toggleMic,
      onResume: _controller.resume,
      onRepeatWord: _controller.repeatWord,
      onReplay: _controller.replay,
      onBackToMenu: _controller.backToSetup,
    );
  }

  // ─────────────────────────────────────────────
  // Top bar
  // ─────────────────────────────────────────────

  Widget _buildTopBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildBackButton(colorScheme),
          const SizedBox(width: 8),
          if (_s.phase == GamePhase.setup) ...[
            _buildSetupTitle(colorScheme),
            const Spacer(),
            _buildStepDots(colorScheme),
          ],
          if (_s.phase != GamePhase.setup) ...[
            const Spacer(),
            // Round indicator
            if (_s.phase == GamePhase.playing || _s.phase == GamePhase.roundResult)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_s.currentRound}/${_s.totalRounds}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            _scoreBadge("Bé", "👶", _s.kidScore, Colors.blue),
            const SizedBox(width: 6),
            ..._s.selectedBots.map((b) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _scoreBadge(b.name, b.avatar, _s.botScores[b.name] ?? 0, b.color),
                )),
            const SizedBox(width: 12),
            if (_s.phase == GamePhase.playing ||
                _s.phase == GamePhase.paused ||
                _s.phase == GamePhase.roundResult)
              _buildPauseButton(colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildBackButton(ColorScheme colorScheme) {
    return IconButton.filledTonal(
      onPressed: () {
        switch (_s.phase) {
          case GamePhase.playing:
          case GamePhase.roundResult:
            _controller.pause();
            break;
          case GamePhase.paused:
          case GamePhase.countdown:
          case GamePhase.finished:
            _controller.backToSetup();
            break;
          case GamePhase.setup:
            context.pop();
            break;
        }
      },
      icon: const Icon(Icons.close_rounded),
    );
  }

  Widget _buildSetupTitle(ColorScheme colorScheme) {
    final titles = ["1. Chọn Trò Chơi!", "2. Chọn Độ Khó!", "3. Chọn Đối Thủ!"];
    return Text(
      titles[_s.setupStep],
      style: GoogleFonts.handlee(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildStepDots(ColorScheme colorScheme) {
    return Row(
      children: List.generate(
        3,
        (i) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _s.setupStep == i ? colorScheme.primary : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildPauseButton(ColorScheme colorScheme) {
    final isPaused = _s.phase == GamePhase.paused;
    return IconButton.filledTonal(
      onPressed: isPaused ? _controller.resume : _controller.pause,
      icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
    );
  }

  Widget _scoreBadge(String name, String icon, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            "$score",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
