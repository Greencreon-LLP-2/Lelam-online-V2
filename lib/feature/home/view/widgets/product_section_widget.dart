import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/home/view/models/feature_list_model.dart';

class ProductSectionWidget extends StatefulWidget {
  final String searchQuery;
  const ProductSectionWidget({super.key, this.searchQuery = ''});

  @override
  State<ProductSectionWidget> createState() => _ProductSectionWidgetState();
}

class _ProductSectionWidgetState extends State<ProductSectionWidget> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;
  bool _hasFeaturedProducts = false;

  @override
  void initState() {
    super.initState();
    _fetchFeaturedProducts();
  }

  Future<void> _fetchFeaturedProducts() async {
    try {
      final url = Uri.https(
        'lelamonline.com',
        '/admin/api/v1/list-feature-post.php',
        {'token': '5cb2c9b569416b5db1604e0e12478ded'},
      );
      final cookieJar = <String, String>{
        'Cookie': 'PHPSESSID=koib3m1uifk1b4ucclf5dsegpe',
      };

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...cookieJar,
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        if (decodedResponse is List) {
          setState(() {
            _products =
                decodedResponse
                    .map<Product>((json) => Product.fromJson(json))
                    .toList();
            _isLoading = false;
            _hasFeaturedProducts = _products.isNotEmpty;
          });
        } else if (decodedResponse is Map) {
          // Handle API error messages
          if (decodedResponse['status'] == 'error') {
            throw Exception('API Error: ${decodedResponse['message']}');
          } else if (decodedResponse['data'] is List) {
            setState(() {
              _products =
                  (decodedResponse['data'] as List)
                      .map<Product>((json) => Product.fromJson(json))
                      .toList();
              _isLoading = false;
              _hasFeaturedProducts = _products.isNotEmpty;
            });
          }
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}\nResponse: ${response.body}',
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load products: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Product> get filteredProducts {
    if (widget.searchQuery.trim().isEmpty) {
      return _products;
    }
    final query = widget.searchQuery.toLowerCase();
    return _products.where((product) {
      return product.title.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.price.contains(query) ||
          product.auctionStartingPrice.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_hasFeaturedProducts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No featured products available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    final products = filteredProducts;

    if (products.isEmpty && widget.searchQuery.isNotEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No products found matching your search',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(context, product);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final isAuction = product.ifAuction == "1";
    final formattedPrice =
        double.tryParse(product.price)?.toStringAsFixed(0) ?? '0';
    final formattedAuctionPrice =
        double.tryParse(product.auctionStartingPrice)?.toStringAsFixed(0) ??
        '0';
    final imageUrl = 'https://lelamonline.com/admin/${product.image}';

    return InkWell(
      onTap: () {
        context.pushNamed(RouteNames.productDetailsPage, extra: product);
      },
      splashColor: AppTheme.primaryColor.withOpacity(.1),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Product Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isAuction) ...[
                              Text(
                                '₹$formattedPrice',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.red,
                                  decorationThickness: 2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '₹$formattedAuctionPrice',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ] else
                              Text(
                                '₹$formattedPrice',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Verified Banner (only for featured products)
            if (product.feature == "1")
              Positioned(
                top: 0,
                right: 0,
                child: CustomPaint(
                  painter: VerifiedBannerPainter(),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class VerifiedBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..shader = const LinearGradient(
            colors: [Colors.blue, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path =
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height * 0.6)
          ..close();

    canvas.drawPath(path, paint);

    // Add shadow
    final shadowPaint =
        Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
