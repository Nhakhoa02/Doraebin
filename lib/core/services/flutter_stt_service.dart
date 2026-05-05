import 'package:speech_to_text/speech_to_text.dart' as stt;
import './stt_service.dart';

class FlutterSTTService implements ISTTService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;

  @override
  bool get isAvailable => _available;

  @override
  bool get isListening => _listening;

  @override
  Future<bool> initialize() async {
    _available = await _speech.initialize(
      onError: (error) => _listening = false,
      onStatus: (status) {
        if (status == 'notListening') _listening = false;
        if (status == 'listening') _listening = true;
      },
    );
    return _available;
  }

  @override
  Future<void> listen({
    required Function(String, bool) onResult,
    Function(dynamic)? onError,
    Function(String)? onStatus,
  }) async {
    if (!_available) return;
    _listening = true;
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      localeId: "vi-VN",
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  @override
  Future<void> stop() async {
    await _speech.stop();
    _listening = false;
  }

  @override
  void dispose() {
    _speech.stop();
  }
}
