import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/feature/categories/models/details_model.dart';
import 'package:lelamonline_flutter/feature/categories/services/attribute_valuePair_service.dart';
import 'package:lelamonline_flutter/feature/categories/services/auction_cars_service.dart';
import 'package:lelamonline_flutter/feature/categories/services/details_service.dart';
import 'package:lelamonline_flutter/feature/categories/seller%20info/seller_info_page.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/feature/home/view/services/location_service.dart';
import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:lelamonline_flutter/utils/palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuctionProductDetailsPage extends StatefulWidget {
  final dynamic product;

  const AuctionProductDetailsPage({super.key, required this.product});

  @override
  State<AuctionProductDetailsPage> createState() =>
      _AuctionProductDetailsPageState();
}

class _AuctionProductDetailsPageState extends State<AuctionProductDetailsPage> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  final TransformationController _transformationController =
      TransformationController();
  bool _isFavorited = false;
  bool _isLoading = true;
  bool _isLoadingLocations = true;
  bool isLoadingSeller = true;
  String sellerErrorMessage = '';
  List<LocationData> _locations = [];
  final LocationService _locationService = LocationService();
  final AuctionService _auctionService = AuctionService();
  List<Attribute> attributes = [];
  List<AttributeVariation> attributeVariations = [];
  Map<String, String> attributeValues = {};
  List<MapEntry<String, String>> orderedAttributeValues = [];
  List<Map<String, dynamic>> _bidHistory = [];
  int _currentBid = 0;
  double _minBidIncrement = 0.0; // Will be set to auction_price_intervel
  String sellerName = 'Unknown';
  String? sellerProfileImage;
  int sellerNoOfPosts = 0;
  String sellerActiveFrom = 'N/A';
  String? userId;

  String get id => _getProperty('id') ?? '';
  String get title => _getProperty('title') ?? '';
  String get image => _getProperty('image') ?? '';
  String get targetPrice => _getProperty('price') ?? '0';
  String get auctionStartingPrice =>
      _getProperty('auctionStartingPrice') ?? '0';
  String get auctionPriceIntervel =>
      _getProperty('auctionPriceIntervel') ?? '0';
  String get landMark => _getProperty('landMark') ?? '';
  String get createdOn => _getProperty('createdOn') ?? '';
  String get createdBy => _getProperty('createdBy') ?? '';
  String get auctionEndin => _getProperty('auctionEndin') ?? '';
  String get modelVariation => _getProperty('modelVariation') ?? '';

dynamic _getProperty(String propertyName) {
  if (widget.product == null) return null;
  switch (propertyName) {
    case 'id':
      return widget.product.id;
    case 'title':
      return widget.product.title;
    case 'image':
      return widget.product.image;
    case 'price':
      return widget.product.price;
    case 'auctionStartingPrice':
      return widget.product.auctionStartingPrice;
    case 'auctionPriceIntervel':
      return widget.product.auctionPriceIntervel;
    case 'landMark':
      return _getLocationName(widget.product.parentZoneId);
    case 'createdOn':
      return widget.product.createdOn;
    case 'createdBy':
      return widget.product.createdBy;
    case 'auctionEndin':
      return widget.product.auctionEndin;
    case 'modelVariation':
      return widget.product.modelVariation;
    default:
      return null;
  }
}
  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchData();
    _fetchSellerInfo();
  }
Future<void> _loadUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? 'Unknown';
    });
    // Print userId in debug console
    debugPrint('AuctionProductDetailsPage - Loaded userId: $userId');
  }
 Future<void> _fetchData() async {
  setState(() {
    _isLoading = true;
    _isLoadingLocations = true;
  });

  try {
    // Fetch locations
    final locationResponse = await _locationService.fetchLocations();
    if (locationResponse != null && locationResponse.status) {
      _locations = locationResponse.data;
    } else {
      throw Exception('Failed to load locations');
    }

    // Fetch attributes and variations
    attributes = await ApiService.fetchAttributes();
    attributeVariations = await ApiService.fetchAttributeVariations(
      widget.product.filters,
    );
    final attributeValuePairs =
        await AttributeValueService.fetchAttributeValuePairs();
    _mapFiltersToValues(attributeValuePairs);

    // Fetch auction-specific data
    _bidHistory = await _auctionService.fetchBidHistory(id);
    _minBidIncrement = double.tryParse(auctionPriceIntervel) ?? 2500.0; // Use auction_price_intervel
    _currentBid =
        _bidHistory.isNotEmpty
            ? int.tryParse(
                  _bidHistory[0]['amount']
                          ?.replaceAll('₹', '')
                          .replaceAll(',', '') ??
                      '0',
                ) ??
                0
            : int.tryParse(auctionStartingPrice) ?? 0;

    setState(() {
      _isLoading = false;
      _isLoadingLocations = false;
    });
  } catch (e) {
    print('Error fetching auction data: $e');
    setState(() {
      _isLoading = false;
      _isLoadingLocations = false;
    });
  }
}
  Future<void> _fetchSellerInfo() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://lelamonline.com/admin/api/v1/post-seller-information.php?token=5cb2c9b569416b5db1604e0e12478ded&user_id=$createdBy',
        ),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'true' &&
            jsonResponse['data'] is List &&
            jsonResponse['data'].isNotEmpty) {
          final data = jsonResponse['data'][0];
          setState(() {
            sellerName = data['name'] ?? 'Unknown';
            sellerProfileImage = data['profile_image'];
            sellerNoOfPosts = data['no_post'] ?? 0;
            sellerActiveFrom = data['active_from'] ?? 'N/A';
            isLoadingSeller = false;
          });
        } else {
          setState(() {
            sellerErrorMessage = 'Invalid seller data';
            isLoadingSeller = false;
          });
        }
      } else {
        setState(() {
          sellerErrorMessage = 'Failed to load seller information';
          isLoadingSeller = false;
        });
      }
    } catch (e) {
      setState(() {
        sellerErrorMessage = 'Error: $e';
        isLoadingSeller = false;
      });
    }
  }

  void _mapFiltersToValues(List<AttributeValuePair> attributeValuePairs) {
    final filters = widget.product.filters as Map<String, dynamic>;
    attributeValues.clear();
    orderedAttributeValues.clear();

    final Set<String> processedAttributes = {};

    for (var pair in attributeValuePairs) {
      if (pair.attributeName.isNotEmpty &&
          pair.attributeValue.isNotEmpty &&
          !processedAttributes.contains(pair.attributeName)) {
        attributeValues[pair.attributeName] = pair.attributeValue;
        orderedAttributeValues.add(
          MapEntry(pair.attributeName, pair.attributeValue),
        );
        processedAttributes.add(pair.attributeName);
      }
    }

    if (filters.containsKey('3')) {
      String variationId;
      if (filters['3'] is String) {
        variationId = filters['3'] as String;
      } else if (filters['3'] is List<dynamic> &&
          (filters['3'] as List).isNotEmpty) {
        variationId = (filters['3'] as List)[0].toString();
      } else {
        variationId = '';
      }
      if (variationId.isNotEmpty) {
        attributeValues['KM Range'] = variationId;
        final kmIndex = orderedAttributeValues.indexWhere(
          (entry) => entry.key == 'KM Range',
        );
        if (kmIndex != -1) {
          orderedAttributeValues[kmIndex] = MapEntry('KM Range', variationId);
        } else {
          orderedAttributeValues.add(MapEntry('KM Range', variationId));
        }
        processedAttributes.add('KM Range');
      }
    }

    filters.forEach((attributeId, variation) {
      if (attributeId != '3') {
        String variationId;
        if (variation is String) {
          variationId = variation;
        } else if (variation is List<dynamic> && variation.isNotEmpty) {
          variationId = variation[0].toString();
        } else {
          return;
        }

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
          if (!processedAttributes.contains(attribute.name)) {
            final variationObj = attributeVariations.firstWhere(
              (varAttr) =>
                  varAttr.id == variationId &&
                  varAttr.attributeId == attributeId,
              orElse:
                  () => AttributeVariation(
                    id: variationId,
                    attributeId: attributeId,
                    name: '',
                    status: '',
                    createdOn: '',
                    updatedOn: '',
                  ),
            );
            if (variationObj.name.isNotEmpty &&
                variationObj.name != variationId) {
              attributeValues[attribute.name] = variationObj.name;
              orderedAttributeValues.add(
                MapEntry(attribute.name, variationObj.name),
              );
              processedAttributes.add(attribute.name);
            }
          }
        }
      }
    });
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

  String _formatPrice(double price) {
    final formatter = NumberFormat.decimalPattern('en_IN');
    return formatter.format(price.round());
  }

  String _getOwnerText(String owners) {
    switch (owners) {
      case '1':
      case '1st Owner':
        return '1st Owner';
      case '2':
      case '2nd Owner':
        return '2nd Owner';
      case '3':
      case '3rd Owner':
        return '3rd Owner';
      default:
        return owners.isNotEmpty ? owners : 'N/A';
    }
  }

  String _formatNumber(String value) {
    if (value == 'N/A') return 'N/A';
    final number = int.tryParse(value.replaceAll(' KM', '')) ?? 0;
    return '$number KM';
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }
List<String> get _images {
  if (image.isNotEmpty) {
    return ['https://lelamonline.com/admin/$image'];
  }
  return [
    'https://images.pexels.com/photos/170811/pexels-photo-170811.jpeg?cs=srgb&dl=pexels-mikebirdy-170811.jpg&fm=jpg',
  ];
}
void _showFullScreenGallery(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (BuildContext context, _, __) {
        final PageController fullScreenController = PageController(
          initialPage: _currentImageIndex,
        );
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: Stack(
                children: [
                  PageView.builder(
                    controller: fullScreenController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                        _resetZoom();
                      });
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.5,
                        maxScale: 5.0,
                        boundaryMargin: const EdgeInsets.all(double.infinity),
                        child: GestureDetector(
                          onDoubleTap: _resetZoom,
                          child: Hero(
                            tag: 'image_$index',
                            child: CachedNetworkImage(
                              imageUrl: _images[index],
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 50,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  CustomSafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_currentImageIndex + 1}/${_images.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 70,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _images.length,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  fullScreenController.animateToPage(
                                    index,
                                    duration: const Duration(
                                      milliseconds: 300,
                                    ),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  width: 70,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _currentImageIndex == index
                                          ? Colors.blue
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: CachedNetworkImage(
                                      imageUrl: _images[index],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(
                                        Icons.error,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

void _showBidDialog(BuildContext context, {bool isIncrease = false}) {
  final TextEditingController bidAmountController = TextEditingController();
  if (isIncrease) {
    bidAmountController.text = (_currentBid + _minBidIncrement).toInt().toString();
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.gavel,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isIncrease ? 'Increase Your Bid' : 'Place Your Bid',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your bid amount in rupees',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content Section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Current Bid Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[50]!, Colors.grey[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Current Highest Bid',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${NumberFormat('#,##,###').format(_currentBid)}',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isIncrease) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber[300]!, width: 1),
                              ),
                              child: Text(
                                'Min. increment: ₹${NumberFormat('#,##,###').format(_minBidIncrement)}',
                                style: TextStyle(
                                  color: Colors.amber[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Bid Input Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: bidAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            margin: const EdgeInsets.only(left: 20, right: 8),
                            child: Text(
                              '₹',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[600],
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.blue[600]!,
                              width: 3,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!, width: 2),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final String amount = bidAmountController.text;
                          if (amount.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a bid amount'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final int bidAmount = int.tryParse(amount) ?? 0;
                          final double minimumPrice = _currentBid + _minBidIncrement;
                          if (bidAmount <= _currentBid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Bid must be higher than ₹${NumberFormat('#,##0').format(_currentBid)}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (bidAmount < minimumPrice) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Minimum price enter ₹${NumberFormat('#,##0').format(minimumPrice)}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (userId == null || userId == 'Unknown') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please log in to place a bid'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            final success = await _auctionService.placeBid(
                              id,
                              userId!, // Use actual userId from SharedPreferences
                              bidAmount,
                            );
                            if (success) {
                              setState(() {
                                _currentBid = bidAmount;
                                _bidHistory.insert(0, {
                                  'bidder': 'You', // Replace with actual user name if available
                                  'amount': '₹${NumberFormat('#,##').format(bidAmount)}',
                                  'time': 'Just now',
                                });
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bid placed successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to place bid'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error placing bid: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.gavel, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              isIncrease ? 'Increase Bid' : 'Submit Bid',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
  // void _showMeetingDialog(BuildContext context) {
  //   DateTime selectedDate = DateTime.now();
  //   TimeOfDay selectedTime = TimeOfDay.now();

  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(15),
  //         ),
  //         title: Column(
  //           children: [
  //             const SizedBox(height: 8),
  //             const Text('Schedule Meeting', style: TextStyle(fontSize: 24)),
  //             const SizedBox(height: 4),
  //             Text(
  //               'Select date and time',
  //               style: TextStyle(
  //                 fontSize: 14,
  //                 color: Colors.grey[600],
  //                 fontWeight: FontWeight.normal,
  //               ),
  //             ),
  //           ],
  //         ),
  //         content: Container(
  //           constraints: const BoxConstraints(maxWidth: 300),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               ListTile(
  //                 leading: const Icon(Icons.calendar_today, color: Colors.blue),
  //                 title: const Text('Select Date'),
  //                 subtitle: Text(
  //                   '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
  //                   style: const TextStyle(color: Colors.blue),
  //                 ),
  //                 onTap: () async {
  //                   final DateTime? picked = await showDatePicker(
  //                     context: context,
  //                     initialDate: selectedDate,
  //                     firstDate: DateTime.now(),
  //                     lastDate: DateTime.now().add(const Duration(days: 30)),
  //                   );
  //                   if (picked != null && picked != selectedDate) {
  //                     selectedDate = picked;
  //                     Navigator.pop(context);
  //                     _showMeetingDialog(context);
  //                   }
  //                 },
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                   side: BorderSide(color: Colors.grey[300]!),
  //                 ),
  //               ),
  //               const SizedBox(height: 12),
  //               ListTile(
  //                 leading: const Icon(Icons.access_time, color: Colors.blue),
  //                 title: const Text('Select Time'),
  //                 subtitle: Text(
  //                   selectedTime.format(context),
  //                   style: const TextStyle(color: Colors.blue),
  //                 ),
  //                 onTap: () async {
  //                   final TimeOfDay? picked = await showTimePicker(
  //                     context: context,
  //                     initialTime: selectedTime,
  //                   );
  //                   if (picked != null && picked != selectedTime) {
  //                     selectedTime = picked;
  //                     Navigator.pop(context);
  //                     _showMeetingDialog(context);
  //                   }
  //                 },
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                   side: BorderSide(color: Colors.grey[300]!),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             style: TextButton.styleFrom(
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 20,
  //                 vertical: 12,
  //               ),
  //             ),
  //             child: Text(
  //               'Cancel',
  //               style: TextStyle(
  //                 color: Colors.grey[600],
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ),
  //           ElevatedButton(
  //             onPressed: () async {
  //               try {
  //                 final success = await _auctionService.agreeToBidding(
  //                   id,
  //                   '6',
  //                 ); // Replace '6' with actual user_id
  //                 if (success) {
  //                   Navigator.pop(context);
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     const SnackBar(
  //                       content: Text('Meeting scheduled and bidding agreed!'),
  //                       backgroundColor: Colors.green,
  //                     ),
  //                   );
  //                 } else {
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     const SnackBar(
  //                       content: Text('Failed to schedule meeting'),
  //                       backgroundColor: Colors.red,
  //                     ),
  //                   );
  //                 }
  //               } catch (e) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(
  //                     content: Text('Error scheduling meeting: $e'),
  //                     backgroundColor: Colors.red,
  //                   ),
  //                 );
  //               }
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.blue,
  //               foregroundColor: Colors.white,
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 20,
  //                 vertical: 12,
  //               ),
  //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  //             ),
  //             child: const Text(
  //               'Schedule Meeting',
  //               style: TextStyle(fontWeight: FontWeight.bold),
  //             ),
  //           ),
  //         ],
  //         actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  //       );
  //     },
  //   );
  // }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  final auctionEndTime =
      DateTime.tryParse(auctionEndin) ??
      DateTime.now().add(const Duration(days: 2, hours: 5));
  final timeLeft = auctionEndTime.difference(DateTime.now());

  return CustomSafeArea(
    child: Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Gallery
                Stack(
                  children: [
                    SizedBox(
                      height: 400,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: _images.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _showFullScreenGallery(context),
                                child: CachedNetworkImage(
                                  imageUrl: _images[index],
                                  width: double.infinity,
                                  height: 400,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1}/${_images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomSafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              _isFavorited
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorited ? Colors.red : Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _isFavorited = !_isFavorited;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () {
                              // TODO: Implement share functionality
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Current Highest Bid Banner
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: Colors.blue.shade50,
                    child: Center(
                      child: Column(
                        children: [
                          const Text(
                            'CURRENT HIGHEST BID',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${NumberFormat('#,##0').format(_currentBid)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Auction Timer
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.red.shade50,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Auction ends in ${timeLeft.inDays}d ${timeLeft.inHours.remainder(24)}h ${timeLeft.inMinutes.remainder(60)}m',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Product Details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        modelVariation,
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          _isLoadingLocations
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  landMark,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                          const Spacer(),
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ends: ${DateFormat('dd-MM-yyyy hh:mm a').format(auctionEndTime)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Starting Price',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '₹${_formatPrice(double.tryParse(auctionStartingPrice) ?? 0)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Target Price',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '₹${_formatPrice(double.tryParse(targetPrice) ?? 0)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#AD ID $id',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement call functionality
                            },
                            icon: const Icon(Icons.call),
                            label: const Text('Call Support'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Details Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailItem(
                                    Icons.calendar_today,
                                    attributeValues['Year'] ?? 'N/A',
                                  ),
                                ),
                                Expanded(
                                  child: _buildDetailItem(
                                    Icons.person,
                                    _getOwnerText(
                                      attributeValues['No of owners'] ?? 'N/A',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _buildDetailItem(
                                    Icons.speed,
                                    _formatNumber(
                                      attributeValues['KM Range'] ?? 'N/A',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailItem(
                                    Icons.local_gas_station,
                                    attributeValues['Fuel Type'] ?? 'N/A',
                                  ),
                                ),
                                Expanded(
                                  child: _buildDetailItem(
                                    Icons.settings,
                                    attributeValues['Transmission'] ?? 'N/A',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const Divider(),
                // Seller Comments
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seller Comments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Column(
                          children: orderedAttributeValues
                              .where(
                                (entry) =>
                                    entry.value != 'N/A' &&
                                    entry.key != 'Co driver side rear tyre',
                              )
                              .map(
                                (entry) => _buildSellerCommentItem(
                                  entry.key,
                                  entry.key == 'No of owners'
                                      ? _getOwnerText(entry.value)
                                      : entry.value,
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                // Seller Information
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seller Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSellerInformationItem(context),
                    ],
                  ),
                ),
                const Divider(),
                // Bidding History
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bidding History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_bidHistory.isEmpty)
                        const Text(
                          'No bids yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        )
                      else
                        Column(
                          children: _bidHistory
                              .map(
                                (bid) => _buildBidHistoryItem(
                                  bid['bidder'] ?? 'Unknown',
                                  bid['amount'] ?? 'N/A',
                                  bid['time'] ?? 'N/A',
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
                // Bottom padding to prevent content from being hidden under fixed buttons
                const SizedBox(height: 80), // Adjust as needed
              ],
            ),
          ),
          // Fixed buttons at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
               
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 5,
                      spreadRadius: 0,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showBidDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                        ),
                        child: const Text('Enter Price'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showBidDialog(context, isIncrease: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                        ),
                        child: const Text('Increase minimum Bid'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerCommentItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildBidHistoryItem(String bidder, String amount, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(
              bidder.substring(0, 1),
              style: const TextStyle(color: Colors.blue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bidder,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInformationItem(BuildContext context) {
    return isLoadingSeller
        ? const Center(child: CircularProgressIndicator())
        : sellerErrorMessage.isNotEmpty
        ? Center(
          child: Text(
            sellerErrorMessage,
            style: const TextStyle(color: Colors.red),
          ),
        )
        : GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SellerInformationPage(userId: createdBy),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage:
                    sellerProfileImage != null && sellerProfileImage!.isNotEmpty
                        ? CachedNetworkImageProvider(sellerProfileImage!)
                        : const AssetImage('assets/images/avatar.gif')
                            as ImageProvider,
                radius: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sellerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member Since $sellerActiveFrom',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Posts: $sellerNoOfPosts',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        );
  }
}