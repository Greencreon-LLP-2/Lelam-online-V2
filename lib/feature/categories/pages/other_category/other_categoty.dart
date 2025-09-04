import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/feature/categories/pages/other_category/other_Category_details_page.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/feature/home/view/services/location_service.dart';
import 'package:lelamonline_flutter/utils/palette.dart';

// MarketplacePost model
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

// MarketplaceService
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

// Bike model extending MarketplacePost
class Bike extends MarketplacePost {
  Bike({
    required String id,
    required String slug,
    required String title,
    required String categoryId,
    required String image,
    required String brand,
    required String model,
    required String modelVariation,
    required String description,
    required String price,
    required String auctionPriceInterval,
    required String auctionStartingPrice,
    required List<String> attributeId,
    required List<String> attributeVariationsId,
    required Map<String, List<String>> filters,
    required String latitude,
    required String longitude,
    required String userZoneId,
    required String parentZoneId,
    required String landMark,
    required String ifAuction,
    required String auctionStatus,
    required String auctionStartin,
    required String auctionEndin,
    required String auctionAttempt,
    required String adminApproval,
    required String ifFinance,
    required String ifExchange,
    required String feature,
    required String status,
    required String visiterCount,
    required String ifSold,
    required String ifExpired,
    required String byDealer,
    required String createdBy,
    required String createdOn,
    required String updatedOn,
  }) : super(
          id: id,
          slug: slug,
          title: title,
          categoryId: categoryId,
          image: image,
          brand: brand,
          model: model,
          modelVariation: modelVariation,
          description: description,
          price: price,
          auctionPriceInterval: auctionPriceInterval,
          auctionStartingPrice: auctionStartingPrice,
          attributeId: attributeId,
          attributeVariationsId: attributeVariationsId,
          filters: filters,
          latitude: latitude,
          longitude: longitude,
          userZoneId: userZoneId,
          parentZoneId: parentZoneId,
          landMark: landMark,
          ifAuction: ifAuction,
          auctionStatus: auctionStatus,
          auctionStartin: auctionStartin,
          auctionEndin: auctionEndin,
          auctionAttempt: auctionAttempt,
          adminApproval: adminApproval,
          ifFinance: ifFinance,
          ifExchange: ifExchange,
          feature: feature,
          status: status,
          visiterCount: visiterCount,
          ifSold: ifSold,
          ifExpired: ifExpired,
          byDealer: byDealer,
          createdBy: createdBy,
          createdOn: createdOn,
          updatedOn: updatedOn,
        );

  factory Bike.fromMarketplacePost(MarketplacePost post) {
    return Bike(
      id: post.id,
      slug: post.slug,
      title: post.title,
      categoryId: post.categoryId,
      image: post.image,
      brand: post.brand,
      model: post.model,
      modelVariation: post.modelVariation,
      description: post.description,
      price: post.price,
      auctionPriceInterval: post.auctionPriceInterval,
      auctionStartingPrice: post.auctionStartingPrice,
      attributeId: post.attributeId,
      attributeVariationsId: post.attributeVariationsId,
      filters: post.filters,
      latitude: post.latitude,
      longitude: post.longitude,
      userZoneId: post.userZoneId,
      parentZoneId: post.parentZoneId,
      landMark: post.landMark,
      ifAuction: post.ifAuction,
      auctionStatus: post.auctionStatus,
      auctionStartin: post.auctionStartin,
      auctionEndin: post.auctionEndin,
      auctionAttempt: post.auctionAttempt,
      adminApproval: post.adminApproval,
      ifFinance: post.ifFinance,
      ifExchange: post.ifExchange,
      feature: post.feature,
      status: post.status,
      visiterCount: post.visiterCount,
      ifSold: post.ifSold,
      ifExpired: post.ifExpired,
      byDealer: post.byDealer,
      createdBy: post.createdBy,
      createdOn: post.createdOn,
      updatedOn: post.updatedOn,
    );
  }
}

class OthersPage extends StatefulWidget {
  const OthersPage({super.key, String? userId});

  @override
  State<OthersPage> createState() => _OthersPageState();
}

class _OthersPageState extends State<OthersPage> {
  String _searchQuery = '';
  String _selectedLocation = 'all';
  List<String> _selectedVehicleTypes = [];
  String _selectedPriceRange = 'all';
  String _selectedCondition = 'all';
  List<String> _selectedFuelTypes = [];

  final TextEditingController _searchController = TextEditingController();
  final MarketplaceService _marketplaceService = MarketplaceService();
  final LocationService _locationService = LocationService();
  List<Bike> _bikes = [];
  List<LocationData> _locations = [];
  bool _isLoading = true;
  bool _isLoadingLocations = true;
  String? _errorMessage;

  late ScrollController _scrollController;
  bool _showAppBarSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    _fetchBikes();
    _fetchLocations();
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
        _errorMessage = 'Error loading locations: $e';
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _fetchBikes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final posts = await _marketplaceService.fetchPosts(
        categoryId: '4', // Change this to the appropriate category ID for bikes
        userZoneId: _selectedLocation == 'all' ? '0' : _selectedLocation,
      );
      setState(() {
        _bikes = posts.map((post) => Bike.fromMarketplacePost(post)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  final List<String> _vehicleTypes = [
    'Motorcycle',
    'Bicycle',
    'E-Bike',
    'Scooter',
  ];

  final List<String> _priceRanges = [
    'all',
    'Under 50K',
    '50K-1L',
    '1L-2L',
    '2L-5L',
    'Above 5L',
  ];

  final List<String> _conditions = ['all', 'New', 'Used'];

  final List<String> _fuelTypes = ['Petrol', 'Electric', 'None'];

  List<Bike> get filteredBikes {
    List<Bike> filtered = _bikes;

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((bike) {
        final vehicleType = bike.filters['vehicleType']?.isNotEmpty ?? false
            ? bike.filters['vehicleType']!.first.toLowerCase()
            : '';
        return bike.title.toLowerCase().contains(query) ||
            bike.brand.toLowerCase().contains(query) ||
            vehicleType.contains(query);
      }).toList();
    }

    if (_selectedLocation != 'all') {
      filtered = filtered
          .where((bike) =>
              bike.userZoneId == _selectedLocation ||
              bike.parentZoneId == _selectedLocation)
          .toList();
    }

    if (_selectedVehicleTypes.isNotEmpty) {
      filtered = filtered.where((bike) {
        final vehicleType = bike.filters['vehicleType']?.isNotEmpty ?? false
            ? bike.filters['vehicleType']!.first
            : '';
        return _selectedVehicleTypes.contains(vehicleType);
      }).toList();
    }

    if (_selectedPriceRange != 'all') {
      filtered = filtered.where((bike) {
        final price = int.tryParse(bike.price) ?? 0;
        switch (_selectedPriceRange) {
          case 'Under 50K':
            return price < 50000;
          case '50K-1L':
            return price >= 50000 && price < 100000;
          case '1L-2L':
            return price >= 100000 && price < 200000;
          case '2L-5L':
            return price >= 200000 && price < 500000;
          case 'Above 5L':
            return price >= 500000;
          default:
            return true;
        }
      }).toList();
    }

    if (_selectedCondition != 'all') {
      filtered = filtered.where((bike) {
        final condition = bike.filters['condition']?.isNotEmpty ?? false
            ? bike.filters['condition']!.first
            : '';
        return condition == _selectedCondition;
      }).toList();
    }

    if (_selectedFuelTypes.isNotEmpty) {
      filtered = filtered.where((bike) {
        final fuelType = bike.filters['fuelType']?.isNotEmpty ?? false
            ? bike.filters['fuelType']!.first
            : '';
        return _selectedFuelTypes.contains(fuelType);
      }).toList();
    }

    return filtered;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
                      'Filter Bikes & Others',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedVehicleTypes.clear();
                          _selectedPriceRange = 'all';
                          _selectedCondition = 'all';
                          _selectedFuelTypes.clear();
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
                        'Vehicle Type',
                        _vehicleTypes,
                        _selectedVehicleTypes,
                        setModalState,
                      ),
                      _buildSingleSelectFilterSection(
                        'Price Range',
                        _priceRanges,
                        _selectedPriceRange,
                        (value) => setModalState(() => _selectedPriceRange = value),
                      ),
                      _buildSingleSelectFilterSection(
                        'Condition',
                        _conditions,
                        _selectedCondition,
                        (value) => setModalState(() => _selectedCondition = value),
                      ),
                      _buildMultiSelectFilterSection(
                        'Fuel Type',
                        _fuelTypes,
                        _selectedFuelTypes,
                        setModalState,
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
          children: options.map((option) {
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
                  color: isSelected ? Palette.primarypink : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Palette.primarypink : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
    ValueChanged<String> onChanged,
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
          children: options.map((option) {
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
                  color: isSelected ? Palette.primarypink : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Palette.primarypink : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
    if (_selectedVehicleTypes.isNotEmpty) count++;
    if (_selectedPriceRange != 'all') count++;
    if (_selectedCondition != 'all') count++;
    if (_selectedFuelTypes.isNotEmpty) count++;
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
          hintText: 'Search bikes...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon: _searchQuery.isNotEmpty
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
        hintText: 'Search by bike type, brand, location...',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
        suffixIcon: _searchQuery.isNotEmpty
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

  String getImageUrl(String imagePath) {
    final cleanedPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return 'https://lelamonline.com/admin/$cleanedPath';
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
                      _selectedLocation = value == 'all'
                          ? 'all'
                          : _locations.firstWhere((loc) => loc.name == value).id;
                      _fetchBikes();
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
                                    : _locations.firstWhere((loc) => loc.name == city).id))
                              const Icon(
                                Icons.check,
                                color: Colors.blue,
                                size: 16,
                              ),
                            if (_selectedLocation ==
                                (city == 'all'
                                    ? 'all'
                                    : _locations.firstWhere((loc) => loc.name == city).id))
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
            child: _isLoadingLocations
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      if (!_showAppBarSearch)
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: _buildSearchField(),
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
                                onPressed: _fetchBikes,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredBikes.isEmpty
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
                                    'No bikes found',
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
                              final bike = filteredBikes[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildBikeCard(bike),
                              );
                            }, childCount: filteredBikes.length),
                          ),
        ],
      ),
    );
  }

  List<String> get _keralaCities {
    return ['all', ..._locations.map((loc) => loc.name)];
  }

  Widget _buildBikeCard(Bike bike) {
    final isFinanceAvailable = bike.ifFinance == '1';
    final isFeatured = bike.feature == '1';
    final isAuction = bike.ifAuction == '1';
    final vehicleType = bike.filters['vehicleType']?.isNotEmpty ?? false
        ? bike.filters['vehicleType']!.first
        : 'N/A';
    final condition = bike.filters['condition']?.isNotEmpty ?? false
        ? bike.filters['condition']!.first
        : 'N/A';
    final fuelType = bike.filters['fuelType']?.isNotEmpty ?? false
        ? bike.filters['fuelType']!.first
        : 'N/A';
    final sellerType = bike.byDealer == '1' ? 'Dealer' : 'Owner';

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BikeDetailsPage(bike: bike),
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
                              image: NetworkImage(getImageUrl(bike.image)),
                              fit: BoxFit.fill,
                              onError: (exception, stackTrace) {
                                print('Failed to load image: ${getImageUrl(bike.image)}');
                                print('Error: $exception');
                              },
                            ),
                          ),
                          child: isFeatured
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
                              bike.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              vehicleType,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAuction
                                  ? '₹${formatPriceInt(double.tryParse(bike.auctionStartingPrice) ?? 0)} - ₹${formatPriceInt(double.tryParse(bike.price) ?? 0)}'
                                  : '₹${formatPriceInt(double.tryParse(bike.price) ?? 0)}',
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
                                  _getLocationName(bike.parentZoneId),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildDetailChip(
                                  Icon(
                                    Icons.calendar_today,
                                    size: 8,
                                    color: Colors.grey[700],
                                  ),
                                  condition,
                                ),
                                const SizedBox(width: 4),
                                _buildDetailChip(
                                  Icon(
                                    Icons.local_gas_station,
                                    size: 8,
                                    color: Colors.grey[700],
                                  ),
                                  fuelType,
                                ),
                                const SizedBox(width: 4),
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
                            color: isAuction ? Palette.primarylightblue : Colors.white,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: isAuction
                              ? _buildAuctionInfo(bike)
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

  Widget _buildAuctionInfo(Bike bike) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.gavel, size: 16, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              'Attempts: ${bike.auctionAttempt}/3',
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
              fontWeight: FontWeight.w600,
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
}