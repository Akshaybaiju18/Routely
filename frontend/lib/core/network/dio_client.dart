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
    return 'http://127.0.0.1:8000/api/';
  }
}
