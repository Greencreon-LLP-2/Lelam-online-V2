// file: lib/feature/home/view/widgets/search_results_widget.dart
import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/feature/categories/pages/real%20estate/real_estate_categories.dart';
import 'package:lelamonline_flutter/feature/home/view/models/feature_list_model.dart';
import 'package:lelamonline_flutter/feature/product/view/pages/product_details_page.dart'
    hide token, baseUrl;

class SearchResultsWidget extends StatefulWidget {
  final String searchQuery;

  const SearchResultsWidget({super.key, required this.searchQuery});

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget> {
  final ApiService apiService = ApiService();

  List<MarketplacePost> _products = [];
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
      final Map<String, dynamic> data = await apiService.get(
        url: searchAnyProduct,
        queryParams: {'q': query},
      );

      if (data['status'] == true &&
          data['data'] != null &&
          data['data'] is List) {
        final results = data['data'] as List;
        setState(() {
          _products =
              results.map((json) => MarketplacePost.fromJson(json)).toList();
        });
      } else {
        setState(() {
          _errorMessage = "No results found for \"$query\"";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error while searching for \"$query\"";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openProductDetails(MarketplacePost product) {
    final featureListModel = FeatureListModel(
      id: product.id.toString(),
      title: product.title,
      price: product.price.toString(),
      image: product.image ?? "",
      ifAuction: product.ifAuction,
      auctionStartingPrice: product.auctionStartingPrice,
      slug: '',
      categoryId: '',
      brand: '',
      model: '',
      modelVariation: '',
      description: '',
      auctionPriceIntervel: '',
      attributeId: [],
      attributeVariationsId: [],
      filters: {},
      latitude: '',
      longitude: '',
      userZoneId: '',
      parentZoneId: '',
      zoneId: '',
      landMark: '',
      auctionStatus: '',
      auctionStartin: '',
      auctionEndin: '',
      auctionAttempt: '',
      adminApproval: '',
      ifFinance: '',
      ifExchange: '',
      feature: '',
      status: '',
      visiterCount: '',
      ifSold: '',
      ifExpired: '',
      byDealer: '',
      createdBy: '',
      createdOn: '',
      updatedOn: '',
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
  }

  Widget _buildProductCard(MarketplacePost product, bool hasDivider) {
    return InkWell(
      onTap: () => _openProductDetails(product),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: hasDivider ? Colors.grey.shade200 : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: product.image.isNotEmpty 
                  ? Image.network(
                    '$getImagePostImageUrl${product.image}',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image),
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                product.title,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.searchQuery.isEmpty) return const SizedBox.shrink();

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
      constraints: const BoxConstraints(maxHeight: 260),
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
                        "No products found",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8)),
                          ),
                          child: Text(
                            "Found ${_products.length} results",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(
                                _products[index],
                                index < _products.length - 1,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
