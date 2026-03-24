// lib/core/widgets/pakistan_city_field.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/pakistan_cities.dart';
import '../theme/app_colors.dart';

class PakistanCityField extends StatefulWidget {
  final String? initialValue;
  final void Function(String?) onChanged;
  final String label;
  final bool required;

  const PakistanCityField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.label = 'CITY',
    this.required = false,
  });

  @override
  State<PakistanCityField> createState() => _PakistanCityFieldState();
}

class _PakistanCityFieldState extends State<PakistanCityField> {
  String? _selected;
  String _otherText = '';
  late final TextEditingController _otherCtrl;

  static const _otherSentinel = 'Other...';

  @override
  void initState() {
    super.initState();
    final v = widget.initialValue;
    if (v != null && kPakistanCities.contains(v)) {
      _selected = v;
    } else if (v != null && v.isNotEmpty) {
      _selected = _otherSentinel;
      _otherText = v;
    }
    _otherCtrl = TextEditingController(text: _otherText);
  }

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  void _emitValue() {
    if (_selected == _otherSentinel) {
      final trimmed = _otherText.trim();
      widget.onChanged(trimmed.isEmpty ? null : trimmed);
    } else {
      widget.onChanged(_selected);
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textMuted.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.fromLTRB(0, 14, 8, 12),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selected,
          dropdownColor: AppColors.surfaceContainerLow,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.onBackground,
          ),
          decoration: _decoration('Select city'),
          validator: widget.required
              ? (v) => v == null ? 'City is required' : null
              : null,
          items: kPakistanCities
              .map((city) => DropdownMenuItem(
                    value: city,
                    child: Text(
                      city,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selected = value;
              if (value != _otherSentinel) {
                _otherText = '';
                _otherCtrl.clear();
              }
            });
            _emitValue();
          },
        ),
        if (_selected == _otherSentinel) ...[
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('city_other_text_field'),
            controller: _otherCtrl,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.onBackground,
            ),
            decoration: _decoration('Enter your city'),
            validator: widget.required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter your city'
                    : null
                : null,
            onChanged: (value) {
              _otherText = value;
              _emitValue();
            },
          ),
        ],
      ],
    );
  }
}
