import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/countries.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import 'auth_text_field.dart';
import 'country_picker.dart';

/// Lets the player edit their country, display name and (optionally)
/// password. Username and email are intentionally not present here — they
/// are fixed once the account is created.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.economy, required this.user});

  final Economy economy;
  final Map<String, dynamic> user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String? _errorText;
  Country? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user['full_name']?.toString() ?? '');
    final code = widget.user['country_code']?.toString();
    if (code != null && code.isNotEmpty) {
      for (final c in kCountries) {
        if (c.code == code) {
          _selectedCountry = c;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save(Strings s) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final body = <String, dynamic>{
      'full_name': _fullNameController.text.trim(),
      'country_code': _selectedCountry?.code,
    };
    if (_passwordController.text.isNotEmpty) {
      body['password'] = _passwordController.text;
    }

    try {
      await ApiClient.post('/profile/update', body: body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.profileUpdated)));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.economy.language);
    return Scaffold(
      backgroundColor: const Color(0xFF2A2018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A2A1C),
        foregroundColor: Colors.white,
        title: Text(s.editProfileTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReadOnlyField(label: s.username, value: widget.user['username']?.toString() ?? ''),
                const SizedBox(height: 10),
                _ReadOnlyField(label: s.email, value: widget.user['email']?.toString() ?? ''),
                const SizedBox(height: 4),
                Text(
                  s.usernameEmailNotEditable,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _fullNameController,
                  label: s.fullNameLabel,
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final picked = await showCountryPicker(context, widget.economy.language);
                    if (picked != null) setState(() => _selectedCountry = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: s.country,
                      labelStyle: const TextStyle(color: Colors.white60),
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
                      style: TextStyle(color: _selectedCountry != null ? Colors.white : Colors.white38),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _passwordController,
                  label: s.newPasswordLabel,
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (v.length < 6) return s.fieldRequired;
                    return null;
                  },
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
                  label: s.confirmNewPasswordLabel,
                  obscureText: _obscureConfirm,
                  validator: (v) {
                    if (_passwordController.text.isEmpty) return null;
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
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitting ? null : () => _save(s),
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
                          s.saveChanges,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF241a11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      child: Text(value, style: const TextStyle(color: Colors.white54)),
    );
  }
}
