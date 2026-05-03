// Copyright (c)  2024  Xiaomi Corporation
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import "dart:io";

// Copy the asset file from src to dst
Future<String> copyAssetFile(String src, [String? dst]) async {
  final Directory directory = await getApplicationSupportDirectory();
  dst ??= basename(src);
  final target = join(directory.path, dst);
  bool exists = await File(target).exists();

  final data = await rootBundle.load(src);

  if (!exists || File(target).lengthSync() != data.lengthInBytes) {
    final List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(target).writeAsBytes(bytes);
  }

  return target;
}

Float32List convertBytesToFloat32(Uint8List bytes, [endian = Endian.little]) {
  final values = Float32List(bytes.length ~/ 2);

  // IMPORTANT: use offsetInBytes to handle Uint8List views correctly
  final data = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);

  for (var i = 0; i < bytes.length; i += 2) {
    int short = data.getInt16(i, endian);
    values[i ~/ 2] = short / 32768.0;
  }

  return values;
}

Future<bool> assetExists(String assetPath) async {
  try {
    await rootBundle.load(assetPath);
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> assetListExists(String paths) async {
  if (paths.trim().isEmpty) return false;

  final pathList = paths
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty);

  if (pathList.isEmpty) return false;

  return Future.wait(pathList.map(assetExists)).then((results) => results.every((e) => e));
}

Future<String> copyAssetToInternalStorage(String assetPath) async {
  final directory = await getApplicationSupportDirectory();
  final targetFile = File(join(directory.path, assetPath));

  // If asset doesn't exist in assets, just return the writable path
  if (!await assetExists(assetPath)) {
    await targetFile.parent.create(recursive: true);
    return targetFile.path;
  }

  // Check if already copied and up-to-date
  if (await targetFile.exists()) {
    final assetData = await rootBundle.load(assetPath);
    if (targetFile.lengthSync() == assetData.lengthInBytes) {
      return targetFile.path;
    }
  }

  await targetFile.parent.create(recursive: true);

  final data = await rootBundle.load(assetPath);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  await targetFile.writeAsBytes(bytes);

  return targetFile.path;
}

Future<String> copyAssetListToInternalStorage(String paths) async {
  if (paths.trim().isEmpty) return paths;

  final pathList = paths
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty);

  final copied = await Future.wait(
    pathList.map(copyAssetToInternalStorage),
  );

  return copied.join(',');
}