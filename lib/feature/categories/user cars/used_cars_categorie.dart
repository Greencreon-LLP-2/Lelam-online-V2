import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/feature/categories/pages/commercial/user%20cars/detail_page/auction_detail_page.dart';
import 'package:lelamonline_flutter/feature/product/view/pages/product_details_page.dart';
import 'package:lelamonline_flutter/utils/palette.dart';

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
  final String zoneId;
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
    required this.zoneId,
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
          value.map((key, value) {
            return MapEntry(key.toString(), parseStringList(value));
          }),
        );
      }
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map) {
            return Map<String, List<String>>.from(
              decoded.map((key, value) {
                return MapEntry(key.toString(), parseStringList(value));
              }),
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
      zoneId: json['zone_id']?.toString() ?? '',
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

  Product toProduct() {

    final convertedFilters = filters.map(
      (key, value) => MapEntry(key, value.isNotEmpty ? value.first : ''),
    );

    return Product(
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
      auctionPriceIntervel: auctionPriceInterval,
      auctionStartingPrice: auctionStartingPrice,
      attributeId: attributeId,
      attributeVariationsId: attributeVariationsId,
      filters: convertedFilters,
      latitude: latitude,
      longitude: longitude,
      userZoneId: userZoneId,
      parentZoneId: parentZoneId,
      zoneId: zoneId,
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
  }
}

// Marketplace Service
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
        // First decode the response body
        final decodedBody = jsonDecode(response.body);

        // Check if the response is a List
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
        }
        // Handle case where API returns a Map with data
        else if (decodedBody is Map && decodedBody.containsKey('data')) {
          final data = decodedBody['data'] as List;
          return data.map((json) => MarketplacePost.fromJson(json)).toList();
        }
        // Handle unexpected format
        else {
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

// Product model (kept as provided for UI compatibility)
class Product {
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
  final String auctionPriceIntervel;
  final String auctionStartingPrice;
  final List<String> attributeId;
  final List<String> attributeVariationsId;
  final Map<String, String> filters;
  final String latitude;
  final String longitude;
  final String userZoneId;
  final String parentZoneId;
  final String zoneId;
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

  Product({
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
    required this.auctionPriceIntervel,
    required this.auctionStartingPrice,
    required this.attributeId,
    required this.attributeVariationsId,
    required this.filters,
    required this.latitude,
    required this.longitude,
    required this.userZoneId,
    required this.parentZoneId,
    required this.zoneId,
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
}

class UsedCarsPage extends StatefulWidget {
  const UsedCarsPage({super.key});

  @override
  State<UsedCarsPage> createState() => _UsedCarsPageState();
}

class _UsedCarsPageState extends State<UsedCarsPage> {
  String _searchQuery = '';
  String _selectedLocation = 'all';
  String _listingType = 'sale';

  final TextEditingController _searchController = TextEditingController();
  final MarketplaceService _marketplaceService = MarketplaceService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter variables
  List<String> _selectedBrands = [];
  String _selectedPriceRange = 'all';
  String _selectedYearRange = 'all';
  String _selectedOwnersRange = 'all';
  List<String> _selectedFuelTypes = [];
  List<String> _selectedTransmissions = [];
  String _selectedKmRange = 'all';
  String _selectedSoldBy = 'all';

  // Scroll controller for dynamic search bar
  late ScrollController _scrollController;
  bool _showAppBarSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    _fetchProducts();
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

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final posts = await _marketplaceService.fetchPosts(
        categoryId: '1',
        userZoneId: '0',
      );
      setState(() {
        _products = posts.map((post) => post.toProduct()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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

  final List<String> _keralaCities = [
    'all',
    'Thiruvananthapuram',
    'Kollam',
    'Pathanamthitta',
    'Alappuzha',
    'Kottayam',
    'Idukki',
    'Ernakulam',
    'Thrissur',
    'Palakkad',
    'Malappuram',
    'Kozhikode',
    'Wayanad',
    'Kannur',
    'Kasaragod',
  ];

  final List<String> _listingTypes = ['sale', 'auction'];

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
              product.landMark.toLowerCase(),
              product.filters['fuel']?.toLowerCase() ?? '',
              product.filters['transmission']?.toLowerCase() ?? '',
              product.filters['year']?.toString() ?? '',
              product.byDealer == '1' ? 'dealer' : 'owner',
            ].join(' ');
            return searchableText.contains(query);
          }).toList();
    }

    if (_selectedLocation != 'all') {
      filtered =
          filtered
              .where((product) => product.landMark == _selectedLocation)
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
                int.tryParse(product.filters['year']?.toString() ?? '0') ?? 0;
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
                int.tryParse(product.filters['owners']?.toString() ?? '0') ?? 0;
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
                  product.filters['fuel']?.toString() ?? '',
                ),
              )
              .toList();
    }

    if (_selectedTransmissions.isNotEmpty) {
      filtered =
          filtered
              .where(
                (product) => _selectedTransmissions.contains(
                  product.filters['transmission']?.toString() ?? '',
                ),
              )
              .toList();
    }

    if (_selectedKmRange != 'all') {
      filtered =
          filtered.where((product) {
            int km =
                int.tryParse(product.filters['km']?.toString() ?? '0') ?? 0;
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
              // casevan 'Dealer':
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
    // Remove any leading slashes to prevent double slashes
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
                            const Text(
                              'Filter Cars',
                              style: TextStyle(
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
                              child: Text(
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.location_on, color: Colors.black87),
            onSelected: (String value) {
              setState(() {
                _selectedLocation = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return _keralaCities.map((String city) {
                return PopupMenuItem<String>(
                  value: city,
                  child: Row(
                    children: [
                      if (_selectedLocation == city)
                        const Icon(Icons.check, color: Colors.blue, size: 16),
                      if (_selectedLocation == city) const SizedBox(width: 8),
                      Text(city == 'all' ? 'All Kerala' : city),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_showAppBarSearch)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildSearchField(),
            ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _listingType = 'sale'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              _listingType == 'sale'
                                  ? Palette.primaryblue
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
                                    ? Colors.white
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _listingType = 'auction'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              _listingType == 'auction'
                                  ? Palette.primaryblue
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
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
                                    ? Colors.white
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
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
                            onPressed: _fetchProducts,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (var product in filteredProducts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildProductCard(product),
                          ),
                        if (filteredProducts.isEmpty)
                          Center(
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
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isAuction = product.ifAuction == '1';
    final isFinanceAvailable = product.ifFinance == '1';
    final isExchangeAvailable = product.ifExchange == '1';

    return GestureDetector(
  onTap: () {
      if (isAuction) {
        // Navigate to auction details page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuctionProductDetailsPage(product: product),
          ),
        );
      } else {
        // Navigate to regular product details page
      Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProductDetailsPage(
        product: product,
        isAuction: product.ifAuction == "1",
      ),
    ),
  );;
      }
    },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.30),
              blurRadius: 4,
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
                Container(
                  width: 140,
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(0),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),

                    child: Image.network(
                      'https://lelamonline.com/admin/${product.image}',
                      fit: BoxFit.cover,
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
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.modelVariation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAuction
                                  ? '₹${_formatNumber(double.tryParse(product.auctionStartingPrice) ?? 0)} - ₹${_formatPriceWithLakh(double.tryParse(product.price) ?? 0)}'
                                  : '₹ ${_formatPriceWithLakh(double.tryParse(product.price) ?? 0)}',
                              style: TextStyle(
                                fontSize: 18,
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
                              product.landMark,
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
                                size: 10,
                                color: Colors.grey[700],
                              ),
                              '${product.filters['year']}',
                            ),
                            const SizedBox(width: 4),
                            _buildDetailChip(
                              Icon(
                                Icons.person,
                                size: 10,
                                color: Colors.grey[700],
                              ),
                              _getOwnerText(product.filters['owners'] ?? '1'),
                            ),
                            const SizedBox(width: 4),
                            _buildDetailChip(
                              Icon(
                                Icons.speed,
                                size: 10,
                                color: Colors.grey[700],
                              ),
                              '${_formatNumber(int.tryParse(product.filters['km']?.toString() ?? '0') ?? 0)} KM',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildDetailChip(
                              Icon(
                                Icons.local_gas_station,
                                size: 10,
                                color: Colors.grey[700],
                              ),
                              '${product.filters['fuel']}',
                            ),
                            const SizedBox(width: 4),
                            _buildDetailChip(
                              Icon(
                                Icons.settings,
                                size: 10,
                                color: Colors.grey[700],
                              ),
                              '${product.filters['transmission']}',
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                  color:
                      isAuction
                          ? Palette.primarylightblue
                          : Colors.green.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child:
                    isAuction
                        ? _buildAuctionInfo(product)
                        : _buildFinanceExchangeInfo(
                          isFinanceAvailable,
                          isExchangeAvailable,
                        ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionInfo(Product product) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.gavel, size: 16, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              'Attempts: ${product.auctionAttempt}/3',
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
          child: Text(
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

  Widget _buildFinanceExchangeInfo(
    bool isFinanceAvailable,
    bool isExchangeAvailable,
  ) {
    if (!isFinanceAvailable && !isExchangeAvailable) {
      return const SizedBox.shrink();
    }

    if (isFinanceAvailable && isExchangeAvailable) {
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Palette.primarylightblue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Finance Available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Palette.primarylightblue,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Palette.primarylightblue),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Exchange Available',
                    style: TextStyle(
                      fontSize: 12,
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Palette.primarylightblue),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance, size: 16, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              'Finance Available',
              style: TextStyle(
                fontSize: 13,
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 16, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              'Exchange Available',
              style: TextStyle(
                fontSize: 13,
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

  Widget _buildDetailChip(Widget icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String _getOwnerText(String owners) {
    switch (owners) {
      case '1':
        return '1st Owner';
      case '2':
        return '2nd Owner';
      case '3':
        return '3rd Owner';
      default:
        return '${owners}th Owner';
    }
  }

  String _formatPriceWithLakh(double price) {
    if (price >= 10000000) {
      double crore = price / 10000000;
      return '${crore.toStringAsFixed(crore == crore.roundToDouble() ? 0 : 2)} Crore';
    } else if (price >= 100000) {
      double lakh = price / 100000;
      return '${lakh.toStringAsFixed(lakh == lakh.roundToDouble() ? 0 : 2)} Lakh';
    } else if (price >= 1000) {
      double thousand = price / 1000;
      return '${thousand.toStringAsFixed(thousand == thousand.roundToDouble() ? 0 : 1)}K';
    } else {
      return price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2);
    }
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
