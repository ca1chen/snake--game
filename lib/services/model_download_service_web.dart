import 'dart:async';

/// 离线语音模型下载服务（Web 端：无需下载，浏览器云端识别）
class ModelDownloadService {
  static final ModelDownloadService _instance = ModelDownloadService._();
  factory ModelDownloadService() => _instance;
  ModelDownloadService._();

  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  Stream<double> get onProgress => _progressController.stream;

  /// Web Speech API 不需要离线模型
  Future<bool> isModelDownloaded() async => true;

  /// Web 端不使用这些路径
  Future<String> get modelPath async => '';
  Future<String> get tokensPath async => '';

  /// 空操作
  Future<bool> downloadModel() async {
    _progressController.add(1.0);
    return true;
  }

  void dispose() => _progressController.close();
}
