import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Categories"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 30,
          mainAxisSpacing: 30,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryCard(
            icon: category['icon'] as IconData,
            title: category['title'] as String,
            color: category['color'] as Color,
            onTap: () {
              // TODO: Navigate to category details
            },
          );
        },
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              // ignore: deprecated_member_use
              colors: [color.withOpacity(0.7), color],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> categories = [
  {'icon': Icons.directions_car, 'title': 'Used Cars', 'color': Colors.blue},
  {'icon': Icons.home, 'title': 'Real Estate', 'color': Colors.green},
  {
    'icon': Icons.local_shipping,
    'title': 'Commercial Vehicles',
    'color': Colors.orange,
  },
  {'icon': Icons.more_horiz, 'title': 'Others', 'color': Colors.purple},
];
