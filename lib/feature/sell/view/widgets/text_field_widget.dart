import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class CustomFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool? isNumberInput;
  final bool alignLabelWithHint;
  final bool isRequired;

  const CustomFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.validator,
    this.maxLines = 1,
    this.isNumberInput = false,
    this.alignLabelWithHint = false,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // color: Colors.grey.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType:
            isNumberInput == true ? TextInputType.number : TextInputType.text,
        inputFormatters:
            isNumberInput == true
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          alignLabelWithHint: alignLabelWithHint,
          prefixIcon: Icon(prefixIcon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator:
            validator ??
            (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'Please enter ${label.toLowerCase()}';
              }
              return null;
            },
      ),
    );
  }
}
