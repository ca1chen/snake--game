import 'dart:async';

/// Stub — 仅用于分析器，运行时不会被加载。
class ModelDownloadService {
  static final ModelDownloadService _instance = ModelDownloadService._();
  factory ModelDownloadService() => _instance;
  ModelDownloadService._();

  final StreamController<double> _progressController =
      StreamController<double>.broadcast();
  Stream<double> get onProgress => _progressController.stream;

  Future<bool> isModelDownloaded() =>
      throw UnsupportedError('Platform not supported');
  Future<String> get modelPath =>
      throw UnsupportedError('Platform not supported');
  Future<String> get tokensPath =>
      throw UnsupportedError('Platform not supported');
  Future<bool> downloadModel() =>
      throw UnsupportedError('Platform not supported');
  void dispose() => _progressController.close();
}
