import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class ProductSectionWidget extends StatefulWidget {
  final String searchQuery;

  const ProductSectionWidget({super.key, this.searchQuery = ''});

  @override
  State<ProductSectionWidget> createState() => _ProductSectionWidgetState();
}

class _ProductSectionWidgetState extends State<ProductSectionWidget> {
  final List<Map<String, dynamic>> _products = List.generate(
    15,
    (index) => {
      'id': index + 1,
      'name': 'Car Model ${index + 1}',
      'listPrice': (index + 1) * 12000, // Higher original price
      'offerPrice':
          (index + 1) * 10000, // Discounted price (original price field)
      'description': 'Description for car model ${index + 1}',
      'image': 'assets/images/car_${index + 1}.jpg',
    },
  );

  List<Map<String, dynamic>> get filteredProducts {
    if (widget.searchQuery.trim().isEmpty) {
      return _products;
    }
    final query = widget.searchQuery.toLowerCase();
    return _products.where((product) {
      return product['name'].toString().toLowerCase().contains(query) ||
          product['description'].toString().toLowerCase().contains(query) ||
          product['listPrice'].toString().contains(query) ||
          product['offerPrice'].toString().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = filteredProducts;

    if (products.isEmpty && widget.searchQuery.isNotEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No products found',
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
        childAspectRatio: 0.7, // Adjusted to accommodate extra price text
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
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
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.asset(
                            product['image'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '₹${product['listPrice']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.red,
                                    decorationThickness: 2,
                                  ),
                                ),
                                const SizedBox(
                                  width: 6,
                                ), // spacing between prices
                                Text(
                                  '₹${product['offerPrice']}',
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
                // Verified Banner with Sharp Edge
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
      },
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
