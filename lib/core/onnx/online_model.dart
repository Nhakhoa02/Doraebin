import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import './utils.dart';

// Remember to change `assets` in ../pubspec.yaml
// and download files to ../assets
Future<sherpa_onnx.OnlineModelConfig> getOnlineModelConfig(
    {required int type}) async {
  switch (type) {
    case 0: // Vietnamese Zipformer INT8 (Recommended)
      final modelDir =
          'assets/models/sherpa-onnx-zipformer-vi-int8-2025-04-20/sherpa-onnx-zipformer-vi-int8-2025-04-20';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder:
              await copyAssetFile('$modelDir/encoder-epoch-12-avg-8.int8.onnx'),
          decoder: await copyAssetFile('$modelDir/decoder-epoch-12-avg-8.onnx'),
          joiner:
              await copyAssetFile('$modelDir/joiner-epoch-12-avg-8.int8.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer2',
      );
    case 1: // Vietnamese Zipformer 30M INT8 (Fast/Small)
      final modelDir =
          'assets/models/sherpa-onnx-zipformer-vi-30M-int8-2026-02-09/sherpa-onnx-zipformer-vi-30M-int8-2026-02-09';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await copyAssetFile('$modelDir/encoder.int8.onnx'),
          decoder: await copyAssetFile('$modelDir/decoder.onnx'),
          joiner: await copyAssetFile('$modelDir/joiner.int8.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer2',
      );
    case 2: // Vietnamese Zipformer Full (Non-quantized)
      final modelDir =
          'assets/models/sherpa-onnx-zipformer-vi-2025-04-20/sherpa-onnx-zipformer-vi-2025-04-20';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await copyAssetFile('$modelDir/encoder-epoch-12-avg-8.onnx'),
          decoder: await copyAssetFile('$modelDir/decoder-epoch-12-avg-8.onnx'),
          joiner: await copyAssetFile('$modelDir/joiner-epoch-12-avg-8.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer2',
      );
    case 3: // Vietnamese Zipformer 30M Full (Non-quantized)
      final modelDir =
          'assets/models/sherpa-onnx-zipformer-vi-30M-2026-02-09/sherpa-onnx-zipformer-vi-30M-2026-02-09';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await copyAssetFile('$modelDir/encoder.onnx'),
          decoder: await copyAssetFile('$modelDir/decoder.onnx'),
          joiner: await copyAssetFile('$modelDir/joiner.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer2',
      );
    default:
      throw ArgumentError('Unsupported type: $type');
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
          mergedDecoder: await copyAssetFile('$modelDir/decoder_model_merged.ort'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'moonshine',
      );
    default:
      throw ArgumentError('Unsupported type: $type');
  }
}