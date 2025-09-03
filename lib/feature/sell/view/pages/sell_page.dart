import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/categories/services/categories_service.dart';
import 'package:lelamonline_flutter/feature/categories/models/categories_model.dart';

class CategoryItem {
  final String name;
  final IconData? icon; // Optional local icon for fallback
  final Color? color;
  final String? imageUrl; // Network image URL

  const CategoryItem({
    required this.name,
    this.icon,
    this.color,
    this.imageUrl,
  });
}

class SellPage extends StatefulWidget {
  const SellPage({super.key, String? userId});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  late Future<List<CategoryModel>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = CategoryService().fetchCategories();
  }

  // Fallback icons and colors for categories based on ID
  final Map<String, CategoryItem> _fallbackCategories = {
    '1': const CategoryItem(
      name: 'Used Cars',
      icon: Icons.directions_car_outlined,
      color: Colors.blue,
    ),
    '2': const CategoryItem(
      name: 'Real Estate',
      icon: Icons.home_work_outlined,
      color: Colors.green,
    ),
    '3': const CategoryItem(
      name: 'Commercial Vehicles',
      icon: Icons.local_shipping_outlined,
      color: Colors.orange,
    ),
    '4': const CategoryItem(
      name: 'Other',
      icon: Icons.more_horiz_outlined,
      color: Colors.grey,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Category',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FutureBuilder<List<CategoryModel>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No categories found'));
                  }

                  final categories = snapshot.data!;

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final fallback = _fallbackCategories[category.id] ??
                          const CategoryItem(
                            name: 'Unknown',
                            icon: Icons.help_outline,
                            color: Colors.grey,
                          );

                      return _CategoryCard(
                        category: CategoryItem(
                          name: category.name,
                          icon: fallback.icon,
                          color: fallback.color,
                          imageUrl: 'https://lelamonline.com/admin/${category.image}',
                        ),
                        onTap: () => _navigateToAdPost(context, category.id), // Pass category.id
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAdPost(BuildContext context, String categoryId) {
    context.pushNamed(RouteNames.adPostPage, extra: categoryId); // Pass categoryId
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItem category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final categoryColor = category.color ?? AppTheme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    image: category.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(category.imageUrl!),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) => const AssetImage('assets/placeholder.png'),
                          )
                        : null,
                  ),
                  child: category.imageUrl == null
                      ? Icon(category.icon, color: categoryColor, size: 28)
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to create listing',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}