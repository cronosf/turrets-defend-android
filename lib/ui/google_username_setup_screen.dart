import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import 'auth_text_field.dart';
import 'availability_hint.dart';
import 'login_screen.dart';
import 'terms_dialog.dart';

/// Shown once, right after a BRAND NEW account is created via Google
/// sign-in (see AuthController::google's `is_new_user` flag) — before the
/// app ever reaches Home. Lets the player pick their own 4-12 character
/// username (instead of the auto-generated placeholder) and requires
/// accepting the Terms, same as the regular register flow. Not dismissible
/// via the back button — the only way out besides completing it is
/// "Cancelar y cerrar sesión".
class GoogleUsernameSetupScreen extends StatefulWidget {
  const GoogleUsernameSetupScreen({super.key, required this.economy});

  final Economy economy;

  @override
  State<GoogleUsernameSetupScreen> createState() => _GoogleUsernameSetupScreenState();
}

class _GoogleUsernameSetupScreenState extends State<GoogleUsernameSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _acceptedTerms = false;
  bool _submitting = false;
  String? _errorText;

  Timer? _debounce;
  bool? _usernameAvailable;
  bool _checkingAvailability = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounce?.cancel();
    setState(() => _usernameAvailable = null);
    final trimmed = value.trim();
    if (trimmed.length < 4 || trimmed.length > 12) return;
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _checkingAvailability = true);
      try {
        final result = await ApiClient.checkAvailability(username: trimmed);
        if (!mounted || _usernameController.text.trim() != trimmed) return;
        setState(() => _usernameAvailable = result['username_available'] as bool?);
      } catch (_) {
        // Best-effort only; the server still validates on submit.
      } finally {
        if (mounted) setState(() => _checkingAvailability = false);
      }
    });
  }

  Future<void> _submit(Strings s) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.mustAcceptTerms), duration: const Duration(seconds: 3)),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });
    try {
      await ApiClient.post('/profile/username', body: {'username': _usernameController.text.trim()});
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.message;
        _submitting = false;
      });
    }
  }

  Future<void> _cancelAndLogOut() async {
    await ApiClient.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.economy.language);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF2A2018),
        appBar: AppBar(
          backgroundColor: const Color(0xFF3A2A1C),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text(s.googleSetupTitle),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.googleSetupSubtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    controller: _usernameController,
                    label: s.username,
                    onChanged: _onUsernameChanged,
                    validator: (v) {
                      final trimmed = (v ?? '').trim();
                      if (trimmed.isEmpty) return s.fieldRequired;
                      if (trimmed.length < 4 || trimmed.length > 12) return s.usernameLengthError;
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  AvailabilityHint(
                    checking: _checkingAvailability,
                    available: _usernameAvailable,
                    checkingLabel: s.checkingAvailability,
                    availableLabel: s.usernameAvailable,
                    takenLabel: s.usernameTaken,
                    idleLabel: s.usernameLengthHint,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                        activeColor: const Color(0xFF3E9B4F),
                      ),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(s.acceptTermsPrefix, style: const TextStyle(color: Colors.white70)),
                            GestureDetector(
                              onTap: () => showTermsDialog(context, widget.economy.language),
                              child: Text(
                                s.termsLinkLabel,
                                style: const TextStyle(
                                  color: Color(0xFFCB7B2A),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 4),
                    Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitting ? null : () => _submit(s),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E9B4F),
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
                            s.googleSetupSubmit,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton(
                      onPressed: _submitting ? null : _cancelAndLogOut,
                      child: Text(s.cancelAndLogOut, style: const TextStyle(color: Colors.white54)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
