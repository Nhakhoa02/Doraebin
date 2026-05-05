import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/services/stt_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'fishing_models.dart';

class FishingController {
  FishingController({required this.onStateChanged});

  final VoidCallback onStateChanged;

  // --- Services ---
  final FlutterTts _tts = FlutterTts();
  final ISTTService _sttService = ISTTService.flutter();
  bool _speechAvailable = false;

  // --- State ---
  FishingGameState _state = const FishingGameState();
  FishingGameState get state => _state;

  // --- Game Loop ---
  Timer? _gameLoopTimer;
  final _rand = Random();
  DateTime? _lastFrameTime;

  // --- Constants ---
  static const int _ammoRechargeAmount = 50;
  static const int _evolutionStreakGoal = 3;

  final List<String> _vocabulary = [
    'Con cá', 'Quả táo', 'Con mèo', 'Cái nhà', 'Trường học',
    'Bánh chưng', 'Ông bà', 'Hoa hồng', 'Con gà', 'Em bé',
    'Mặt trời', 'Nước uống', 'Đồ chơi', 'Quả bóng', 'Cái ghế',
  ];

  final List<String> _fishEmojis = ['🐟', '🐠', '🐡', '🐙', '🦑', '🦐', '🦀'];

  // ─────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────

  Future<void> init() async {
    await _tts.setLanguage("vi-VN");
    await _tts.setPitch(1.1);
    await _tts.setSpeechRate(0.5);

    try {
      _speechAvailable = await _sttService.initialize();
    } catch (e) {
      _speechAvailable = false;
    }
  }

  void startGame() {
    _state = const FishingGameState();
    _lastFrameTime = DateTime.now();
    _gameLoopTimer?.cancel();
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      _update();
    });
  }

  void dispose() {
    _gameLoopTimer?.cancel();
    _tts.stop();
    _sttService.dispose();
  }

  void _emit(FishingGameState newState) {
    _state = newState;
    onStateChanged();
  }

  // ─────────────────────────────────────────────
  // Game Loop & Physics
  // ─────────────────────────────────────────────

  void _update() {
    if (_state.phase != FishingPhase.playing) return;

    final now = DateTime.now();
    final dt = now.difference(_lastFrameTime!).inMilliseconds / 1000.0;
    _lastFrameTime = now;

    // 1. Move Projectiles
    final newProjectiles = <Projectile>[];
    for (var p in _state.activeProjectiles) {
      final nextPos = p.position + p.velocity * dt;
      // Keep if on screen (assume 1000x1000 virtual space for logic, or relative %)
      if (nextPos.dy > -100 && nextPos.dx > -100 && nextPos.dx < 1100) {
        newProjectiles.add(p.copyWith(position: nextPos));
      }
    }

    // 2. Move Fish & Handle Collisions
    final newFish = <FishItem>[];
    int scoreGain = 0;
    int coinGain = 0;
    final projectilesToRemove = <int>[];

    for (var fish in _state.activeFish) {
      var nextX = fish.position.dx + (fish.isMovingRight ? 1 : -1) * fish.speed * dt;
      
      // Wrap around
      if (fish.isMovingRight && nextX > 1100) nextX = -100;
      if (!fish.isMovingRight && nextX < -100) nextX = 1100;

      var currentFish = fish.copyWith(position: Offset(nextX, fish.position.dy));
      bool hit = false;

      for (int i = 0; i < newProjectiles.length; i++) {
        final p = newProjectiles[i];
        final dist = (p.position - currentFish.position).distance;
        if (dist < (p.radius + 30)) { // Simple circle collision
          hit = true;
          projectilesToRemove.add(i);
          break;
        }
      }

      if (hit) {
        final newHp = currentFish.hp - 1;
        if (newHp <= 0) {
          scoreGain += 10;
          coinGain += currentFish.value;
          // Fish is caught!
        } else {
          newFish.add(currentFish.copyWith(hp: newHp));
        }
      } else {
        newFish.add(currentFish);
      }
    }

    // Remove consumed projectiles
    for (var idx in projectilesToRemove.reversed.toSet()) {
      if (idx < newProjectiles.length) newProjectiles.removeAt(idx);
    }

    // 3. Spawn Fish if needed
    if (newFish.length < 5 && _rand.nextDouble() < 0.05) {
      newFish.add(_spawnRandomFish());
    }

    _emit(_state.copyWith(
      activeProjectiles: newProjectiles,
      activeFish: newFish,
      score: _state.score + scoreGain,
      coins: _state.coins + coinGain,
    ));
  }

  FishItem _spawnRandomFish() {
    final isRight = _rand.nextBool();
    return FishItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      emoji: _fishEmojis[_rand.nextInt(_fishEmojis.length)],
      position: Offset(isRight ? -50 : 1050, _rand.nextDouble() * 400 + 100),
      speed: _rand.nextDouble() * 100 + 50,
      isMovingRight: isRight,
      value: _rand.nextInt(10) + 5,
    );
  }

  // ─────────────────────────────────────────────
  // User Actions
  // ─────────────────────────────────────────────

  void shoot(Offset target) {
    if (_state.phase != FishingPhase.playing) return;
    if (_state.ammo <= 0) {
      _startRechargeTask();
      return;
    }

    // Cannon is at bottom center (assume 0.5, 1.0 in relative coords)
    const startPos = Offset(500, 900);
    final direction = (target - startPos);
    final velocity = direction / direction.distance * 600;

    final p = Projectile(
      position: startPos,
      velocity: velocity,
      level: _state.cannonLevel,
      radius: 20.0 + (_state.cannonLevel * 5),
    );

    _emit(_state.copyWith(
      activeProjectiles: [..._state.activeProjectiles, p],
      ammo: _state.ammo - 1,
    ));

    if (_state.ammo - 1 <= 0) {
      _startRechargeTask();
    }
  }

  void tryUpgrade() {
    if (_state.phase != FishingPhase.playing) return;
    
    final cost = _state.cannonLevel * 100;
    if (_state.coins >= cost) {
      _startEvolutionTrial();
    }
  }

  // ─────────────────────────────────────────────
  // Learning Tasks
  // ─────────────────────────────────────────────

  void _startRechargeTask() {
    final word = _vocabulary[_rand.nextInt(_vocabulary.length)];
    _emit(_state.copyWith(
      phase: FishingPhase.rechargeTask,
      currentTaskWord: word,
      recognizedWords: "",
    ));
    _tts.speak("Đọc to chữ này để nạp đạn nhé!");
    Future.delayed(const Duration(milliseconds: 1500), () => _startMic());
  }

  void _startEvolutionTrial() {
    _emit(_state.copyWith(
      phase: FishingPhase.evolutionTask,
      upgradeStreak: 0,
    ));
    _nextEvolutionQuiz();
  }

  void _nextEvolutionQuiz() {
    final word = _vocabulary[_rand.nextInt(_vocabulary.length)];
    final type = _rand.nextBool() ? QuizType.read : QuizType.recognize;
    
    List<String> options = [];
    if (type == QuizType.recognize) {
      options = [word];
      while (options.length < 3) {
        final alt = _vocabulary[_rand.nextInt(_vocabulary.length)];
        if (!options.contains(alt)) options.add(alt);
      }
      options.shuffle();
      _tts.speak("Tìm chữ $word");
    } else {
      _tts.speak("Đọc chữ này lên nào!");
    }

    _emit(_state.copyWith(
      currentTaskWord: word,
      currentTaskType: type,
      taskOptions: options,
      recognizedWords: "",
    ));

    if (type == QuizType.read) {
      Future.delayed(const Duration(milliseconds: 1500), () => _startMic());
    }
  }

  void onOptionSelected(String word) {
    if (_state.phase != FishingPhase.evolutionTask) return;
    if (_state.currentTaskType != QuizType.recognize) return;

    if (word == _state.currentTaskWord) {
      _onTaskSuccess();
    } else {
      _onTaskFail();
    }
  }

  void _onTaskSuccess() {
    if (_state.phase == FishingPhase.rechargeTask) {
      _tts.speak("Giỏi quá! Đã nạp thêm đạn.");
      _emit(_state.copyWith(
        phase: FishingPhase.playing,
        ammo: _state.ammo + _ammoRechargeAmount,
      ));
      _lastFrameTime = DateTime.now(); // Reset delta
    } else if (_state.phase == FishingPhase.evolutionTask) {
      final nextStreak = _state.upgradeStreak + 1;
      if (nextStreak >= _evolutionStreakGoal) {
        final cost = _state.cannonLevel * 100;
        _tts.speak("Tuyệt vời! Súng đã được nâng cấp!");
        _emit(_state.copyWith(
          phase: FishingPhase.playing,
          cannonLevel: _state.cannonLevel + 1,
          coins: _state.coins - cost,
          upgradeStreak: 0,
        ));
        _lastFrameTime = DateTime.now();
      } else {
        _emit(_state.copyWith(upgradeStreak: nextStreak));
        _tts.speak("Đúng rồi! Còn ${3 - nextStreak} câu nữa.");
        Future.delayed(const Duration(milliseconds: 1000), () => _nextEvolutionQuiz());
      }
    }
  }

  void _onTaskFail() {
    _tts.speak("Sai rồi, thử lại nhé!");
    if (_state.phase == FishingPhase.evolutionTask) {
      _emit(_state.copyWith(upgradeStreak: 0));
      Future.delayed(const Duration(milliseconds: 1000), () => _nextEvolutionQuiz());
    }
  }

  // --- Mic ---

  Future<void> _startMic() async {
    if (!_speechAvailable || _state.isListening) return;

    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    _emit(_state.copyWith(isListening: true, recognizedWords: ""));
    await _sttService.listen(
      onResult: (words, isFinal) {
        _emit(_state.copyWith(recognizedWords: words));
        
        if (_state.currentTaskWord != null && 
            words.toLowerCase().contains(_state.currentTaskWord!.toLowerCase())) {
          _sttService.stop();
          _onTaskSuccess();
        }
      },
      onStatus: (status) {
        if (status == 'notListening' && _state.isListening) {
          _emit(_state.copyWith(isListening: false));
        }
      },
    );
  }
}
