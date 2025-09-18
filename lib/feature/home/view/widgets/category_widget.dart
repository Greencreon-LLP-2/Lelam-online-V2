import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this import
import 'package:lelamonline_flutter/feature/categories/pages/commercial/commercial_categories.dart';
import 'package:lelamonline_flutter/feature/categories/models/categories_model.dart';
import 'package:lelamonline_flutter/feature/categories/pages/other_category/other_categoty.dart';
import 'package:lelamonline_flutter/feature/categories/pages/real%20estate/real_estate_categories.dart';
import 'package:lelamonline_flutter/feature/categories/services/categories_service.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/used_cars_categorie.dart';
import 'package:shimmer/shimmer.dart';

class CategoryWidget extends StatefulWidget {
  const CategoryWidget({super.key});

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  late Future<List<CategoryModel>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = CategoryService().fetchCategories();
  }

  // Retry function for 429 errors
  Future<void> _retryAfterDelay(Duration delay) async {
    await Future.delayed(delay);
    if (mounted) {
      setState(() {
        _categoriesFuture = CategoryService().fetchCategories();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _categoriesFuture = CategoryService().fetchCategories();
          });
          await _categoriesFuture; // Wait for the data to reload
        },
        child: FutureBuilder<List<CategoryModel>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerCategories();
            } else if (snapshot.hasError) {
              final error = snapshot.error.toString();
              if (error.contains('429') || error.contains('Too Many Requests')) {
                // Handle 429 specifically with retry
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      const Text('Too many requests. Please wait...'),
                      ElevatedButton(
                        onPressed: () => _retryAfterDelay(const Duration(seconds: 2)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No categories found'));
            }

            final categories = snapshot.data!;

            return ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(width: 35),
              itemCount: categories.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final category = categories[index];
                final imageUrl = 'https://lelamonline.com/admin/${category.image}';
                return InkWell(
                  onTap: () {
                    print(category.id);
                    switch (category.id) {
                      case "1":
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UsedCarsPage(),
                          ),
                        );
                        break;
                      case "2":
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RealEstatePage(),
                          ),
                        );
                        break;
                      case "3":
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommercialVehiclesPage(),
                          ),
                        );
                        break;
                      case '4':
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OthersPage()),
                        );
                        break;
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                color: Colors.grey[300],
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              // Handle 429 error specifically
                              if (error.toString().contains('429') || error.toString().contains('Too Many Requests')) {
                                return Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    color: Colors.grey[300],
                                  ),
                                );
                              }
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                            httpHeaders: {
                              'User-Agent': 'LelamOnlineApp/1.0', // Custom user agent to potentially bypass some limits
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 70,
                        child: Text(
                          category.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerCategories() {
    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(width: 35),
      itemCount: 5, // Show 5 shimmer placeholders
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 70,
                height: 12,
                color: Colors.grey[300],
              ),
            ],
          ),
        );
      },
    );
  }
}