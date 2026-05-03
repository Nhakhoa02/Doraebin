import 'dart:async';
import 'dart:typed_data';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:record/record.dart';
import './stt_service.dart';
import '../onnx/online_model.dart';
import '../onnx/utils.dart';

class SherpaSTTService implements ISTTService {
  // Use OfflineRecognizer because the current models are non-streaming
  sherpa_onnx.OfflineRecognizer? _recognizer;
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription? _audioSubscription;
  
  bool _isListening = false;
  bool _isAvailable = false;
  bool _isInitialized = false;
  
  String _lastResult = "";
  final List<double> _audioBuffer = [];
  Timer? _recognitionTimer;

  @override
  bool get isAvailable => _isAvailable;

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      sherpa_onnx.initBindings();
      
      // Use Offline Moonshine model (Type 0 in getOfflineModelConfig)
      // Moonshine is a high-quality offline model that works well for Vietnamese
      final modelConfig = await getOfflineModelConfig(type: 0);
      final config = sherpa_onnx.OfflineRecognizerConfig(
        model: modelConfig,
      );
      
      _recognizer = sherpa_onnx.OfflineRecognizer(config);
      
      _isAvailable = true;
      _isInitialized = true;
      print("SherpaSTTService (Offline/Moonshine) initialized successfully");
      return true;
    } catch (e) {
      print("SherpaSTTService initialization error: $e");
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
    if (!_isAvailable || _recognizer == null) {
      final ok = await initialize();
      if (!ok) {
        onError?.call("Failed to initialize Sherpa ONNX");
        return;
      }
    }
    
    if (!await _audioRecorder.hasPermission()) {
      onError?.call("Microphone permission denied");
      return;
    }

    _isListening = true;
    _lastResult = "";
    _audioBuffer.clear();
    
    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    );

    try {
      final recordStream = await _audioRecorder.startStream(config);
      onStatus?.call('listening');

      // For offline models, we collect audio and process it periodically
      // to simulate streaming.
      _recognitionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isListening || _audioBuffer.isEmpty) return;
        _runRecognition(onResult);
      });

      _audioSubscription = recordStream.listen(
        (Uint8List data) {
          if (!_isListening) return;
          final samples = convertBytesToFloat32(data);
          _audioBuffer.addAll(samples);
        },
        onError: onError,
      );
    } catch (e) {
      onError?.call("Failed to start audio stream: $e");
    }
  }

  void _runRecognition(Function(String) onResult) {
    if (_recognizer == null || _audioBuffer.isEmpty) return;

    try {
      final stream = _recognizer!.createStream();
      stream.acceptWaveform(samples: Float32List.fromList(_audioBuffer), sampleRate: 16000);
      _recognizer!.decode(stream);
      
      final result = _recognizer!.getResult(stream);
      if (result.text.isNotEmpty && result.text != _lastResult) {
        _lastResult = result.text;
        onResult(_lastResult);
      }
      stream.free();
    } catch (e) {
      print("Recognition error: $e");
    }
  }

  @override
  Future<void> stop() async {
    _isListening = false;
    _recognitionTimer?.cancel();
    _recognitionTimer = null;
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _audioRecorder.stop();
    
    // Final recognition pass
    if (_audioBuffer.isNotEmpty) {
      // We don't have the onResult callback here in the simple stop()
      // but we could store it or pass it. For now, we just ensure it's stopped.
    }
    _audioBuffer.clear();
  }

  @override
  void dispose() {
    stop();
    _audioRecorder.dispose();
    _recognizer?.free();
  }
}
