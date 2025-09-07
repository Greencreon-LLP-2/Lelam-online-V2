import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/feature/categories/models/product_model.dart';
import 'package:lelamonline_flutter/feature/categories/models/used_cars_model.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/auction_detail_page.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/market_used_cars_page.dart';
import 'package:lelamonline_flutter/feature/categories/services/attribute_valuePair_service.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/feature/home/view/services/location_service.dart';
import 'package:lelamonline_flutter/utils/palette.dart';
import 'package:lelamonline_flutter/feature/categories/services/details_service.dart';
import 'package:lelamonline_flutter/feature/categories/models/details_model.dart';

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

    if (_postsCache.containsKey(cacheKey)) {
      print('Returning cached posts for $cacheKey');
      return _postsCache[cacheKey]!;
    }

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
                  print('Error parsing post: $e');
                  print('Problematic JSON: $json');
                  throw Exception('Failed to parse post: $e');
                }
              }).toList();
          _postsCache[cacheKey] = posts;
          return posts;
        } else if (decodedBody is Map && decodedBody.containsKey('data')) {
          final data = decodedBody['data'] as List;
          final posts =
              data.map((json) => MarketplacePost.fromJson(json)).toList();
          _postsCache[cacheKey] = posts;
          return posts;
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

  Future<List<Attribute>> fetchAttributes() async {
    if (_attributesCache != null) {
      print('Returning cached attributes');
      return _attributesCache!;
    }
    _attributesCache = await ApiService.fetchAttributes();
    return _attributesCache!;
  }

  Future<List<AttributeVariation>> fetchAttributeVariations(
    Map<String, String> params,
  ) async {
    if (_attributeVariationsCache != null) {
      print('Returning cached attribute variations');
      return _attributeVariationsCache!;
    }
    _attributeVariationsCache = await ApiService.fetchAttributeVariations(
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
  final String? userId;
  const UsedCarsPage({super.key, this.showAuctions = false, this.userId});

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
  final LocationService _locationService = LocationService();
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
  late ScrollController _scrollController;
  bool _showAppBarSearch = false;

  Future<void> _checkLoginStatus() async {
    final userId = widget.userId ?? await _storage.read(key: 'userId');
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
      final locationResponse = await _locationService.fetchLocations();
      if (locationResponse != null && locationResponse.status) {
        setState(() {
          _locations = locationResponse.data;
          _isLoadingLocations = false;
          print(
            'Locations fetched: ${_locations.map((loc) => "${loc.id}: ${loc.name}").toList()}',
          );
        });
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading locations: $e';
        _isLoadingLocations = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    _listingType = widget.showAuctions ? 'auction' : 'sale';
    _checkLoginStatus().then((_) {
      if (_listingType == 'auction' && _userId == null) {
        context.pushNamed(
          RouteNames.pleaseLoginPage,
          extra: {'redirectToAuctions': true},
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

  void _handleScroll() {
    if (_scrollController.offset > 100 && !_showAppBarSearch) {
      setState(() => _showAppBarSearch = true);
    } else if (_scrollController.offset <= 100 && _showAppBarSearch) {
      setState(() => _showAppBarSearch = false);
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
    if (_userId == null && _listingType == 'auction') {
      context.pushNamed(
        RouteNames.pleaseLoginPage,
        extra: {'redirectToAuctions': true},
      );
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
        categoryId: '1',
        userZoneId: _selectedLocation == 'all' ? '0' : _selectedLocation,
        listingType: _listingType,
        userId: _userId ?? '2',
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
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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

  Map<String, String> _mapFiltersToValues(
    Map<String, String> filters,
    String productId,
  ) {
    final Map<String, String> attributeValues = {};
    final Set<String> processedAttributes = {};
    if (_productAttributeValues.containsKey(productId)) {
      attributeValues.addAll(_productAttributeValues[productId]!);
      processedAttributes.addAll(attributeValues.keys);
    }
    filters.forEach((attributeId, variationId) {
      if (variationId.isNotEmpty &&
          !processedAttributes.contains(_getAttributeNameFromId(attributeId))) {
        try {
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
          if (variation.name.isNotEmpty) {
            attributeValues[attribute.name] = variation.name;
            processedAttributes.add(attribute.name);
          }
        } catch (e) {
          print('Error mapping attribute $attributeId: $e');
        }
      }
    });
    return attributeValues;
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

  List<Product> get filteredProducts {
    List<Product> filtered = _products;

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filtered =
          filtered.where((product) {
            final searchableText = [
              product.title.toLowerCase(),
              product.brand.toLowerCase(),
              product.model.toLowerCase(),
              product.modelVariation.toLowerCase(),
              _getLocationName(product.parentZoneId).toLowerCase(),
              product.filters['4']?.toLowerCase() ?? '',
              product.filters['5']?.toLowerCase() ?? '',
              product.filters['1']?.toString() ?? '',
              product.byDealer == '1' ? 'dealer' : 'owner',
            ].join(' ');
            return searchableText.contains(query);
          }).toList();
    }

    if (_selectedLocation != 'all') {
      filtered =
          filtered
              .where((product) => product.parentZoneId == _selectedLocation)
              .toList();
    }

    if (_listingType == 'auction') {
      filtered = filtered.where((product) => product.ifAuction == '1').toList();
    } else if (_listingType == 'sale') {
      filtered = filtered.where((product) => product.ifAuction == '0').toList();
    }

    if (_selectedBrands.isNotEmpty) {
      filtered =
          filtered
              .where((product) => _selectedBrands.contains(product.brand))
              .toList();
    }

    if (_selectedPriceRange != 'all') {
      filtered =
          filtered.where((product) {
            int price =
                product.ifAuction == '1'
                    ? (int.tryParse(product.auctionStartingPrice) ?? 0)
                    : (int.tryParse(product.price) ?? 0);
            switch (_selectedPriceRange) {
              case 'Under ₹2 Lakh':
                return price < 200000;
              case '₹2-5 Lakh':
                return price >= 200000 && price < 500000;
              case '₹5-10 Lakh':
                return price >= 500000 && price < 1000000;
              case '₹10-20 Lakh':
                return price >= 1000000 && price < 2000000;
              case 'Above ₹20 Lakh':
                return price >= 2000000;
              default:
                return true;
            }
          }).toList();
    }

    if (_selectedYearRange != 'all') {
      filtered =
          filtered.where((product) {
            int year =
                int.tryParse(product.filters['1']?.toString() ?? '0') ?? 0;
            switch (_selectedYearRange) {
              case '2020 & Above':
                return year >= 2020;
              case '2018-2019':
                return year >= 2018 && year <= 2019;
              case '2015-2017':
                return year >= 2015 && year <= 2017;
              case '2010-2014':
                return year >= 2010 && year <= 2014;
              case 'Below 2010':
                return year < 2010;
              default:
                return true;
            }
          }).toList();
    }

    if (_selectedOwnersRange != 'all') {
      filtered =
          filtered.where((product) {
            int owners =
                int.tryParse(product.filters['2']?.toString() ?? '0') ?? 0;
            switch (_selectedOwnersRange) {
              case '1st Owner':
                return owners == 1;
              case '2nd Owner':
                return owners == 2;
              case '3rd Owner':
                return owners == 3;
              case '4+ Owners':
                return owners >= 4;
              default:
                return true;
            }
          }).toList();
    }

    if (_selectedFuelTypes.isNotEmpty) {
      filtered =
          filtered
              .where(
                (product) => _selectedFuelTypes.contains(
                  product.filters['4']?.toString() ?? '',
                ),
              )
              .toList();
    }

    if (_selectedTransmissions.isNotEmpty) {
      filtered =
          filtered
              .where(
                (product) => _selectedTransmissions.contains(
                  product.filters['5']?.toString() ?? '',
                ),
              )
              .toList();
    }

    if (_selectedKmRange != 'all') {
      filtered =
          filtered.where((product) {
            int km = int.tryParse(product.filters['3']?.toString() ?? '0') ?? 0;
            switch (_selectedKmRange) {
              case 'Under 10K':
                return km < 10000;
              case '10K-30K':
                return km >= 10000 && km < 30000;
              case '30K-50K':
                return km >= 30000 && km < 50000;
              case '50K-80K':
                return km >= 50000 && km < 80000;
              case 'Above 80K':
                return km >= 80000;
              default:
                return true;
            }
          }).toList();
    }

    if (_selectedSoldBy != 'all') {
      filtered =
          filtered.where((product) {
            switch (_selectedSoldBy) {
              case 'Owner':
                return product.byDealer == '0';
              case 'Certified Dealer':
                return product.byDealer == '1';
              default:
                return true;
            }
          }).toList();
    }

    return filtered;
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
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _listingType == 'auction'
                                  ? 'Filter Auction Cars'
                                  : 'Filter Cars',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  _selectedBrands.clear();
                                  _selectedPriceRange = 'all';
                                  _selectedYearRange = 'all';
                                  _selectedOwnersRange = 'all';
                                  _selectedFuelTypes.clear();
                                  _selectedTransmissions.clear();
                                  _selectedKmRange = 'all';
                                  _selectedSoldBy = 'all';
                                });
                              },
                              child: const Text(
                                'Clear All',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMultiSelectFilterSection(
                                'Brand',
                                _brands,
                                _selectedBrands,
                                setModalState,
                              ),
                              _buildSingleSelectFilterSection(
                                'Price Range',
                                _priceRanges,
                                _selectedPriceRange,
                                (value) => setModalState(
                                  () => _selectedPriceRange = value,
                                ),
                                subtitle:
                                    _listingType == 'auction'
                                        ? 'Filter by starting bid price'
                                        : 'Filter by sale price',
                              ),
                              _buildSingleSelectFilterSection(
                                'Year',
                                _yearRanges,
                                _selectedYearRange,
                                (value) => setModalState(
                                  () => _selectedYearRange = value,
                                ),
                              ),
                              _buildSingleSelectFilterSection(
                                'Number of Owners',
                                _ownerRanges,
                                _selectedOwnersRange,
                                (value) => setModalState(
                                  () => _selectedOwnersRange = value,
                                ),
                              ),
                              _buildMultiSelectFilterSection(
                                'Fuel Type',
                                _fuelTypes,
                                _selectedFuelTypes,
                                setModalState,
                              ),
                              _buildMultiSelectFilterSection(
                                'Transmission',
                                _transmissions,
                                _selectedTransmissions,
                                setModalState,
                              ),
                              _buildSingleSelectFilterSection(
                                'KM Driven',
                                _kmRanges,
                                _selectedKmRange,
                                (value) => setModalState(
                                  () => _selectedKmRange = value,
                                ),
                              ),
                              _buildSingleSelectFilterSection(
                                'Sold By',
                                _soldByOptions,
                                _selectedSoldBy,
                                (value) => setModalState(
                                  () => _selectedSoldBy = value,
                                ),
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.primarypink,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.primaryblue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Apply Filters',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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

  Widget _buildMultiSelectFilterSection(
    String title,
    List<String> options,
    List<String> selectedValues,
    StateSetter setModalState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              options.map((option) {
                final isSelected = selectedValues.contains(option);
                return GestureDetector(
                  onTap: () {
                    setModalState(() {
                      if (isSelected) {
                        selectedValues.remove(option);
                      } else {
                        selectedValues.add(option);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Palette.primarypink
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? Palette.primarypink
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSingleSelectFilterSection(
    String title,
    List<String> options,
    String selectedValue,
    ValueChanged<String> onChanged, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              options.map((option) {
                final isSelected = selectedValue == option;
                final displayText = option == 'all' ? 'Any $title' : option;
                return GestureDetector(
                  onTap: () => onChanged(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Palette.primarypink
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? Palette.primarypink
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      displayText,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
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
      body: RefreshIndicator(
        onRefresh: () => _fetchProducts(forceRefresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child:
                  _isLoadingLocations
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
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
                                      onTap: () {
                                        if (_userId == null) {
                                          if (kDebugMode) {
                                            print(
                                              'Auction button clicked, but userId is null',
                                            );
                                          }
                                          context.pushNamed(
                                            RouteNames.pleaseLoginPage,
                                            extra: {'redirectToAuctions': true},
                                          );
                                        } else {
                                          setState(() {
                                            _listingType = 'auction';
                                            _fetchProducts();
                                          });
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
            if (!_isLoadingLocations)
              _isLoading
                  ? const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  )
                  : _errorMessage != null
                  ? SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: $_errorMessage',
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
                    ),
                  )
                  : filteredProducts.isEmpty
                  ? SliverToBoxAdapter(
                    child: Center(
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
                    ),
                  )
                  : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = filteredProducts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildProductCard(product),
                      );
                    }, childCount: filteredProducts.length),
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
                              child: Image.network(
                                'https://lelamonline.com/admin/${product.image}',
                                fit: BoxFit.cover,
                                height: 700,
                                width: 200,
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                    'Failed to load image: https://lelamonline.com/${product.image}',
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
                                if (isFeatured)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
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
                                Text(
                                  isAuction
                                      ? '${_formatPrice(double.tryParse(product.auctionStartingPrice) ?? 0)} - ${_formatPrice(double.tryParse(product.price) ?? 0)}'
                                      : '${_formatPrice(double.tryParse(product.price) ?? 0)}',
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
          padding: const EdgeInsets.all(5.0),
          child: Row(
            children: [
              const Icon(Icons.gavel, size: 16, color: Colors.black),
              const SizedBox(width: 6),
              Text(
                'Attempts: ${product.auctionAttempt}/3',
                style: const TextStyle(
                  fontSize: 13,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
}
