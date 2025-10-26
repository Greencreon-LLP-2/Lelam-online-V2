import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/utils/palette.dart';

class CustomDropdownWidget<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<T> items;
  final void Function(T?)? onChanged;
  final bool isRequired;
  final String Function(T) itemToString;
  final String? Function(T?)? validator;
  final String hintText;
  final GlobalKey<FormFieldState>? fieldKey;
  final Widget? prefixIcon;
  final bool enabled;
  final VoidCallback?
  onDropdownOpened; // Optional callback for when dropdown is opened

  const CustomDropdownWidget({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.isRequired = false,
    required this.itemToString,
    this.validator,
    this.hintText = '',
    this.fieldKey,
    this.prefixIcon,
    this.enabled = true,
    this.onDropdownOpened,
  });

  @override
  State<CustomDropdownWidget<T>> createState() =>
      _CustomDropdownWidgetState<T>();
}

class _CustomDropdownWidgetState<T> extends State<CustomDropdownWidget<T>> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
        if (!_focusNode.hasFocus) {
          _focusNode.unfocus();
        }
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String get _displayText {
    if (widget.value != null) {
      return widget.itemToString(widget.value as T);
    }
    return '';
  }

  String get _placeholderText {
    final baseText =
        widget.hintText.isNotEmpty ? widget.hintText : widget.label;
    return widget.isRequired ? '$baseText *' : baseText;
  }

  // Show dropdown dialog with max height
  Future<void> _showDropdownDialog(
    BuildContext context,
    FormFieldState<T> field,
  ) async {
    // Unfocus any text field before showing the dialog
    FocusScope.of(context).unfocus();
    // Notify that dropdown is opened (optional)
    widget.onDropdownOpened?.call();

    final T? selectedValue = await showDialog<T?>(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
                minWidth: double.infinity,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with title and close button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select ${widget.label}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context, null),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Scrollable list with scrollbar
                  Flexible(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        scrollbarTheme: Theme.of(
                          context,
                        ).scrollbarTheme.copyWith(
                          thumbColor: MaterialStateProperty.all(Colors.blue),
                        ),
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        trackVisibility: true,
                        thickness: 6.0,
                        radius: const Radius.circular(10),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            // Clear option
                            ListTile(
                              title: Text(
                                'Clear selection',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context, null);
                              },
                            ),
                            // Regular items
                            ...widget.items.map(
                              (item) => ListTile(
                                title: Text(
                                  widget.itemToString(item),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context, item);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    if (selectedValue != null || selectedValue == null) {
      widget.onChanged?.call(selectedValue);
      field.didChange(selectedValue); // Update FormField state
      if (mounted) {
        setState(() {
          _isFocused = false; // Reset focus state after selection
        });
      }
      if (widget.fieldKey?.currentState != null) {
        widget.fieldKey!.currentState!.validate();
      }
      // Ensure no text field gains focus after selection
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValue = widget.value != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: FormField<T>(
        key: widget.fieldKey,
        initialValue: widget.value,
        validator:
            widget.validator ??
            (value) {
              if (widget.isRequired && value == null) {
                return 'Please select ${widget.label.toLowerCase()}';
              }
              return null;
            },
        onSaved: widget.onChanged,
        builder: (FormFieldState<T> field) {
          return GestureDetector(
            onTap:
                widget.enabled
                    ? () {
                      // Unfocus any text field and request focus for dropdown
                      FocusManager.instance.primaryFocus?.unfocus();

                      _showDropdownDialog(context, field);
                    }
                    : null,
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: !hasValue ? _placeholderText : null,
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
                labelText:
                    widget.isRequired ? '${widget.label} *' : widget.label,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color:
                      _isFocused ? Palette.primaryblue : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                prefixIcon:
                    widget.prefixIcon != null
                        ? Container(
                          margin: const EdgeInsets.all(8),
                          child: widget.prefixIcon,
                        )
                        : null,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.prefixIcon != null ? 8 : 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Palette.primaryblue,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor:
                    widget.enabled
                        ? (_isFocused ? Colors.white : Colors.grey.shade50)
                        : Colors.grey.shade100,
                errorText: field.errorText,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? _displayText : _placeholderText,
                      style: TextStyle(
                        fontSize: 15,
                        color: hasValue ? Colors.black87 : Colors.grey.shade500,
                        fontWeight:
                            hasValue ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color:
                          _isFocused
                              ? Palette.primaryblue
                              : Colors.grey.shade600,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
