import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/countries.dart';

/// A searchable bottom sheet — a plain dropdown with ~195 entries is
/// unusable without a filter box.
Future<Country?> showCountryPicker(BuildContext context, AppLanguage language) {
  final s = Strings(language);
  final sorted = [...kCountries]
    ..sort((a, b) => (language == AppLanguage.es ? a.nameEs : a.nameEn)
        .compareTo(language == AppLanguage.es ? b.nameEs : b.nameEn));

  return showModalBottomSheet<Country>(
    context: context,
    backgroundColor: const Color(0xFF3A2A1C),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return _CountryPickerBody(
            countries: sorted,
            language: language,
            searchHint: s.selectCountry,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

class _CountryPickerBody extends StatefulWidget {
  const _CountryPickerBody({
    required this.countries,
    required this.language,
    required this.searchHint,
    required this.scrollController,
  });

  final List<Country> countries;
  final AppLanguage language;
  final String searchHint;
  final ScrollController scrollController;

  @override
  State<_CountryPickerBody> createState() => _CountryPickerBodyState();
}

class _CountryPickerBodyState extends State<_CountryPickerBody> {
  late List<Country> _filtered = widget.countries;
  final _searchController = TextEditingController();

  String _nameOf(Country c) => widget.language == AppLanguage.es ? c.nameEs : c.nameEn;

  /// Strips accents so a plain-ASCII search (which is what most people type
  /// on a phone keyboard) still matches names like "Perú" or "Bahréin".
  static const _accented = 'áéíóúüñ';
  static const _plain = 'aeiouun';
  String _normalize(String input) {
    final buffer = StringBuffer();
    for (final char in input.toLowerCase().split('')) {
      final idx = _accented.indexOf(char);
      buffer.write(idx == -1 ? char : _plain[idx]);
    }
    return buffer.toString();
  }

  void _onSearchChanged(String query) {
    final q = _normalize(query.trim());
    setState(() {
      _filtered = q.isEmpty
          ? widget.countries
          : widget.countries.where((c) => _normalize(_nameOf(c)).contains(q)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            autofocus: false,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: widget.searchHint,
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF2A2018),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final country = _filtered[index];
                return ListTile(
                  title: Text(_nameOf(country), style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.of(context).pop(country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
