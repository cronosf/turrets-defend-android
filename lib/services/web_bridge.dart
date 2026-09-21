import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

void _log(String msg) => debugPrint('TUERRETCRO_API | $msg');

/// Runs API requests INSIDE a headless WebView loaded on the real domain
/// (see [origin]), instead of calling the API directly with `package:http`.
///
/// Why: shared hosts running the Imunify360 firewall serve a JS challenge to
/// unknown clients and block "bare" HTTP clients (like Dart's `http`
/// package) with "Access denied by Imunify360 bot-protection". A real
/// browser solves that JS challenge automatically and gets a pass-through
/// cookie. Running the `fetch()` calls from inside the WebView (same
/// origin, same cookie, same User-Agent) makes them look like the web's own
/// traffic. This exact approach is already proven working in production for
/// another app on the same kind of hosting.
class WebBridge {
  WebBridge._();

  /// Domain loaded in the WebView to pass the Imunify360 challenge.
  static const String origin = 'https://disfracescharos.com';

  /// Real mobile-browser User-Agent (needed so Imunify360 treats the
  /// session as a browser and hands out the pass-through cookie).
  static const String _userAgent =
      'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  static HeadlessInAppWebView? _webView;
  static InAppWebViewController? _ctrl;
  static bool _ready = false;
  static Completer<void>? _initing;

  /// Boots the headless WebView (once) and waits for the domain to load,
  /// giving Imunify360 time to resolve its JS challenge and set its cookie.
  static Future<void> ensureReady() async {
    if (_ready && _ctrl != null) return;
    if (_initing != null) return _initing!.future;
    _initing = Completer<void>();

    final loaded = Completer<void>();
    try {
      _webView = HeadlessInAppWebView(
        // A 0px WebView can fail to run the JS challenge, so use a real size.
        initialSize: const Size(1080, 2000),
        initialUrlRequest: URLRequest(url: WebUri('$origin/')),
        initialSettings: InAppWebViewSettings(
          userAgent: _userAgent,
          javaScriptEnabled: true,
          clearCache: false,
          cacheEnabled: true,
          incognito: false,
          thirdPartyCookiesEnabled: true,
          domStorageEnabled: true,
          databaseEnabled: true,
        ),
        onLoadStop: (controller, url) {
          _ctrl = controller;
          _log('onLoadStop url=$url');
          if (!loaded.isCompleted) loaded.complete();
        },
        onReceivedError: (controller, request, error) {
          _ctrl = controller;
          _log('onReceivedError ${error.type} ${error.description}');
          if (!loaded.isCompleted) loaded.complete();
        },
      );
      await _webView!.run();
      _log('webview run() ok, esperando carga…');

      await loaded.future.timeout(
        const Duration(seconds: 25),
        onTimeout: () => _log('timeout esperando primera carga'),
      );

      // Margin for Imunify360's JS challenge to finish and set its cookie.
      await Future.delayed(const Duration(milliseconds: 1800));

      _ready = true;
      _initing!.complete();
      _log('ensureReady completo');
    } catch (e) {
      _initing!.completeError(e);
      _initing = null;
      rethrow;
    }
  }

  /// JSON/normal request (GET/POST) via the WebView's fetch. Retries if
  /// Imunify360 hasn't cleared the session yet.
  static Future<http.Response> request({
    required String method,
    required String url,
    Map<String, String>? headers,
    String? body,
  }) async {
    await ensureReady();

    http.Response last = http.Response('', 599);
    for (var attempt = 0; attempt < 5; attempt++) {
      last = await _fetch(method: method, url: url, headers: headers, body: body);
      final prefix = last.body.length > 120 ? last.body.substring(0, 120) : last.body;
      _log('fetch[$attempt] $method $url -> ${last.statusCode} | $prefix');

      if (!last.body.contains('Imunify360')) return last;

      // Still blocked: reload the domain to force the JS challenge and wait.
      try {
        await _ctrl?.loadUrl(urlRequest: URLRequest(url: WebUri('$origin/')));
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 2200));
    }
    return last;
  }

  static Future<http.Response> _fetch({
    required String method,
    required String url,
    Map<String, String>? headers,
    String? body,
  }) async {
    final ctrl = _ctrl;
    if (ctrl == null) return http.Response('', 599);

    final result = await ctrl.callAsyncJavaScript(
      functionBody: r"""
        try {
          const opt = { method: method, headers: headers || {}, credentials: 'include' };
          if (body !== null && body !== undefined && method !== 'GET' && method !== 'HEAD') {
            opt.body = body;
          }
          const r = await fetch(url, opt);
          const t = await r.text();
          return { status: r.status, body: t };
        } catch (e) {
          return { status: 0, body: 'WEBVIEW_FETCH_ERROR: ' + (e && e.message ? e.message : e) };
        }
      """,
      arguments: {
        'url': url,
        'method': method,
        'headers': headers ?? <String, String>{},
        'body': body,
      },
    );

    return _toResponse(result?.value);
  }

  static http.Response _toResponse(dynamic value) {
    if (value is Map) {
      final status = (value['status'] is num)
          ? (value['status'] as num).toInt()
          : int.tryParse('${value['status']}') ?? 0;
      final body = value['body']?.toString() ?? '';
      return http.Response(
        body,
        status == 0 ? 599 : status,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    }
    return http.Response('', 599);
  }
}
