import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

import 'model_download_service_stub.dart'
    if (dart.library.io) 'model_download_service_mobile.dart'
    if (dart.library.js_interop) 'model_download_service_web.dart';

/// 离线语音识别服务封装（移动端：sherpa_onnx + record）
class SpeechService {
  static final SpeechService _instance = SpeechService._();
  factory SpeechService() => _instance;
  SpeechService._();

  final ModelDownloadService _modelService = ModelDownloadService();

  AudioRecorder? _recorder;
  OfflineRecognizer? _recognizer;
  bool _isListening = false;
  String? _recordingPath;

  final StreamController<_SpeechResult> _resultController =
      StreamController<_SpeechResult>.broadcast();

  Stream<_SpeechResult> get onResult => _resultController.stream;
  bool get isListening => _isListening;

  /// 移动端始终支持语音识别（只要有模型）
  static bool get isSupported => true;

  Future<void> _ensureInitialized() async {
    if (_recognizer != null) return;

    try {
      initBindings();
    } catch (_) {}

    final downloaded = await _modelService.isModelDownloaded();
    if (!downloaded) {
      throw StateError('MODEL_NOT_DOWNLOADED');
    }

    final modelPath = await _modelService.modelPath;
    final tokensPath = await _modelService.tokensPath;

    final config = OfflineRecognizerConfig(
      model: OfflineModelConfig(
        paraformer: OfflineParaformerModelConfig(model: modelPath),
        tokens: tokensPath,
        modelType: 'paraformer',
        numThreads: 2,
        provider: 'cpu',
        debug: false,
      ),
    );

    _recognizer = OfflineRecognizer(config);
  }

  Future<void> startListening() async {
    if (_isListening) {
      await cancelListening();
    }

    try {
      await _ensureInitialized();
    } catch (e) {
      if (e is StateError) {
        _resultController.add(const _SpeechResult(error: 'MODEL_NOT_DOWNLOADED'));
      } else {
        _resultController.add(_SpeechResult(error: '初始化失败: $e'));
      }
      rethrow;
    }

    if (_recorder != null) {
      try { await _recorder!.dispose(); } catch (_) {}
      _recorder = null;
    }

    _isListening = true;

    final recorder = AudioRecorder();
    final hasPermission = await recorder.hasPermission();
    if (!hasPermission) {
      _isListening = false;
      recorder.dispose();
      final err = '麦克风权限未授予';
      _resultController.add(_SpeechResult(error: err));
      throw Exception(err);
    }

    final tempDir = await getTemporaryDirectory();
    _recordingPath = '${tempDir.path}/voice_'
        '${DateTime.now().millisecondsSinceEpoch}.wav';

    try {
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );
      _recorder = recorder;
    } catch (e) {
      _isListening = false;
      recorder.dispose();
      _resultController.add(_SpeechResult(error: '录音启动失败: $e'));
      rethrow;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;

    final recorder = _recorder;
    _recorder = null;
    final recordingPath = _recordingPath;

    String? filePath;
    try {
      filePath = await recorder?.stop();
    } catch (e) {
      _resultController.add(_SpeechResult(error: '停止录音失败: $e'));
      try { await recorder?.dispose(); } catch (_) {}
      return;
    }
    filePath ??= recordingPath;

    try { await recorder?.dispose(); } catch (_) {}

    if (filePath == null || !File(filePath).existsSync()) {
      _resultController.add(_SpeechResult(
        error: '录音文件不存在${filePath != null ? ': $filePath' : ''}',
      ));
      _cleanupTempFile(recordingPath);
      return;
    }

    try {
      final wave = readWave(filePath);

      if (wave.samples.isEmpty) {
        _resultController.add(const _SpeechResult(error: '录音为空'));
        return;
      }

      final stream = _recognizer!.createStream();
      stream.acceptWaveform(
        samples: wave.samples,
        sampleRate: wave.sampleRate,
      );
      _recognizer!.decode(stream);
      final result = _recognizer!.getResult(stream);
      stream.free();

      final text = result.text.trim();
      if (text.isEmpty) {
        _resultController.add(const _SpeechResult(error: '未识别到语音内容'));
      } else {
        _resultController.add(_SpeechResult(text: text, isLast: true));
      }
    } catch (e) {
      _resultController.add(_SpeechResult(error: '识别失败: $e'));
    } finally {
      _cleanupTempFile(filePath);
      _cleanupTempFile(recordingPath);
    }
  }

  Future<void> cancelListening() async {
    if (!_isListening) return;
    _isListening = false;
    final recorder = _recorder;
    _recorder = null;
    try { await recorder?.cancel(); } catch (_) {}
    try { await recorder?.dispose(); } catch (_) {}
    if (_recordingPath != null) {
      _cleanupTempFile(_recordingPath!);
    }
  }

  Future<bool> isModelReady() => _modelService.isModelDownloaded();
  Stream<double> get modelDownloadProgress => _modelService.onProgress;
  Future<bool> downloadModel() => _modelService.downloadModel();

  void reset() {
    _isListening = false;
    if (_recorder != null) {
      try { _recorder!.cancel(); } catch (_) {}
      try { _recorder!.dispose(); } catch (_) {}
      _recorder = null;
    }
  }

  void dispose() {
    reset();
    _recognizer?.free();
    _recognizer = null;
    _resultController.close();
  }

  void _cleanupTempFile(String? path) {
    if (path == null) return;
    try { File(path).deleteSync(); } catch (_) {}
  }
}

class _SpeechResult {
  final String? text;
  final bool isLast;
  final String? error;
  const _SpeechResult({this.text, this.isLast = false, this.error});
  bool get hasError => error != null;
}
