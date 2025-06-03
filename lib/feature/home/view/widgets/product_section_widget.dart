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
  // Mock data - replace with actual data from your backend
  final List<Map<String, dynamic>> _products = List.generate(
    20,
    (index) => {
      'id': index + 1,
      'name': 'Product ${index + 1}',
      'price': (index + 1) * 100,
      'description': 'Description for product ${index + 1}',
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
          product['price'].toString().contains(query);
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
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return InkWell(
          onTap: () {
            context.pushNamed(RouteNames.productDetailsPage);
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
            child: Column(
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
                    child: Center(
                      child: Icon(
                        Icons.image,
                        size: 40,
                        color: Colors.grey.shade400,
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
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${product['price']}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
