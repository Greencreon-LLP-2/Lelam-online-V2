import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/categories/models/market_place_detail.dart';
import 'package:lelamonline_flutter/feature/categories/models/used_cars_model.dart'
    show MarketplacePost;
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/market_used_cars_page.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/used_cars_categorie.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/feature/categories/models/product_model.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ShortListPage extends StatefulWidget {
  const ShortListPage({super.key, String? userId});

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
  final MarketplaceService2 _marketplaceService = MarketplaceService2();

  List<LocationData> _locations = [];
  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    debugPrint('ShortListPage - initState: Starting initialization');
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserId();
    debugPrint('ShortListPage - _initialize: userId=$userId, errorMessage=$errorMessage');
    if (userId == null || userId!.isEmpty) {
      setState(() {
        errorMessage = 'please_login';
        isLoading = false;
        _isLoadingLocations = false;
      });
      debugPrint('ShortListPage - _initialize: Set please_login due to null/empty userId');
      return;
    }
    await _fetchLocations();
    await _fetchShortlistedItems();
  }

  Future<void> _loadUserId() async {
    final userProvider = Provider.of<LoggedUserProvider>(
      context,
      listen: false,
    );
    final userData = userProvider.userData;
    setState(() {
      userId = userData?.userId;
      debugPrint('ShortListPage - _loadUserId: userId=$userId, userData?.userId=${userData?.userId}');
      if (userId == null || userId!.isEmpty) {
        errorMessage = 'please_login';
        isLoading = false;
        _isLoadingLocations = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Please log in'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _fetchLocations() async {
    setState(() {
      _isLoadingLocations = true;
    });

    try {
      final Map<String, dynamic> response = await ApiService().get(
        url: locations,
      );

      if (response['status'].toString() == 'true' && response['data'] is List) {
        final locationResponse = LocationResponse.fromJson(response);
        setState(() {
          _locations = locationResponse.data;
          _isLoadingLocations = false;
        });
      } else {
        throw Exception('Invalid API response format');
      }
    } catch (e) {
      debugPrint('ShortListPage - _fetchLocations: Error fetching locations: $e');
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _fetchShortlistedItems() async {
    if (userId == null || userId!.isEmpty) {
      setState(() {
        errorMessage = 'please_login';
        isLoading = false;
        _isLoadingLocations = false;
      });
      debugPrint('ShortListPage - _fetchShortlistedItems: Set please_login due to null/empty userId');
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
      debugPrint('ShortListPage - _fetchShortlistedItems: Fetching shortlisted items: $url');
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        if (responseData['status'] == 'true') {
          if (responseData['data'] is List) {
            shortlistData = List<Map<String, dynamic>>.from(responseData['data']);
            final postIds =
                shortlistData.map<String>((item) => item['post_id'].toString()).toList();
            final products = await _fetchProductsForPostIds(postIds);
            setState(() {
              shortlistedProducts = products;
              isLoading = false;
            });
          } else if (responseData['data'] == 'Data not found') {
            setState(() {
              shortlistedProducts = [];
              shortlistData = [];
              isLoading = false;
            });
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
      debugPrint('ShortListPage - _fetchShortlistedItems: Error fetching shortlist: $e');
      setState(() {
        errorMessage = 'Error loading shortlist: $e';
        isLoading = false;
      });
    }
  }

Future<List<Product>> _fetchProductsForPostIds(List<String> postIds) async {
  List<Product> products = [];
  try {
    // Fetch marketplace posts (no auction terms required)
    final marketplacePosts = await _marketplaceService.fetchPosts(
      categoryId: '1',
      userZoneId: '0',
      listingType: 'sale',
      userId: userId ?? '2',
    );

    // Fetch auction posts, but handle terms error gracefully
    List<MarketplacePost> auctionPosts = [];
    try {
      auctionPosts = await _marketplaceService.fetchPosts(
        categoryId: '1',
        userZoneId: '0',
        listingType: 'auction',
        userId: userId ?? '2',
      );
    } catch (e) {
      if (e.toString().contains('Please accept live auction terms')) {
        debugPrint('ShortListPage - _fetchProductsForPostIds: Auction terms not accepted, skipping auction posts: $e');
        // Continue with marketplace posts only
      } else {
        debugPrint('ShortListPage - _fetchProductsForPostIds: Error fetching auction posts: $e');
      }
    }

    final allPosts = [
      ...marketplacePosts,
      ...auctionPosts,
    ].where((post) => post != null).cast<MarketplacePost>().toList();

    for (String postId in postIds) {
      try {
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
            ifExchange: '0',
            slug: '',
            categoryId: '',
            brand: '',
            model: '',
            modelVariation: '',
            description: '',
            auctionPriceInterval: '',
            attributeId: [],
            attributeVariationsId: [],
            latitude: '',
            longitude: '',
            userZoneId: '',
            landMark: '',
            auctionStatus: '',
            auctionStartin: '',
            auctionEndin: '',
            adminApproval: '',
            feature: '',
            status: '',
            visiterCount: '',
            ifSold: '',
            ifExpired: '',
            updatedOn: '',
            ifOfferPrice: '',
            offerPrice: '',
            ifVerifyed: '',
          ),
        );
        products.add(matchingPost.toProduct());
      } catch (e) {
        debugPrint('ShortListPage - _fetchProductsForPostIds: Error fetching product for post_id $postId: $e');
      }
    }
  } catch (e) {
    debugPrint('ShortListPage - _fetchProductsForPostIds: General error fetching posts: $e');
    setState(() {
      errorMessage = 'Some items could not be loaded: $e';
      isLoading = false;
    });
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
                decoration: BoxDecoration(color: Colors.grey.shade200),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: 'https://lelamonline.com/admin/${product.image}',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        color: Colors.grey[300],
                      ),
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Shortlisted: ${_formatShortlistTime(shortlistItem['created_on'] ?? '')}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
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

  Widget _buildShimmerEffect() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 5, // Show 5 shimmer placeholders
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
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
                    color: Colors.grey[300],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 100,
                          height: 14,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 150,
                          height: 14,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 120,
                          height: 14,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ShortListPage - build: userId=$userId, errorMessage=$errorMessage, isLoading=$isLoading, _isLoadingLocations=$_isLoadingLocations');
    if (errorMessage == 'please_login') {
      debugPrint('ShortListPage - build: Rendering login button due to please_login');
    } else if (isLoading || _isLoadingLocations) {
      debugPrint('ShortListPage - build: Rendering shimmer effect');
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 50,
        title: const Text("Shortlist"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: errorMessage == 'please_login'
          ? Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // const Icon(
                  //   Icons.error_outline,
                  //   size: 64,
                  //   color: Colors.red,
                  // ),
                  const SizedBox(height: 16),
                
               
                  ElevatedButton(
                    
                    onPressed: () {
                      context.push(RouteNames.loginPage);
                      debugPrint('ShortListPage - Navigating to login page');
                    },
                    style: ElevatedButton.styleFrom(

                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon(
                        //   Icons.login,
                        //   color: Colors.white,
                        //   size: 20.0,
                        // ),
                        SizedBox(width: 8.0),
                        Text(
                          'Please Login to View Shortlist',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : isLoading || _isLoadingLocations
              ? _buildShimmerEffect()
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
                          itemExtent: 150, // Fixed height for better performance
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