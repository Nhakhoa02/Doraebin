import 'dart:async';
import './flutter_stt_service.dart';
import './sherpa_stt_service.dart';

abstract class ISTTService {
  Future<bool> initialize();
  Future<void> listen({
    required Function(String, bool) onResult,
    Function(dynamic)? onError,
    Function(String)? onStatus,
  });
  Future<void> stop();
  bool get isListening;
  bool get isAvailable;
  void dispose();

  factory ISTTService.flutter() => FlutterSTTService();
  factory ISTTService.sherpa({int type = 0, bool online = false}) =>
      SherpaSTTService(type: type, online: online);
}
