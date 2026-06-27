import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioClient {
  final Dio dio;

  DioClient() : dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api/';
      }
    } catch (_) {
      // Platform check can throw on unsupported systems/runtimes
    }
    return 'http://localhost:8000/api/';
  }
}
