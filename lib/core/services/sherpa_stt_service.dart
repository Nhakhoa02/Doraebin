import 'dart:async';
import 'dart:typed_data';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:record/record.dart';
import './stt_service.dart';
import '../onnx/online_model.dart';
import '../onnx/utils.dart';

/// Simulates real-time streaming ASR using an offline (non-streaming) model
/// combined with Silero VAD for speech boundary detection.
///
/// Architecture (mirrors the Kotlin SimulateStreamingAsr reference):
///   1. Mic → PCM 16-bit @ 16 kHz mono → Float32 samples
///   2. Samples are fed to Silero VAD in 512-sample windows
///   3. While speech is detected, the accumulated buffer is periodically
///      sent to the OfflineRecognizer for interim results (~every 200 ms)
///   4. When VAD emits a completed speech segment, a final decode is run
///      and the result is delivered via the callback
class SherpaSTTService implements ISTTService {
  final int type;
  final bool online;

  sherpa_onnx.OfflineRecognizer? _offlineRecognizer;
  sherpa_onnx.OnlineRecognizer? _onlineRecognizer;
  sherpa_onnx.OnlineStream? _onlineStream;
  sherpa_onnx.VoiceActivityDetector? _vad;

  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription? _audioSubscription;

  bool _isListening = false;
  bool _isAvailable = false;
  bool _isInitialized = false;

  SherpaSTTService({this.type = 0, this.online = false});

  // Callbacks stored for the duration of a listen() session
  Function(String)? _onResult;
  Function(dynamic)? _onError;
  Function(String)? _onStatus;

  // Audio processing state (mirrors Kotlin's coroutine-local vars)
  final List<double> _audioBuffer = [];
  int _bufferOffset = 0;
  bool _isSpeechStarted = false;
  int _speechStartOffset = 0;
  int _lastAsrTimestamp = 0;
  String _lastText = '';
  bool _resultAdded = false;

  // Guard against re-entrant processing
  bool _isProcessing = false;
  int _diagCounter = 0;

  // Timer for periodic processing
  Timer? _processTimer;

  static const int _sampleRate = 16000;
  static const int _vadWindowSize = 512;

  @override
  bool get isAvailable => _isAvailable;

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      sherpa_onnx.initBindings();

      if (online) {
        // --- TRUE STREAMING MODE ---
        print('[SherpaSTT] Loading online streaming model (type: $type)...');
        final modelConfig = await getOnlineModelConfig(type: type);
        final config = sherpa_onnx.OnlineRecognizerConfig(
          model: modelConfig,
          enableEndpoint: true,
          rule1MinTrailingSilence: 2.4,
          rule2MinTrailingSilence: 1.2,
          rule3MinUtteranceLength: 300,
        );
        _onlineRecognizer = sherpa_onnx.OnlineRecognizer(config);
        _onlineStream = _onlineRecognizer!.createStream();
        print('[SherpaSTT] Online recognizer created OK');
      } else {
        // --- SIMULATED STREAMING MODE (VAD + OFFLINE) ---
        print('[SherpaSTT] Loading offline model (type: $type)...');
        final modelConfig = await getOfflineModelConfig(type: type);
        final config = sherpa_onnx.OfflineRecognizerConfig(
          model: modelConfig,
        );
        _offlineRecognizer = sherpa_onnx.OfflineRecognizer(config);
        print('[SherpaSTT] Offline recognizer created OK');

        // Initialize VAD (Silero VAD)
        print('[SherpaSTT] Loading VAD model...');
        final vadConfig = await getVadModelConfig(type: 0);
        _vad = sherpa_onnx.VoiceActivityDetector(
          config: vadConfig,
          bufferSizeInSeconds: 30,
        );
        print('[SherpaSTT] VAD created OK');
      }

      _isAvailable = true;
      _isInitialized = true;
      print(
          '[SherpaSTT] ✅ Initialized (${online ? "TRUE STREAMING" : "VAD + OFFLINE SIMULATION"})');
      return true;
    } catch (e, st) {
      print('[SherpaSTT] ❌ Init error: $e\n$st');
      _isAvailable = false;
      return false;
    }
  }

  @override
  Future<void> listen({
    required Function(String) onResult,
    Function(dynamic)? onError,
    Function(String)? onStatus,
  }) async {
    if (!_isAvailable ||
        (online && _onlineRecognizer == null) ||
        (!online && (_offlineRecognizer == null || _vad == null))) {
      final ok = await initialize();
      if (!ok) {
        onError?.call('Failed to initialize Sherpa ONNX');
        return;
      }
    }

    if (!await _audioRecorder.hasPermission()) {
      onError?.call('Microphone permission denied');
      return;
    }

    // Store callbacks
    _onResult = onResult;
    _onError = onError;
    _onStatus = onStatus;

    // Reset state
    _isListening = true;
    _audioBuffer.clear();
    _bufferOffset = 0;
    _isSpeechStarted = false;
    _speechStartOffset = 0;
    _lastAsrTimestamp = _currentTimeMs();
    _lastText = '';
    _resultAdded = false;
    _isProcessing = false;
    _diagCounter = 0;

    if (online) {
      _onlineStream?.free();
      _onlineStream = _onlineRecognizer!.createStream();
    } else {
      _vad!.reset();
    }

    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: _sampleRate,
      numChannels: 1,
    );

    try {
      final recordStream = await _audioRecorder.startStream(config);
      onStatus?.call('listening');
      print('[SherpaSTT] 🎤 Mic stream started');

      _audioSubscription = recordStream.listen(
        (Uint8List data) {
          if (!_isListening) return;
          final samples = convertBytesToFloat32(data);
          if (online) {
            _onlineStream?.acceptWaveform(
                samples: samples, sampleRate: _sampleRate);
          } else {
            _audioBuffer.addAll(samples);
          }
        },
        onError: (e) {
          print('[SherpaSTT] ❌ Audio stream error: $e');
          _onError?.call('Audio stream error: $e');
        },
      );

      // Process audio at ~100ms intervals
      _processTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _processAudioBuffer(),
      );
    } catch (e) {
      print('[SherpaSTT] ❌ Failed to start stream: $e');
      onError?.call('Failed to start audio stream: $e');
    }
  }

  /// Core processing loop
  void _processAudioBuffer() {
    if (!_isListening) return;
    if (online && _onlineRecognizer == null) return;
    if (!online && (_vad == null || _offlineRecognizer == null)) return;

    // Prevent re-entrant calls (decode can be slow)
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      if (online) {
        _processOnline();
      } else {
        _processOfflineWithVad();
      }
    } catch (e) {
      print('[SherpaSTT] ❌ Process error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// True streaming processing logic
  void _processOnline() {
    while (_onlineRecognizer!.isReady(_onlineStream!)) {
      _onlineRecognizer!.decode(_onlineStream!);
    }

    final result = _onlineRecognizer!.getResult(_onlineStream!);
    final text = result.text.trim();

    if (text.isNotEmpty && text != _lastText) {
      _lastText = text;
      _onResult?.call(_lastText);
      print('[SherpaSTT] 📝 Online: "$text"');
    }

    if (_onlineRecognizer!.isEndpoint(_onlineStream!)) {
      _onlineRecognizer!.reset(_onlineStream!);
      print('[SherpaSTT] 🏁 Online: Endpoint detected');
    }
  }

  /// Simulated streaming logic (VAD + Offline)
  void _processOfflineWithVad() {
    _feedVadAndDetect();
    _runPeriodicAsr();
    _processCompletedSegments();
  }

  /// Step 1+2: Feed audio to VAD and detect speech onset (Offline mode only)
  void _feedVadAndDetect() {
    int windowsProcessed = 0;
    while (_bufferOffset + _vadWindowSize <= _audioBuffer.length) {
      final window = Float32List(_vadWindowSize);
      for (int i = 0; i < _vadWindowSize; i++) {
        window[i] = _audioBuffer[_bufferOffset + i];
      }
      _vad!.acceptWaveform(window);
      _bufferOffset += _vadWindowSize;
      windowsProcessed++;

      // Detect speech onset
      if (!_isSpeechStarted && _vad!.isDetected()) {
        _isSpeechStarted = true;
        // Look back 0.4 seconds (6400 samples @ 16kHz) for context
        _speechStartOffset = _bufferOffset - 6400;
        if (_speechStartOffset < 0) _speechStartOffset = 0;
        _lastAsrTimestamp = _currentTimeMs();
        print('[SherpaSTT] 🗣️ Speech detected at offset $_bufferOffset');
      }
    }

    // Diagnostic: log every ~2 seconds
    _diagCounter++;
    if (_diagCounter % 20 == 0) {
      print('[SherpaSTT] 📊 buf=${_audioBuffer.length} '
          'offset=$_bufferOffset '
          'windows=$windowsProcessed '
          'speech=$_isSpeechStarted '
          'vadDetected=${_vad!.isDetected()} '
          'vadEmpty=${_vad!.isEmpty()}');
    }
  }

  /// Step 3: Run ASR periodically during active speech (Offline mode only)
  void _runPeriodicAsr() {
    if (!_isSpeechStarted) return;

    final elapsed = _currentTimeMs() - _lastAsrTimestamp;
    if (elapsed < 200) return;

    final sampleCount = _bufferOffset - _speechStartOffset;
    if (sampleCount <= 0) return;

    try {
      final speechSamples = Float32List(sampleCount);
      for (int i = 0; i < sampleCount; i++) {
        speechSamples[i] = _audioBuffer[_speechStartOffset + i];
      }

      final stream = _offlineRecognizer!.createStream();
      stream.acceptWaveform(samples: speechSamples, sampleRate: _sampleRate);
      _offlineRecognizer!.decode(stream);
      final result = _offlineRecognizer!.getResult(stream);
      stream.free();

      final text = result.text.trim();
      if (text.isNotEmpty) {
        _lastText = text;
        _onResult?.call(_lastText);
        _resultAdded = true;
        print('[SherpaSTT] 📝 Interim: "$text"');
      }

      _lastAsrTimestamp = _currentTimeMs();
    } catch (e) {
      print('[SherpaSTT] ❌ Interim ASR error: $e');
    }
  }

  /// Step 4: Process completed VAD segments (Offline mode only)
  void _processCompletedSegments() {
    while (!_vad!.isEmpty()) {
      final segment = _vad!.front();
      print('[SherpaSTT] 📦 VAD segment: ${segment.samples.length} samples');

      try {
        final stream = _offlineRecognizer!.createStream();
        stream.acceptWaveform(
          samples: segment.samples,
          sampleRate: _sampleRate,
        );
        _offlineRecognizer!.decode(stream);
        final result = _offlineRecognizer!.getResult(stream);
        stream.free();

        final text = result.text.trim();
        if (text.isNotEmpty) {
          _lastText = text;
          _onResult?.call(_lastText);
          print('[SherpaSTT] ✅ Final: "$text"');
        }
      } catch (e) {
        print('[SherpaSTT] ❌ Final ASR error: $e');
      }

      _vad!.pop();

      // Reset state for next utterance
      _isSpeechStarted = false;
      _audioBuffer.clear();
      _bufferOffset = 0;
      _resultAdded = false;
    }
  }

  @override
  Future<void> stop() async {
    print('[SherpaSTT] 🛑 Stopping...');
    _isListening = false;
    _processTimer?.cancel();
    _processTimer = null;
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _audioRecorder.stop();

    if (online) {
      // For online mode, just grab one last result if any
      if (_onlineRecognizer != null && _onlineStream != null) {
        while (_onlineRecognizer!.isReady(_onlineStream!)) {
          _onlineRecognizer!.decode(_onlineStream!);
        }
        final result = _onlineRecognizer!.getResult(_onlineStream!);
        if (result.text.isNotEmpty) {
          _onResult?.call(result.text.trim());
        }
        _onlineRecognizer!.reset(_onlineStream!);
      }
    } else {
      // Flush any remaining speech in the VAD
      if (_vad != null && _offlineRecognizer != null) {
        _vad!.flush();
        while (!_vad!.isEmpty()) {
          final segment = _vad!.front();
          try {
            final stream = _offlineRecognizer!.createStream();
            stream.acceptWaveform(
                samples: segment.samples, sampleRate: _sampleRate);
            _offlineRecognizer!.decode(stream);
            final result = _offlineRecognizer!.getResult(stream);
            stream.free();
            if (result.text.isNotEmpty) {
              _onResult?.call(result.text.trim());
            }
          } catch (e) {
            print('[SherpaSTT] ❌ Flush error: $e');
          }
          _vad!.pop();
        }

        // Final residual decode
        if (_isSpeechStarted && _bufferOffset > _speechStartOffset) {
          final sampleCount = _bufferOffset - _speechStartOffset;
          final speechSamples = Float32List(sampleCount);
          for (int i = 0; i < sampleCount; i++) {
            speechSamples[i] = _audioBuffer[_speechStartOffset + i];
          }
          try {
            final stream = _offlineRecognizer!.createStream();
            stream.acceptWaveform(
                samples: speechSamples, sampleRate: _sampleRate);
            _offlineRecognizer!.decode(stream);
            final result = _offlineRecognizer!.getResult(stream);
            stream.free();
            if (result.text.isNotEmpty) {
              _onResult?.call(result.text.trim());
            }
          } catch (e) {
            print('[SherpaSTT] ❌ Stop residual error: $e');
          }
        }
      }
    }

    _audioBuffer.clear();
    _bufferOffset = 0;
    _isSpeechStarted = false;
    _onStatus?.call('notListening');
    _onResult = null;
    _onError = null;
    _onStatus = null;
    print('[SherpaSTT] 🛑 Stopped');
  }

  @override
  void dispose() {
    stop();
    _audioRecorder.dispose();
    _vad?.free();
    _offlineRecognizer?.free();
    _onlineStream?.free();
    _onlineRecognizer?.free();
    _vad = null;
    _offlineRecognizer = null;
    _onlineStream = null;
    _onlineRecognizer = null;
  }

  int _currentTimeMs() => DateTime.now().millisecondsSinceEpoch;
}
