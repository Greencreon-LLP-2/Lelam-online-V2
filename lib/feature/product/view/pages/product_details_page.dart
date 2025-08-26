import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/categories/models/details_model.dart';
import 'package:lelamonline_flutter/feature/categories/services/details_service.dart';
import 'package:lelamonline_flutter/feature/categories/user%20cars/used_cars_categorie.dart';
import 'package:lelamonline_flutter/feature/home/view/models/feature_list_model.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/feature/home/view/services/location_service.dart';
import 'package:lelamonline_flutter/utils/palette.dart';

class ProductDetailsPage extends StatefulWidget {
  final dynamic product; // Can be either Product or FeatureListModel
  final bool isAuction;

  const ProductDetailsPage({
    super.key,
    required this.product,
    this.isAuction = false,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  // Data properties
  Brand? brand;
  BrandModel? brandModel;
  ModelVariation? modelVariationObj;
  List<Attribute> attributes = [];
  List<AttributeVariation> attributeVariations = [];
  bool isLoadingDetails = false;

  // Add this getter to your _ProductDetailsPageState class
  Map<String, dynamic> get filters {
    if (widget.product is Product) {
      return (widget.product as Product).filters;
    } else if (widget.product is FeatureListModel) {
      final featureFilters = (widget.product as FeatureListModel).filters;
      // Convert Map<String, dynamic> to consistent format
      return featureFilters.map((key, value) {
        if (value is List) {
          return MapEntry(key, value.isNotEmpty ? value.first.toString() : '');
        }
        return MapEntry(key, value.toString());
      });
    }
    return {};
  }

  // UI controllers
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  final TransformationController _transformationController =
      TransformationController();
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _fetchDetailsData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetailsData() async {
    setState(() {
      isLoadingDetails = true;
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

      // Fetch brand
      final brands = await ApiService.fetchBrands();
      brand = brands.firstWhere(
        (b) => b.id == widget.product.brand,
        orElse:
            () => Brand(
              id: '',
              slug: '',
              categoryId: '',
              name: 'Unknown Brand',
              image: '',
              status: '',
              createdOn: '',
              updatedOn: '',
            ),
      );

      // Fetch brand model
      final brandModels = await ApiService.fetchBrandModels();
      brandModel = brandModels.firstWhere(
        (m) => m.id == widget.product.model,
        orElse:
            () => BrandModel(
              id: '',
              brandId: '',
              slug: '',
              name: 'Unknown Model',
              image: '',
              status: '',
              createdOn: '',
              updatedOn: '',
            ),
      );

      // Fetch model variation
      final modelVariations = await ApiService.fetchModelVariations();
      modelVariationObj = modelVariations.firstWhere(
        (v) => v.id == widget.product.modelVariation,
        orElse:
            () => ModelVariation(
              id: '',
              slug: '',
              brandId: '',
              brandModelId: '',
              name: 'Unknown Variation',
              image: '',
              status: '',
              createdOn: '',
              updatedOn: '',
            ),
      );

      // Fetch attributes
      attributes = await ApiService.fetchAttributes();

      // Fetch attribute variations
      attributeVariations = await ApiService.fetchAttributeVariations();

      setState(() {
        _isLoadingLocations = false;
      });
    } catch (e) {
      print('Error fetching details: $e');
      setState(() {
        _isLoadingLocations = false;
        isLoadingDetails = false;
      });
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
            name: zoneId, // Fallback to zoneId if not found
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

  // Helper methods to access properties consistently
  String get id => _getProperty('id') ?? '';
  String get title => _getProperty('title') ?? '';
  String get image => _getProperty('image') ?? '';
  String get modelVariation => _getProperty('modelVariation') ?? '';
  String get price => _getProperty('price') ?? '0';
  String get auctionStartingPrice =>
      _getProperty('auctionStartingPrice') ?? '0';
  String get landMark => _getProperty('landMark') ?? '';
  String get createdOn => _getProperty('createdOn') ?? '';
  String get createdBy => _getProperty('createdBy') ?? '';
  String get byDealer => _getProperty('byDealer') ?? '0';
  String get ifAuction => _getProperty('ifAuction') ?? '0';
  String get auctionAttempt => _getProperty('auctionAttempt') ?? '0';
  dynamic _getProperty(String propertyName) {
    if (widget.product == null) return null;

    if (widget.product is FeatureListModel) {
      final product = widget.product as FeatureListModel;
      switch (propertyName) {
        case 'id':
          return product.id;
        case 'title':
          return product.title;
        case 'image':
          return product.image;
        case 'modelVariation':
          return product.modelVariation;
        case 'price':
          return product.price;
        case 'auctionStartingPrice':
          return product.auctionStartingPrice;
        case 'landMark':
          return _getLocationName(product.parentZoneId);
        case 'createdOn':
          return product.createdOn;
        case 'createdBy':
          return product.createdBy;
        case 'byDealer':
          return product.byDealer;
        case 'ifAuction':
          return product.ifAuction;
        case 'auctionAttempt':
          return product.auctionAttempt;
        default:
          return null;
      }
    } else if (widget.product is Product) {
      final product = widget.product as Product;
      switch (propertyName) {
        case 'id':
          return product.id;
        case 'title':
          return product.title;
        case 'image':
          return product.image;
        case 'modelVariation':
          return product.modelVariation;
        case 'price':
          return product.price;
        case 'auctionStartingPrice':
          return product.auctionStartingPrice;
        case 'landMark':
          return _getLocationName(product.parentZoneId);
        case 'createdOn':
          return product.createdOn;
        case 'createdBy':
          return product.createdBy;
        case 'byDealer':
          return product.byDealer;
        case 'ifAuction':
          return product.ifAuction;
        case 'auctionAttempt':
          return product.auctionAttempt;
        default:
          return null;
      }
    }
    return null;
  }

  final LocationService _locationService = LocationService();
  List<LocationData> _locations = [];
  bool _isLoadingLocations = true;

  List<String> get _images {
    if (image.isNotEmpty) {
      return ['https://lelamonline.com/admin/$image'];
    }
    return [
      'https://images.pexels.com/photos/170811/pexels-photo-170811.jpeg?cs=srgb&dl=pexels-mikebirdy-170811.jpg&fm=jpg',
    ];
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
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
                          onInteractionStart: (ScaleStartDetails details) {},
                          onInteractionUpdate: (ScaleUpdateDetails details) {},
                          onInteractionEnd: (ScaleEndDetails details) {
                            if (details.velocity.pixelsPerSecond.distance > 0) {
                              final double scale =
                                  _transformationController.value
                                      .getMaxScaleOnAxis();
                              if (scale < 0.5) {
                                _resetZoom();
                              } else if (scale > 5.0) {
                                _transformationController.value =
                                    Matrix4.identity()..scale(5.0);
                              }
                            }
                          },
                          child: GestureDetector(
                            onDoubleTap: _resetZoom,
                            child: Hero(
                              tag: 'image_$index',
                              child: CachedNetworkImage(
                                imageUrl: _images[index],
                                fit: BoxFit.contain,
                                placeholder:
                                    (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
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
                    SafeArea(
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
                                    onPressed:
                                        () => Navigator.of(context).pop(),
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
                                        color:
                                            _currentImageIndex == index
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
                                        placeholder:
                                            (context, url) => const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                        errorWidget:
                                            (context, url, error) => const Icon(
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

  void _showMeetingDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Column(
            children: [
              const SizedBox(height: 8),
              const Text('Schedule Meeting', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                'Select date',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.calendar_today,
                    color: AppTheme.primaryColor,
                  ),
                  title: const Text('Select Date'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: const TextStyle(color: AppTheme.primaryColor),
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null && picked != selectedDate) {
                      selectedDate = picked;
                      Navigator.pop(context);
                      _showMeetingDialog(context);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                print(
                  'Meeting scheduled for ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text(
                'Schedule Meeting',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    );
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

  String _getAttributeName(String id) {
    return attributes
        .firstWhere(
          (attr) => attr.id == id,
          orElse:
              () => Attribute(
                id: '',
                slug: '',
                name: 'Unknown Attribute',
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
        )
        .name;
  }

  String _getAttributeVariationName(String id) {
    return attributeVariations
        .firstWhere(
          (variation) => variation.id == id,
          orElse:
              () => AttributeVariation(
                id: '',
                attributeId: '',
                name: 'Unknown Variation',
                status: '',
                createdOn: '',
                updatedOn: '',
              ),
        )
        .name;
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

  String _formatNumber(num number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(2)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(number == number.roundToDouble() ? 0 : 2);
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
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

  Widget _buildSellerInformationItem(
    String name,
    String memberSince,
    BuildContext context,
  ) {
    return Row(
      children: [
        const CircleAvatar(
          backgroundImage: AssetImage('assets/images/avatar.gif'),
          radius: 30,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                memberSince,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  // Navigate to seller profile
                },
                child: const Text(
                  'SEE PROFILE',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ],
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'You are the first one to ask question',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Ask a question functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('Ask a question'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                  placeholder:
                                      (context, url) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                  errorWidget:
                                      (context, url, error) =>
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
                    SafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
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
                              // Share functionality
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                            createdOn,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '₹ ${_formatPriceWithLakh(double.tryParse(price) ?? 0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      // const SizedBox(height: 16),
                      // if (isLoadingDetails)
                      //   const Center(child: CircularProgressIndicator())
                      // else
                      //   Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       if (brand != null)
                      //         _buildDetailRow('Brand', brand!.name),
                      //       if (brandModel != null)
                      //         _buildDetailRow('Model', brandModel!.name),
                      //       if (modelVariationObj != null)
                      //         _buildDetailRow(
                      //           'Variant',
                      //           modelVariationObj!.name,
                      //         ),
                      //       const SizedBox(height: 8),
                      //       const Text(
                      //         'Specifications',
                      //         style: TextStyle(
                      //           fontSize: 18,
                      //           fontWeight: FontWeight.bold,
                      //         ),
                      //       ),
                      //       const SizedBox(height: 8),
                      //       if (widget.product.attributeId.isNotEmpty)
                      //         ...widget.product.attributeId.asMap().entries.map(
                      //           (entry) {
                      //             final index = entry.key;
                      //             final attributeId = entry.value;
                      //             final variationId =
                      //                 index <
                      //                         widget
                      //                             .product
                      //                             .attributeVariationsId
                      //                             .length
                      //                     ? widget
                      //                         .product
                      //                         .attributeVariationsId[index]
                      //                     : '';

                      //             return _buildDetailRow(
                      //               _getAttributeName(attributeId),
                      //               _getAttributeVariationName(variationId),
                      //             );
                      //           },
                      //         ).toList(),
                      //     ],
                      //   ),
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
                              // Call functionality
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.30),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  child: Padding(
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailItem(
                                Icons.calendar_today,
                                filters['year'] ?? 'N/A',
                              ),
                            ),
                            Expanded(
                              child: _buildDetailItem(
                                Icons.person,
                                _getOwnerText(filters['owners'] ?? '1'),
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
                                filters['fuel'] ?? 'N/A',
                              ),
                            ),
                            Expanded(
                              child: _buildDetailItem(
                                Icons.settings,
                                filters['transmission'] ?? 'N/A',
                              ),
                            ),
                            Expanded(
                              child: _buildDetailItem(
                                Icons.speed,
                                '${_formatNumber(int.tryParse(filters['km']?.toString() ?? '0') ?? 0)} KM',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
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
                      _buildSellerCommentItem('Year', filters['year'] ?? 'N/A'),
                      _buildSellerCommentItem(
                        'No Of Owners',
                        _getOwnerText(filters['owners'] ?? '1'),
                      ),
                      _buildSellerCommentItem(
                        'Fuel Type',
                        filters['fuel'] ?? 'N/A',
                      ),
                      _buildSellerCommentItem(
                        'Transmission',
                        filters['transmission'] ?? 'N/A',
                      ),
                      _buildSellerCommentItem(
                        'Service History',
                        'In Showroom Only',
                      ),
                      _buildSellerCommentItem(
                        'Sold By',
                        byDealer == '1' ? 'Dealer' : 'Owner',
                      ),
                    ],
                  ),
                ),
                const Divider(),
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
                      _buildSellerInformationItem(
                        createdBy,
                        'Member Since $createdOn',
                        context,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Questions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildQuestionsSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Contact seller functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.primarypink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text('Contact Seller'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showMeetingDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.primaryblue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text('Fix Meeting'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
