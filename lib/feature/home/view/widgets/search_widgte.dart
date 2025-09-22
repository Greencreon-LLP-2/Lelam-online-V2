import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/feature/categories/models/market_place_detail.dart';
import 'package:lelamonline_flutter/feature/categories/models/product_model.dart';
import 'package:lelamonline_flutter/feature/categories/models/used_cars_model.dart';
import 'package:lelamonline_flutter/feature/home/view/models/feature_list_model.dart';
import 'package:lelamonline_flutter/feature/product/view/pages/product_details_page.dart';
import 'package:lelamonline_flutter/utils/palette.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'dart:developer' as developer;

class SearchResultsPage extends StatefulWidget {
  final String searchQuery;

  const SearchResultsPage({super.key, required this.searchQuery});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final ApiService apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  List<LocationData> _locations = [];
  bool _isLoadingLocations = true;
  Map<String, Map<String, String>> _postAttributeValuesCache = {};
  Set<String> _fetchingPostIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.searchQuery.isNotEmpty) {
      _fetchProducts(widget.searchQuery);
    }
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    setState(() {
      _isLoadingLocations = true;
    });

    try {
      final Map<String, dynamic> response = await apiService.get(
        url: locations,
      );
      if (response['status'].toString() == 'true' && response['data'] is List) {
        final locationResponse = LocationResponse.fromJson(response);
        setState(() {
          _locations = locationResponse.data;
          _isLoadingLocations = false;
          developer.log(
            'Locations fetched: ${_locations.map((loc) => "${loc.id}: ${loc.name}").toList()}',
          );
        });
      } else {
        throw Exception('Invalid API response format');
      }
    } catch (e) {
      setState(() {
        _isLoadingLocations = false;
      });
      developer.log('Error fetching locations: $e');
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
        final posts = results.map((json) => MarketplacePost.fromJson(json)).toList();
        final products = posts.map((post) => post.toProduct()).toList();
        setState(() {
          _products = products;
          _isLoading = false;
        });
        for (var product in products) {
          _fetchPostAttributes(product.id);
        }
      } else {
        setState(() {
          _errorMessage = "No results found for \"$query\"";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error while searching for \"$query\"";
        _isLoading = false;
      });
      developer.log('Error fetching search results: $e');
    }
  }

  Future<void> _fetchPostAttributes(String postId) async {
    if (_postAttributeValuesCache.containsKey(postId) ||
        _fetchingPostIds.contains(postId)) {
      return;
    }
    _fetchingPostIds.add(postId);
    try {
      final attributes = await MarketplaceService2().fetchPostDetailsWithIcons(postId);
      if (mounted) {
        setState(() {
          _postAttributeValuesCache[postId] = attributes;
          _fetchingPostIds.remove(postId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchingPostIds.remove(postId);
        });
      }
      developer.log('Error fetching attributes for post $postId: $e');
    }
  }

  void _openProductDetails(Product product) {
    final featureListModel = FeatureListModel(
      id: product.id,
      title: product.title,
      price: product.price,
      image: product.image ?? "",
      ifAuction: product.ifAuction,
      auctionStartingPrice: product.auctionStartingPrice,
      slug: '',
      categoryId: '',
      brand: '',
      model: '',
      modelVariation: product.modelVariation,
      description: '',
      auctionPriceIntervel: '',
      attributeId: [],
      attributeVariationsId: [],
      filters: {},
      latitude: '',
      longitude: '',
      userZoneId: '',
      parentZoneId: product.parentZoneId,
      zoneId: '',
      landMark: '',
      auctionStatus: '',
      auctionStartin: '',
      auctionEndin: '',
      auctionAttempt: product.auctionAttempt,
      adminApproval: '',
      ifFinance: product.ifFinance,
      ifExchange: product.ifExchange,
      feature: product.feature,
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

  String _getLocationName(String zoneId) {
    if (zoneId == 'all' || zoneId.isEmpty) return 'All Kerala';
    final location = _locations.firstWhere(
      (loc) => loc.id == zoneId,
      orElse: () => LocationData(
        id: '',
        slug: '',
        parentId: '',
        name: zoneId,
        image: '',
        description: '',
        latitude: '',
        longitude: '',
        popular: '',
        status: '',
        allStoreOnOff: '',
        createdOn: '',
        updatedOn: '',
      ),
    );
    return location.name;
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(price.round());
  }

  String _getOwnerText(String owners) {
    if (owners.contains('1st')) return '1st Owner';
    if (owners.contains('2nd')) return '2nd Owner';
    if (owners.contains('3rd')) return '3rd Owner';
    if (owners.contains('4')) return '4+ Owners';
    return owners.isNotEmpty ? owners : 'N/A';
  }

  String _formatKmRange(String value) {
    if (value == 'N/A') return 'N/A';
    final kmMatch = RegExp(r'(\d+)').firstMatch(value);
    if (kmMatch != null) {
      final number = int.parse(kmMatch.group(1)!);
      final formattedNumber = NumberFormat.decimalPattern('en_IN').format(number);
      return value.replaceFirst(RegExp(r'\d+'), formattedNumber);
    }
    return value;
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isAuction = product.ifAuction == '1';
    final isFinanceAvailable = product.ifFinance == '1';
    final isExchangeAvailable = product.ifExchange == '1';
    final isFeatured = product.feature == '1';
    final isVerified = product.ifVerifyed == '1';
    final hasOffer = product.ifOfferPrice == '1';

    return GestureDetector(
      onTap: () {
        developer.log('Tapped product: ${product.title}, isAuction: $isAuction');
        FocusScope.of(context).unfocus();
        _openProductDetails(product);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.30),
              blurRadius: 5,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    width: 120,
                    height: 150,
                    margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    decoration: BoxDecoration(color: Colors.grey.shade200),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: 'https://lelamonline.com/admin/${product.image}',
                            fit: BoxFit.cover,
                            width: 120,
                            height: 150,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) {
                              developer.log(
                                'Failed to load image: https://lelamonline.com/admin/${product.image}',
                              );
                              developer.log('Error: $error');
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.directions_car,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                              );
                            },
                          ),
                        ),
                        if (isAuction)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AUCTION',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (isVerified || isFeatured)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.verified, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    "Verified",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
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
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.modelVariation.isNotEmpty ? product.modelVariation : 'N/A',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isAuction)
                          Text(
                            '${_formatPrice(double.tryParse(product.auctionStartingPrice) ?? 0)} - ${_formatPrice(double.tryParse(product.price) ?? 0)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Palette.primaryblue,
                            ),
                          )
                        else if (hasOffer)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatPrice(double.tryParse(product.price) ?? 0),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                _formatPrice(double.tryParse(product.offerPrice) ?? 0),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Palette.primaryblue,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            _formatPrice(double.tryParse(product.price) ?? 0),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Palette.primaryblue,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getLocationName(product.parentZoneId),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            final attributeValues = _postAttributeValuesCache[product.id] ?? {};
                            final isFetching = _fetchingPostIds.contains(product.id);
                            final year = attributeValues['Year'] ?? 'N/A';
                            final owners = attributeValues['No of owners'] ?? 'N/A';
                            final transmission = attributeValues['Transmission'] ?? 'N/A';
                            final fuelType = attributeValues['Fuel Type'] ?? 'N/A';
                            final kmRange = attributeValues['KM Range'] ?? 'N/A';

                            if (isFetching && attributeValues.isEmpty) {
                              return const SizedBox(
                                height: 32,
                                child: Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }

                            return Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                if (year != 'N/A')
                                  _buildDetailChip(Icons.calendar_today, year),
                                if (owners != 'N/A')
                                  _buildDetailChip(Icons.person, _getOwnerText(owners)),
                                if (kmRange != 'N/A')
                                  _buildDetailChip(Icons.speed, _formatKmRange(kmRange)),
                                if (fuelType != 'N/A')
                                  _buildDetailChip(Icons.local_gas_station, fuelType),
                                if (transmission != 'N/A')
                                  _buildDetailChip(Icons.settings, transmission),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isAuction || isFinanceAvailable || isExchangeAvailable)
              Container(
                decoration: BoxDecoration(
                  color: (isAuction || isFinanceAvailable || isExchangeAvailable)
                      ? Palette.primarylightblue
                      : Colors.grey.shade50,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: isAuction
                      ? Row(
                          children: [
                            const Icon(Icons.gavel, size: 10, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              'Attempts: ${product.auctionAttempt}/3',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (isFinanceAvailable && isExchangeAvailable) ...[
                              Row(
                                children: const [
                                  Icon(Icons.account_balance, size: 10, color: Colors.black),
                                  SizedBox(width: 4),
                                  Text(
                                    'Finance Available',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    height: 14,
                                    width: 1,
                                    color: Colors.black54,
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                              ),
                              Row(
                                children: const [
                                  Icon(Icons.swap_horiz, size: 10, color: Colors.black),
                                  SizedBox(width: 4),
                                  Text(
                                    'Exchange Available',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (isFinanceAvailable) ...[
                              Row(
                                children: const [
                                  Icon(Icons.account_balance, size: 10, color: Colors.black),
                                  SizedBox(width: 4),
                                  Text(
                                    'Finance Available',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (isExchangeAvailable) ...[
                              Row(
                                children: const [
                                  Icon(Icons.swap_horiz, size: 10, color: Colors.black),
                                  SizedBox(width: 4),
                                  Text(
                                    'Exchange Available',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results for "${widget.searchQuery}"'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading || _isLoadingLocations
          ? const Center(child: CircularProgressIndicator(color: Palette.primaryblue))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _fetchProducts(widget.searchQuery),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No cars found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search terms',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(_products[index]);
                      },
                    ),
    );
  }
}