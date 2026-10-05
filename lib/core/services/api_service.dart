import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// آدرس بک‌اند
const String kBaseUrl = 'http://179.237.79.75';

const _storage = FlutterSecureStorage();
const _tokenKey = 'alpha_vpn_token';

// ─────────────────────────────────────────────────────────────
// Exception های سفارشی
// ─────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException(String message) : super(401, message);
}

class ForbiddenException extends ApiException {
  const ForbiddenException(String message) : super(403, message);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => 'NetworkException: $message';
}

// ─────────────────────────────────────────────────────────────
// ApiService
// ─────────────────────────────────────────────────────────────

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  static const _timeout = Duration(seconds: 15);

  // ── Token management ───────────────────────────────────────

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<bool> get hasToken async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  // ── Header builder ─────────────────────────────────────────

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Response parser ────────────────────────────────────────

  Map<String, dynamic> _parse(http.Response res) {
    final body = utf8.decode(res.bodyBytes);
    final json = jsonDecode(body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return json is Map<String, dynamic> ? json : {'data': json};
    }
    final detail = json is Map ? (json['detail'] ?? 'خطای ناشناخته') : 'خطای ناشناخته';
    switch (res.statusCode) {
      case 401:
        throw UnauthorizedException(detail.toString());
      case 403:
        throw ForbiddenException(detail.toString());
      default:
        throw ApiException(res.statusCode, detail.toString());
    }
  }

  // ── HTTP verbs ─────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    bool auth = true,
  }) async {
    try {
      final res = await _client
          .get(Uri.parse('$kBaseUrl$path'), headers: await _headers(auth: auth))
          .timeout(_timeout);
      return _parse(res);
    } on SocketException {
      throw const NetworkException('اتصال به اینترنت برقرار نیست');
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    } on TimeoutException {
      throw const NetworkException('سرور پاسخ نداد — دوباره تلاش کن');
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    try {
      final res = await _client
          .post(Uri.parse('$kBaseUrl$path'),
              headers: await _headers(auth: auth), body: jsonEncode(body))
          .timeout(_timeout);
      return _parse(res);
    } on SocketException {
      throw const NetworkException('اتصال به اینترنت برقرار نیست');
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    } on TimeoutException {
      throw const NetworkException('سرور پاسخ نداد — دوباره تلاش کن');
    }
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final res = await _client
          .patch(Uri.parse('$kBaseUrl$path'),
              headers: await _headers(auth: auth), body: jsonEncode(body))
          .timeout(_timeout);
      return _parse(res);
    } on SocketException {
      throw const NetworkException('اتصال به اینترنت برقرار نیست');
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    } on TimeoutException {
      throw const NetworkException('سرور پاسخ نداد — دوباره تلاش کن');
    }
  }
}
