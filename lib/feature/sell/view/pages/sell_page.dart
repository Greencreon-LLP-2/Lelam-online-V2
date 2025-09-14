import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/categories/services/categories_service.dart';
import 'package:lelamonline_flutter/feature/categories/models/categories_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

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
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  late Future<List<CategoryModel>> _categoriesFuture;
  late final LoggedUserProvider _userProvider;
  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
    _categoriesFuture = CategoryService().fetchCategories();
  }

  Future<bool> _checkPostLimit(String categoryId) async {
    try {
      // Reverted to original endpoint (exists on server and returns JSON)
      final response = await http.get(
        Uri.parse(
          'https://lelamonline.com/admin/api/v1/select-category.php?token=5cb2c9b569416b5db1604e0e12478ded&user_id=${_userProvider.userId}&cat_id=$categoryId',
        ),
        headers: {'token': '5cb2c9b569416b5db1604e0e12478ded'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'true' && data['code'] == 4) {
          if (mounted) {
            await showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Post Limit Exceeded'),
                    content: Text(
                      data['data'] ??
                          'You have posted your permitted post limit in this category. Please upgrade your plan.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
            );
          }
          return false; // Limit exceeded
        }
        return true; // Limit not exceeded (or no limit info)
      } else {
        print('Failed to check post limit: ${response.reasonPhrase}');
        return false; // Fail closed on error
      }
    } catch (e) {
      print('Error checking post limit: $e');
      return false; // Fail closed on exception
    }
  }

  void _navigateToAdPost(BuildContext context, String categoryId) async {
    if (!_userProvider.isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to post an ad'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      context.pushNamed(RouteNames.loginPage);
      return;
    }

    final canPost = await _checkPostLimit(categoryId);
    if (!canPost) {
      return; // Dialog shown in _checkPostLimit, or failed silently
    }

    // Pass extra as Map<String, dynamic> for type safety
    final extraData = <String, dynamic>{'categoryId': categoryId};

    if (mounted) {
      context.pushNamed(RouteNames.adPostPage, extra: extraData);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_userProvider.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              context.pushNamed(RouteNames.loginPage);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Log In to Sell',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
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

                      return _CategoryCard(
                        category: CategoryItem(
                          name: category.name,
                          imageUrl:
                              'https://lelamonline.com/admin/${category.image}',
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
                    image:
                        category.imageUrl != null
                            ? DecorationImage(
                              image: NetworkImage(category.imageUrl!),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                print('Image load error: $exception');
                              },
                            )
                            : null,
                  ),
                  child:
                      category.imageUrl == null
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
