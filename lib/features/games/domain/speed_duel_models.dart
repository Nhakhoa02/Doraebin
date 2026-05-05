import 'package:flutter/material.dart';

// --- Enums ---

enum DuelMode { recognize, read }

enum GamePhase { setup, loading, countdown, playing, paused, roundResult, finished }

// --- Data Classes ---

class BotInfo {
  final String name;
  final String avatar;
  final double speedFactor;
  final Color color;

  const BotInfo({
    required this.name,
    required this.avatar,
    required this.speedFactor,
    required this.color,
  });
}

/// Immutable snapshot of the game state, rebuilt on every change.
class DuelGameState {
  final GamePhase phase;
  final int setupStep;

  // Config
  final DuelMode mode;
  final double difficulty;
  final List<BotInfo> selectedBots;

  // Scores
  final int kidScore;
  final Map<String, int> botScores;

  // Round
  final int currentRound;
  final int totalRounds;
  final String? targetWord;
  final List<String> options;
  final List<String> roundWinners; // List of winners for this round
  final String gameMessage;

  // Countdown
  final int countdownValue;

  // Mic
  final bool isListening;
  final String recognizedWords;
  final int timeRemainingSeconds; // For read mode countdown (0 = no timer)

  const DuelGameState({
    this.phase = GamePhase.setup,
    this.setupStep = 0,
    this.mode = DuelMode.recognize,
    this.difficulty = 0.5,
    this.selectedBots = const [],
    this.kidScore = 0,
    this.botScores = const {},
    this.currentRound = 0,
    this.totalRounds = 10,
    this.targetWord,
    this.options = const [],
    this.gameMessage = "",
    this.countdownValue = 3,
    this.isListening = false,
    this.recognizedWords = "",
    this.timeRemainingSeconds = 0,
    this.roundWinners = const [],
  });

  DuelGameState copyWith({
    GamePhase? phase,
    int? setupStep,
    DuelMode? mode,
    double? difficulty,
    List<BotInfo>? selectedBots,
    int? kidScore,
    Map<String, int>? botScores,
    int? currentRound,
    int? totalRounds,
    String? targetWord,
    List<String>? options,
    String? gameMessage,
    int? countdownValue,
    bool? isListening,
    String? recognizedWords,
    int? timeRemainingSeconds,
    List<String>? roundWinners,
  }) {
    return DuelGameState(
      phase: phase ?? this.phase,
      setupStep: setupStep ?? this.setupStep,
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      selectedBots: selectedBots ?? this.selectedBots,
      kidScore: kidScore ?? this.kidScore,
      botScores: botScores ?? this.botScores,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      targetWord: targetWord ?? this.targetWord,
      options: options ?? this.options,
      roundWinners: roundWinners ?? this.roundWinners,
      gameMessage: gameMessage ?? this.gameMessage,
      countdownValue: countdownValue ?? this.countdownValue,
      isListening: isListening ?? this.isListening,
      recognizedWords: recognizedWords ?? this.recognizedWords,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
    );
  }

  /// Who's in the lead?
  String get leaderName {
    String leader = "Bé";
    int topScore = kidScore;
    for (final entry in botScores.entries) {
      if (entry.value > topScore) {
        topScore = entry.value;
        leader = entry.key;
      }
    }
    return leader;
  }

  int get leaderScore {
    int topScore = kidScore;
    for (final entry in botScores.entries) {
      if (entry.value > topScore) {
        topScore = entry.value;
      }
    }
    return topScore;
  }

  bool get isKidWinning => kidScore >= leaderScore && kidScore > 0;
}
