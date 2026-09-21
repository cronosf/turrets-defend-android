import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/countries.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import 'auth_text_field.dart';
import 'availability_hint.dart';
import 'country_picker.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'terms_dialog.dart';

/// Creates a real account against `server/api_turret` (`POST /auth/register`)
/// once the form + required Terms checkbox validate.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.economy});

  final Economy economy;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _submitting = false;
  String? _errorText;
  Country? _selectedCountry;

  Timer? _usernameDebounce;
  Timer? _emailDebounce;
  bool? _usernameAvailable;
  bool? _emailAvailable;
  bool _checkingUsername = false;
  bool _checkingEmail = false;

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    setState(() => _usernameAvailable = null);
    final trimmed = value.trim();
    if (trimmed.length < 3) return;
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _checkingUsername = true);
      try {
        final result = await ApiClient.checkAvailability(username: trimmed);
        if (!mounted || _usernameController.text.trim() != trimmed) return;
        setState(() => _usernameAvailable = result['username_available'] as bool?);
      } catch (_) {
        // Best-effort only; the server still validates on submit.
      } finally {
        if (mounted) setState(() => _checkingUsername = false);
      }
    });
  }

  void _onEmailChanged(String value) {
    _emailDebounce?.cancel();
    setState(() => _emailAvailable = null);
    final trimmed = value.trim();
    if (!trimmed.contains('@') || !trimmed.contains('.')) return;
    _emailDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _checkingEmail = true);
      try {
        final result = await ApiClient.checkAvailability(email: trimmed);
        if (!mounted || _emailController.text.trim() != trimmed) return;
        setState(() => _emailAvailable = result['email_available'] as bool?);
      } catch (_) {
        // Best-effort only; the server still validates on submit.
      } finally {
        if (mounted) setState(() => _checkingEmail = false);
      }
    });
  }

  Future<void> _submit(Strings s) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_usernameAvailable == false || _emailAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.usernameTaken), duration: const Duration(seconds: 3)),
      );
      return;
    }
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
      await ApiClient.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        countryCode: _selectedCountry?.code,
        remember: true,
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

  /// Register always replaces Login in the stack (see [LoginScreen._goToRegister]),
  /// so if there's something left to pop to, it's Home (Login was itself
  /// pushed on top of it from "Mi perfil"). Otherwise Login was the stack's
  /// root, so push Home fresh.
  void _proceedToHome() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(economy: widget.economy)),
      );
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen(economy: widget.economy)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.economy.language);
    return Scaffold(
      backgroundColor: const Color(0xFF2A2018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A2A1C),
        foregroundColor: Colors.white,
        title: Text(s.registerTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _usernameController,
                  label: s.username,
                  onChanged: _onUsernameChanged,
                  validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null,
                ),
                const SizedBox(height: 4),
                AvailabilityHint(
                  checking: _checkingUsername,
                  available: _usernameAvailable,
                  checkingLabel: s.checkingAvailability,
                  availableLabel: s.usernameAvailable,
                  takenLabel: s.usernameTaken,
                ),
                const SizedBox(height: 10),
                AuthTextField(
                  controller: _emailController,
                  label: s.email,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _onEmailChanged,
                  validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null,
                ),
                const SizedBox(height: 4),
                AvailabilityHint(
                  checking: _checkingEmail,
                  available: _emailAvailable,
                  checkingLabel: s.checkingAvailability,
                  availableLabel: s.emailAvailable,
                  takenLabel: s.emailTaken,
                ),
                const SizedBox(height: 10),
                FormField<Country>(
                  initialValue: _selectedCountry,
                  validator: (value) => value == null ? s.fieldRequired : null,
                  builder: (field) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showCountryPicker(context, widget.economy.language);
                        if (picked != null) {
                          setState(() => _selectedCountry = picked);
                          field.didChange(picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: s.country,
                          labelStyle: const TextStyle(color: Colors.white60),
                          errorText: field.errorText,
                          suffixIcon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF3A2A1C),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF54402C)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCB7B2A), width: 2),
                          ),
                        ),
                        child: Text(
                          _selectedCountry != null
                              ? (widget.economy.language == AppLanguage.es
                                    ? _selectedCountry!.nameEs
                                    : _selectedCountry!.nameEn)
                              : s.selectCountry,
                          style: TextStyle(
                            color: _selectedCountry != null ? Colors.white : Colors.white38,
                          ),
                        ),
                      ),
                    );
                  },
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
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _confirmPasswordController,
                  label: s.confirmPassword,
                  obscureText: _obscureConfirm,
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.fieldRequired;
                    if (v != _passwordController.text) return s.passwordsDontMatch;
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.white54,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 8),
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
                  Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
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
                          s.createAccount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s.haveAccountAlready, style: const TextStyle(color: Colors.white70)),
                    GestureDetector(
                      onTap: _goToLogin,
                      child: Text(
                        s.loginLink,
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
