import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/feature/categories/pages/real%20estate/real_estate_details_page.dart';
import 'package:lelamonline_flutter/utils/palette.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';

import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/auction_detail_page.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/market_used_cars_page.dart';

// MarketplacePost model (unchanged)
class MarketplacePost {
  final String id;
  final String slug;
  final String title;
  final String categoryId;
  final String image;
  final String brand;
  final String model;
  final String modelVariation;
  final String description;
  final String price;
  final String auctionPriceInterval;
  final String auctionStartingPrice;
  final List<String> attributeId;
  final List<String> attributeVariationsId;
  final Map<String, List<String>> filters;
  final String latitude;
  final String longitude;
  final String userZoneId;
  final String parentZoneId;
  final String landMark;
  final String ifAuction;
  final String auctionStatus;
  final String auctionStartin;
  final String auctionEndin;
  final String auctionAttempt;
  final String adminApproval;
  final String ifFinance;
  final String ifExchange;
  final String feature;
  final String status;
  final String visiterCount;
  final String ifSold;
  final String ifExpired;
  final String byDealer;
  final String createdBy;
  final String createdOn;
  final String updatedOn;

  MarketplacePost({
    required this.id,
    required this.slug,
    required this.title,
    required this.categoryId,
    required this.image,
    required this.brand,
    required this.model,
    required this.modelVariation,
    required this.description,
    required this.price,
    required this.auctionPriceInterval,
    required this.auctionStartingPrice,
    required this.attributeId,
    required this.attributeVariationsId,
    required this.filters,
    required this.latitude,
    required this.longitude,
    required this.userZoneId,
    required this.parentZoneId,
    required this.landMark,
    required this.ifAuction,
    required this.auctionStatus,
    required this.auctionStartin,
    required this.auctionEndin,
    required this.auctionAttempt,
    required this.adminApproval,
    required this.ifFinance,
    required this.ifExchange,
    required this.feature,
    required this.status,
    required this.visiterCount,
    required this.ifSold,
    required this.ifExpired,
    required this.byDealer,
    required this.createdBy,
    required this.createdOn,
    required this.updatedOn,
  });

  factory MarketplacePost.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return List<String>.from(value);
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List)
            return List<String>.from(decoded.map((e) => e.toString()));
        } catch (e) {
          return value.split(',').map((e) => e.trim()).toList();
        }
      }
      return [];
    }

    Map<String, List<String>> parseFilters(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, List<String>>.from(
          value.map(
            (key, value) => MapEntry(key.toString(), parseStringList(value)),
          ),
        );
      }
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map) {
            return Map<String, List<String>>.from(
              decoded.map(
                (key, value) =>
                    MapEntry(key.toString(), parseStringList(value)),
              ),
            );
          }
        } catch (e) {
          return {};
        }
      }
      return {};
    }

    return MarketplacePost(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      modelVariation: json['model_variation']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      auctionPriceInterval: json['auction_price_intervel']?.toString() ?? '0',
      auctionStartingPrice: json['auction_starting_price']?.toString() ?? '0',
      attributeId: parseStringList(json['attribute_id']),
      attributeVariationsId: parseStringList(json['attribute_variations_id']),
      filters: parseFilters(json['filters']),
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      userZoneId: json['user_zone_id']?.toString() ?? '',
      parentZoneId: json['parent_zone_id']?.toString() ?? '',
      landMark: json['land_mark']?.toString() ?? '',
      ifAuction: json['if_auction']?.toString() ?? '0',
      auctionStatus: json['auction_status']?.toString() ?? '',
      auctionStartin: json['auction_startin']?.toString() ?? '',
      auctionEndin: json['auction_endin']?.toString() ?? '',
      auctionAttempt: json['auction_attempt']?.toString() ?? '0',
      adminApproval: json['admin_approval']?.toString() ?? '0',
      ifFinance: json['if_finance']?.toString() ?? '0',
      ifExchange: json['if_exchange']?.toString() ?? '0',
      feature: json['feature']?.toString() ?? '0',
      status: json['status']?.toString() ?? '0',
      visiterCount: json['visiter_count']?.toString() ?? '0',
      ifSold: json['if_sold']?.toString() ?? '0',
      ifExpired: json['if_expired']?.toString() ?? '0',
      byDealer: json['by_dealer']?.toString() ?? '0',
      createdBy: json['created_by']?.toString() ?? '',
      createdOn: json['created_on']?.toString() ?? '',
      updatedOn: json['updated_on']?.toString() ?? '',
    );
  }
}

// MarketplaceService (unchanged)
class MarketplaceService {
  static const String baseUrl = 'https://lelamonline.com/admin/api/v1';
  static const String token = '5cb2c9b569416b5db1604e0e12478ded';

  Future<List<MarketplacePost>> fetchPosts({
    required String categoryId,
    required String userZoneId,
  }) async {
    final url =
        '$baseUrl/list-category-post-marketplace.php?token=$token&category_id=$categoryId&user_zone_id=$userZoneId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is List) {
          return decodedBody.map((json) {
            try {
              return MarketplacePost.fromJson(json);
            } catch (e) {
              print('Error parsing post: $e');
              print('Problematic JSON: $json');
              throw Exception('Failed to parse post: $e');
            }
          }).toList();
        } else if (decodedBody is Map && decodedBody.containsKey('data')) {
          final data = decodedBody['data'] as List;
          return data.map((json) => MarketplacePost.fromJson(json)).toList();
        } else {
          throw Exception('Unexpected API response format');
        }
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchPosts: $e');
      throw Exception('Error fetching posts: $e');
    }
  }
}

class RealEstatePage extends StatefulWidget {
  const RealEstatePage({super.key, String? userId});

  @override
  State<RealEstatePage> createState() => _RealEstatePageState();
}

class _RealEstatePageState extends State<RealEstatePage> {
  String _searchQuery = '';
  String _selectedLocation = 'all';
  String _listingType = 'sale'; // Added for sale/auction toggle
  final TextEditingController _searchController = TextEditingController();
  final MarketplaceService _marketplaceService = MarketplaceService();

  List<MarketplacePost> _posts = [];
  List<LocationData> _locations = [];
  bool _isLoading = true;
  bool _isLoadingLocations = true;
  String? _errorMessage;

  // Filter variables
  List<String> _selectedPropertyTypes = [];
  String _selectedPriceRange = 'all';
  String _selectedBedroomRange = 'all';
  String _selectedAreaRange = 'all';
  List<String> _selectedFurnishings = [];
  String _selectedPostedBy = 'all';

  late ScrollController _scrollController;
  bool _showAppBarSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    _fetchPosts();
    _fetchLocations();
  }

  String _norm(String? s) => (s ?? '').toString().toLowerCase().trim();

  int _parsePriceSafe(String s) {
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  void _applySearch() {
    setState(() {
      _searchQuery = _searchController.text;
    });

    _fetchPosts();
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

  Future<void> _fetchLocations() async {
    setState(() {
      _isLoadingLocations = true;
      _errorMessage = null;
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
        _errorMessage = 'Error loading locations: $e';
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final posts = await _marketplaceService.fetchPosts(
        categoryId: '2',
        userZoneId: _selectedLocation == 'all' ? '0' : _selectedLocation,
      );
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  final List<String> _propertyTypes = [
    'Apartment',
    'Villa',
    'House',
    'Office',
    'Shop',
    'Penthouse',
    'Duplex',
    'Warehouse',
    'Plot',
    'Farmhouse',
  ];

  final List<String> _priceRanges = [
    'all',
    'Under 50L',
    '50L-1Cr',
    '1Cr-2Cr',
    '2Cr-5Cr',
    'Above 5Cr',
  ];

  final List<String> _bedroomRanges = ['all', '1', '2', '3', '4', '5+'];

  final List<String> _areaRanges = [
    'all',
    'Under 500 sq ft',
    '500-1000 sq ft',
    '1000-1500 sq ft',
    '1500-2000 sq ft',
    'Above 2000 sq ft',
  ];

  final List<String> _furnishings = [
    'Furnished',
    'Semi-Furnished',
    'Unfurnished',
  ];

  final List<String> _postedByOptions = ['all', 'Owner', 'Builder', 'Agent'];

  List<String> get _keralaCities {
    return ['all', ..._locations.map((loc) => loc.name)];
  }

  List<MarketplacePost> get filteredPosts {
    List<MarketplacePost> filtered = _posts;

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((post) {
            final title = _norm(post.title);
            final landmark = _norm(post.landMark);
              final parentLocation = _norm(_getLocationName(post.parentZoneId));
             final userLocation = _norm(_getLocationName(post.userZoneId));
            final propTypes = post.filters['propertyType'] ?? <String>[];
            final propMatch = propTypes.any((p) => _norm(p).contains(query));
            return title.contains(query) ||
                landmark.contains(query) ||
                 parentLocation.contains(query) ||
                 userLocation.contains(query) ||
                propMatch;
          }).toList();
    }

    if (_selectedLocation != 'all') {
      filtered =
          filtered
              .where(
                (post) =>
                    post.userZoneId == _selectedLocation ||
                    post.parentZoneId == _selectedLocation,
              )
              .toList();
    }

    if (_listingType == 'auction') {
      filtered = filtered.where((post) => post.ifAuction == '1').toList();
    } else if (_listingType == 'sale') {
      filtered = filtered.where((post) => post.ifAuction == '0').toList();
    }

    if (_selectedPropertyTypes.isNotEmpty) {
      final selectedSet = _selectedPropertyTypes.map((s) => _norm(s)).toSet();
      filtered =
          filtered.where((post) {
            final propList = post.filters['propertyType'] ?? <String>[];
            final propNorm = propList.map((p) => _norm(p)).toList();
            return propNorm.any((p) => selectedSet.contains(p));
          }).toList();
    }

    if (_selectedPriceRange != 'all') {
      filtered =
          filtered.where((post) {
            final priceStr =
                _listingType == 'auction'
                    ? post.auctionStartingPrice
                    : post.price;
            int price = _parsePriceSafe(priceStr);

            switch (_selectedPriceRange) {
              case 'Under 50L':
                return price < 5000000;
              case '50L-1Cr':
                return price >= 5000000 && price < 10000000;
              case '1Cr-2Cr':
                return price >= 10000000 && price < 20000000;
              case '2Cr-5Cr':
                return price >= 20000000 && price < 50000000;
              case 'Above 5Cr':
                return price >= 50000000;
              default:
                return true;
            }
          }).toList();
    }

    if (_selectedBedroomRange != 'all') {
      filtered =
          filtered.where((post) {
            final bedroomsStr =
                post.filters['bedrooms']?.isNotEmpty ?? false
                    ? post.filters['bedrooms']!.first
                    : '0';
            int bedrooms = int.tryParse(bedroomsStr) ?? 0;
            switch (_selectedBedroomRange) {
              case '1':
                return bedrooms == 1;
              case '2':
                return bedrooms == 2;
              case '3':
                return bedrooms == 3;
              case '4':
                return bedrooms == 4;
              case '5+':
                return bedrooms >= 5;
              default:
                return true;
            }
          }).toList();
    }

    if (_selectedAreaRange != 'all') {
      filtered =
          filtered.where((post) {
            final areaStr =
                post.filters['area']?.isNotEmpty ?? false
                    ? post.filters['area']!.first
                    : '0';
            int area = int.tryParse(areaStr) ?? 0;
            switch (_selectedAreaRange) {
              case 'Under 500 sq ft':
                return area < 500;
              case '500-1000 sq ft':
                return area >= 500 && area < 1000;
              case '1000-1500 sq ft':
                return area >= 1000 && area < 1500;
              case '1500-2000 sq ft':
                return area >= 1500 && area < 2000;
              case 'Above 2000 sq ft':
                return area >= 2000;
              default:
                return true;
            }
          }).toList();
    }

    if (_selectedFurnishings.isNotEmpty) {
      final selectedSet = _selectedFurnishings.map((s) => _norm(s)).toSet();
      filtered =
          filtered.where((post) {
            final furnList = post.filters['furnishing'] ?? <String>[];
            final furnNorm = furnList.map((f) => _norm(f)).toList();
            return furnNorm.any((f) => selectedSet.contains(f));
          }).toList();
    }

    if (_selectedPostedBy != 'all') {
      filtered =
          filtered.where((post) {
            switch (_selectedPostedBy) {
              case 'Owner':
                return post.byDealer == '0';
              case 'Builder':
              case 'Agent':
                return post.byDealer == '1';
              default:
                return true;
            }
          }).toList();
    }

    return filtered;
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
                            const Text(
                              'Filter Properties',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  _selectedPropertyTypes.clear();
                                  _selectedPriceRange = 'all';
                                  _selectedBedroomRange = 'all';
                                  _selectedAreaRange = 'all';
                                  _selectedFurnishings.clear();
                                  _selectedPostedBy = 'all';
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
                                'Property Type',
                                _propertyTypes,
                                _selectedPropertyTypes,
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
                                'Bedrooms',
                                _bedroomRanges,
                                _selectedBedroomRange,
                                (value) => setModalState(
                                  () => _selectedBedroomRange = value,
                                ),
                              ),
                              _buildSingleSelectFilterSection(
                                'Area',
                                _areaRanges,
                                _selectedAreaRange,
                                (value) => setModalState(
                                  () => _selectedAreaRange = value,
                                ),
                              ),
                              _buildMultiSelectFilterSection(
                                'Furnishing',
                                _furnishings,
                                _selectedFurnishings,
                                setModalState,
                              ),
                              _buildSingleSelectFilterSection(
                                'Posted By',
                                _postedByOptions,
                                _selectedPostedBy,
                                (value) => setModalState(
                                  () => _selectedPostedBy = value,
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
                                onPressed: () async {
                                  setState(() {});
                                  await _fetchPosts();
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
    if (_selectedPropertyTypes.isNotEmpty) count++;
    if (_selectedPriceRange != 'all') count++;
    if (_selectedBedroomRange != 'all') count++;
    if (_selectedAreaRange != 'all') count++;
    if (_selectedFurnishings.isNotEmpty) count++;
    if (_selectedPostedBy != 'all') count++;
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
          hintText: 'Search properties...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade400),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                    _applySearch();
                  },
                ),
              IconButton(
                icon: Icon(Icons.search, color: Colors.grey.shade400),
                onPressed: _applySearch,
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 10),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
        onSubmitted: (value) {
          _applySearch();
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
      onSubmitted: (value) {
        setState(() => _searchQuery = value);
        _fetchPosts();
      },
      decoration: InputDecoration(
        hintText: 'Search by property type, location, features...',
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
                    _fetchPosts();
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
      body: CustomScrollView(
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
                                        _fetchPosts();
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
                                        borderRadius: BorderRadius.circular(10),
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
                                // Expanded(
                                //   child: GestureDetector(
                                //     onTap: () {
                                //       setState(() {
                                //         _listingType = 'auction';
                                //         _fetchPosts();
                                //       });
                                //     },
                                //     child: Container(
                                //       padding: const EdgeInsets.symmetric(
                                //         vertical: 12,
                                //       ),
                                //       decoration: BoxDecoration(
                                //         color:
                                //             _listingType == 'auction'
                                //                 ? Palette.white
                                //                 : Colors.transparent,
                                //         borderRadius: BorderRadius.circular(10),
                                //       ),
                                //       child: Text(
                                //         'Auction',
                                //         textAlign: TextAlign.center,
                                //         style: TextStyle(
                                //           fontWeight:
                                //               _listingType == 'auction'
                                //                   ? FontWeight.w600
                                //                   : FontWeight.normal,
                                //           color:
                                //               _listingType == 'auction'
                                //                   ? Colors.black
                                //                   : Colors.grey.shade600,
                                //           fontSize: 12,
                                //         ),
                                //       ),
                                //     ),
                                //   ),
                                // ),
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
                          onPressed: _fetchPosts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
                : filteredPosts.isEmpty
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
                          'No properties found',
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
                    final post = filteredPosts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPostCard(post),
                    );
                  }, childCount: filteredPosts.length),
                ),
        ],
      ),
    );
  }

  String getImageUrl(String imagePath) {
    final cleanedPath =
        imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return 'https://lelamonline.com/admin/$cleanedPath';
  }

  Widget _buildPostCard(MarketplacePost post) {
    final isFinanceAvailable = post.ifFinance == '1';
    final isFeatured = post.feature == '1';
    final isAuction = post.ifAuction == '1';
    final propertyType =
        post.filters['propertyType']?.isNotEmpty ?? false
            ? post.filters['propertyType']!.first
            : 'N/A';
    final sellerType = post.byDealer == '1' ? 'Dealer' : 'Owner';

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => RealEstateProductDetailsPage(
                      product: post,
                      isAuction: isAuction,
                    ),
              ),
            );
          },
          child: Container(
            width: constraints.maxWidth,
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
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
                        height: 138,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(0),
                          ),
                        ),
                        child: Container(
                          width: 130,
                          height: 138,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            image: DecorationImage(
                              image: NetworkImage(getImageUrl(post.image)),
                              fit:
                                  BoxFit
                                      .fill, // Ensures full image is visible, scaled to fit
                              onError: (exception, stackTrace) {
                                print(
                                  'Failed to load image: ${getImageUrl(post.image)}',
                                );
                                print('Error: $exception');
                              },
                            ),
                          ),
                          child:
                              isFeatured
                                  ? Align(
                                    alignment: Alignment.topLeft,
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        top: 8,
                                        left: 8,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white),
                                      ),
                                      child: const Text(
                                        'FEATURED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                  : null,
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
                              post.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Text(
                            //   propertyType,
                            //   style: TextStyle(
                            //     fontSize: 10,
                            //     color: Colors.grey.shade600,
                            //   ),
                            // ),
                            const SizedBox(height: 8),
                            Text(
                              isAuction
                                  ? '₹${formatPriceInt(double.tryParse(post.auctionStartingPrice) ?? 0)} - ₹${formatPriceInt(double.tryParse(post.price) ?? 0)}'
                                  : '₹${formatPriceInt(double.tryParse(post.price) ?? 0)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Palette.primaryblue,
                              ),
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
                                  _getLocationName(post.parentZoneId),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildDetailChip(
                              Icon(
                                Icons.person,
                                size: 8,
                                color: Colors.grey[700],
                              ),
                              sellerType,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (isAuction || isFinanceAvailable)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isAuction
                                    ? Palette.primarylightblue
                                    : Colors.white,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child:
                              isAuction
                                  ? _buildAuctionInfo(post)
                                  : _buildFinanceInfo(isFinanceAvailable),
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

  Widget _buildAuctionInfo(MarketplacePost post) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.gavel, size: 16, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              'Attempts: ${post.auctionAttempt}/3',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white),
          ),
          child: const Text(
            'AUCTION',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceInfo(bool isFinanceAvailable) {
    if (!isFinanceAvailable) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Palette.primarylightblue),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.account_balance, size: 10, color: Colors.black),
          const SizedBox(width: 8),
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
    );
  }

  Widget _buildDetailChip(Widget icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  String formatPriceInt(double price) {
    final formatter = NumberFormat.decimalPattern('en_IN');
    return formatter.format(price.round());
  }

  String _formatNumber(num number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(2)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(number == number.roundToDouble() ? 0 : 2);
    }
  }
}
