import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/categories/services/categories_service.dart';
import 'package:lelamonline_flutter/feature/categories/models/categories_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CategoryItem {
  final String name;
  final IconData? icon;
  final Color? color;
  final String? imageUrl;

  const CategoryItem({
    required this.name,
    this.icon,
    this.color,
    this.imageUrl,
  });
}

class SellPage extends StatefulWidget {
  final String? userId;

  const SellPage({super.key, this.userId});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  late Future<List<CategoryModel>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _checkUserId();
    _categoriesFuture = CategoryService().fetchCategories();
  }

  void _checkUserId() {
    if (widget.userId == null || widget.userId!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Fluttertoast.showToast(
          msg: 'Please log in to sell items',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          textColor: Colors.white,
          fontSize: 16.0,
        );
        context.replaceNamed(RouteNames.pleaseLoginPage);
      });
    }
  }

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

  Future<bool> _checkPostLimit(String categoryId) async {
    if (widget.userId == null || widget.userId!.isEmpty) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://lelamonline.com/admin/api/v1/select-category.php?token=5cb2c9b569416b5db1604e0e12478ded&user_id=${widget.userId}&cat_id=$categoryId',
        ),
        headers: {
          'token': '5cb2c9b569416b5db1604e0e12478ded',
          'Cookie': 'PHPSESSID=sgju9bt1ljebrc8sbca4bcn64a',
        },
      );

      print('Post limit check response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'true' && data['code'] == 4) {
          // Show dialog with error message
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Post Limit Exceeded'),
              content: Text(data['data'] ?? 'You have posted your permitted post limit in this category. Please upgrade your plan.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return false; // Limit exceeded
        }
        return true; // Limit not exceeded
      } else {
        print('Failed to check post limit: ${response.reasonPhrase}');
        Fluttertoast.showToast(
          msg: 'Error checking post limit. Please try again.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return false;
      }
    } catch (e) {
      print('Error checking post limit: $e');
      Fluttertoast.showToast(
        msg: 'Error checking post limit: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return false;
    }
  }

  void _navigateToAdPost(BuildContext context, String categoryId) async {
    if (widget.userId == null || widget.userId!.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please log in to create a listing',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      context.replaceNamed(RouteNames.pleaseLoginPage);
      return;
    }

    // Check post limit before navigating
    final canPost = await _checkPostLimit(categoryId);
    if (!canPost) {
      return; // Dialog already shown in _checkPostLimit
    }

    context.pushNamed(
      RouteNames.adPostPage,
      extra: {'categoryId': categoryId, 'userId': widget.userId},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null || widget.userId!.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                        onTap: () => _navigateToAdPost(context, category.id),
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
                            onError: (exception, stackTrace) => const AssetImage(
                              'assets/placeholder.png',
                            ),
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