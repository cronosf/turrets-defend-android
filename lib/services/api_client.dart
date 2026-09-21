import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'web_bridge.dart';

/// Thrown when the API returns an error (status >= 400) or the request
/// itself fails (network/timeout/WAF block).
class ApiException implements Exception {
  ApiException(this.message, this.statusCode, [this.code]);

  final String message;
  final int statusCode;
  final String? code;

  @override
  String toString() => message;
}

/// Central HTTP client for the TuerretCro backend (`server/api_turret`).
///
/// Requests go straight over `package:http` first — the `.htaccess` on
/// `/api_turret/` already disables the hosting's Imunify360 firewall for
/// this path, confirmed by extensive direct testing with zero blocks. Only
/// if a response actually looks WAF-blocked does a call retry through
/// [WebBridge]'s headless WebView, which is slow to spin up (a real
/// browser engine booting) but survives a live Imunify360 challenge. Doing
/// it this way instead of always going through the WebView keeps every
/// screen's first load fast in the common case, while still self-healing
/// if the WAF ever does kick in.
///
/// Holds the bearer token + logged-in user in memory, persisting them to
/// SharedPreferences only when the caller asks to be "remembered".
class ApiClient {
  ApiClient._();

  static const String baseUrl = 'https://disfracescharos.com/api_turret';

  static const _tokenKey = 'api_auth_token';
  static const _userKey = 'api_auth_user';

  static String? _token;
  static Map<String, dynamic>? _user;

  static String? get token => _token;
  static bool get hasToken => _token != null && _token!.isNotEmpty;
  static Map<String, dynamic>? get currentUser => _user;

  /// Restores a previously "remembered" session, if any. No-op (and leaves
  /// [hasToken] false) if the user didn't check "remember me" last time,
  /// since nothing was written to disk in that case.
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        _user = jsonDecode(userJson) as Map<String, dynamic>;
      } catch (_) {
        _user = null;
      }
    }
  }

  static Future<void> _persistSession(
    String token,
    Map<String, dynamic>? user, {
    required bool remember,
  }) async {
    _token = token;
    _user = user;
    if (!remember) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (user != null) await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // ─── Auth ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    required bool remember,
  }) async {
    final data = await post('/auth/login', body: {
      'identifier': identifier,
      'password': password,
    }) as Map<String, dynamic>;
    await _persistSession(
      data['token'] as String,
      data['user'] as Map<String, dynamic>?,
      remember: remember,
    );
    return data;
  }

  /// Live uniqueness check backing the register form and the Google
  /// sign-up username modal. Pass only the field(s) you want checked.
  static Future<Map<String, dynamic>> checkAvailability({String? username, String? email}) async {
    final data = await get('/auth/availability', query: {
      'username': ?username,
      'email': ?email,
    });
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> google({
    required String idToken,
    required bool remember,
  }) async {
    final data = await post('/auth/google', body: {'id_token': idToken}) as Map<String, dynamic>;
    await _persistSession(
      data['token'] as String,
      data['user'] as Map<String, dynamic>?,
      remember: remember,
    );
    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? countryCode,
    required bool remember,
  }) async {
    final data = await post('/auth/register', body: {
      'username': username,
      'email': email,
      'password': password,
      'country_code': ?countryCode,
    }) as Map<String, dynamic>;
    await _persistSession(
      data['token'] as String,
      data['user'] as Map<String, dynamic>?,
      remember: remember,
    );
    return data;
  }

  // ─── Verbos ──────────────────────────────────────────────────────────────

  static Map<String, String> _headers({bool json = true}) {
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (hasToken) 'Authorization': 'Bearer $_token',
    };
  }

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseUrl/$clean').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  static Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    final uri = _uri(path, query);
    return _send(
      direct: () => http.get(uri, headers: _headers(json: false)),
      viaBridge: () => WebBridge.request(method: 'GET', url: uri.toString(), headers: _headers(json: false)),
    );
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body}) {
    final uri = _uri(path);
    final encodedBody = jsonEncode(body ?? {});
    return _send(
      direct: () => http.post(uri, headers: _headers(), body: encodedBody),
      viaBridge: () => WebBridge.request(method: 'POST', url: uri.toString(), headers: _headers(), body: encodedBody),
    );
  }

  // ─── Núcleo ──────────────────────────────────────────────────────────────

  static Future<dynamic> _send({
    required Future<http.Response> Function() direct,
    required Future<http.Response> Function() viaBridge,
  }) async {
    try {
      final response = await direct().timeout(const Duration(seconds: 15));
      if (!_looksWafBlocked(response)) return _parse(response);
    } on ApiException {
      // A real API error (4xx/5xx business logic, e.g. wrong password) —
      // not a connectivity/WAF issue, so don't waste time retrying.
      rethrow;
    } catch (_) {
      // Direct call failed outright (timeout, no connection, WAF hanging
      // the connection, etc.) — fall through to the WebView bridge below
      // rather than failing outright; a genuine no-internet failure will
      // fail there too, just slower.
    }

    try {
      final response = await viaBridge().timeout(const Duration(seconds: 60));
      return _parse(response);
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw ApiException('Sin conexión a internet. (${e.message})', 0);
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder (timeout).', 0);
    } catch (e) {
      throw ApiException('Fallo de red: $e', 0);
    }
  }

  static bool _looksWafBlocked(http.Response response) {
    return response.body.contains('Imunify360');
  }

  static dynamic _parse(http.Response response) {
    final status = response.statusCode;
    final bodyTxt = response.body;

    if (bodyTxt.startsWith('WEBVIEW_FETCH_ERROR')) {
      throw ApiException('Error de conexión con el servidor.', 0);
    }
    if (bodyTxt.contains('Imunify360')) {
      throw ApiException(
        'El firewall del servidor está bloqueando la app temporalmente. Intenta de nuevo en unos segundos.',
        403,
      );
    }

    dynamic data;
    if (bodyTxt.isNotEmpty) {
      try {
        data = jsonDecode(bodyTxt);
      } catch (_) {
        data = bodyTxt;
      }
    }

    if (status >= 200 && status < 300) return data;

    String msg = 'Error ($status)';
    String? code;
    if (data is Map && data['message'] != null) {
      msg = data['message'].toString();
      code = data['code']?.toString();
    }
    throw ApiException(msg, status, code);
  }
}
