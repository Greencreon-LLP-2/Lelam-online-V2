// file: lib/feature/home/view/widgets/search_results_widget.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/feature/home/view/models/feature_list_model.dart';
import 'package:lelamonline_flutter/feature/product/view/pages/product_details_page.dart' hide token, baseUrl;
import 'package:flutter/foundation.dart';

class SearchResultsWidget extends StatefulWidget {
  final String searchQuery;

  const SearchResultsWidget({super.key, required this.searchQuery});

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget> {
  List<dynamic> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    if (widget.searchQuery.isNotEmpty) {
      _fetchProducts(widget.searchQuery);
    }
  }

  @override
  void didUpdateWidget(covariant SearchResultsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _fetchProducts(widget.searchQuery);
    }
  }

  Future<void> _fetchProducts(String query) async {
    setState(() {
      _products = [];
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/search-post.php?token=${token}&q=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'true' && responseData['data'] is List) {
          setState(() {
            _products = responseData['data'];
            _isLoading = false;
          });
          if (kDebugMode) {
            print('Products fetched for query "$query": ${_products.length} items');
          }
        } else {
          throw Exception('Invalid response: ${responseData['status']}');
        }
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load products: $e';
      });
      if (kDebugMode) {
        print('Error fetching products: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Failed to load products'),
          backgroundColor: Colors.red.withOpacity(0.8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.searchQuery.isEmpty) {
      return const SizedBox.shrink(); // Hide when no query
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      constraints: const BoxConstraints(
        maxHeight: 200, // Limit height to mimic dropdown
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                )
              : _products.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No products found',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return InkWell(
                          onTap: () {
                            // Map API response to FeatureListModel
                            final featureListModel = FeatureListModel(
                              id: product['id']?.toString() ?? '',
                              title: product['name'] ?? 'Unnamed Product',
                              price: product['price']?.toString() ?? '0',
                              image: product['image']?.toString() ?? '',
                              ifAuction: product['ifAuction']?.toString() ?? '0',
                              auctionStartingPrice:
                                  product['auctionStartingPrice']?.toString() ?? '0', slug: '', categoryId: '', brand: '', model: '', modelVariation: '', description: '', auctionPriceIntervel: '', attributeId: [], attributeVariationsId: [], filters: {}, latitude: '', longitude: '', userZoneId: '', parentZoneId: '', zoneId: '', landMark: '', auctionStatus: '', auctionStartin: '', auctionEndin: '', auctionAttempt: '', adminApproval: '', ifFinance: '', ifExchange: '', feature: '', status: '', visiterCount: '', ifSold: '', ifExpired: '', byDealer: '', createdBy: '', createdOn: '', updatedOn: '',
                              // Add other required fields if necessary
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsPage(
                                  product: featureListModel,
                                  isAuction: featureListModel.ifAuction == "1",
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: index < _products.length - 1 ? 1 : 0, // No border for last item
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    product['name'] ?? 'Unnamed Product',
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'ID: ${product['id'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}