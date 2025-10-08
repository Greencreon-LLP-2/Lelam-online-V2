import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class CustomFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool? isNumberInput;
  final bool alignLabelWithHint;
  final bool isRequired;
  final void Function(String)? onChanged;
  final GlobalKey<FormFieldState>? fieldKey;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;

  const CustomFormField({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.validator,
    this.maxLines = 1,
    this.isNumberInput = false,
    this.alignLabelWithHint = false,
    this.isRequired = false,
    this.onChanged,
    this.fieldKey,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
  });

  @override
  State<CustomFormField> createState() => _CustomFormFieldState();
}

class _CustomFormFieldState extends State<CustomFormField> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        key: widget.fieldKey,
        controller: widget.controller,
        focusNode: _focusNode,
        maxLines: widget.maxLines,
        obscureText: widget.obscureText,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType ?? 
            (widget.isNumberInput == true ? TextInputType.number : TextInputType.text),
        inputFormatters: widget.isNumberInput == true 
            ? [FilteringTextInputFormatter.digitsOnly] 
            : null,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: widget.isRequired ? '${widget.label} *' : widget.label,
          alignLabelWithHint: widget.alignLabelWithHint,
          labelStyle: TextStyle(
            fontSize: 16,
            color: _isFocused 
                ? AppTheme.primaryColor 
                : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: TextStyle(
            fontSize: 14,
            color: _isFocused 
                ? AppTheme.primaryColor 
                : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: widget.prefixIcon != null 
              ? Container(
                  margin: const EdgeInsets.all(12),
                  child: Icon(
                    widget.prefixIcon,
                    color: _isFocused 
                        ? AppTheme.primaryColor 
                        : Colors.grey.shade600,
                    size: 20,
                  ),
                )
              : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.prefixIcon != null ? 8 : 20,
            vertical: widget.maxLines == 1 ? 18 : 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: widget.enabled 
              ? (_isFocused ? Colors.white : Colors.grey.shade50)
              : Colors.grey.shade100,
        ),
        validator: widget.validator ??
            (value) {
              if (widget.isRequired && (value == null || value.isEmpty)) {
                return 'Please enter ${widget.label.toLowerCase()}';
              }
              return null;
            },
        onChanged: widget.onChanged,
      ),
    );
  }
}