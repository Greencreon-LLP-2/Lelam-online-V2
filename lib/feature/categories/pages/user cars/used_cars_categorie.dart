import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/feature/categories/models/details_model.dart' hide ModelVariation;
import 'package:lelamonline_flutter/feature/categories/models/market_place_detail.dart';
import 'package:lelamonline_flutter/feature/categories/models/product_model.dart';
import 'package:lelamonline_flutter/feature/categories/models/used_cars_model.dart';

import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/auction_detail_page.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/market_used_cars_page.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/utils/filters_page.dart';
import 'package:lelamonline_flutter/utils/palette.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../services/details_service.dart' show TempApiService;
import 'package:lelamonline_flutter/feature/categories/models/model_variation_model.dart';

class MarketplaceService {
  static final Map<String, List<MarketplacePost>> _postsCache = {};
  static List<Attribute>? _attributesCache;
  static List<AttributeVariation>? _attributeVariationsCache;

  Future<List<MarketplacePost>> fetchPosts({
    required String categoryId,
    required String userZoneId,
    required String listingType,
    required String userId,
  }) async {
    final cacheKey = '$categoryId-$userZoneId-$listingType-$userId';
    final endpoint =
        listingType == 'auction'
            ? '$baseUrl/list-category-post-auction.php'
            : '$baseUrl/list-category-post-marketplace.php';
    final url =
        listingType == 'auction'
            ? '$endpoint?token=$token&category_id=$categoryId&user_id=$userId&user_zone_id=$userZoneId'
            : '$endpoint?token=$token&category_id=$categoryId&user_zone_id=$userZoneId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is List) {
          final posts =
              decodedBody.map((json) {
                try {
                  return MarketplacePost.fromJson(json);
                } catch (e) {
                  developer.log('Error parsing post: $e');
                  developer.log('Problematic JSON: $json');
                  throw Exception('Failed to parse post: $e');
                }
              }).toList();
          _postsCache[cacheKey] = posts;
          return posts;
        } else if (decodedBody is Map && decodedBody.containsKey('data')) {
          if (decodedBody['data'] is List) {
            final data = decodedBody['data'] as List;
            final posts =
                data.map((json) => MarketplacePost.fromJson(json)).toList();
            _postsCache[cacheKey] = posts;
            return posts;
          } else if (decodedBody['data'] ==
              'Please accept live auction terms') {
            throw Exception('Please accept live auction terms');
          } else if (decodedBody['data'] == 'Data not found') {
            developer.log('No posts found for $listingType');
            _postsCache[cacheKey] = [];
            return [];
          } else {
            throw Exception('Unexpected data format: ${decodedBody['data']}');
          }
        } else {
          throw Exception('Unexpected API response format');
        }
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in fetchPosts ($listingType): $e');
      throw Exception('Error fetching posts: $e');
    }
  }

  Future<String> fetchAuctionTerms() async {
    final url = '$baseUrl/live-auction-terms.php?token=$token';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map &&
            decodedBody.containsKey('data') &&
            decodedBody['data'] is List &&
            decodedBody['data'].isNotEmpty) {
          final details = decodedBody['data'][0]['details']?.toString() ?? '';
          if (details.isEmpty) {
            throw Exception('No terms details found in response');
          }
          return details;
        } else {
          throw Exception('Unexpected terms response format');
        }
      } else {
        throw Exception('Failed to load terms: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching auction terms: $e');
      throw Exception('Error fetching terms: $e');
    }
  }

  Future<bool> acceptAuctionTerms(String userId) async {
    final url =
        '$baseUrl/live-auction-terms-accept.php?token=$token&user_id=$userId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody['status'] == 'true') {
          return true;
        } else {
          throw Exception('Failed to accept terms: ${decodedBody['data']}');
        }
      } else {
        throw Exception('Failed to accept terms: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error accepting auction terms: $e');
      return false;
    }
  }

  Future<List<Attribute>> fetchAttributes() async {
    if (_attributesCache != null) {
      developer.log('Returning cached attributes');
      return _attributesCache!;
    }
    _attributesCache = await TempApiService.fetchAttributes();
    return _attributesCache!;
  }

  Future<List<AttributeVariation>> fetchAttributeVariations(
    Map<String, String> params,
  ) async {
    if (_attributeVariationsCache != null) {
      developer.log('Returning cached attribute variations');
      return _attributeVariationsCache!;
    }
    _attributeVariationsCache = await TempApiService.fetchAttributeVariations(
      params,
    );
    return _attributeVariationsCache!;
  }

  static void clearCache() {
    _postsCache.clear();
    _attributesCache = null;
    _attributeVariationsCache = null;
  }
}

class UsedCarsPage extends StatefulWidget {
  final bool showAuctions;

  const UsedCarsPage({super.key, this.showAuctions = false});

  @override
  State<UsedCarsPage> createState() => _UsedCarsPageState();
}

class _UsedCarsPageState extends State<UsedCarsPage> {
  String? _userId;
  String _searchQuery = '';
  String _selectedLocation = 'all';
  String _listingType = 'Marketpalce';
  final TextEditingController _searchController = TextEditingController();
  final MarketplaceService2 _marketplaceService = MarketplaceService2();
  final _storage = const FlutterSecureStorage();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<LocationData> _locations = [];
  bool _isLoadingLocations = true;
  final Map<String, Map<String, String>> _postAttributeValuesCache = {};
  List<String> _selectedBrands = [];
  String _selectedPriceRange = 'all';
  String _selectedYearRange = 'all';
  String _selectedOwnersRange = 'all';
  List<String> _selectedFuelTypes = [];
  List<String> _selectedTransmissions = [];
  String _selectedKmRange = 'all';
  String _selectedSoldBy = 'all';
  ScrollController _scrollController = ScrollController();
  bool _showAppBarSearch = false;
  bool _showMainSearch = true;
  late final LoggedUserProvider _userProvider;
  final Set<String> _fetchingPostIds = {};
  Timer? _debounceTimer;
  List<Product> _filteredProductsCache = [];
  bool _filtersChanged = false;
  Map<String, ModelVariation?> _modelVariationsCache = {};
Set<String> _fetchingModelVariationIds = {};

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    _listingType = widget.showAuctions ? 'auction' : 'Marketplace';
    _checkLoginStatus().then((_) {
      if (_listingType == 'auction' && (_userId == null || _userId!.isEmpty)) {
        context.push(
          RouteNames.loginPage,
          extra: {'redirectTo': 'usedCars', 'listingType': 'auction'},
        );
      } else {
        _fetchProducts();
      }
    });
    _fetchLocations();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.offset > 100 && !_showAppBarSearch) {
      setState(() {
        _showAppBarSearch = true;
        _showMainSearch = false;
      });
    } else if (_scrollController.offset <= 100 && _showAppBarSearch) {
      setState(() {
        _showAppBarSearch = false;
        _showMainSearch = true;
      });
    }
    _fetchVisibleAttributes();
  }



  Future<bool> _showTermsAndConditionsDialog(BuildContext context) async {
    bool isAccepted = false;
    String termsHtml = '';
    bool isLoadingTerms = true;
    String? termsError;

    try {
      termsHtml = await _marketplaceService.fetchAuctionTerms();
      isLoadingTerms = false;
    } catch (e) {
      termsError = e.toString();
      isLoadingTerms = false;
    }

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool dialogIsAccepted = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Auction Terms & Conditions'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoadingTerms)
                      const Center(child: CircularProgressIndicator())
                    else if (termsError != null)
                      Text(
                        'Error loading terms: $termsError',
                        style: const TextStyle(fontSize: 14, color: Colors.red),
                      )
                    else
                      Html(
                        data: termsHtml,
                        style: {'body': Style(fontSize: FontSize(14))},
                      ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('I accept the terms and conditions'),
                      value: dialogIsAccepted,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          dialogIsAccepted = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      dialogIsAccepted && !isLoadingTerms && termsError == null
                          ? () async {
                            bool accepted = await _marketplaceService
                                .acceptAuctionTerms(_userId ?? '');
                            if (accepted) {
                              await _storage.write(
                                key: 'auction_terms_accepted',
                                value: 'true',
                              );
                              context.pop();
                            } else {
                              setState(() {
                                _errorMessage =
                                    'Failed to accept terms. Please try again.';
                              });
                              context.pop();
                            }
                          }
                          : null,
                  child: const Text('Accept'),
                ),
              ],
            );
          },
        );
      },
    ).then((value) {
      isAccepted = value ?? false;
    });

    return isAccepted;
  }

  Future<bool> _checkAuctionTermsAcceptance() async {
    final url =
        '${MarketplaceService2.baseUrl}/auction-start-checking.php?token=${MarketplaceService2.token}&cat_id=14';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody['status'] == 'true' &&
            decodedBody['data'] == 'Please accept live auction terms') {
          return false;
        }
        return true;
      } else {
        throw Exception(
          'Failed to check auction terms: ${response.statusCode}',
        );
      }
    } catch (e) {
      developer.log('Error checking auction terms: $e');
      return false;
    }
  }

  Future<void> _checkLoginStatus() async {
    final userId =
        _userProvider.userId ?? await _storage.read(key: 'userId') ?? '';
    if (mounted) {
      setState(() {
        _userId = userId;
      });
      if (kDebugMode) {
        developer.log('Checked login status: userId = $_userId');
      }
    }
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

  Future<void> _fetchProducts({bool forceRefresh = false}) async {
    if (_listingType == 'auction' && (_userId == null || _userId!.isEmpty)) {
      developer.log(
        'Redirecting to login page: userId=$_userId, listingType=$_listingType',
      );
      context.push(
        RouteNames.loginPage,
        extra: {'redirectTo': 'usedCars', 'listingType': 'auction'},
      );
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }
    if (forceRefresh) {
      MarketplaceService2.clearCache();
      _postAttributeValuesCache.clear();
      _fetchingPostIds.clear();
      _filteredProductsCache.clear();
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final posts = await _marketplaceService.fetchPosts(
        categoryId: '1',
        userZoneId: _selectedLocation == 'all' ? '0' : _selectedLocation,
        listingType: _listingType,
        userId: _userId ?? '',
      );
      final products = posts.map((post) => post.toProduct()).toList();
      setState(() {
        _products = products;
        _filtersChanged = true;
        _isLoading = false;
      });
      _fetchVisibleAttributes();
    } catch (e) {
      if (e.toString().contains('Please accept live auction terms')) {
        bool accepted = await _showTermsAndConditionsDialog(context);
        if (accepted) {
          await _fetchProducts();
        } else {
          setState(() {
            _errorMessage =
                'You must accept the auction terms to view auctions.';
            _isLoading = false;
          });
        }
      } else if (e.toString().contains(
        'Unexpected data format: Data not found',
      )) {
        setState(() {
          _products = [];
          _filteredProductsCache = [];
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load cars. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPostAttributes(String postId) async {
    if (_postAttributeValuesCache.containsKey(postId) ||
        _fetchingPostIds.contains(postId)) {
      return;
    }
    _fetchingPostIds.add(postId);
    try {
      final attributes = await _marketplaceService.fetchPostDetailsWithIcons(
        postId,
      );
      if (mounted) {
        setState(() {
          _postAttributeValuesCache[postId] = attributes;
          _fetchingPostIds.remove(postId);
          _filtersChanged = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchingPostIds.remove(postId);
        });
      }
    }
  }

Future<void> _fetchModelVariation(String postId) async {
  if (_modelVariationsCache.containsKey(postId) || _fetchingModelVariationIds.contains(postId)) {
    return;
  }
  _fetchingModelVariationIds.add(postId);
  try {
    final variation = await _marketplaceService.fetchModelVariation(postId);
    if (mounted) {
      setState(() {
        _modelVariationsCache[postId] = variation;
        _fetchingModelVariationIds.remove(postId);
        _filtersChanged = true;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _fetchingModelVariationIds.remove(postId);
      });
    }
  }
}

  void _fetchVisibleAttributes() {
  if (_debounceTimer?.isActive ?? false) return;
  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
    final screenHeight = MediaQuery.of(context).size.height;
    final scrollOffset = _scrollController.offset;
    const itemHeight = 180.0;
    final firstVisibleIndex = (scrollOffset / itemHeight).floor();
    final lastVisibleIndex = ((scrollOffset + screenHeight) / itemHeight).ceil();

    for (int i = firstVisibleIndex; i <= lastVisibleIndex && i < _filteredProductsCache.length; i++) {
      final product = _filteredProductsCache[i];
      if (!_postAttributeValuesCache.containsKey(product.id) && !_fetchingPostIds.contains(product.id)) {
        _fetchPostAttributes(product.id);
      }
      if (!_modelVariationsCache.containsKey(product.id) && !_fetchingModelVariationIds.contains(product.id)) {
        _fetchModelVariation(product.id);
      }
    }
  });
}

  String _getLocationName(String zoneId) {
    if (zoneId == 'all') return 'All Kerala';
    final location = _locations.firstWhere(
      (loc) => loc.id == zoneId,
      orElse:
          () => LocationData(
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

  final List<String> _brands = [
    'Ambassador',
    'Ashok Leyland',
    'Aston Martin',
    'Audi',
    'Bajaj',
    'Bentley',
    'BMW',
    'Bugatti',
    'BYD',
    'Cadillac',
    'Chevrolet',
    'Chrysler',
    'Citroen',
    'Daewoo',
    'Datsun',
    'DC',
    'Eicher Polaris',
    'Ferrari',
    'Fiat',
    'Force Motors',
    'Ford',
    'Honda',
    'Hummer',
    'Hyundai',
    'ICML',
    'Isuzu',
    'Jaguar',
    'Jeep',
    'Kia',
    'Lamborghini',
    'Land Rover',
    'Lexus',
    'Mahindra',
    'Mahindra Renault',
    'Maruti Suzuki',
    'Maserati',
    'Maybach',
    'Mazda',
    'Mercedes-Benz',
    'MG',
    'Mini',
    'Mitsubishi',
    'Nissan',
    'Opel',
    'Porsche',
    'Premier',
    'Renault',
    'Rolls-Royce',
    'Skoda',
    'Ssangyong',
    'Tata',
    'Tesla',
    'Toyota',
    'Volkswagen',
    'Volvo',
  ];

  final List<String> _priceRanges = [
    'all',
    'Under ₹2 Lakh',
    '₹2-5 Lakh',
    '₹5-10 Lakh',
    '₹10-20 Lakh',
    'Above ₹20 Lakh',
  ];

  final List<String> _yearRanges = [
    'all',
    '2020 & Above',
    '2018-2019',
    '2015-2017',
    '2010-2014',
    'Below 2010',
  ];

  final List<String> _ownerRanges = [
    'all',
    '1st Owner',
    '2nd Owner',
    '3rd Owner',
    '4+ Owners',
  ];

  final List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'CNG',
    'Electric',
    'Hybrid',
  ];

  final List<String> _transmissions = ['Manual', 'Automatic', 'CVT'];

  final List<String> _kmRanges = [
    'all',
    'Under 10K',
    '10K-30K',
    '30K-50K',
    '50K-80K',
    'Above 80K',
  ];

  final List<String> _soldByOptions = [
    'all',
    'Dealer',
    'Owner',
    'Certified Dealer',
  ];

  List<String> get _keralaCities {
    return ['all', ..._locations.map((loc) => loc.name)];
  }

  List<Product> get filteredProducts {
    if (!_filtersChanged) return _filteredProductsCache;

    // Filter products based on all criteria
    final filtered =
        _products.where((product) {
          final attributeValues = _postAttributeValuesCache[product.id] ?? {};

          // Search query filtering
          if (_searchQuery.trim().isNotEmpty) {
            final query = _searchQuery.toLowerCase().trim();
            final searchableText = [
              product.title.toLowerCase(),
              product.brand.toLowerCase(),
              product.model.toLowerCase(),
              product.modelVariation.toLowerCase(),
              _getLocationName(product.parentZoneId).toLowerCase(),
              attributeValues['Fuel Type']?.toLowerCase() ?? '',
              attributeValues['Transmission']?.toLowerCase() ?? '',
              attributeValues['Year']?.toLowerCase() ?? '',
              attributeValues['Sold by']?.toLowerCase() ??
                  (product.byDealer == '1' ? 'dealer' : 'owner'),
            ].join(' ');
            if (!searchableText.contains(query)) return false;
          }

          // Location filter
          if (_selectedLocation != 'all' &&
              product.parentZoneId != _selectedLocation) {
            return false;
          }
          if (_listingType == 'auction' && product.ifAuction != '1') {
            return false;
          }
          if (_listingType == 'Marketplace' && product.ifAuction != '0') {
            return false;
          }
          if (_selectedBrands.isNotEmpty &&
              !_selectedBrands.contains(product.brand)) {
            return false;
          }
          if (_selectedPriceRange != 'all') {
            int price =
                product.ifAuction == '1'
                    ? (int.tryParse(product.auctionStartingPrice) ?? 0)
                    : (int.tryParse(product.price) ?? 0);
            switch (_selectedPriceRange) {
              case 'Under ₹2 Lakh':
                if (price >= 200000) return false;
                break;
              case '₹2-5 Lakh':
                if (price < 200000 || price >= 500000) return false;
                break;
              case '₹5-10 Lakh':
                if (price < 500000 || price >= 1000000) return false;
                break;
              case '₹10-20 Lakh':
                if (price < 1000000 || price >= 2000000) return false;
                break;
              case 'Above ₹20 Lakh':
                if (price < 2000000) return false;
                break;
            }
          }

          // Year range filter
          final yearStr = attributeValues['Year'] ?? '0';
          final year = int.tryParse(yearStr) ?? 0;
          if (_selectedYearRange != 'all') {
            switch (_selectedYearRange) {
              case '2020 & Above':
                if (year < 2020) return false;
                break;
              case '2018-2019':
                if (year < 2018 || year > 2019) return false;
                break;
              case '2015-2017':
                if (year < 2015 || year > 2017) return false;
                break;
              case '2010-2014':
                if (year < 2010 || year > 2014) return false;
                break;
              case 'Below 2010':
                if (year >= 2010) return false;
                break;
            }
          }

          // Owners range filter
          final ownersStr = attributeValues['No of owners'] ?? '';
          int owners = 0;
          if (ownersStr.contains('1st')) {
            owners = 1;
          } else if (ownersStr.contains('2nd'))
            owners = 2;
          else if (ownersStr.contains('3rd'))
            owners = 3;
          else if (ownersStr.contains('4'))
            owners = 4;
          if (_selectedOwnersRange != 'all') {
            switch (_selectedOwnersRange) {
              case '1st Owner':
                if (owners != 1) return false;
                break;
              case '2nd Owner':
                if (owners != 2) return false;
                break;
              case '3rd Owner':
                if (owners != 3) return false;
                break;
              case '4+ Owners':
                if (owners < 4) return false;
                break;
            }
          }

          // Fuel type filter
          final fuel = attributeValues['Fuel Type'] ?? '';
          if (_selectedFuelTypes.isNotEmpty &&
              !_selectedFuelTypes.contains(fuel)) {
            return false;
          }
          final trans = attributeValues['Transmission'] ?? '';
          if (_selectedTransmissions.isNotEmpty &&
              !_selectedTransmissions.contains(trans)) {
            return false;
          }
          final kmStr = attributeValues['KM Range'] ?? '';
          int km = 0;
          final kmMatch = RegExp(r'(\d+)').firstMatch(kmStr);
          if (kmMatch != null) km = int.tryParse(kmMatch.group(1) ?? '0') ?? 0;
          if (_selectedKmRange != 'all') {
            switch (_selectedKmRange) {
              case 'Under 10K':
                if (km >= 10000) return false;
                break;
              case '10K-30K':
                if (km < 10000 || km >= 30000) return false;
                break;
              case '30K-50K':
                if (km < 30000 || km >= 50000) return false;
                break;
              case '50K-80K':
                if (km < 50000 || km >= 80000) return false;
                break;
              case 'Above 80K':
                if (km < 80000) return false;
                break;
            }
          }

          // Sold by filter
          final soldBy =
              attributeValues['Sold by'] ??
              (product.byDealer == '1' ? 'Dealer' : 'Owner');
          if (_selectedSoldBy != 'all') {
            switch (_selectedSoldBy) {
              case 'Owner':
                if (soldBy != 'Owner') return false;
                break;
              case 'Dealer':
              case 'Certified Dealer':
                if (soldBy != 'Dealer' && soldBy != 'Certified Dealer') {
                  return false;
                }
                break;
            }
          }

          return true;
        }).toList();

    // Sort products based on search query relevance if search query exists
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filtered.sort((a, b) {
        final aScore = _calculateRelevanceScore(a, query);
        final bScore = _calculateRelevanceScore(b, query);
        return bScore.compareTo(aScore); // Higher score comes first
      });
    }

    _filteredProductsCache = filtered;
    _filtersChanged = false;
    return filtered;
  }

  double _calculateRelevanceScore(Product product, String query) {
    final attributeValues = _postAttributeValuesCache[product.id] ?? {};
    double score = 0;

    if (product.title.toLowerCase().contains(query)) score += 3.0;
    if (product.brand.toLowerCase().contains(query)) score += 2.0;
    if (product.model.toLowerCase().contains(query)) score += 1.5;
    if (product.modelVariation.toLowerCase().contains(query)) score += 1.0;
    if (_getLocationName(product.parentZoneId).toLowerCase().contains(query))
      score += 0.5;
    if ((attributeValues['Fuel Type']?.toLowerCase() ?? '').contains(query))
      score += 0.5;
    if ((attributeValues['Transmission']?.toLowerCase() ?? '').contains(query))
      score += 0.5;
    if ((attributeValues['Year']?.toLowerCase() ?? '').contains(query))
      score += 0.5;
    if ((attributeValues['Sold by']?.toLowerCase() ??
            (product.byDealer == '1' ? 'dealer' : 'owner'))
        .contains(query))
      score += 0.5;

    return score;
  }

  String getImageUrl(String imagePath) {
    final cleanedPath =
        imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return 'https://lelamonline.com/$cleanedPath';
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder:
          (context) => FilterPage(
            brands: _brands,
            priceRanges: _priceRanges,
            yearRanges: _yearRanges,
            ownerRanges: _ownerRanges,
            fuelTypes: _fuelTypes,
            transmissions: _transmissions,
            kmRanges: _kmRanges,
            soldByOptions: _soldByOptions,
            selectedBrands: _selectedBrands,
            selectedPriceRange: _selectedPriceRange,
            selectedYearRange: _selectedYearRange,
            selectedOwnersRange: _selectedOwnersRange,
            selectedFuelTypes: _selectedFuelTypes,
            selectedTransmissions: _selectedTransmissions,
            selectedKmRange: _selectedKmRange,
            selectedSoldBy: _selectedSoldBy,
            listingType: _listingType,
            onClearAll: () {
              _fetchProducts();
              developer.log("works");
            },
            onApplyFilters: ({
              required List<String> selectedBrands,
              required String selectedPriceRange,
              required String selectedYearRange,
              required String selectedOwnersRange,
              required List<String> selectedFuelTypes,
              required List<String> selectedTransmissions,
              required String selectedKmRange,
              required String selectedSoldBy,
            }) {
              setState(() {
                _selectedBrands = selectedBrands;
                _selectedPriceRange = selectedPriceRange;
                _selectedYearRange = selectedYearRange;
                _selectedOwnersRange = selectedOwnersRange;
                _selectedFuelTypes = selectedFuelTypes;
                _selectedTransmissions = selectedTransmissions;
                _selectedKmRange = selectedKmRange;
                _selectedSoldBy = selectedSoldBy;
              });
              _fetchFilterListings();
            },
          ),
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedBrands.isNotEmpty) count++;
    if (_selectedPriceRange != 'all') count++;
    if (_selectedYearRange != 'all') count++;
    if (_selectedOwnersRange != 'all') count++;
    if (_selectedFuelTypes.isNotEmpty) count++;
    if (_selectedTransmissions.isNotEmpty) count++;
    if (_selectedKmRange != 'all') count++;
    if (_selectedSoldBy != 'all') count++;
    return count;
  }

  Widget _buildAppBarSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: false,
        decoration: InputDecoration(
          hintText: 'Search cars...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade400),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                        _filtersChanged = true;
                      });
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 10),
        ),
        onChanged:
            (value) => setState(() {
              _searchQuery = value;
              _filtersChanged = true;
            }),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filtersChanged = true;
          });
        },
        // Add these lines
        autofillHints: null, // Disable autofill entirely
        enableSuggestions: false, // Optional: Disable suggestions/autocomplete
        enableInteractiveSelection: true, // Keep selection enabled
        decoration: InputDecoration(
          hintText: 'Search by brand, model, location, fuel type...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade400),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                        _filtersChanged = true;
                      });
                    },
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildListingTypeButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_listingType != 'Marketplace') {
                  setState(() {
                    _listingType = 'Marketplace';
                    _products = [];
                    _postAttributeValuesCache.clear();
                    _fetchingPostIds.clear();
                    _filteredProductsCache.clear();
                    _filtersChanged = true;
                  });
                  _fetchProducts(forceRefresh: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _listingType == 'Marketplace'
                        ? Colors.grey.shade400
                        : Colors.grey.shade200,
                foregroundColor:
                    _listingType == 'Marketplace'
                        ? Colors.white
                        : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Marketplace',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_listingType != 'auction') {
                  setState(() {
                    _listingType = 'auction';
                    _products = [];
                    _postAttributeValuesCache.clear();
                    _fetchingPostIds.clear();
                    _filteredProductsCache.clear();
                    _filtersChanged = true;
                  });
                  _fetchProducts(forceRefresh: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _listingType == 'auction'
                        ? Colors.grey.shade400
                        : Colors.grey.shade200,
                foregroundColor:
                    _listingType == 'auction' ? Colors.white : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Auction',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log(
      'UsedCarsPage - Building UI: userId=$_userId, listingType=$_listingType, errorMessage=$_errorMessage',
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title:
            _showAppBarSearch
                ? _buildAppBarSearchField()
                : const Text('Used Cars'),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: _showFilterBottomSheet,
                icon: const Icon(Icons.tune, color: Colors.black87),
              ),
              if (_getActiveFilterCount() > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_getActiveFilterCount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _isLoadingLocations
              ? const CircularProgressIndicator()
              : PopupMenuButton<String>(
                icon: const Icon(Icons.location_on, color: Colors.black87),
                onSelected: (String value) {
                  setState(() {
                    _selectedLocation =
                        value == 'all'
                            ? 'all'
                            : _locations
                                .firstWhere((loc) => loc.name == value)
                                .id;
                    _filtersChanged = true;
                    _fetchProducts();
                  });
                },
                itemBuilder: (BuildContext context) {
                  return _keralaCities.map((String city) {
                    return PopupMenuItem<String>(
                      value: city,
                      child: Row(
                        children: [
                          if (_selectedLocation ==
                              (city == 'all'
                                  ? 'all'
                                  : _locations
                                      .firstWhere((loc) => loc.name == city)
                                      .id))
                            const Icon(
                              Icons.check,
                              color: Colors.blue,
                              size: 16,
                            ),
                          if (_selectedLocation ==
                              (city == 'all'
                                  ? 'all'
                                  : _locations
                                      .firstWhere((loc) => loc.name == city)
                                      .id))
                            const SizedBox(width: 8),
                          Text(city == 'all' ? 'All Kerala' : city),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
        ],
      ),
      body:
          _isLoading || _isLoadingLocations
              ? const Center(
                child: CircularProgressIndicator(color: Palette.primaryblue),
              )
              : _listingType == 'auction' &&
                  (_userId == null || _userId!.isEmpty || _userId == 'Unknown')
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Please log in to view auction listings',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        developer.log(
                          'Navigating to login page from auction prompt',
                        );
                        context.push(
                          RouteNames.loginPage,
                          extra: {
                            'redirectTo': 'usedCars',
                            'listingType': 'auction',
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.primaryblue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Log In'),
                    ),
                  ],
                ),
              )
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
                      onPressed: () => _fetchProducts(forceRefresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : filteredProducts.isEmpty
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
                      'Try adjusting your filters or search terms',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: () => _fetchProducts(forceRefresh: true),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount:
                      _products.length +
                      (_showMainSearch ? 2 : 1), // Removed SearchResultsWidget
                  itemBuilder: (context, index) {
                    if (_showMainSearch && index == 0) {
                      return _buildSearchField();
                    }
                    if (index == (_showMainSearch ? 1 : 0)) {
                      return _buildListingTypeButtons();
                    }
                    final productIndex = index - (_showMainSearch ? 2 : 1);
                    if (productIndex < filteredProducts.length) {
                      // Use filteredProducts here
                      final product = filteredProducts[productIndex];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildProductCard(product),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
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
        if (isAuction) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuctionProductDetailsPage(product: product),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MarketPlaceProductDetailsPage(
                    product: product,
                    isAuction: product.ifAuction == '1',
                  ),
            ),
          );
        }
      },
      child: Container(
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
                    // remove left gap so image aligns with any full-width banner above
                    margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                    
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl:
                                'https://lelamonline.com/admin/${product.image}',
                            fit: BoxFit.cover,
                            width: 120,
                            height: 150,
                            // memCacheHeight: 120,
                            // memCacheWidth: 120,
                            // maxHeightDiskCache: 120,
                            // maxWidthDiskCache: 120,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // rounded pill shape
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.verified,
                                    size: 12,
                                    color: Colors.white,
                                  ),
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
  _modelVariationsCache[product.id] != null
      ? ' ${_modelVariationsCache[product.id]!.variations}'
      : _fetchingModelVariationIds.contains(product.id)
          ? 'Loading...'
          : product.modelVariation, // Fallback
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
                                _formatPrice(
                                  double.tryParse(product.price) ?? 0,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                _formatPrice(
                                  double.tryParse(product.offerPrice) ?? 0,
                                ),
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
                            final attributeValues =
                                _postAttributeValuesCache[product.id] ?? {};
                            final isFetching = _fetchingPostIds.contains(
                              product.id,
                            );
                            final year = attributeValues['Year'] ?? 'N/A';
                            final owners =
                                attributeValues['No of owners'] ?? 'N/A';
                            final transmission =
                                attributeValues['Transmission'] ?? 'N/A';
                            final fuelType =
                                attributeValues['Fuel Type'] ?? 'N/A';
                            final kmRange =
                                attributeValues['KM Range'] ?? 'N/A';

                            if (isFetching && attributeValues.isEmpty) {
                              return const SizedBox(
                                height: 32,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                                  _buildDetailChip(
                                    Icons.person,
                                    _getOwnerText(owners),
                                  ),
                                if (kmRange != 'N/A')
                                  _buildDetailChip(
                                    Icons.speed,
                                    _formatKmRange(kmRange),
                                  ),
                                if (fuelType != 'N/A')
                                  _buildDetailChip(
                                    Icons.local_gas_station,
                                    fuelType,
                                  ),
                                if (transmission != 'N/A')
                                  _buildDetailChip(
                                    Icons.settings,
                                    transmission,
                                  ),
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
                  color:
                      (isAuction || isFinanceAvailable || isExchangeAvailable)
                          ? Palette.primarylightblue
                          : Colors.grey.shade50,
                  // keep bottom radius to match card but no extra gap
                  
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 0,
                  ),
                  child:
                      isAuction
                          ? _buildAuctionInfo(product)
                          : _buildFinanceExchangeInfo(
                            isFinanceAvailable,
                            isExchangeAvailable,
                          ),
                ),
              ),
          ],
        ),
      ),
    );
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

  Widget _buildAuctionInfo(Product product) {
    return Row(
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
    );
  }

  Widget _buildFinanceExchangeInfo(
    bool isFinanceAvailable,
    bool isExchangeAvailable,
  ) {
    List<Widget> children = [];
    if (isFinanceAvailable) {
      children.add(
        Row(
          children: [
            const Icon(Icons.account_balance, size: 10, color: Colors.black),
            const SizedBox(width: 4),
            const Text(
              'Finance Available',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    if (isExchangeAvailable) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 8));
      children.add(
        Row(
          children: [
            const Icon(Icons.swap_horiz, size: 10, color: Colors.black),
            const SizedBox(width: 4),
            const Text(
              'Exchange Available',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            (isFinanceAvailable || isExchangeAvailable)
                ? Palette.primarylightblue
                : Colors.grey.shade50,
        // borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(children: children),
    );
  }

  String _getOwnerText(String owners) {
    if (owners.contains('1st')) return '1st Owner';
    if (owners.contains('2nd')) return '2nd Owner';
    if (owners.contains('3rd')) return '3rd Owner';
    if (owners.contains('4')) return '4+ Owners';
    return owners.isNotEmpty ? owners : 'N/A';
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(price.round());
  }

  String _formatKmRange(String value) {
    if (value == 'N/A') return 'N/A';
    final kmMatch = RegExp(r'(\d+)').firstMatch(value);
    if (kmMatch != null) {
      final number = int.parse(kmMatch.group(1)!);
      final formattedNumber = NumberFormat.decimalPattern(
        'en_IN',
      ).format(number);
      return value.replaceFirst(RegExp(r'\d+'), formattedNumber);
    }
    return value;
  }

  Future<void> _fetchFilterListings() async {
    final Map<String, String> queryParams = {};
    // Brands (multi-select)
    if (_selectedBrands.isNotEmpty) {
      queryParams['brands'] = _selectedBrands.join(',');
    }

    // Price Range
    if (_selectedPriceRange != 'all') {
      final parts = _selectedPriceRange.split('-');
      if (parts.length == 2) {
        queryParams['min_price'] = parts[0];
        queryParams['max_price'] = parts[1];
      }
    }

    // Year Range (similar to price)
    if (_selectedYearRange != 'all') {
      final parts = _selectedYearRange.split('-');
      if (parts.length == 2) {
        queryParams['min_year'] = parts[0];
        queryParams['max_year'] = parts[1];
      }
    }

    // Owners Range
    if (_selectedOwnersRange != 'all') {
      final parts = _selectedOwnersRange.split('-');
      if (parts.length == 2) {
        queryParams['min_owners'] = parts[0];
        queryParams['max_owners'] = parts[1];
      }
    }

    // Fuel Types (multi-select)
    if (_selectedFuelTypes.isNotEmpty) {
      queryParams['fuel_types'] = _selectedFuelTypes.join(',');
    }

    // Transmissions (multi-select)
    if (_selectedTransmissions.isNotEmpty) {
      queryParams['transmissions'] = _selectedTransmissions.join(',');
    }

    // KM Range
    if (_selectedKmRange != 'all') {
      final parts = _selectedKmRange.split('-');
      if (parts.length == 2) {
        queryParams['min_km'] = parts[0];
        queryParams['max_km'] = parts[1];
      }
    }

    // Sold By
    if (_selectedSoldBy != 'all') {
      queryParams['sold_by'] = _selectedSoldBy;
    }

    // Add listingType if needed
    queryParams['listing_type'] = _listingType;

    try {
      final apiService = ApiService();
      final Map<String, dynamic> response = await apiService.postMultipart(
        url: "$baseUrl/filter-used-cars-listings.php",
        fields: queryParams,
      );

      final dataList = response['data'] as List<dynamic>? ?? [];

      final finalPosts =
          dataList.map((item) {
            final json = item as Map<String, dynamic>;
            return MarketplacePost.fromJson(json);
          }).toList();

      final List<Product> products =
          finalPosts.map((post) => post.toProduct()).toList();

      // final attributeValuePairs
      //     await AttributeValueService.fetchAttributeValuePairs();

      setState(() {
        _products = products;
        // _productAttributeValues = _mapAttributeValuePairs(attributeValuePairs);
        _isLoading = false;
      });
    } catch (e) {
      developer.log("Error while fetching filter listings: $e");
    }
  }
}
