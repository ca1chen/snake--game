import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

import 'model_download_service.dart';

/// 离线语音识别服务封装
///
/// 使用 sherpa_onnx Paraformer 中文 Small 模型 + record 录音实现完全离线识别。
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

  /// 确保 sherpa_onnx 和模型已就绪
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

  /// 开始录音
  Future<void> startListening() async {
    // 若已处于监听状态，先强制取消并等待清理，避免并发竞态
    if (_isListening) {
      await cancelListening();
    }

    // 1. 确保模型就绪
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

    // 2. 彻底清理上一次的 recorder
    if (_recorder != null) {
      try { await _recorder!.dispose(); } catch (_) {}
      _recorder = null;
    }

    // 3. 标记状态，尽早让 stopListening 可识别
    _isListening = true;

    // 4. 创建新 recorder 并检查权限
    final recorder = AudioRecorder();
    // hasPermission 内部会等 semaphore，顺带等 recorder 初始化完成
    final hasPermission = await recorder.hasPermission();
    if (!hasPermission) {
      _isListening = false;
      recorder.dispose();
      final err = '麦克风权限未授予';
      _resultController.add(_SpeechResult(error: err));
      throw Exception(err);
    }

    // 5. 获取临时目录
    final tempDir = await getTemporaryDirectory();
    _recordingPath = '${tempDir.path}/voice_'
        '${DateTime.now().millisecondsSinceEpoch}.wav';

    // 6. 开始录音
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

  /// 停止录音并离线识别
  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;

    final recorder = _recorder;
    _recorder = null;
    final recordingPath = _recordingPath;

    // 1. 停止录音
    String? filePath;
    try {
      filePath = await recorder?.stop();
    } catch (e) {
      _resultController.add(_SpeechResult(error: '停止录音失败: $e'));
      try { await recorder?.dispose(); } catch (_) {}
      return;
    }
    filePath ??= recordingPath;

    // 2. 释放 recorder（注意：只用 dispose，不用 cancel——cancel 会删文件）
    try { await recorder?.dispose(); } catch (_) {}

    // 3. 验证文件存在
    if (filePath == null || !File(filePath).existsSync()) {
      _resultController.add(_SpeechResult(
        error: '录音文件不存在${filePath != null ? ': $filePath' : ''}',
      ));
      // 即使文件不存在，也清理可能的遗留路径
      _cleanupTempFile(recordingPath);
      return;
    }

    // 4. 离线识别
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
      // 无论成功或失败，都删除临时文件
      _cleanupTempFile(filePath);
      _cleanupTempFile(recordingPath);
    }
  }

  /// 取消录音
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

  /// 检查模型是否已下载
  Future<bool> isModelReady() => _modelService.isModelDownloaded();

  /// 模型下载进度流
  Stream<double> get modelDownloadProgress => _modelService.onProgress;

  /// 下载模型
  Future<bool> downloadModel() => _modelService.downloadModel();

  /// 重置当前录音会话状态（页面退出时调用，不关闭单例资源）
  void reset() {
    _isListening = false;
    if (_recorder != null) {
      try { _recorder!.cancel(); } catch (_) {}
      try { _recorder!.dispose(); } catch (_) {}
      _recorder = null;
    }
  }

  /// 释放所有资源（仅在应用退出时调用）
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

/// 语音识别结果
class _SpeechResult {
  final String? text;
  final bool isLast;
  final String? error;

  const _SpeechResult({this.text, this.isLast = false, this.error});

  bool get hasError => error != null;
}
