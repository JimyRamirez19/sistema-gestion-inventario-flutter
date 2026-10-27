import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static const int connectTimeoutSeconds = 10;
  static const int receiveTimeoutSeconds = 10;

  static String get baseUrl {
    if (dotenv.isInitialized) {
      final rawUrl = dotenv.env['API_BASE_URL'];
      if (rawUrl != null && rawUrl.trim().isNotEmpty) {
        final trimmed = rawUrl.trim();
        if (!kIsWeb && Platform.isAndroid) {
          if (trimmed.contains('localhost')) {
            return trimmed.replaceAll('localhost', '10.0.2.2');
          }
          if (trimmed.contains('127.0.0.1')) {
            return trimmed.replaceAll('127.0.0.1', '10.0.2.2');
          }
        }
        return trimmed;
      }
    }

    // Default intelligent fallback based on platform
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  static const String productosEndpoint = '/productos';
}
