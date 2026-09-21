import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import '../services/google_auth_service.dart';
import 'auth_text_field.dart';
import 'google_logo.dart';
import 'google_username_setup_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

/// The app's first screen after the native splash. If no [economy] is
/// passed in, this is the root of the navigation stack, so it creates and
/// owns the single shared [Economy] instance (and kicks off [GameAudio]
/// with it) — every other screen receives that same instance rather than
/// creating its own. When reached instead from Home's "Mi perfil" (already
/// has an [economy]), it reuses that one.
///
/// Talks to the real backend at `server/api_turret` via [ApiClient]. When
/// this is the root screen, it first tries to restore a "remembered"
/// session (see [ApiClient.loadSession]) and skips straight to Home if the
/// token still checks out.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.economy});

  final Economy? economy;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _submitting = false;
  bool _checkingSession = false;
  String? _errorText;

  late final Economy _economy;

  @override
  void initState() {
    super.initState();
    final provided = widget.economy;
    if (provided != null) {
      _economy = provided;
    } else {
      _economy = Economy();
      GameAudio.instance.init(_economy);
      _economy.loadPersisted();
      GameAudio.instance.playMenuMusic();
      _checkingSession = true;
      _restoreSession();
    }
  }

  Future<void> _restoreSession() async {
    try {
      await ApiClient.loadSession();
      if (!ApiClient.hasToken) {
        if (mounted) setState(() => _checkingSession = false);
        return;
      }
      // Cheap way to confirm the remembered token hasn't been revoked/expired.
      await ApiClient.get('/profile');
      if (!mounted) return;
      _proceedToHome();
    } on ApiException catch (e) {
      // Only a genuine "unauthenticated" response means the token itself is
      // bad — clear it. A network/WAF hiccup shouldn't wipe an otherwise
      // valid remembered session; just fall back to the login form and let
      // the next launch retry.
      if (e.statusCode == 401) {
        try {
          await ApiClient.logout();
        } catch (_) {}
      }
      if (mounted) setState(() => _checkingSession = false);
    } catch (_) {
      if (mounted) setState(() => _checkingSession = false);
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// If Login was pushed on top of an existing Home (e.g. from "Mi perfil"),
  /// just pop back to it. If Login is the root of the stack (fresh app
  /// launch), push Home to replace it.
  void _proceedToHome() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(economy: _economy)),
      );
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    try {
      await ApiClient.login(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
        remember: _rememberMe,
      );
      if (!mounted) return;
      _proceedToHome();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.message;
        _submitting = false;
      });
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    try {
      final idToken = await GoogleAuthService.signIn();
      if (idToken == null) {
        // User closed the account picker without choosing one.
        if (mounted) setState(() => _submitting = false);
        return;
      }
      final result = await ApiClient.google(idToken: idToken, remember: _rememberMe);
      if (!mounted) return;
      if (result['is_new_user'] == true) {
        final completed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => GoogleUsernameSetupScreen(economy: _economy)),
        );
        if (!mounted || completed != true) {
          // They cancelled (logged out) instead of finishing setup.
          setState(() => _submitting = false);
          return;
        }
      }
      _proceedToHome();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.message;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = '$e';
        _submitting = false;
      });
    }
  }

  void _goToRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => RegisterScreen(economy: _economy)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings(_economy.language);

    if (_checkingSession) {
      return const Scaffold(
        backgroundColor: Color(0xFF2A2018),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFCB7B2A))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2A2018),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset('assets/images/ui/MenuBanner.png', width: 200),
                ),
                const SizedBox(height: 28),
                AuthTextField(
                  controller: _identifierController,
                  label: s.usernameOrEmail,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _passwordController,
                  label: s.password,
                  obscureText: _obscurePassword,
                  validator: (v) => (v == null || v.isEmpty) ? s.fieldRequired : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.white54,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v ?? true),
                      activeColor: const Color(0xFF3E9B4F),
                    ),
                    Expanded(
                      child: Text(s.rememberMe, style: const TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCB7B2A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                        )
                      : Text(
                          s.logIn,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(s.orContinueWith, style: const TextStyle(color: Colors.white38)),
                    ),
                    const Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: _submitting ? null : _continueWithGoogle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide.none,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GoogleLogo(size: 20),
                      const SizedBox(width: 10),
                      Text(
                        s.continueWithGoogle,
                        style: const TextStyle(
                          color: Color(0xFF3C4043),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s.noAccountYet, style: const TextStyle(color: Colors.white70)),
                    GestureDetector(
                      onTap: _goToRegister,
                      child: Text(
                        s.registerLink,
                        style: const TextStyle(
                          color: Color(0xFFCB7B2A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
