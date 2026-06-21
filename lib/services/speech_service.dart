import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/logger.dart';

/// 语音识别服务 — 封装 speech_to_text 插件
/// 管理录音生命周期：初始化 → 开始监听 → 实时回调 → 停止返回
class SpeechService {
  static final stt.SpeechToText _stt = stt.SpeechToText();

  static bool _initialized = false;
  static bool get isAvailable => _stt.isAvailable;
  static bool get isListening => _stt.isListening;

  /// 初始化语音引擎（整个页面生命周期调用一次）
  static Future<bool> initialize() async {
    if (_initialized && _stt.isAvailable) return true;

    try {
      _initialized = await _stt.initialize(
        onStatus: (status) => Logger.d('Speech', 'Status: $status'),
        onError: (error) => Logger.e('Speech', 'Error: $error'),
        debugLogging: false,
      );
      Logger.d('Speech', 'Initialized: $_initialized, available: ${_stt.isAvailable}');
      return _initialized;
    } catch (e) {
      Logger.e('Speech', 'Initialize failed: $e');
      return false;
    }
  }

  /// 开始监听（中文普通话）
  /// [onResult] — 实时识别结果回调（partialResults 会产生多次回调）
  /// [onStatus] — 状态变化回调，如 "listening"、"done"、"notListening"
  static Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(String status)? onStatus,
  }) async {
    if (!_stt.isAvailable) {
      final ok = await initialize();
      if (!ok) return;
    }

    await _stt.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        final isFinal = result.finalResult;
        onResult(text, isFinal);
      },
      localeId: 'zh_CN',
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      onDevice: true,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: false,
    );
  }

  /// 停止监听，返回最终识别文本
  static Future<String> stopListening() async {
    if (!_stt.isListening) return '';
    final text = _stt.lastRecognizedWords;
    await _stt.stop();
    return text;
  }

  /// 取消监听（不保存结果）
  static Future<void> cancel() async {
    if (_stt.isListening) {
      await _stt.cancel();
    }
  }
}
