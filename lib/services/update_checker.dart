import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_version.dart';

/// Info about an available update, returned by [UpdateChecker.check] when
/// the latest GitHub release is newer than [kAppVersion].
class UpdateInfo {
  const UpdateInfo({required this.version, required this.downloadUrl, required this.notes});

  final String version;
  final String downloadUrl;
  final String notes;
}

/// Checks the GitHub Releases of this app's own repo for a newer version
/// than the one currently installed, so the app can prompt the player to
/// download the new APK (the project isn't on Play Store, so there's no
/// automatic update channel otherwise).
///
/// Talks directly to api.github.com with `package:http` — unlike
/// disfracescharos.com, GitHub isn't behind the Imunify360 firewall, so
/// there's no need to go through [WebBridge] here.
class UpdateChecker {
  UpdateChecker._();

  static const String _latestReleaseUrl =
      'https://api.github.com/repos/cronosf/turrets-defend-android/releases/latest';

  /// Returns update info if a newer release is available, or null if
  /// already up to date, there are no releases yet, or the check failed
  /// (no internet, GitHub unreachable, etc. — this is best-effort and
  /// should never block or crash the app).
  static Future<UpdateInfo?> check() async {
    try {
      final response = await http
          .get(Uri.parse(_latestReleaseUrl), headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = data['tag_name']?.toString();
      if (tag == null || !_isNewer(tag, kAppVersion)) return null;

      final assets = data['assets'] as List<dynamic>? ?? [];
      String? downloadUrl;
      for (final asset in assets) {
        final name = asset['name']?.toString() ?? '';
        if (name.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url']?.toString();
          break;
        }
      }
      // Fall back to the release page itself if no .apk asset is attached.
      downloadUrl ??= data['html_url']?.toString();
      if (downloadUrl == null) return null;

      return UpdateInfo(
        version: tag,
        downloadUrl: downloadUrl,
        notes: data['body']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Compares two "vX.Y.Z" version strings; true if [remote] > [local].
  static bool _isNewer(String remote, String local) {
    final r = _parse(remote);
    final l = _parse(local);
    for (var i = 0; i < 3; i++) {
      if (r[i] != l[i]) return r[i] > l[i];
    }
    return false;
  }

  static List<int> _parse(String version) {
    final clean = version.startsWith('v') ? version.substring(1) : version;
    final parts = clean.split('.');
    return List.generate(3, (i) => i < parts.length ? int.tryParse(parts[i]) ?? 0 : 0);
  }
}
