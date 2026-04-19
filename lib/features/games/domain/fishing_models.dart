import 'package:flutter/material.dart';

enum FishingPhase {
  playing,
  rechargeTask, // Running out of ammo
  evolutionTask, // Leveling up the gun
  result
}

/// The type of quiz in the evolution trial
enum QuizType { recognize, read }

class FishItem {
  final String id;
  final String emoji;
  final Offset position;
  final double speed;
  final bool isMovingRight;
  final double width;
  final double height;
  final int value; // Coins awarded
  final int hp;
  final String? word; // For special "Word Fish" or boss fish

  const FishItem({
    required this.id,
    required this.emoji,
    required this.position,
    required this.speed,
    this.isMovingRight = true,
    this.width = 60,
    this.height = 40,
    this.value = 10,
    this.hp = 1,
    this.word,
  });

  FishItem copyWith({
    Offset? position,
    int? hp,
  }) {
    return FishItem(
      id: id,
      emoji: emoji,
      position: position ?? this.position,
      speed: speed,
      isMovingRight: isMovingRight,
      width: width,
      height: height,
      value: value,
      hp: hp ?? this.hp,
      word: word,
    );
  }
}

class Projectile {
  final Offset position;
  final Offset velocity;
  final int level;
  final double radius;

  const Projectile({
    required this.position,
    required this.velocity,
    required this.level,
    this.radius = 20,
  });

  Projectile copyWith({Offset? position}) {
    return Projectile(
      position: position ?? this.position,
      velocity: velocity,
      level: level,
      radius: radius,
    );
  }
}

class FishingGameState {
  final FishingPhase phase;
  final int score;
  final int coins;
  final int ammo;
  final int cannonLevel;
  
  final List<FishItem> activeFish;
  final List<Projectile> activeProjectiles;

  // Evolution Trial state
  final int upgradeStreak; // 0 to 3
  final String? currentTaskWord;
  final QuizType currentTaskType;
  final List<String> taskOptions;

  // Mic state for reading tasks
  final bool isListening;
  final String recognizedWords;

  const FishingGameState({
    this.phase = FishingPhase.playing,
    this.score = 0,
    this.coins = 0,
    this.ammo = 50,
    this.cannonLevel = 1,
    this.activeFish = const [],
    this.activeProjectiles = const [],
    this.upgradeStreak = 0,
    this.currentTaskWord,
    this.currentTaskType = QuizType.recognize,
    this.taskOptions = const [],
    this.isListening = false,
    this.recognizedWords = "",
  });

  FishingGameState copyWith({
    FishingPhase? phase,
    int? score,
    int? coins,
    int? ammo,
    int? cannonLevel,
    List<FishItem>? activeFish,
    List<Projectile>? activeProjectiles,
    int? upgradeStreak,
    String? currentTaskWord,
    QuizType? currentTaskType,
    List<String>? taskOptions,
    bool? isListening,
    String? recognizedWords,
  }) {
    return FishingGameState(
      phase: phase ?? this.phase,
      score: score ?? this.score,
      coins: coins ?? this.coins,
      ammo: ammo ?? this.ammo,
      cannonLevel: cannonLevel ?? this.cannonLevel,
      activeFish: activeFish ?? this.activeFish,
      activeProjectiles: activeProjectiles ?? this.activeProjectiles,
      upgradeStreak: upgradeStreak ?? this.upgradeStreak,
      currentTaskWord: currentTaskWord ?? this.currentTaskWord,
      currentTaskType: currentTaskType ?? this.currentTaskType,
      taskOptions: taskOptions ?? this.taskOptions,
      isListening: isListening ?? this.isListening,
      recognizedWords: recognizedWords ?? this.recognizedWords,
    );
  }
}
