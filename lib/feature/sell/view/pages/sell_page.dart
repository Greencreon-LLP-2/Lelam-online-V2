// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class SellPage extends StatelessWidget {
  const SellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Used Cars',
      'Real Estate',
      'Commercial Vehicles',
      'Other',
      'Mobile Phones',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Category')),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              context.pushNamed(
                RouteNames.adPostPage,
                extra: categories[index],
              );
            },
            child: ListTile(
              title: Text(categories[index]),
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: const Icon(Icons.category),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          );
        },
      ),
    );
  }
}
