import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/home/view/models/feature_list_model.dart';
import 'package:lelamonline_flutter/feature/home/view/provider/product_provider.dart';
import 'package:lelamonline_flutter/feature/product/view/pages/product_details_page.dart';
import 'package:provider/provider.dart';


class ProductSectionWidget extends StatelessWidget {
  final String searchQuery;
  const ProductSectionWidget({super.key, this.searchQuery = '', String? userId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                provider.error!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!provider.hasFeaturedProducts) {
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

        final products = provider.getFilteredProducts(searchQuery);

        if (products.isEmpty && searchQuery.isNotEmpty) {
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
          padding: const EdgeInsets.all(5),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(context, product);
          },
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, FeatureListModel product) {
    final isAuction = product.ifAuction == "1";
    final formattedPrice =
        double.tryParse(product.price)?.toStringAsFixed(0) ?? '0';
    final formattedAuctionPrice =
        double.tryParse(product.auctionStartingPrice)?.toStringAsFixed(0) ??
        '0';
    final imageUrl = 'https://lelamonline.com/admin/${product.image}';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(
              product: product,
              isAuction: product.ifAuction == "1",
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
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
                  flex: 2,
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
                        errorBuilder: (context, error, stackTrace) => Container(
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
                              value: loadingProgress.expectedTotalBytes != null
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
                            fontSize: 12,
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
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.blue, Colors.blueAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height * 0.6)
      ..close();

    canvas.drawPath(path, paint);

    final shadowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}