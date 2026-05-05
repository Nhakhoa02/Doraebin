import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import './utils.dart';

// Remember to change `assets` in ../pubspec.yaml
// and download files to ../assets
Future<sherpa_onnx.OnlineModelConfig> getOnlineModelConfig(
    {required int type}) async {
  switch (type) {
    case 0: // Multi-language Streaming Zipformer (ar, en, id, ja, ru, th, vi, zh)
      final modelDir =
          'assets/models/sherpa-onnx-streaming-zipformer-ar_en_id_ja_ru_th_vi_zh-2025-02-10/sherpa-onnx-streaming-zipformer-ar_en_id_ja_ru_th_vi_zh-2025-02-10';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await copyAssetFile(
              '$modelDir/encoder-epoch-75-avg-11-chunk-16-left-128.int8.onnx'),
          decoder: await copyAssetFile(
              '$modelDir/decoder-epoch-75-avg-11-chunk-16-left-128.onnx'),
          joiner: await copyAssetFile(
              '$modelDir/joiner-epoch-75-avg-11-chunk-16-left-128.int8.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer2',
      );
    default:
      throw ArgumentError('Unsupported Online type: $type');
  }
}

Future<sherpa_onnx.OfflineModelConfig> getOfflineModelConfig(
    {required int type}) async {
  switch (type) {
    case 0: // Vietnamese Moonshine Base Quantized
      final modelDir =
          'assets/models/sherpa-onnx-moonshine-base-vi-quantized-2026-02-27/sherpa-onnx-moonshine-base-vi-quantized-2026-02-27';
      return sherpa_onnx.OfflineModelConfig(
        moonshine: sherpa_onnx.OfflineMoonshineModelConfig(
          preprocessor: '', // Not provided in this version
          encoder: await copyAssetFile('$modelDir/encoder_model.ort'),
          mergedDecoder:
              await copyAssetFile('$modelDir/decoder_model_merged.ort'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'moonshine',
      );
    case 1: // Vietnamese Zipformer INT8 (Offline mode)
      final modelDir =
          'assets/models/sherpa-onnx-zipformer-vi-int8-2025-04-20/sherpa-onnx-zipformer-vi-int8-2025-04-20';
      return sherpa_onnx.OfflineModelConfig(
        transducer: sherpa_onnx.OfflineTransducerModelConfig(
          encoder:
              await copyAssetFile('$modelDir/encoder-epoch-12-avg-8.int8.onnx'),
          decoder: await copyAssetFile('$modelDir/decoder-epoch-12-avg-8.onnx'),
          joiner:
              await copyAssetFile('$modelDir/joiner-epoch-12-avg-8.int8.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer2',
      );
    case 2: // Vietnamese Zipformer 30M INT8 (Offline mode)
      final modelDir =
          'assets/models/sherpa-onnx-zipformer-vi-30M-int8-2026-02-09/sherpa-onnx-zipformer-vi-30M-int8-2026-02-09';
      return sherpa_onnx.OfflineModelConfig(
        transducer: sherpa_onnx.OfflineTransducerModelConfig(
          encoder: await copyAssetFile('$modelDir/encoder.int8.onnx'),
          decoder: await copyAssetFile('$modelDir/decoder.onnx'),
          joiner: await copyAssetFile('$modelDir/joiner.int8.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer2',
      );
    case 3: // Vietnamese Zipformer Full (Non-quantized, Offline mode)
      final modelDir =
          'assets/models/sherpa-onnx-zipformer-vi-2025-04-20/sherpa-onnx-zipformer-vi-2025-04-20';
      return sherpa_onnx.OfflineModelConfig(
        transducer: sherpa_onnx.OfflineTransducerModelConfig(
          encoder: await copyAssetFile('$modelDir/encoder-epoch-12-avg-8.onnx'),
          decoder: await copyAssetFile('$modelDir/decoder-epoch-12-avg-8.onnx'),
          joiner: await copyAssetFile('$modelDir/joiner-epoch-12-avg-8.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer2',
      );
    case 4: // Vietnamese Zipformer 30M Full (Non-quantized, Offline mode)
      final modelDir =
          'assets/models/sherpa-onnx-zipformer-vi-30M-2026-02-09/sherpa-onnx-zipformer-vi-30M-2026-02-09';
      return sherpa_onnx.OfflineModelConfig(
        transducer: sherpa_onnx.OfflineTransducerModelConfig(
          encoder: await copyAssetFile('$modelDir/encoder.onnx'),
          decoder: await copyAssetFile('$modelDir/decoder.onnx'),
          joiner: await copyAssetFile('$modelDir/joiner.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer2',
      );
    default:
      throw ArgumentError('Unsupported Offline type: $type');
  }
}

/// Get the VAD (Voice Activity Detection) model config using Silero VAD.
///
/// type 0 = silero_vad.onnx (standard v5, 2.3MB — recommended)
/// type 1 = silero_vad_k2.onnx (k2-fsa repackaged, 644KB)
Future<sherpa_onnx.VadModelConfig> getVadModelConfig({int type = 0}) async {
  final String assetPath;
  switch (type) {
    case 0:
      assetPath = 'assets/models/VAD/silero_vad.onnx';
    case 1:
      assetPath = 'assets/models/VAD/silero_vad_k2.onnx';
    default:
      throw ArgumentError('Unsupported VAD type: $type');
  }

  final modelPath = await copyAssetFile(assetPath);
  return sherpa_onnx.VadModelConfig(
    sileroVad: sherpa_onnx.SileroVadModelConfig(
      model: modelPath,
      minSilenceDuration: 0.5,  // seconds of silence to end a speech segment
      minSpeechDuration: 0.5,  // minimum speech length to trigger
      maxSpeechDuration: 30.0,  // max speech segment (seconds)
      threshold: 0.25,          // speech probability threshold
      windowSize: 512,          // must be 512 for 16kHz
    ),
    sampleRate: 16000,
    numThreads: 1,
    debug: true,  // Enable debug logging to see VAD internals
  );
}