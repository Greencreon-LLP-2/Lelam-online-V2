import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class SellPage extends StatelessWidget {
  const SellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choose Category')),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Category ${index + 1}'),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: Icon(Icons.category),
            ),
            trailing: Icon(Icons.arrow_forward_ios),
          );
        },
      ),
    );
  }
}
