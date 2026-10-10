import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// لیست آدرس‌های بک‌اند به ترتیب اولویت (HTTPS، سپس HTTP، و در نهایت IP مستقیم)
const List<String> kBaseUrls = [
  'https://alpha.mewshkel.sbs:8000',
  'http://alpha.mewshkel.sbs:8000',
  'http://83.228.224.223:8000',
];

/// آدرس فعال پیش‌فرض
String get kBaseUrl => ApiService().activeBaseUrl;

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

  String _activeBaseUrl = kBaseUrls.first;
  String get activeBaseUrl => _activeBaseUrl;

  final http.Client _client = http.Client();
  static const _timeout = Duration(seconds: 8);

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

  // ── Fallback Executor ───────────────────────────────────────

  Future<http.Response> _executeWithFallback(
    Future<http.Response> Function(String baseUrl) requestFn,
  ) async {
    // ابتدا آدرس فعال را امتحان کن، سپس سایر آدرس‌های جایگزین
    final candidates = [
      _activeBaseUrl,
      ...kBaseUrls.where((u) => u != _activeBaseUrl),
    ];

    dynamic lastError;

    for (int i = 0; i < candidates.length; i++) {
      final currentUrl = candidates[i];
      try {
        final res = await requestFn(currentUrl).timeout(_timeout);

        // اگر خطای سمت سرور (5xx) داد و هنوز آدرس جایگزین دیگری داریم، آدرس بعدی را امتحان کن
        if (res.statusCode >= 500 && i < candidates.length - 1) {
          lastError = ApiException(res.statusCode, 'خطای سرور');
          continue;
        }

        // موفقیت در اتصال — ذخیره آدرس فعال برای درخواست‌های بعدی
        _activeBaseUrl = currentUrl;
        return res;
      } on SocketException catch (e) {
        lastError = e;
      } on HandshakeException catch (e) {
        lastError = e;
      } on TlsException catch (e) {
        lastError = e;
      } on http.ClientException catch (e) {
        lastError = e;
      } on TimeoutException catch (e) {
        lastError = e;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError is TimeoutException) {
      throw const NetworkException('سرور پاسخ نداد — دوباره تلاش کن');
    } else if (lastError is SocketException) {
      throw const NetworkException('اتصال به اینترنت برقرار نیست');
    } else if (lastError is http.ClientException) {
      throw NetworkException(lastError.message);
    } else if (lastError is ApiException) {
      throw lastError;
    } else {
      throw const NetworkException('خطا در برقراری ارتباط با سرور');
    }
  }

  // ── Response parser ────────────────────────────────────────

  Map<String, dynamic> _parse(http.Response res) {
    final body = utf8.decode(res.bodyBytes);
    final json = jsonDecode(body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      // بک‌اند همه چیز رو داخل { success: true, data: {...} } میفرسته
      if (json is Map<String, dynamic> &&
          json.containsKey('success') &&
          json.containsKey('data')) {
        final data = json['data'];
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      return json is Map<String, dynamic> ? json : {'data': json};
    }

    final detail = json is Map
        ? (json['detail'] ?? json['message'] ?? 'خطای ناشناخته')
        : 'خطای ناشناخته';
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
    final headers = await _headers(auth: auth);
    final res = await _executeWithFallback(
      (baseUrl) => _client.get(Uri.parse('$baseUrl$path'), headers: headers),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final headers = await _headers(auth: auth);
    final payload = jsonEncode(body);
    final res = await _executeWithFallback(
      (baseUrl) => _client.post(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: payload,
      ),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final headers = await _headers(auth: auth);
    final payload = jsonEncode(body);
    final res = await _executeWithFallback(
      (baseUrl) => _client.patch(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: payload,
      ),
    );
    return _parse(res);
  }
}
