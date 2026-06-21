import 'dart:async';
import 'dart:html' as html;

import 'model_download_service_stub.dart'
    if (dart.library.io) 'model_download_service_mobile.dart'
    if (dart.library.js_interop) 'model_download_service_web.dart';

/// Web Speech API 封装（Web 端：浏览器内置 SpeechRecognition API）
class SpeechService {
  static final SpeechService _instance = SpeechService._();
  factory SpeechService() => _instance;
  SpeechService._();

  final ModelDownloadService _modelService = ModelDownloadService();
  bool _isListening = false;
  html.SpeechRecognition? _recognition;

  final StreamController<_SpeechResult> _resultController =
      StreamController<_SpeechResult>.broadcast();

  Stream<_SpeechResult> get onResult => _resultController.stream;
  bool get isListening => _isListening;

  /// 检测浏览器是否支持 SpeechRecognition
  static bool get isSupported {
    // iOS 上所有浏览器（含 Chrome/Edge）均不支持 Web Speech API
    // 因为 Apple 强制所有浏览器使用 WebKit
    try {
      final ua = html.window.navigator.userAgent.toLowerCase();
      if (ua.contains('iphone') || ua.contains('ipad')) return false;
    } catch (_) {}

    try {
      html.SpeechRecognition();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> startListening() async {
    if (_isListening) {
      await cancelListening();
    }

    try {
      if (!isSupported) {
        _resultController.add(const _SpeechResult(
            error: '当前浏览器不支持语音识别，iOS 请用桌面端 Chrome'));
        return;
      }

      final rec = html.SpeechRecognition()
        ..lang = 'zh-CN'
        ..interimResults = true
        ..continuous = true;

      // onresult — 每段识别结果回调
      rec.onResult.listen((html.SpeechRecognitionEvent event) {
        final results = event.results;
        if (results == null || results.isEmpty) return;

        final lastResult = results.last;
        if (lastResult == null || lastResult.length == 0) return;

        final firstAlt = lastResult.item(0);
        final text = firstAlt?.transcript ?? '';
        final isFinal = lastResult.isFinal ?? false;

        if (text.isNotEmpty) {
          _resultController.add(_SpeechResult(text: text, isLast: isFinal));
        }
      });

      // onend — 识别结束
      rec.onEnd.listen((_) {
        _isListening = false;
      });

      // onerror — 识别出错
      rec.onError.listen((html.SpeechRecognitionError event) {
        final error = event.message ?? event.error ?? 'unknown';
        _resultController.add(_SpeechResult(error: '语音识别错误: $error'));
        _isListening = false;
      });

      rec.start();
      _recognition = rec;
      _isListening = true;
    } catch (e) {
      _isListening = false;
      _resultController.add(_SpeechResult(error: '启动失败: $e'));
      rethrow;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening || _recognition == null) return;
    try {
      _recognition!.stop();
    } catch (_) {}
    _isListening = false;
  }

  Future<void> cancelListening() async {
    if (!_isListening) return;
    _isListening = false;
    try {
      _recognition?.abort();
    } catch (_) {}
    _recognition = null;
  }

  Future<bool> isModelReady() => _modelService.isModelDownloaded();
  Stream<double> get modelDownloadProgress => _modelService.onProgress;
  Future<bool> downloadModel() => _modelService.downloadModel();
  void reset() => _isListening = false;
  void dispose() => _resultController.close();
}

class _SpeechResult {
  final String? text;
  final bool isLast;
  final String? error;
  const _SpeechResult({this.text, this.isLast = false, this.error});
  bool get hasError => error != null;
}
