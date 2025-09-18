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
import 'package:lelamonline_flutter/feature/categories/models/product_model.dart';
import 'package:lelamonline_flutter/feature/categories/models/used_cars_model.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/auction_detail_page.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/market_used_cars_page.dart';
import 'package:lelamonline_flutter/feature/categories/services/attribute_valuePair_service.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/utils/filters_page.dart';
import 'package:lelamonline_flutter/utils/palette.dart';
import 'package:lelamonline_flutter/feature/categories/services/details_service.dart';
import 'package:lelamonline_flutter/feature/categories/models/details_model.dart';
import 'package:provider/provider.dart';

class MarketplaceService {
  static const String baseUrl = 'https://lelamonline.com/admin/api/v1';
  static const String token = '5cb2c9b569416b5db1604e0e12478ded';

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
      print('Fetching posts from: $url');
      final response = await http.get(Uri.parse(url));
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);

        if (decodedBody is List) {
          final posts =
              decodedBody.map((json) {
                try {
                  return MarketplacePost.fromJson(json);
                } catch (e) {
                  print('Error parsing post: $e');
                  print('Problematic JSON: $json');
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
            print('No posts found for $listingType');
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
      print('Error in fetchPosts ($listingType): $e');
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
      print('Error fetching auction terms: $e');
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
      print('Error accepting auction terms: $e');
      return false;
    }
  }

  Future<List<Attribute>> fetchAttributes() async {
    if (_attributesCache != null) {
      print('Returning cached attributes');
      return _attributesCache!;
    }
    _attributesCache = await TempApiService.fetchAttributes();
    return _attributesCache!;
  }

  Future<List<AttributeVariation>> fetchAttributeVariations(
    Map<String, String> params,
  ) async {
    if (_attributeVariationsCache != null) {
      print('Returning cached attribute variations');
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
  String _listingType = 'sale';
  final TextEditingController _searchController = TextEditingController();
  final MarketplaceService _marketplaceService = MarketplaceService();
  final _storage = const FlutterSecureStorage();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<LocationData> _locations = [];
  bool _isLoadingLocations = true;
  List<Attribute> attributes = [];
  List<AttributeVariation> attributeVariations = [];
  Map<String, Map<String, String>> _productAttributeValues = {};
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
  late final LoggedUserProvider _userProvider;

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
                              Navigator.pop(dialogContext, true);
                            } else {
                              setState(() {
                                _errorMessage =
                                    'Failed to accept terms. Please try again.';
                              });
                              Navigator.pop(dialogContext, false);
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
        '${MarketplaceService.baseUrl}/auction-start-checking.php?token=${MarketplaceService.token}&cat_id=14';
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
      print('Error checking auction terms: $e');
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
        print('Checked login status: userId = $_userId');
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
          print(
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
    }
  }

  Future<void> _fetchAttributesAndVariations() async {
    try {
      attributes = await _marketplaceService.fetchAttributes();
      attributeVariations = await _marketplaceService.fetchAttributeVariations(
        {},
      );
      final attributeValuePairs =
          await AttributeValueService.fetchAttributeValuePairs();
      setState(() {
        _productAttributeValues = _mapAttributeValuePairs(attributeValuePairs);
      });
    } catch (e) {
      print('Error fetching attributes/variations/pairs: $e');
    }
  }

  Future<void> _fetchProducts({bool forceRefresh = false}) async {
    if (_listingType == 'auction' && (_userId == null || _userId!.isEmpty)) {
      debugPrint(
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
      MarketplaceService.clearCache();
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final posts = await _marketplaceService.fetchPosts(
        categoryId: _listingType == 'auction' ? '1' : '1',
        userZoneId: _selectedLocation == 'all' ? '0' : _selectedLocation,
        listingType: _listingType,
        userId: _userId ?? '',
      );
      final products = posts.map((post) => post.toProduct()).toList();
      final attributeValuePairs =
          await AttributeValueService.fetchAttributeValuePairs();
      setState(() {
        _products = products;
        _productAttributeValues = _mapAttributeValuePairs(attributeValuePairs);
        _isLoading = false;
      });
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

  void _handleScroll() {
    if (_scrollController.offset > 100 && !_showAppBarSearch) {
      setState(() => _showAppBarSearch = true);
    } else if (_scrollController.offset <= 100 && _showAppBarSearch) {
      setState(() => _showAppBarSearch = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    _listingType = widget.showAuctions ? 'auction' : 'sale';
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
    _fetchAttributesAndVariations();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, Map<String, String>> _mapAttributeValuePairs(
    List<AttributeValuePair> attributeValuePairs,
  ) {
    final Map<String, Map<String, String>> productAttributeValues = {};
    for (var product in _products) {
      final Map<String, String> attributeValues = {};
      final Set<String> processedAttributes = {};
      for (var pair in attributeValuePairs) {
        if (pair.attributeName.isNotEmpty &&
            pair.attributeValue.isNotEmpty &&
            !processedAttributes.contains(pair.attributeName)) {
          attributeValues[pair.attributeName] = pair.attributeValue;
          processedAttributes.add(pair.attributeName);
        }
      }
      product.filters.forEach((attributeId, variationId) {
        if (variationId.isNotEmpty) {
          final attribute = attributes.firstWhere(
            (attr) => attr.id == attributeId,
            orElse:
                () => Attribute(
                  id: attributeId,
                  slug: '',
                  name: _getAttributeNameFromId(attributeId),
                  listOrder: '',
                  categoryId: '',
                  formValidation: '',
                  ifDetailsIcons: '',
                  detailsIcons: '',
                  detailsIconsOrder: '',
                  showFilter: '',
                  status: '',
                  createdOn: '',
                  updatedOn: '',
                ),
          );
          final variation = attributeVariations.firstWhere(
            (varAttr) =>
                varAttr.id == variationId && varAttr.attributeId == attributeId,
            orElse:
                () => AttributeVariation(
                  id: variationId,
                  attributeId: attributeId,
                  name: _getVariationNameFromId(attributeId, variationId),
                  status: '',
                  createdOn: '',
                  updatedOn: '',
                ),
          );
          if (!processedAttributes.contains(attribute.name) &&
              variation.name.isNotEmpty) {
            attributeValues[attribute.name] = variation.name;
            processedAttributes.add(attribute.name);
          }
        }
      });
      productAttributeValues[product.id] = attributeValues;
    }
    return productAttributeValues;
  }

  String _getVariationNameFromId(String attributeId, String variationId) {
    switch (attributeId) {
      case '1':
        return variationId;
      case '2':
        switch (variationId) {
          case '1':
          case '19':
            return '1st Owner';
          case '2':
          case '59':
            return '2nd Owner';
          case '3':
            return '3rd Owner';
          default:
            return variationId.isNotEmpty ? '${variationId}th Owner' : 'N/A';
        }
      case '3':
        return variationId.isNotEmpty ? '$variationId KM' : 'N/A';
      case '4':
        switch (variationId) {
          case '8':
            return 'Petrol';
          case '9':
            return 'Diesel';
          case '10':
            return 'CNG';
          case '11':
            return 'Electric';
          case '12':
            return 'Hybrid';
          default:
            return variationId;
        }
      case '5':
        switch (variationId) {
          case '13':
            return 'Manual';
          case '14':
            return 'Automatic';
          case '15':
            return 'CVT';
          default:
            return variationId;
        }
      default:
        return variationId;
    }
  }

  String _getAttributeNameFromId(String id) {
    switch (id) {
      case '1':
        return 'Year';
      case '2':
        return 'No of owners';
      case '3':
        return 'KM Range';
      case '4':
        return 'Fuel Type';
      case '5':
        return 'Transmission';
      case '6':
        return 'Service History';
      case '7':
        return 'Accident History';
      case '8':
        return 'Replacements';
      case '9':
        return 'Flood Affected';
      case '10':
        return 'Engine Condition';
      case '11':
        return 'Transmission Condition';
      case '12':
        return 'Suspension Condition';
      case '13':
        return 'Features';
      case '14':
        return 'Functions';
      case '15':
        return 'Battery';
      case '16':
        return 'Driver side front tyre';
      case '17':
        return 'Driver side rear tyre';
      case '18':
        return 'Co driver side front tyre';
      case '19':
        return 'Co driver side rear tyre';
      case '20':
        return 'Rust';
      case '21':
        return 'Emission Norms';
      case '22':
        return 'Status Of RC';
      case '23':
        return 'Registration valid till';
      case '24':
        return 'Insurance Type';
      case '25':
        return 'Insurance Upto';
      case '26':
        return 'Scratches';
      case '27':
        return 'Dents';
      case '28':
        return 'Sold by';
      default:
        return 'Unknown Attribute';
    }
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
    'Maruti Suzuki',
    'Hyundai',
    'Tata',
    'Honda',
    'Toyota',
    'Mahindra',
    'BMW',
    'Audi',
    'Ford',
    'Volkswagen',
    'Kia',
    'Skoda',
    'Nissan',
    'Renault',
    'Mercedes',
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
            onClearAll: (){
              _fetchProducts();
              print("works");
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
                      });
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 10),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
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
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
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
        title: _showAppBarSearch ? _buildAppBarSearchField() : null,
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
                        debugPrint(
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
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          if (!_showAppBarSearch)
                            Container(
                              color: Colors.white,
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: _buildSearchField(),
                            ),
                          Container(
                            color: Colors.grey.shade200,
                            padding: const EdgeInsets.all(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _listingType = 'sale';
                                          _fetchProducts();
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _listingType == 'sale'
                                                  ? Palette.white
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          'Market Place',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight:
                                                _listingType == 'sale'
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                            color:
                                                _listingType == 'sale'
                                                    ? Colors.black
                                                    : Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        if (_userId == null ||
                                            _userId!.isEmpty ||
                                            _userId == 'Unknown') {
                                          debugPrint(
                                            'Auction button clicked, userId: $_userId',
                                          );
                                          context.push(
                                            RouteNames.loginPage,
                                            extra: {
                                              'redirectTo': 'usedCars',
                                              'listingType': 'auction',
                                            },
                                          );
                                        } else {
                                          bool termsAccepted =
                                              await _checkAuctionTermsAcceptance();
                                          if (!termsAccepted) {
                                            bool accepted =
                                                await _showTermsAndConditionsDialog(
                                                  context,
                                                );
                                            if (accepted) {
                                              setState(() {
                                                _listingType = 'auction';
                                                _fetchProducts();
                                              });
                                            }
                                          } else {
                                            setState(() {
                                              _listingType = 'auction';
                                              _fetchProducts();
                                            });
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _listingType == 'auction'
                                                  ? Palette.white
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          'Auction',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight:
                                                _listingType == 'auction'
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                            color:
                                                _listingType == 'auction'
                                                    ? Colors.black
                                                    : Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = _products[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildProductCard(product),
                        );
                      }, childCount: _products.length),
                    ),
                  ],
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
    final attributeValues = _productAttributeValues[product.id] ?? {};

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            if (isAuction) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AuctionProductDetailsPage(product: product),
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
            width: constraints.maxWidth,
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.white,
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
                      padding: const EdgeInsets.only(left: 10),
                      child: Container(
                        width: 120,
                        height: 155,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(0),
                          ),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(12),
                              ),
                              child: CachedNetworkImage(
                                imageUrl:
                                    'https://lelamonline.com/admin/${product.image}',
                                fit: BoxFit.cover,
                                height: 700,
                                width: 200,
                                placeholder:
                                    (context, url) => Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                errorWidget: (context, url, error) {
                                  print(
                                    'Failed to load image: https://lelamonline.com/admin/${product.image}',
                                  );
                                  print('Error: $error');
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
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'AUCTION',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            if (isVerified)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (isFeatured)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.white,
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    product.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              product.modelVariation,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isAuction)
                                  Text(
                                    '${_formatPrice(double.tryParse(product.auctionStartingPrice) ?? 0)} - ${_formatPrice(double.tryParse(product.price) ?? 0)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Palette.primaryblue,
                                    ),
                                  )
                                else if (hasOffer)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatPrice(
                                          double.tryParse(product.price) ?? 0,
                                        ),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      Text(
                                        _formatPrice(
                                          double.tryParse(product.offerPrice) ??
                                              0,
                                        ),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Palette.primaryblue,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    _formatPrice(
                                      double.tryParse(product.price) ?? 0,
                                    ),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Palette.primaryblue,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getLocationName(product.parentZoneId),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (attributeValues.isNotEmpty)
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      if (attributeValues['Year'] != null &&
                                          attributeValues['Year']!.isNotEmpty)
                                        _buildDetailChipWithIcon(
                                          Icons.calendar_today,
                                          attributeValues['Year']!,
                                        ),
                                      const SizedBox(width: 4),
                                      if (attributeValues['No of owners'] !=
                                              null &&
                                          attributeValues['No of owners']!
                                              .isNotEmpty)
                                        _buildDetailChipWithIcon(
                                          Icons.person,
                                          _getOwnerText(
                                            attributeValues['No of owners']!,
                                          ),
                                        ),
                                      const SizedBox(width: 4),
                                      if (attributeValues['KM Range'] != null &&
                                          attributeValues['KM Range']!
                                              .isNotEmpty)
                                        _buildDetailChipWithIcon(
                                          Icons.speed,
                                          _formatKmRange(
                                            attributeValues['KM Range']!,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (attributeValues['Fuel Type'] !=
                                              null &&
                                          attributeValues['Fuel Type']!
                                              .isNotEmpty)
                                        _buildDetailChipWithIcon(
                                          Icons.local_gas_station,
                                          attributeValues['Fuel Type']!,
                                        ),
                                      const SizedBox(width: 4),
                                      if (attributeValues['Transmission'] !=
                                              null &&
                                          attributeValues['Transmission']!
                                              .isNotEmpty)
                                        _buildDetailChipWithIcon(
                                          Icons.settings,
                                          attributeValues['Transmission']!,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (isAuction || isFinanceAvailable || isExchangeAvailable)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 0,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isAuction
                                    ? Palette.primarylightblue
                                    : Colors.white,
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailChipWithIcon(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionInfo(Product product) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              const Icon(Icons.gavel, size: 13, color: Colors.black),
              const SizedBox(width: 6),
              Text(
                'Attempts: ${product.auctionAttempt}/3',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceExchangeInfo(
    bool isFinanceAvailable,
    bool isExchangeAvailable,
  ) {
    if (!isFinanceAvailable && !isExchangeAvailable) {
      return const SizedBox.shrink();
    }
    if (isFinanceAvailable && isExchangeAvailable) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(color: Palette.primarylightblue),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.account_balance,
                    size: 12,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Finance Available',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 30, color: Colors.black),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: Palette.primarylightblue,
                border: Border.all(color: Palette.primarylightblue),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(Icons.swap_horiz, size: 12, color: Colors.black),
                  const SizedBox(width: 6),
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
            ),
          ),
        ],
      );
    }
    if (isFinanceAvailable) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: Palette.primarylightblue,
          border: Border.all(color: Palette.primarylightblue),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.account_balance, size: 10, color: Colors.black),
            const SizedBox(width: 8),
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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: Palette.primarylightblue,
          border: Border.all(color: Palette.primarylightblue),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.swap_horiz, size: 10, color: Colors.black),
            const SizedBox(width: 8),
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
    return const SizedBox.shrink();
  }

  String _getOwnerText(String owners) {
    switch (owners) {
      case '1':
      case '19':
      case '1st Owner':
        return '1st Owner';
      case '2':
      case '59':
      case '2nd Owner':
        return '2nd Owner';
      case '3':
      case '3rd Owner':
        return '3rd Owner';
      default:
        return owners.isNotEmpty ? owners : 'N/A';
    }
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
    final number = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final formatter = NumberFormat.decimalPattern('en_IN');
    return '${formatter.format(number)} KM';
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
        url: "$baseUrl/filter-listings.php",
        fields: queryParams,
      );

      final dataList = response['data'] as List<dynamic>? ?? [];

      final finalPosts =
          dataList.map((item) {
            final json = item as Map<String, dynamic>;
            return MarketplacePost.fromJson(json);
          }).toList();

      final products = finalPosts.map((post) => post.toProduct()).toList();

      // final attributeValuePairs =
      //     await AttributeValueService.fetchAttributeValuePairs();

      setState(() {
        _products = products;
        // _productAttributeValues = _mapAttributeValuePairs(attributeValuePairs);
        _isLoading = false;
      });

      print('works');
      print(response);
    } catch (e) {
      print("Error while fetching filter listings: $e");
    }
  }

  // List<Product> get filteredFinalProducts {
  //   List<Product> filtered = _products;

  //   if (_searchQuery.trim().isNotEmpty) {
  //     final query = _searchQuery.toLowerCase().trim();
  //     filtered =
  //         filtered.where((product) {
  //           final searchableText = [
  //             product.title.toLowerCase(),
  //             product.brand.toLowerCase(),
  //             product.model.toLowerCase(),
  //             product.modelVariation.toLowerCase(),
  //             _getLocationName(product.parentZoneId).toLowerCase(),
  //             product.filters['4']?.toLowerCase() ?? '',
  //             product.filters['5']?.toLowerCase() ?? '',
  //             product.filters['1']?.toString() ?? '',
  //             product.byDealer == '1' ? 'dealer' : 'owner',
  //           ].join(' ');
  //           return searchableText.contains(query);
  //         }).toList();
  //   }

  //   if (_selectedLocation != 'all') {
  //     filtered =
  //         filtered
  //             .where((product) => product.parentZoneId == _selectedLocation)
  //             .toList();
  //   }

  //   if (_listingType == 'auction') {
  //     filtered = filtered.where((product) => product.ifAuction == '1').toList();
  //   } else if (_listingType == 'sale') {
  //     filtered = filtered.where((product) => product.ifAuction == '0').toList();
  //   }

  //   if (_selectedBrands.isNotEmpty) {
  //     filtered =
  //         filtered
  //             .where((product) => _selectedBrands.contains(product.brand))
  //             .toList();
  //   }

  //   if (_selectedPriceRange != 'all') {
  //     filtered =
  //         filtered.where((product) {
  //           int price =
  //               product.ifAuction == '1'
  //                   ? (int.tryParse(product.auctionStartingPrice) ?? 0)
  //                   : (int.tryParse(product.price) ?? 0);
  //           switch (_selectedPriceRange) {
  //             case 'Under ₹2 Lakh':
  //               return price < 200000;
  //             case '₹2-5 Lakh':
  //               return price >= 200000 && price < 500000;
  //             case '₹5-10 Lakh':
  //               return price >= 500000 && price < 1000000;
  //             case '₹10-20 Lakh':
  //               return price >= 1000000 && price < 2000000;
  //             case 'Above ₹20 Lakh':
  //               return price >= 2000000;
  //             default:
  //               return true;
  //           }
  //         }).toList();
  //   }

  //   if (_selectedYearRange != 'all') {
  //     filtered =
  //         filtered.where((product) {
  //           int year =
  //               int.tryParse(product.filters['1']?.toString() ?? '0') ?? 0;
  //           switch (_selectedYearRange) {
  //             case '2020 & Above':
  //               return year >= 2020;
  //             case '2018-2019':
  //               return year >= 2018 && year <= 2019;
  //             case '2015-2017':
  //               return year >= 2015 && year <= 2017;
  //             case '2010-2014':
  //               return year >= 2010 && year <= 2014;
  //             case 'Below 2010':
  //               return year < 2010;
  //             default:
  //               return true;
  //           }
  //         }).toList();
  //   }

  //   if (_selectedOwnersRange != 'all') {
  //     filtered =
  //         filtered.where((product) {
  //           int owners =
  //               int.tryParse(product.filters['2']?.toString() ?? '0') ?? 0;
  //           switch (_selectedOwnersRange) {
  //             case '1st Owner':
  //               return owners == 1;
  //             case '2nd Owner':
  //               return owners == 2;
  //             case '3rd Owner':
  //               return owners == 3;
  //             case '4+ Owners':
  //               return owners >= 4;
  //             default:
  //               return true;
  //           }
  //         }).toList();
  //   }

  //   if (_selectedFuelTypes.isNotEmpty) {
  //     filtered =
  //         filtered
  //             .where(
  //               (product) => _selectedFuelTypes.contains(
  //                 product.filters['4']?.toString() ?? '',
  //               ),
  //             )
  //             .toList();
  //   }

  //   if (_selectedTransmissions.isNotEmpty) {
  //     filtered =
  //         filtered
  //             .where(
  //               (product) => _selectedTransmissions.contains(
  //                 product.filters['5']?.toString() ?? '',
  //               ),
  //             )
  //             .toList();
  //   }

  //   if (_selectedKmRange != 'all') {
  //     filtered =
  //         filtered.where((product) {
  //           int km = int.tryParse(product.filters['3']?.toString() ?? '0') ?? 0;
  //           switch (_selectedKmRange) {
  //             case 'Under 10K':
  //               return km < 10000;
  //             case '10K-30K':
  //               return km >= 10000 && km < 30000;
  //             case '30K-50K':
  //               return km >= 30000 && km < 50000;
  //             case '50K-80K':
  //               return km >= 50000 && km < 80000;
  //             case 'Above 80K':
  //               return km >= 80000;
  //             default:
  //               return true;
  //           }
  //         }).toList();
  //   }

  //   if (_selectedSoldBy != 'all') {
  //     filtered =
  //         filtered.where((product) {
  //           switch (_selectedSoldBy) {
  //             case 'Owner':
  //               return product.byDealer == '0';
  //             case 'Certified Dealer':
  //               return product.byDealer == '1';
  //             default:
  //               return true;
  //           }
  //         }).toList();
  //   }

  //   return filtered;
  // }
}
