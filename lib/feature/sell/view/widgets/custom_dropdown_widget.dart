import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class CustomDropdownWidget<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final void Function(T?) onChanged;
  final IconData prefixIcon;
  final bool isRequired;
  final String? Function(T?)? validator;
  final String Function(T) itemToString;

  const CustomDropdownWidget({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.prefixIcon,
    this.isRequired = false,
    this.validator,
    required this.itemToString,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
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
      items:
          items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemToString(item)),
            );
          }).toList(),
      onChanged: onChanged,
      validator:
          validator ??
          (value) {
            if (isRequired && value == null) {
              return 'Please select a ${label.toLowerCase()}';
            }
            return null;
          },
    );
  }
}
