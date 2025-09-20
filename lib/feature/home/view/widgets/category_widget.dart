import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lelamonline_flutter/feature/categories/pages/commercial/commercial_categories.dart';
import 'package:lelamonline_flutter/feature/categories/models/categories_model.dart';
import 'package:lelamonline_flutter/feature/categories/pages/other_category/other_categoty.dart';
import 'package:lelamonline_flutter/feature/categories/pages/real%20estate/real_estate_categories.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/used_cars_categorie.dart';
import 'package:lelamonline_flutter/feature/categories/services/categories_service.dart';

import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http; // For handling HTTP errors

class CategoryWidget extends StatefulWidget {
  const CategoryWidget({super.key});

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  late Future<List<CategoryModel>> _categoriesFuture;

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchCategoriesWithRetry();
  }

  // Function to fetch categories with retry logic
  Future<List<CategoryModel>> _fetchCategoriesWithRetry({int retryCount = 0}) async {
    try {
      return await CategoryService().fetchCategories();
    } on http.ClientException catch (e) {
      // Handle HTTP errors
      if (e.message.contains('429') && retryCount < maxRetries) {
        // Exponential backoff: delay = initialRetryDelay * 2^retryCount
        await Future.delayed(initialRetryDelay * (1 << retryCount));
        return _fetchCategoriesWithRetry(retryCount: retryCount + 1);
      }
      // Log the error for debugging
      debugPrint('Error fetching categories: $e');
      rethrow; // Rethrow to display in UI
    } catch (e) {
      // Handle other errors
      debugPrint('Unexpected error: $e');
      rethrow;
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
            _categoriesFuture = _fetchCategoriesWithRetry();
          });
          await _categoriesFuture;
        },
        child: FutureBuilder<List<CategoryModel>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerCategories();
            } else if (snapshot.hasError) {
              // User-friendly error message
              String errorMessage = 'Failed to load categories. Please try again.';
              if (snapshot.error.toString().contains('429')) {
                errorMessage = 'Too many requests. Please wait and try again.';
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _categoriesFuture = _fetchCategoriesWithRetry();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
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
                              // Retry image loading for 429 errors
                              if (error.toString().contains('429')) {
                                return FutureBuilder(
                                  future: _retryImageLoad(imageUrl),
                                  builder: (context, imageSnapshot) {
                                    if (imageSnapshot.connectionState == ConnectionState.waiting) {
                                      return Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                          color: Colors.grey[300],
                                        ),
                                      );
                                    } else if (imageSnapshot.hasError) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    }
                                    return Image.network(imageUrl, fit: BoxFit.cover);
                                  },
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

  // Function to retry image loading with exponential backoff
  Future<void> _retryImageLoad(String imageUrl, {int retryCount = 0}) async {
    try {
      final response = await http.get(Uri.parse(imageUrl), headers: {
        'User-Agent': 'LelamOnlineApp/1.0',
      });
      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 429 && retryCount < maxRetries) {
        await Future.delayed(initialRetryDelay * (1 << retryCount));
        return _retryImageLoad(imageUrl, retryCount: retryCount + 1);
      } else {
        throw Exception('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      rethrow;
    }
  }

  Widget _buildShimmerCategories() {
    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(width: 35),
      itemCount: 5,
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