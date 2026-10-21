import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../props/app_colors.dart';

/// Field teks dengan label di atas, ikon di kiri, dan opsi lihat/sembunyi sandi.
class AppTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final bool showValid;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final String? trailingLabel;
  final String? helper;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.showValid = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
    this.onChanged,
    this.trailingLabel,
    this.helper,
    this.inputFormatters,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _hidden = true;

  OutlineInputBorder _border(Color c, [double w = 1.0]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: w),
  );

  Widget? _suffix() {
    if (widget.isPassword) {
      final eye = IconButton(
        onPressed: () => setState(() => _hidden = !_hidden),
        icon: Icon(
          _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 19,
          color: AppColors.textMuted,
        ),
      );
      if (!widget.showValid) return eye;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 20, color: AppColors.green),
          eye,
        ],
      );
    }
    if (widget.showValid) {
      return const Icon(Icons.check_circle, size: 20, color: AppColors.green);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (widget.trailingLabel != null)
              Text(
                widget.trailingLabel!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted ??
              (_) => FocusManager.instance.primaryFocus?.unfocus(),
          validator: widget.validator,
          onChanged: widget.onChanged,
          inputFormatters: widget.inputFormatters,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.tint(AppColors.textMuted, 0.65),
            ),
            prefixIcon: Icon(widget.icon, size: 20, color: AppColors.textMuted),
            suffixIcon: _suffix(),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            border: _border(AppColors.line),
            enabledBorder: _border(AppColors.line),
            focusedBorder: _border(AppColors.orange, 1.5),
            errorBorder: _border(AppColors.red),
            focusedErrorBorder: _border(AppColors.red, 1.5),
            errorStyle: const TextStyle(fontSize: 11, color: AppColors.red),
          ),
        ),
        if (widget.helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              widget.helper!,
              style: const TextStyle(
                fontSize: 10,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}
