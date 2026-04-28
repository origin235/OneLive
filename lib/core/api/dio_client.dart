import 'package:dio/dio.dart';
import 'package:simple_live_core/simple_live_core.dart';

class DioClient {
  static DioClient? _instance;

  static DioClient get instance {
    _instance ??= DioClient();
    return _instance!;
  }

  late Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ),
    );
    dio.interceptors.add(CustomInterceptor());
  }
}

/// API 异常，携带 HTTP 状态码和平台信息
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? platform;

  ApiException(this.message, {this.statusCode = 0, this.platform});

  @override
  String toString() => '[${platform ?? "API"}] $message (HTTP $statusCode)';
}
