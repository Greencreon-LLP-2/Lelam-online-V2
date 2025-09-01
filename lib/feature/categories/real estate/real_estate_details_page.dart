import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/categories/models/details_model.dart';
import 'package:lelamonline_flutter/feature/categories/real%20estate/real_estate_categories.dart';
import 'package:lelamonline_flutter/feature/categories/services/attribute_valuePair_service.dart';
import 'package:lelamonline_flutter/feature/categories/services/details_service.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/feature/home/view/services/location_service.dart';
import 'package:lelamonline_flutter/utils/palette.dart';

class RealEstateProductDetailsPage extends StatefulWidget {
  final MarketplacePost product;
  final bool isAuction;

  const RealEstateProductDetailsPage({
    super.key,
    required this.product,
    this.isAuction = false,
  });

  @override
  State<RealEstateProductDetailsPage> createState() =>
      _RealEstateProductDetailsPageState();
}

class _RealEstateProductDetailsPageState
    extends State<RealEstateProductDetailsPage> {
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
    final filters = widget.product.filters;
    attributeValues.clear();
    orderedAttributeValues.clear();

    print('Attribute Value Pairs: $attributeValuePairs');
    print('Attribute Variations: $attributeVariations');
    print('Filters: $filters');

    final Set<String> processedAttributes = {};

    // Map seller type from byDealer field
    attributeValues['Seller Type'] =
        widget.product.byDealer == '1' ? 'Dealer' : 'Owner';
    orderedAttributeValues.add(
      MapEntry('Seller Type', attributeValues['Seller Type']!),
    );
    processedAttributes.add('Seller Type');

    // Map filters to attribute names and values
    for (var attribute in attributes) {
      final attributeId = attribute.id;
      if (filters.containsKey(attributeId) &&
          filters[attributeId]!.isNotEmpty &&
          filters[attributeId]!.first.isNotEmpty) {
        final filterValue = filters[attributeId]!.first;
        // Check if the filter value is an ID that needs mapping
        final variation = attributeVariations.firstWhere(
          (variation) => variation.id == filterValue,
          orElse:
              () => AttributeVariation(
                id: '',
                name: filterValue,
                attributeId: '',
                status: '',
                createdOn: '',
                updatedOn: '',
              ), // Fallback to filter value if no mapping
        );
        final value = variation.name.isNotEmpty ? variation.name : filterValue;
        attributeValues[attribute.name] = value;
        orderedAttributeValues.add(MapEntry(attribute.name, value));
        processedAttributes.add(attribute.name);
        print('Added from filters: ${attribute.name} = $value');
      }
    }

    // Add auction-specific attributes if isAuction is true
    if (widget.isAuction) {
      attributeValues['Auction Starting Price'] = formatPriceInt(
        double.tryParse(widget.product.auctionStartingPrice) ?? 0,
      );
      attributeValues['Auction Attempts'] = widget.product.auctionAttempt;
      orderedAttributeValues.add(
        MapEntry(
          'Auction Starting Price',
          attributeValues['Auction Starting Price']!,
        ),
      );
      orderedAttributeValues.add(
        MapEntry('Auction Attempts', attributeValues['Auction Attempts']!),
      );
      processedAttributes.add('Auction Starting Price');
      processedAttributes.add('Auction Attempts');
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

  String get id => widget.product.id;
  String get title => widget.product.title;
  String get image => widget.product.image;
  String get price => widget.product.price;
  String get landMark => _getLocationName(widget.product.parentZoneId);
  String get createdOn => widget.product.createdOn;
  String get createdBy => widget.product.createdBy;
  String get byDealer => widget.product.byDealer;
  bool get isFinanceAvailable => widget.product.ifFinance == '1';
  bool get isFeatured => widget.product.feature == '1';

  List<String> get _images {
    if (image.isNotEmpty) {
      return ['https://lelamonline.com/admin/$image'];
    }
    return [
      'https://images.pexels.com/photos/106399/pexels-photo-106399.jpeg?cs=srgb&dl=pexels-binyamin-mellish-106399.jpg&fm=jpg',
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

  String _stripHtmlTags(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '').trim();
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
                          if (isFeatured)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
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
                        widget.isAuction
                            ? 'Starting Bid: ₹${formatPriceInt(double.tryParse(widget.product.auctionStartingPrice) ?? 0)}'
                            : '₹${formatPriceInt(double.tryParse(price) ?? 0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      if (widget.isAuction) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Max Bid: ₹${formatPriceInt(double.tryParse(price) ?? 0)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
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
                      if (isFinanceAvailable)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_balance,
                                size: 16,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Finance Available',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
                              _buildDetailItem(
                                Icons.person,
                                attributeValues['Seller Type'] ?? 'N/A',
                              ),
                              if (widget.isAuction) ...[
                                const SizedBox(height: 12),
                                _buildDetailItem(
                                  Icons.gavel,
                                  'Attempts: ${attributeValues['Auction Attempts'] ?? '0'}/3',
                                ),
                              ],
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
                                        entry.key != 'Seller Type' &&
                                        entry.key != 'Auction Starting Price' &&
                                        entry.key != 'Auction Attempts',
                                  )
                                  .map(
                                    (entry) => _buildSellerCommentItem(
                                      entry.key,
                                      entry.value,
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
                        'Description',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _stripHtmlTags(widget.product.description),
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
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
                        // Contact seller or place bid functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.primarypink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        widget.isAuction ? 'Place Bid' : 'Contact Seller',
                      ),
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
