import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around `google_sign_in`, configured with the Web OAuth
/// client (see server/api_turret/.env's GOOGLE_CLIENT_ID — same value,
/// pulled from android/app/google-services.json's auto-generated web
/// client) as `serverClientId`, so the id_token this returns is
/// audience-matched to what `GoogleAuthService::verify()` checks server-side.
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleSignIn _instance = GoogleSignIn(
    serverClientId: '430434080681-aqa6657i83vrjhfmcdl6u4emkeavmke7.apps.googleusercontent.com',
    scopes: const ['email'],
  );

  /// Shows the account picker and returns the ID token to send to
  /// `POST /auth/google`, or null if the user cancelled it.
  static Future<String?> signIn() async {
    final account = await _instance.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  }

  static Future<void> signOut() => _instance.signOut();
}
