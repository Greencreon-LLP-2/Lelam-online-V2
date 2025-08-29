import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/categories/models/details_model.dart';
import 'package:lelamonline_flutter/feature/categories/services/attribute_valuePair_service.dart';
import 'package:lelamonline_flutter/feature/categories/services/details_service.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/feature/home/view/services/location_service.dart';
import 'package:lelamonline_flutter/utils/palette.dart';

class MarketPlaceProductDetailsPage extends StatefulWidget {
  final dynamic product;
  final bool isAuction;

  const MarketPlaceProductDetailsPage({
    super.key,
    required this.product,
    this.isAuction = false,
  });

  @override
  State<MarketPlaceProductDetailsPage> createState() =>
      _MarketPlaceProductDetailsPageState();
}

class _MarketPlaceProductDetailsPageState
    extends State<MarketPlaceProductDetailsPage> {
  List<Attribute> attributes = [];
  List<AttributeVariation> attributeVariations = [];
  bool isLoadingDetails = false;
  Map<String, String> attributeValues = {};
  List<MapEntry<String, String>> orderedAttributeValues = [];
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  final TransformationController _transformationController =
      TransformationController();
  bool _isFavorited = false;
  bool _isLoadingLocations = true;
  List<LocationData> _locations = [];
  final LocationService _locationService = LocationService();

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
      final locationResponse = await _locationService.fetchLocations();
      if (locationResponse != null && locationResponse.status) {
        _locations = locationResponse.data;
      } else {
        throw Exception('Failed to load locations');
      }

      attributes = await ApiService.fetchAttributes();
      attributeVariations = await ApiService.fetchAttributeVariations(
        widget.product.filters,
      );
      final attributeValuePairs =
          await AttributeValueService.fetchAttributeValuePairs();

      _mapFiltersToValues(attributeValuePairs);

      setState(() {
        isLoadingDetails = false;
        _isLoadingLocations = false;
      });
    } catch (e) {
      print('Error fetching details: $e');
      setState(() {
        isLoadingDetails = false;
        _isLoadingLocations = false;
      });
    }
  }

  void _mapFiltersToValues(List<AttributeValuePair> attributeValuePairs) {
    final filters = widget.product.filters as Map<String, dynamic>;
    attributeValues.clear();
    orderedAttributeValues.clear();

    print('Attribute Value Pairs: $attributeValuePairs');
    print(
      'Attribute Variations: ${attributeVariations.map((v) => {'id': v.id, 'attribute_id': v.attributeId, 'name': v.name}).toList()}',
    );
    print('Filters: $filters');

    final Set<String> processedAttributes = {};

    // Process attribute value pairs from API
    for (var pair in attributeValuePairs) {
      if (pair.attributeName.isNotEmpty &&
          pair.attributeValue.isNotEmpty &&
          !processedAttributes.contains(pair.attributeName)) {
        attributeValues[pair.attributeName] = pair.attributeValue;
        orderedAttributeValues.add(
          MapEntry(pair.attributeName, pair.attributeValue),
        );
        processedAttributes.add(pair.attributeName);
        print('Added from API: ${pair.attributeName} = ${pair.attributeValue}');
      } else {
        print('Skipped API pair: ${pair.attributeName} (duplicate or invalid)');
      }
    }

    // Process KM Range (ID 3) specially
    if (filters.containsKey('3')) {
      String variationId;
      if (filters['3'] is String) {
        variationId = filters['3'] as String; // Handle string value
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
        print('Added KM Range from filters: $variationId');
      }
    }

    // Process other filters
    filters.forEach((attributeId, variation) {
      if (attributeId != '3') {
        String variationId;
        if (variation is String) {
          variationId = variation; // Handle string value
        } else if (variation is List<dynamic> && variation.isNotEmpty) {
          variationId = variation[0].toString();
        } else {
          print('Skipped filter: attribute_id=$attributeId (empty or invalid)');
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
            print(
              'Attribute ID: $attributeId, Variation ID: $variationId, Name: ${variationObj.name}',
            );
            if (variationObj.name.isNotEmpty &&
                variationObj.name != variationId) {
              attributeValues[attribute.name] = variationObj.name;
              orderedAttributeValues.add(
                MapEntry(attribute.name, variationObj.name),
              );
              processedAttributes.add(attribute.name);
              print(
                'Added from variations: ${attribute.name} = ${variationObj.name}',
              );
            } else {
              print(
                'Skipped variation: ${attribute.name} (invalid name or ID match)',
              );
            }
          }
        }
      }
    });

    print('Final attributeValues: $attributeValues');
    print('Final orderedAttributeValues: $orderedAttributeValues');
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

  String get id => _getProperty('id') ?? '';
  String get title => _getProperty('title') ?? '';
  String get image => _getProperty('image') ?? '';
  String get price => _getProperty('price') ?? '0';
  String get landMark => _getProperty('landMark') ?? '';
  String get createdOn => _getProperty('createdOn') ?? '';
  String get createdBy => _getProperty('createdBy') ?? '';
  String get byDealer => _getProperty('byDealer') ?? '0';

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
      case 'landMark':
        return _getLocationName(widget.product.parentZoneId);
      case 'createdOn':
        return widget.product.createdOn;
      case 'createdBy':
        return widget.product.createdBy;
      case 'byDealer':
        return widget.product.byDealer;
      default:
        return null;
    }
  }

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

  String formatPriceInt(double price) {
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
                        '₹ ${formatPriceInt(double.tryParse(price) ?? 0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
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
                        if (isLoadingDetails)
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
                                        attributeValues['No of owners'] ??
                                            'N/A',
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
                                  Expanded(
                                    child: _buildDetailItem(
                                      Icons.build,
                                      attributeValues['Engine Condition'] ??
                                          'N/A',
                                    ),
                                  ),
                                ],
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
                      if (isLoadingDetails)
                        const Center(child: CircularProgressIndicator())
                      else
                        Column(
                          children:
                              orderedAttributeValues
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
            bottom: -5,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                // No background color
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: Offset(1, 3),
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
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text('Place Bid'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showMeetingDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.primaryblue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        shape: const RoundedRectangleBorder(
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
