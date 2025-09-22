import 'package:flutter/material.dart';

class SearchButtonWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;

  const SearchButtonWidget({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search products...',

        suffixIcon: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            final query = controller.text.trim();
            onSearch(query);
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      onSubmitted: (value) {
        onSearch(value.trim());
      },
    );
  }
}