import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/services/stt_service.dart';
import '../../../core/data/database_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'speed_duel_models.dart';

/// Centralized game controller that owns ALL game logic, timers, and mic lifecycle.
///
/// The UI subscribes to [stateNotifier] and rebuilds reactively.
/// This eliminates race conditions by funneling every state change through
/// a single [_emit] method and serializing mic start/stop behind [_micLock].
class SpeedDuelController {
  SpeedDuelController({required this.onStateChanged});

  // --- External callback ---
  final VoidCallback onStateChanged;

  // --- Services ---
  final FlutterTts _tts = FlutterTts();
  final ISTTService _sttService = ISTTService.sherpa(type: 4, online: false); // Switch to .sherpa() to use Sherpa ONNX
  final DatabaseService _dbService = DatabaseService();
  bool _speechAvailable = false;

  // --- State ---
  DuelGameState _state = const DuelGameState();
  DuelGameState get state => _state;

  // --- Timers ---
  Timer? _countdownTimer;
  final List<Timer> _botTimers = [];  // Per-bot timers (recognize mode)
  Timer? _kidTimeoutTimer;            // Kid timeout (read mode)
  Timer? _tickTimer;                  // 1s tick for visual countdown
  Timer? _roundResultTimer;

  // --- Mic lock to prevent overlapping start/stop ---
  bool _micBusy = false;

  // --- Vocabulary pool ---
  List<String> _vocabulary = [];

  // --- Bot roster ---
  final List<BotInfo> allBots = const [
    BotInfo(name: "Nobita", avatar: "🤓", speedFactor: 0.6, color: Colors.green),
    BotInfo(name: "Shizuka", avatar: "🎀", speedFactor: 1.0, color: Colors.pink),
    BotInfo(name: "Chaien", avatar: "🦍", speedFactor: 1.6, color: Colors.orange),
    BotInfo(name: "Suneo", avatar: "🦊", speedFactor: 1.3, color: Colors.blue),
  ];

  // ─────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────

  Future<void> init() async {
    await _tts.setLanguage("vi-VN");
    await _tts.setPitch(1.1);
    await _tts.setSpeechRate(0.5);

    // Initialize database and load vocabulary (excluding alphabet)
    await _dbService.init();
    final allWords = _dbService.getAllWords();
    _vocabulary = allWords
        .where((w) => w['category_id'] != 'alphabet')
        .map((w) => w['text'] as String)
        .toList();
    
    // Fallback if database is empty
    if (_vocabulary.isEmpty) {
      _vocabulary = ['Con cá', 'Quả táo', 'Con mèo', 'Cái nhà', 'Trường học'];
    }
  }

  Future<void> initSTT() async {
    try {
      _speechAvailable = await _sttService.initialize();
    } catch (e) {
      debugPrint("STT init failed: $e");
      _speechAvailable = false;
    }
  }

  void dispose() {
    _cancelAllTimers();
    _stopMicImmediate();
    _sttService.dispose();
    _tts.stop();
  }

  // ─────────────────────────────────────────────
  // State management
  // ─────────────────────────────────────────────

  void _emit(DuelGameState newState) {
    _state = newState;
    onStateChanged();
  }

  void _cancelAllTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    for (final t in _botTimers) { t.cancel(); }
    _botTimers.clear();
    _kidTimeoutTimer?.cancel();
    _kidTimeoutTimer = null;
    _tickTimer?.cancel();
    _tickTimer = null;
    _roundResultTimer?.cancel();
    _roundResultTimer = null;
  }

  // ─────────────────────────────────────────────
  // Setup flow
  // ─────────────────────────────────────────────

  void selectMode(DuelMode mode) {
    _emit(_state.copyWith(mode: mode));
    _tts.speak("Tiếp theo nhé!");
    Future.delayed(const Duration(milliseconds: 250), () {
      _emit(_state.copyWith(setupStep: 1));
    });
  }

  void selectDifficulty(double d) {
    _emit(_state.copyWith(difficulty: d));
    _tts.speak("Tiếp theo nhé!");
    Future.delayed(const Duration(milliseconds: 250), () {
      _emit(_state.copyWith(setupStep: 2));
    });
  }

  void toggleBot(BotInfo bot) {
    final bots = List<BotInfo>.from(_state.selectedBots);
    if (bots.contains(bot)) {
      bots.remove(bot);
    } else {
      bots.add(bot);
    }
    _emit(_state.copyWith(selectedBots: bots));
  }

  void prevStep() {
    if (_state.setupStep > 0) {
      _emit(_state.copyWith(setupStep: _state.setupStep - 1));
    }
  }

  /// Returns an error message if we can't start, null if OK.
  Future<String?> startGame() async {
    if (_state.selectedBots.isEmpty) {
      return "Hãy chọn ít nhất 1 đối thủ nhé!";
    }

    if (_state.mode == DuelMode.read) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        return "Cần quyền mic để chơi chế độ này nhé!";
      }
    }

    // Initialize STT (the laggy part) if in read mode
    if (_state.mode == DuelMode.read && !_speechAvailable) {
      _emit(_state.copyWith(
        phase: GamePhase.loading,
        gameMessage: "Bạn chờ xíu nha!...",
      ));
      
      // Add a tiny delay so the user sees the loading screen (prevents jarring transition)
      await Future.delayed(const Duration(milliseconds: 500));
      
      await initSTT();
      if (!_speechAvailable) {
        _emit(_state.copyWith(phase: GamePhase.setup));
        return "Không thể khởi động nhận giọng nói. Hãy thử lại!";
      }
    }

    // Reset scores
    final botScores = <String, int>{};
    for (final bot in _state.selectedBots) {
      botScores[bot.name] = 0;
    }

    _emit(_state.copyWith(
      phase: GamePhase.countdown,
      kidScore: 0,
      botScores: botScores,
      currentRound: 0,
      countdownValue: 3,
      gameMessage: "",
      recognizedWords: "",
    ));

    _runCountdown();
    return null;
  }

  // ─────────────────────────────────────────────
  // Countdown
  // ─────────────────────────────────────────────

  void _runCountdown() {
    _tts.speak("3");
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final val = _state.countdownValue - 1;
      if (val > 0) {
        _emit(_state.copyWith(countdownValue: val));
        _tts.speak("$val");
      } else {
        timer.cancel();
        _countdownTimer = null;
        _emit(_state.copyWith(
          countdownValue: 0,
          gameMessage: "Bắt đầu!",
        ));
        _tts.stop().then((_) => _tts.speak("Bắt đầu!"));
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          _emit(_state.copyWith(phase: GamePhase.playing));
          _startNewRound();
        });
      }
    });
  }

  // ─────────────────────────────────────────────
  // Round lifecycle
  // ─────────────────────────────────────────────

  void _startNewRound() {
    _cancelAllTimers();

    final round = _state.currentRound + 1;
    if (round > _state.totalRounds) {
      _finishGame();
      return;
    }

    final rand = Random();
    final target = _vocabulary[rand.nextInt(_vocabulary.length)];

    List<String> options = [];
    if (_state.mode == DuelMode.recognize) {
      options = [target];
      while (options.length < 4) {
        final extra = _vocabulary[rand.nextInt(_vocabulary.length)];
        if (!options.contains(extra)) options.add(extra);
      }
      options.shuffle();
    }

    _emit(_state.copyWith(
      phase: GamePhase.playing,
      currentRound: round,
      targetWord: target,
      options: options,
      roundWinners: [],
      recognizedWords: "",
      isListening: false,
      gameMessage: _state.mode == DuelMode.recognize
          ? "Tìm chữ! (lượt $round/${_state.totalRounds})"
          : "Đọc to lên! (lượt $round/${_state.totalRounds})",
    ));

    if (_state.mode == DuelMode.recognize) {
      _tts.stop().then((_) => _tts.speak(target));
    } else {
      // // For read mode: start mic after a brief delay
      // Future.delayed(const Duration(milliseconds: 500), () {
      //   if (_state.phase == GamePhase.playing && _state.roundWinners.isEmpty) {
      //     _startMic();
      //   }
      // });
    }

    _scheduleBotAnswer();
  }

  void _scheduleBotAnswer() {
    if (_state.phase != GamePhase.playing) return;

    // Clean up previous timers
    for (final t in _botTimers) { t.cancel(); }
    _botTimers.clear();
    _kidTimeoutTimer?.cancel();
    _kidTimeoutTimer = null;

    final bots = _state.selectedBots;
    if (bots.isEmpty) return;
    final rand = Random();

    if (_state.mode == DuelMode.recognize) {
      // ── RECOGNIZE MODE ──
      // Each bot gets its OWN randomized timer.
      // speedFactor makes them faster, difficulty shrinks the base window.
      // Large random range ensures different bots can win different rounds.
      for (final bot in bots) {
        // Base window: Easy=5s, Medium=3.5s, Hard=2s
        double baseDelay = 5000 - (_state.difficulty * 3000);
        // Scale by bot speed (higher speedFactor = shorter delay)
        double scaled = baseDelay / bot.speedFactor;
        // Add significant random jitter (±40% of base) so results vary
        int jitter = (scaled * 0.8).toInt();
        int finalDelay = scaled.toInt() + rand.nextInt(jitter.clamp(500, 4000));

          final timer = Timer(Duration(milliseconds: finalDelay), () {
            if (_state.phase == GamePhase.playing && _state.roundWinners.isEmpty) {
              _resolveRound(winnerNames: [bot.name], isKidWin: false);
            }
          });
        _botTimers.add(timer);
      }
    } else {
      // ── READ MODE ──
      // Kid has ~10 seconds to read the word aloud.
      // After timeout OR when kid reads correctly, each bot rolls a random chance to score.
      // This means multiple entities (Kid + any bots) can win in one round!

      // Start visual countdown
      _emit(_state.copyWith(timeRemainingSeconds: 10));
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final remaining = _state.timeRemainingSeconds - 1;
        if (remaining >= 0 && _state.phase == GamePhase.playing && _state.roundWinners.isEmpty) {
          _emit(_state.copyWith(timeRemainingSeconds: remaining));
        } else {
          timer.cancel();
        }
      });

      _kidTimeoutTimer = Timer(const Duration(seconds: 10), () {
        _tickTimer?.cancel();
        _tickTimer = null;
        if (_state.phase != GamePhase.playing || _state.roundWinners.isNotEmpty) return;

        // Kid failed to read in time — stop mic
        _stopMicImmediate();
        _tts.speak("Đáp án là ${_state.targetWord}!");
        
        // Roll for each bot independently
        final winners = _rollForBots();
        _resolveRound(winnerNames: winners, isKidWin: false);
      });
    }
  }

  /// ROLL FOR BOTS in Read Mode (Independent chances based on difficulty)
  List<String> _rollForBots() {
    final rand = Random();
    final winners = <String>[];
    for (final bot in _state.selectedBots) {
      // Chance = difficulty * speedFactor * 0.4
      double chance = _state.difficulty * bot.speedFactor * 0.4;
      if (rand.nextDouble() < chance) {
        winners.add(bot.name);
      }
    }
    return winners;
  }

  // ─────────────────────────────────────────────
  // Round resolution (single entry point for all wins)
  // ─────────────────────────────────────────────

  void _resolveRound({required List<String> winnerNames, required bool isKidWin}) {
    // Guard: only resolve once per round transitions
    if (_state.roundWinners.isNotEmpty || isKidWin && _state.roundWinners.contains("Bé")) return;
    if (_state.phase != GamePhase.playing) return;

    _cancelAllTimers();
    _stopMicImmediate();

    int newKidScore = _state.kidScore;
    final newBotScores = Map<String, int>.from(_state.botScores);
    final finalWinners = List<String>.from(winnerNames);

    if (isKidWin) {
      newKidScore++;
      if (!finalWinners.contains("Bé")) {
        finalWinners.add("Bé");
      }
    }

    for (final name in winnerNames) {
      if (name != "Bé") {
        newBotScores[name] = (newBotScores[name] ?? 0) + 1;
      }
    }

    String message;
    if (finalWinners.isEmpty) {
      message = "Không ai được điểm! 😅";
      _tts.speak("Đáp án là ${_state.targetWord}! Các bạn cố lên nhé!");
    } else if (finalWinners.length == 1) {
      final w = finalWinners.first;
      if (w == "Bé") {
        message = "Hoan hô! Bé thắng! 🎉";
        _tts.speak("Con giỏi lắm!");
      } else {
        message = "$w thắng rồi! 😢";
        _tts.speak("Đáp án là ${_state.targetWord}! $w thắng rồi!");
      }
    } else {
      if (finalWinners.contains("Bé")) {
        message = "Bé và ${finalWinners.where((n) => n != "Bé").join(", ")} đều thắng! 👏";
        _tts.speak("Bé giỏi quá, các bạn cũng giỏi nữa!");
      } else {
        message = "${finalWinners.join(", ")} đều thắng! 🤖";
        _tts.speak("Đáp án là ${_state.targetWord}! Cả nhà đều thắng!");
      }
    }

    _emit(_state.copyWith(
      phase: GamePhase.roundResult,
      roundWinners: finalWinners,
      kidScore: newKidScore,
      botScores: newBotScores,
      gameMessage: message,
      isListening: false,
    ));

    // Auto-advance if kid win
    if (isKidWin){
        _roundResultTimer = Timer(const Duration(seconds: 3), () {
        _roundResultTimer = null;
        if (_state.phase == GamePhase.roundResult) {
          _startNewRound();
        }
      });
    } else {
      // Let kids practice if they want and a next button to next round
      _roundResultTimer = null;
      
      if (_state.mode == DuelMode.read) {
        // Wait for current TTS (winner announcement) to finish before prompting for practice
        Future.delayed(const Duration(seconds: 4), () {
          if (_state.phase == GamePhase.roundResult && !_state.roundWinners.contains("Bé")) {
            _emit(_state.copyWith(
              gameMessage: "Nào, bé đọc lại từ này nhé! 🎤",
            ));
            // _startMic(); // Kid now clicks manually to practice
          }
        });
      } else {
        Future.delayed(const Duration(seconds: 3), () {
          if (_state.phase == GamePhase.roundResult) {
            _startNewRound();
          }
        });
      }
    }
    
  }

  void onOptionTap(String word) {
    if (_state.phase != GamePhase.playing || _state.roundWinners.isNotEmpty) return;
    if (_state.mode != DuelMode.recognize) return;

    if (word == _state.targetWord) {
      _resolveRound(winnerNames: [], isKidWin: true);
    } else {
      _tts.speak(word);
      _emit(_state.copyWith(gameMessage: "Chưa đúng ❌ Thử lại nhé!"));
    }
  }

  // ─────────────────────────────────────────────
  // Mic lifecycle (serialized to prevent overlaps)
  // ─────────────────────────────────────────────

  Future<void> _startMic() async {
    if (_micBusy) return;
    if (!_speechAvailable) return;
    
    // Allow listening in playing phase OR roundResult (for practice)
    if (_state.phase != GamePhase.playing && _state.phase != GamePhase.roundResult) return;
    
    // If we're in roundResult, only start if the kid hasn't won yet
    if (_state.phase == GamePhase.roundResult && _state.roundWinners.contains("Bé")) return;

    _micBusy = true;

    try {
      // Ensure stopped first
      await _sttService.stop();
      await Future.delayed(const Duration(milliseconds: 100));

      if ((_state.phase != GamePhase.playing && _state.phase != GamePhase.roundResult) ||
          (_state.phase == GamePhase.roundResult && _state.roundWinners.contains("Bé"))) {
        _micBusy = false;
        return;
      }

      _emit(_state.copyWith(isListening: true, recognizedWords: ""));

      await _sttService.listen(
        onResult: (words, isFinal) {
          // Guard for phase change
          if (_state.phase != GamePhase.playing && _state.phase != GamePhase.roundResult) {
            _stopMicImmediate();
            return;
          }
          
          if (_state.phase == GamePhase.roundResult && _state.roundWinners.contains("Bé")) {
            _stopMicImmediate();
            return;
          }

          _emit(_state.copyWith(recognizedWords: words));

          // NEW: Only handle final result after user stops (no real-time/VAD anymore)
          if (!isFinal) return;

          // Check if the kid read the word correctly
          // For final result, we can check if the entire transcript contains the target word
          // instead of just the last few words, but we'll stick to a similar logic if preferred.
          // However, contains() on the whole string is safer for post-recording.
          
          final transcript = words.toLowerCase();
          final target = _state.targetWord?.toLowerCase() ?? "";

          if (target.isNotEmpty && transcript.contains(target)) {
            if (_state.phase == GamePhase.playing) {
              // Kid won during regular play! Also roll for bots independently
              final botWinners = _rollForBots();
              _resolveRound(winnerNames: botWinners, isKidWin: true);
            } else {
              // Practice success in roundResult phase!
              _stopMicImmediate();
              _emit(_state.copyWith(
                gameMessage: "Tuyệt vời! Bé đã đọc đúng rồi! ✨",
                roundWinners: [..._state.roundWinners, "Bé"],
              ));
              _tts.speak("Đúng rồi! Con giỏi lắm!");
              
              // Move to next round after 3 seconds
              Future.delayed(const Duration(seconds: 3), () {
                if (_state.phase == GamePhase.roundResult) {
                  _startNewRound();
                }
              });
            }
          } else if (isFinal && _state.phase == GamePhase.roundResult && words.isNotEmpty) {
            // Wrong attempt during practice - give feedback
            _stopMicImmediate();
            _emit(_state.copyWith(gameMessage: "Chưa đúng rồi, nghe lại nhé! 👂"));
            _tts.speak(_state.targetWord!);
            
            // // RE-START MIC DISABLED: Kid now clicks manually
            // Future.delayed(const Duration(seconds: 2), () {
            //   if (_state.phase == GamePhase.roundResult && !_state.roundWinners.contains("Bé")) {
            //     _startMic();
            //   }
            // });
          }
        },
        onStatus: (status) {
          if (status == 'notListening' && _state.isListening) {
            _emit(_state.copyWith(isListening: false));
            // // Auto-restart DISABLED: Kid now clicks manually
            // if (_state.phase == GamePhase.playing && _state.roundWinners.isEmpty) {
            //   Future.delayed(const Duration(milliseconds: 400), () => _startMic());
            // }
          }
        },
      );
    } catch (e) {
      debugPrint("Mic start error: $e");
      _emit(_state.copyWith(isListening: false));
    } finally {
      _micBusy = false;
    }
  }

  void _stopMicImmediate() {
    try {
      _sttService.stop();
    } catch (_) {}
    if (_state.isListening) {
      _emit(_state.copyWith(isListening: false));
    }
  }

  /// Called when the user manually taps the mic button.
  Future<void> toggleMic() async {
    // Allow toggling in playing (if no winner yet) or roundResult (for practice)
    final canToggle = (_state.phase == GamePhase.playing && _state.roundWinners.isEmpty) ||
                     (_state.phase == GamePhase.roundResult && !_state.roundWinners.contains("Bé"));
    
    if (!canToggle) return;

    if (_state.isListening) {
      _stopMicImmediate();
    } else {
      await _startMic();
    }
  }

  // ─────────────────────────────────────────────
  // Pause / Resume
  // ─────────────────────────────────────────────

  void pause() {
    if (_state.phase != GamePhase.playing && _state.phase != GamePhase.roundResult) return;

    _cancelAllTimers();
    _stopMicImmediate();

    _emit(_state.copyWith(
      phase: GamePhase.paused,
      isListening: false,
    ));
  }

  void resume() {
    if (_state.phase != GamePhase.paused) return;

    _emit(_state.copyWith(
      phase: GamePhase.playing,
      gameMessage: _state.mode == DuelMode.recognize
          ? "Tìm chữ! (lượt ${_state.currentRound}/${_state.totalRounds})"
          : "Đọc to lên! (lượt ${_state.currentRound}/${_state.totalRounds})",
    ));

    // Only restart if the round hasn't been won yet
    if (_state.roundWinners.isEmpty) {
      _scheduleBotAnswer();
      // // Auto-start mic DISABLED on resume
      // if (_state.mode == DuelMode.read) {
      //   Future.delayed(const Duration(milliseconds: 300), () {
      //     if (_state.phase == GamePhase.playing) _startMic();
      //   });
      // }
    } else {
      // Round was won before pause — transition to next round
      _roundResultTimer = Timer(const Duration(seconds: 1), () {
        _startNewRound();
      });
    }
  }

  // ─────────────────────────────────────────────
  // Game end
  // ─────────────────────────────────────────────

  void _finishGame() {
    _cancelAllTimers();
    _stopMicImmediate();

    final isKidWinner = _state.isKidWinning;
    _emit(_state.copyWith(
      phase: GamePhase.finished,
      gameMessage: isKidWinner ? "CON THẮNG RỒI! 🏆" : "${_state.leaderName} thắng! 😊",
    ));

    _tts.speak(isKidWinner ? "Con giỏi lắm! Con thắng rồi!" : "${_state.leaderName} thắng rồi! Cố lên nhé!");
  }

  /// Go back to setup from finished/paused/countdown state.
  void backToSetup() {
    _cancelAllTimers();
    _stopMicImmediate();
    _emit(const DuelGameState()); // fresh setup state
  }

  /// Replay with the same settings.
  void replay() {
    _cancelAllTimers();
    _stopMicImmediate();

    final kept = DuelGameState(
      mode: _state.mode,
      difficulty: _state.difficulty,
      selectedBots: _state.selectedBots,
    );
    _emit(kept.copyWith(setupStep: 2)); // go back to bot select
  }

  /// Repeat TTS for the current target word.
  void repeatWord() {
    if (_state.targetWord != null) {
      // Stop the mic before speaking to avoid feedback
      _stopMicImmediate();
      _tts.speak(_state.targetWord!);
    }
  }
}
