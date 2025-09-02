import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class CustomDropdownWidget<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final void Function(T?) onChanged;
  final IconData? prefixIcon;
  final bool isRequired;
  final String? Function(T?)? validator;
  final String Function(T) itemToString;

  const CustomDropdownWidget({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.prefixIcon,
    this.isRequired = false,
    this.validator,
    required this.itemToString,
    required String hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(1, 10),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<T>(
        value: items.contains(value) ? value : null, // Ensure value is valid
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
         // prefixIcon: Icon(prefixIcon),
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
            items.isEmpty
                ? [
                  DropdownMenuItem<T>(
                    value: null,
                    child: Text('No options available'),
                  ),
                ]
                : items.map((T item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(itemToString(item)),
                  );
                }).toList(),
        onChanged: items.isEmpty ? null : onChanged, // Disable if no items
        validator:
            validator ??
            (value) {
              if (isRequired && value == null) {
                return 'Please select a ${label.toLowerCase()}';
              }
              return null;
            },
      ),
    );
  }
}
