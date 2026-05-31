import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:http/http.dart' as http;

import '../../../core/data/database_service.dart';
import '../../../core/onnx/online_model.dart';
import '../../../core/onnx/utils.dart';


class ModelTestScreen extends StatefulWidget {
  const ModelTestScreen({super.key});

  @override
  State<ModelTestScreen> createState() => _ModelTestScreenState();
}

class _ModelTestScreenState extends State<ModelTestScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _referenceController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription? _audioSub;
  final List<int> _pcmBytes = [];

  bool _isRecording = false;
  int _secondsRecorded = 0;
  Timer? _timer;

  // Model loading state
  bool _isModelsLoading = true;
  bool _hasLoadingError = false;
  String _errorMessage = '';
  String _loadingStatus = 'Đang khởi động hệ thống ASR...';
  double _loadingProgress = 0.0;

  // Preloaded Recognizers
  sherpa_onnx.OfflineRecognizer? _moonshineRecognizer;
  sherpa_onnx.OfflineRecognizer? _zip30mRecognizer;
  sherpa_onnx.OfflineRecognizer? _zip2025Recognizer;

  // Processing state
  bool _isProcessing = false;
  String _processingStatus = '';

  // Transcripts & Latency
  String _moonshineTranscript = '';
  int _moonshineLatencyMs = 0;

  String _zip30mTranscript = '';
  int _zip30mLatencyMs = 0;

  String _zip2025Transcript = '';
  int _zip2025LatencyMs = 0;

  // HTTP POST state
  bool _isSending = false;
  String _uploadStatus = '';

  // Vocabulary for random words
  List<String> _vocabularyList = [];

  // Mic Pulse animation
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
    _preloadModels();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _timer?.cancel();
    _audioSub?.cancel();
    _audioRecorder.dispose();
    _pulseController.dispose();
    
    // Free the preloaded recognizers to prevent memory leaks!
    _moonshineRecognizer?.free();
    _zip30mRecognizer?.free();
    _zip2025Recognizer?.free();
    
    super.dispose();
  }

  Future<void> _loadVocabulary() async {
    try {
      final dbService = DatabaseService();
      await dbService.init();
      final allWords = dbService.getAllWords();
      setState(() {
        _vocabularyList = allWords
            .where((w) => w['category_id'] != 'alphabet')
            .map((w) => w['text'] as String)
            .toList();
        if (_vocabularyList.isEmpty) {
          _vocabularyList = ['Con cá', 'Quả táo', 'Con mèo', 'Cái nhà', 'Trường học'];
        }
      });
      _setRandomWord();
    } catch (e) {
      print('Error loading vocabulary: $e');
      setState(() {
        _vocabularyList = ['Con cá', 'Quả táo', 'Con mèo', 'Cái nhà', 'Trường học'];
      });
      _setRandomWord();
    }
  }

  void _setRandomWord() {
    if (_vocabularyList.isNotEmpty) {
      final rand = Random();
      final word = _vocabularyList[rand.nextInt(_vocabularyList.length)];
      _referenceController.text = word;
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quyền truy cập micro bị từ chối!')),
      );
      return;
    }

    try {
      _pcmBytes.clear();
      setState(() {
        _moonshineTranscript = '';
        _zip30mTranscript = '';
        _zip2025Transcript = '';
        _moonshineLatencyMs = 0;
        _zip30mLatencyMs = 0;
        _zip2025LatencyMs = 0;
        _uploadStatus = '';
        _secondsRecorded = 0;
      });

      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      final recordStream = await _audioRecorder.startStream(config);
      
      setState(() {
        _isRecording = true;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          _secondsRecorded++;
        });
      });

      _audioSub = recordStream.listen(
        (data) {
          _pcmBytes.addAll(data);
        },
        onError: (e) {
          print('Recording Stream Error: $e');
        },
      );
    } catch (e) {
      print('Failed to start recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khởi động ghi âm: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _timer = null;
    await _audioSub?.cancel();
    _audioSub = null;
    await _audioRecorder.stop();
    
    setState(() {
      _isRecording = false;
    });

    await _decodeAllModels();
  }

  Future<void> _decodeAllModels() async {
    if (_pcmBytes.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Đang chuyển đổi dữ liệu âm thanh...';
    });

    try {
      final float32Samples = convertBytesToFloat32(Uint8List.fromList(_pcmBytes));
      
      // Initialize bindings if not already done
      sherpa_onnx.initBindings();

      // 1. Moonshine Base Quantized (Offline Type 0)
      setState(() {
        _processingStatus = 'Model 1: Moonshine Base đang giải mã...';
      });
      final sw1 = Stopwatch()..start();
      final t1 = await _runSingleModelASR(0, float32Samples);
      sw1.stop();
      setState(() {
        _moonshineTranscript = t1;
        _moonshineLatencyMs = sw1.elapsedMilliseconds;
      });

      // 2. Zipformer-vi-30M Full (Offline Type 4)
      setState(() {
        _processingStatus = 'Model 2: Zipformer 30M đang giải mã...';
      });
      final sw2 = Stopwatch()..start();
      final t2 = await _runSingleModelASR(4, float32Samples);
      sw2.stop();
      setState(() {
        _zip30mTranscript = t2;
        _zip30mLatencyMs = sw2.elapsedMilliseconds;
      });

      // 3. Zipformer-vi-2025-04-20 Full (Offline Type 3)
      setState(() {
        _processingStatus = 'Model 3: Zipformer 2025 đang giải mã...';
      });
      final sw3 = Stopwatch()..start();
      final t3 = await _runSingleModelASR(3, float32Samples);
      sw3.stop();
      setState(() {
        _zip2025Transcript = t3;
        _zip2025LatencyMs = sw3.elapsedMilliseconds;
      });

      setState(() {
        _processingStatus = 'Giải mã tất cả các model hoàn tất!';
      });
    } catch (e) {
      setState(() {
        _processingStatus = 'Lỗi trong quá trình giải mã: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _preloadModels() async {
    setState(() {
      _isModelsLoading = true;
      _hasLoadingError = false;
      _errorMessage = '';
      _loadingStatus = 'Đang khởi tạo cấu hình âm thanh...';
      _loadingProgress = 0.1;
    });

    try {
      sherpa_onnx.initBindings();
      await Future.delayed(const Duration(milliseconds: 100));

      // 1. Moonshine
      if (_moonshineRecognizer == null) {
        setState(() {
          _loadingStatus = 'Đang nạp mô hình Moonshine Base (1/3)...';
          _loadingProgress = 0.3;
        });
        final moonshineConfig = await getOfflineModelConfig(type: 0);
        _moonshineRecognizer = sherpa_onnx.OfflineRecognizer(
          sherpa_onnx.OfflineRecognizerConfig(model: moonshineConfig)
        );
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 2. Zipformer 30M
      if (_zip30mRecognizer == null) {
        setState(() {
          _loadingStatus = 'Đang nạp mô hình Zipformer 30M (2/3)...';
          _loadingProgress = 0.6;
        });
        final zip30mConfig = await getOfflineModelConfig(type: 4);
        _zip30mRecognizer = sherpa_onnx.OfflineRecognizer(
          sherpa_onnx.OfflineRecognizerConfig(model: zip30mConfig)
        );
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 3. Zipformer 2025
      if (_zip2025Recognizer == null) {
        setState(() {
          _loadingStatus = 'Đang nạp mô hình Zipformer 2025 (3/3)...';
          _loadingProgress = 0.9;
        });
        final zip2025Config = await getOfflineModelConfig(type: 3);
        _zip2025Recognizer = sherpa_onnx.OfflineRecognizer(
          sherpa_onnx.OfflineRecognizerConfig(model: zip2025Config)
        );
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() {
        _isModelsLoading = false;
        _loadingProgress = 1.0;
      });
    } catch (e) {
      setState(() {
        _hasLoadingError = true;
        _errorMessage = e.toString();
        _loadingStatus = 'Lỗi nạp mô hình ASR!';
      });
      print('Model preload error: $e');
    }
  }

  Future<String> _runSingleModelASR(int type, Float32List samples) async {
    try {
      sherpa_onnx.OfflineRecognizer? recognizer;
      if (type == 0) {
        recognizer = _moonshineRecognizer;
      } else if (type == 4) {
        recognizer = _zip30mRecognizer;
      } else if (type == 3) {
        recognizer = _zip2025Recognizer;
      }

      if (recognizer == null) {
        return 'Lỗi: Mô hình chưa được nạp!';
      }

      final stream = recognizer.createStream();
      stream.acceptWaveform(samples: samples, sampleRate: 16000);
      recognizer.decode(stream);
      
      final result = recognizer.getResult(stream);
      final text = result.text.trim();
      
      stream.free();
      return text.isNotEmpty ? text : '(Không nhận dạng được từ nào)';
    } catch (e) {
      print('Model $type decode error: $e');
      return 'Lỗi giải mã: $e';
    }
  }

  Uint8List _buildWavHeader(int numBytes) {
    final header = ByteData(44);
    
    // "RIFF"
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    
    header.setUint32(4, 36 + numBytes, Endian.little);
    
    // "WAVE"
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    
    // "fmt " chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // space
    
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, 1, Endian.little); // Mono
    header.setUint32(24, 16000, Endian.little); // Sample rate
    header.setUint32(28, 32000, Endian.little); // Byte rate (16000 * 2)
    header.setUint16(32, 2, Endian.little); // Block align
    header.setUint16(34, 16, Endian.little); // Bits per sample
    
    // "data" chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    
    header.setUint32(40, numBytes, Endian.little);
    
    return header.buffer.asUint8List();
  }

  Future<void> _sendTestResults() async {
    if (_pcmBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng ghi âm trước khi gửi!')),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _uploadStatus = 'Đang xử lý âm thanh...';
    });

    try {
      final header = _buildWavHeader(_pcmBytes.length);
      final wavBytes = BytesBuilder();
      wavBytes.add(header);
      wavBytes.add(_pcmBytes);
      final fullWavData = wavBytes.toBytes();

      final uri = Uri.parse('https://stt-test-server.onrender.com/test-cases');
      final request = http.MultipartRequest('POST', uri);

      request.fields['reference_text'] = _referenceController.text.trim();
      
      final modelResults = {
        'Moonshine': _moonshineTranscript,
        'Zipformer-vi-30M': _zip30mTranscript,
        'Zipformer-vi-2025-04-20': _zip2025Transcript,
      };
      request.fields['model_results'] = jsonEncode(modelResults);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          fullWavData,
          filename: 'audio_$timestamp.wav',
        ),
      );

      setState(() {
        _uploadStatus = 'Đang tải lên server...';
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _uploadStatus = 'Tải lên thành công! (HTTP ${response.statusCode})';
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('🎉 Thành công', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Test case đã được gửi lên server thành công!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _uploadStatus = 'Thất bại: HTTP ${response.statusCode}\n${response.body}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi server: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        _uploadStatus = 'Lỗi kết nối: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi dữ liệu: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildTargetCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Từ khóa mục tiêu (Reference)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.shuffle, color: Colors.purple),
                  onPressed: _isRecording || _isProcessing ? null : _setRandomWord,
                  tooltip: 'Chọn từ ngẫu nhiên',
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _referenceController,
              enabled: !_isRecording && !_isProcessing,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Nhập từ khóa hoặc câu cần đọc...',
                fillColor: Colors.grey.shade50,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard({required bool isExpanded}) {
    final cardContent = Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (_isRecording)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.15 + (_pulseController.value * 0.15)),
                  ),
                  child: child,
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.stop, color: Colors.white, size: 40),
                  onPressed: _toggleRecording,
                ),
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isProcessing ? Colors.grey : Colors.purple.shade600,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
              ),
              child: IconButton(
                icon: const Icon(Icons.mic, color: Colors.white, size: 40),
                onPressed: _isProcessing ? null : _toggleRecording,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _isRecording
                ? 'Đang ghi âm... ${_formatDuration(_secondsRecorded)}'
                : (_isProcessing
                    ? _processingStatus
                    : 'Nhấn mic để bắt đầu ghi âm'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _isRecording
                  ? Colors.red
                  : (_isProcessing ? Colors.purple.shade700 : Colors.grey.shade700),
            ),
          ),
          if (_pcmBytes.isNotEmpty && !_isRecording)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Kích thước file ghi: ~${(_pcmBytes.length / 1024).toStringAsFixed(1)} KB (PCM 16k)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
        ],
      ),
    );

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: isExpanded
          ? Center(child: cardContent)
          : cardContent,
    );
  }

  Widget _buildSendCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSending || _isRecording || _isProcessing || _pcmBytes.isEmpty
                    ? null
                    : _sendTestResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _isSending ? 'Đang gửi...' : 'Gửi Kết Quả Lên Server',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard({required bool isExpanded}) {
    final listContent = ListView(
      shrinkWrap: !isExpanded,
      physics: isExpanded ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
      children: [
        _buildModelResultCard(
          name: '🚀 Moonshine (Base Quantized)',
          transcript: _moonshineTranscript,
          latencyMs: _moonshineLatencyMs,
          color: Colors.blue.shade50,
          accentColor: Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildModelResultCard(
          name: '⚡ Zipformer 30M (Full)',
          transcript: _zip30mTranscript,
          latencyMs: _zip30mLatencyMs,
          color: Colors.green.shade50,
          accentColor: Colors.green,
        ),
        const SizedBox(height: 16),
        _buildModelResultCard(
          name: '🐢 Zipformer 2025-04-20 (Full)',
          transcript: _zip2025Transcript,
          latencyMs: _zip2025LatencyMs,
          color: Colors.amber.shade50,
          accentColor: Colors.amber,
        ),
      ],
    );

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Text(
              'So Sánh Kết Quả Nhận Dạng 📊',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade900,
              ),
            ),
            const SizedBox(height: 16),
            isExpanded
                ? Expanded(child: listContent)
                : listContent,
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.shade100.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A cute pulsing laboratory beaker or brain icon (smaller height)
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 0.9 + (_pulseController.value * 0.2);
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Icon(Icons.science_rounded, size: 36, color: Colors.purple.shade700),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chuẩn Bị Hệ Thống ASR 🧪',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.itim(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _hasLoadingError
                      ? 'Đã xảy ra lỗi trong quá trình chuẩn bị các mô hình.'
                      : 'Ứng dụng đang nạp trước các mô hình trí tuệ nhân tạo để dịch thuật tức thì.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                if (_hasLoadingError) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Quay lại', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _preloadModels,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Thử lại', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _loadingProgress,
                      minHeight: 8,
                      backgroundColor: Colors.purple.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade500),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loadingStatus,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isModelsLoading) {
      return _buildLoadingScreen();
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Kiểm Thử Hiệu Năng Model ASR 🧪',
                      style: GoogleFonts.itim(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isProcessing)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.purple)),
                      ),
                    )
                  else if (_uploadStatus.isNotEmpty)
                    Flexible(
                      child: Text(
                        _uploadStatus,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _uploadStatus.toLowerCase().contains('thành công') ? Colors.green : Colors.red,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            
            // Main Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 720 || constraints.maxHeight < 600) {
                      // Portrait / Mobile view or short height: Vertical layout
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTargetCard(),
                            const SizedBox(height: 16),
                            _buildRecordCard(isExpanded: false),
                            const SizedBox(height: 16),
                            _buildSendCard(),
                            const SizedBox(height: 16),
                            _buildResultsCard(isExpanded: false),
                          ],
                        ),
                      );
                    } else {
                      // Landscape / Desktop view: Horizontal Row
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Column: Input & Recording Controls
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                _buildTargetCard(),
                                const SizedBox(height: 16),
                                Expanded(child: _buildRecordCard(isExpanded: true)),
                                const SizedBox(height: 16),
                                _buildSendCard(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right Column: ASR Results & Latency Comparison
                          Expanded(
                            flex: 6,
                            child: _buildResultsCard(isExpanded: true),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelResultCard({
    required String name,
    required String transcript,
    required int latencyMs,
    required Color color,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accentColor.shade900,
                  ),
                ),
              ),
              if (latencyMs > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      '${latencyMs}ms',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor.shade800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              transcript.isNotEmpty ? transcript : '(Chờ ghi âm để dịch)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: transcript.isNotEmpty && transcript != '(Chờ ghi âm để dịch)'
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: transcript.isNotEmpty && transcript != '(Chờ ghi âm để dịch)'
                    ? Colors.black87
                    : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to get shade900, shade800 and shade700 dynamically if we use material colors
extension on Color {
  Color get shade900 => _adjustLightness(0.2);
  Color get shade800 => _adjustLightness(0.3);
  Color get shade700 => _adjustLightness(0.4);

  Color _adjustLightness(double factor) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness * factor).clamp(0.0, 1.0)).toColor();
  }
}
