import 'package:flutter/material.dart';

class SearchButtonWidget extends StatelessWidget {
  const SearchButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: Offset(0, 10),
          ),
        ],
      ),

      child: Center(
        child: TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
            // alignLabelWithHint: true,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            hintText: 'Find Cars and more ...',
            contentPadding: EdgeInsets.symmetric(
              vertical: 14,
            ), // Center vertically
          ),
        ),
      ),
    );
  }
}
