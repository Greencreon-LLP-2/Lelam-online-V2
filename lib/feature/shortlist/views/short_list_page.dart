import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/categories/models/used_cars_model.dart' show MarketplacePost;
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/market_used_cars_page.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/used_cars_categorie.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/feature/home/view/services/location_service.dart';
import 'package:lelamonline_flutter/feature/categories/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../categories/services/used_cars_service.dart' hide MarketplaceService;

class ShortListPage extends StatefulWidget {
  final String? userId;
  const ShortListPage({super.key, this.userId});

  @override
  State<ShortListPage> createState() => _ShortListPageState();
}

class _ShortListPageState extends State<ShortListPage> {
  final String _baseUrl = 'https://lelamonline.com/admin/api/v1';
  final String _token = '5cb2c9b569416b5db1604e0e12478ded';
  List<Product> shortlistedProducts = [];
  List<Map<String, dynamic>> shortlistData = [];
  bool isLoading = true;
  String? errorMessage;
  String? userId;
  final MarketplaceService _marketplaceService = MarketplaceService();
  final LocationService _locationService = LocationService();
  List<LocationData> _locations = [];
  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserId();
    await _fetchLocations();
    if (userId != null && userId != 'Unknown') {
      await _fetchShortlistedItems();
    } else {
      setState(() {
        errorMessage = 'Please log in to view your shortlist';
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? widget.userId ?? 'Unknown';
    });
    debugPrint('ShortListPage - Loaded userId: $userId');
  }

  Future<void> _fetchLocations() async {
    setState(() {
      _isLoadingLocations = true;
    });
    try {
      final locationResponse = await _locationService.fetchLocations();
      if (locationResponse != null && locationResponse.status) {
        setState(() {
          _locations = locationResponse.data;
          _isLoadingLocations = false;
        });
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading locations: $e';
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _fetchShortlistedItems() async {
    if (userId == null || userId == 'Unknown') {
      setState(() {
        errorMessage = 'User ID not available';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final headers = {
        'token': _token,
        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
      };
      final url = '$_baseUrl/list-shortlist.php?token=$_token&user_id=$userId';
      debugPrint('Fetching shortlisted items: $url');
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('list-shortlist.php response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        if (responseData['status'] == 'true') {
          if (responseData['data'] is List) {
            shortlistData = List<Map<String, dynamic>>.from(responseData['data']);
            final postIds = shortlistData.map<String>((item) => item['post_id'].toString()).toList();
            final products = await _fetchProductsForPostIds(postIds);
            setState(() {
              shortlistedProducts = products;
              isLoading = false;
            });

            // Cache in SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('shortlist_$userId', responseBody);
            debugPrint('Shortlisted items cached: ${shortlistedProducts.length} items');
          } else if (responseData['data'] == 'Data not found') {
            setState(() {
              shortlistedProducts = [];
              shortlistData = [];
              isLoading = false;
            });
            debugPrint('No shortlisted items found for userId: $userId');
          } else {
            throw Exception('Unexpected data format');
          }
        } else {
          throw Exception('API returned status false');
        }
      } else {
        throw Exception('Failed to load shortlist: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error fetching shortlist: $e');
      setState(() {
        errorMessage = 'Error loading shortlist: $e';
        isLoading = false;
      });

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cachedShortlist = prefs.getString('shortlist_$userId');
      if (cachedShortlist != null) {
        try {
          final responseData = jsonDecode(cachedShortlist);
          if (responseData['status'] == 'true' && responseData['data'] is List) {
            shortlistData = List<Map<String, dynamic>>.from(responseData['data']);
            final postIds = shortlistData.map<String>((item) => item['post_id'].toString()).toList();
            final products = await _fetchProductsForPostIds(postIds);
            setState(() {
              shortlistedProducts = products;
              isLoading = false;
            });
            debugPrint('Loaded ${shortlistedProducts.length} items from cache');
          } else {
            setState(() {
              shortlistedProducts = [];
              shortlistData = [];
              isLoading = false;
            });
          }
        } catch (e) {
          debugPrint('Error parsing cached shortlist: $e');
          setState(() {
            errorMessage = 'Error loading cached shortlist';
            isLoading = false;
          });
        }
      }
    }
  }

  Future<List<Product>> _fetchProductsForPostIds(List<String> postIds) async {
    List<Product> products = [];
    for (String postId in postIds) {
      try {
        // Fetch marketplace and auction posts
        final marketplacePosts = (await _marketplaceService.fetchPosts(
          categoryId: '1',
          userZoneId: '0',
          listingType: 'sale',
          userId: userId ?? '2',
        )) ?? [];
        final auctionPosts = (await _marketplaceService.fetchPosts(
          categoryId: '1',
          userZoneId: '0',
          listingType: 'auction',
          userId: userId ?? '2',
        )) ?? [];

        // Combine posts and filter out null values
        final allPosts = [...marketplacePosts, ...auctionPosts].where((post) => post != null).cast<MarketplacePost>().toList();

        // Find matching post
        final matchingPost = allPosts.firstWhere(
          (post) => post.id == postId,
          orElse: () => MarketplacePost(
            id: postId,
            title: 'Product $postId',
            image: '',
            price: '0',
            parentZoneId: 'Unknown',
            createdOn: '',
            createdBy: 'Unknown',
            byDealer: '0',
            filters: {},
            ifAuction: '0',
            auctionStartingPrice: '0',
            auctionAttempt: '0',
            ifFinance: '0',
            ifExchange: '0', slug: '', categoryId: '', brand: '', model: '', modelVariation: '', description: '', auctionPriceInterval: '', attributeId: [], attributeVariationsId: [], latitude: '', longitude: '', userZoneId: '', landMark: '', auctionStatus: '', auctionStartin: '', auctionEndin: '', adminApproval: '', feature: '', status: '', visiterCount: '', ifSold: '', ifExpired: '', updatedOn: '',
          ),
        );
        products.add(matchingPost.toProduct());
      } catch (e) {
        debugPrint('Error fetching product for post_id $postId: $e');
      }
    }
    return products;
  }

  String _getLocationName(String zoneId) {
    if (zoneId == 'all') return 'All Kerala';
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
    final formatter = NumberFormat.decimalPattern('en_IN');
    return formatter.format(price.round());
  }

  String _formatShortlistTime(String createdOn) {
    try {
      final dateTime = DateTime.parse(createdOn);
      final formatter = DateFormat('dd MMM yyyy, hh:mm a');
      return formatter.format(dateTime);
    } catch (e) {
      return createdOn.isNotEmpty ? createdOn : 'N/A';
    }
  }

  Widget _buildProductCard(Product product, Map<String, dynamic> shortlistItem) {
    final isAuction = product.ifAuction == '1';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarketPlaceProductDetailsPage(
              product: product,
              userId: userId,
              isAuction: isAuction,
            ),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                 // borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: 'https://lelamonline.com/admin/${product.image}',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.directions_car,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Text(
                    //   'Name: ${product.createdBy}',
                    //   style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    // ),
                    Text(
                      isAuction
                          ? 'Starting Bid: ₹${_formatPrice(double.tryParse(product.auctionStartingPrice) ?? 0)}'
                          : 'Price: ₹${_formatPrice(double.tryParse(product.price) ?? 0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      'Location: ${_getLocationName(product.parentZoneId)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    Text(
                      'Shortlisted: ${_formatShortlistTime(shortlistItem['created_on'] ?? '')}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('STARTING WIDGET UPDATE');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
       // centerTitle: true,
       toolbarHeight: 50,
        title: const Text("Shortlist"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: isLoading || _isLoadingLocations
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : shortlistedProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No shortlisted items found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: shortlistedProducts.length,
                      itemBuilder: (context, index) {
                        final product = shortlistedProducts[index];
                        final shortlistItem = shortlistData.firstWhere(
                          (item) => item['post_id'].toString() == product.id,
                          orElse: () => {'created_on': ''},
                        );
                        return _buildProductCard(product, shortlistItem);
                      },
                    ),
    );
  }
}