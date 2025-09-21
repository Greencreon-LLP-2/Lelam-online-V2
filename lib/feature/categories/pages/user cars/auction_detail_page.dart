import 'dart:convert';
import 'dart:math' as developer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/feature/categories/models/market_place_detail.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/market_used_cars_page.dart';
import 'package:lelamonline_flutter/feature/categories/seller%20info/seller_info_page.dart'
    hide baseUrl, token;
import 'package:lelamonline_flutter/feature/categories/services/auction_cars_service.dart';
import 'package:lelamonline_flutter/feature/categories/models/seller_comment_model.dart';
import 'package:lelamonline_flutter/feature/chat/views/widget/chat_dialog.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:lelamonline_flutter/utils/palette.dart';
import 'package:provider/provider.dart';

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
  String attributesErrorMessage = '';
  List<LocationData> _locations = [];
  List<SellerComment> uniqueSellerComments = [];
  List<SellerComment> detailComments = [];

  bool _isLoadingContainerInfo = false;
  List<ContainerInfo> _containerInfo = [];
  String _containerInfoError = '';

  final AuctionService _auctionService = AuctionService();
  List<Map<String, dynamic>> _bidHistory = [];
  int _currentBid = 0;
  double _minBidIncrement = 0.0;
  String sellerName = 'Unknown';
  String? sellerProfileImage;
  int sellerNoOfPosts = 0;
  String sellerActiveFrom = '';
  String? userId;
  String _currentHighestBid = '0';
  bool isLoadingSellerComments = false;
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
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await _fetchLocations();

    await Future.delayed(Duration(milliseconds: 500));
    await _fetchSellerInfo();

    await Future.delayed(Duration(milliseconds: 200));
    await _fetchData();
    await _fetchContainerInfo();
  }

  Future<void> _loadUserId() async {
    final userProvider = Provider.of<LoggedUserProvider>(
      context,
      listen: false,
    );
    final userData = userProvider.userData;
    setState(() {
      userId = userData?.userId ?? '';
    });
    debugPrint('AuctionProductDetailsPage - Loaded userId: $userId');
  }

  Future<void> _fetchContainerInfo() async {
    setState(() {
      _isLoadingContainerInfo = true;
      _containerInfoError = '';
    });

    try {
      final response = await MarketplaceService2.fetchContainerInfo(id);
      setState(() {
        _containerInfo = response.data;
        _isLoadingContainerInfo = false;
      });
    } catch (e) {
      setState(() {
        _containerInfoError = 'Failed to load details: $e';
        _isLoadingContainerInfo = false;
      });
    }
  }

  Widget _buildContainerInfo() {
    if (_isLoadingContainerInfo) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_containerInfoError.isNotEmpty) {
      return Center(
        child: Text(
          _containerInfoError,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_containerInfo.isEmpty) {
      return const Center(child: Text('Loading.......'));
    }

    return Container(
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (_containerInfo.length > 0)
                          _buildContainerDetailItem(
                            _getIconFromBootstrap(_containerInfo[0].icon),
                            _containerInfo[0].value,
                          ),
                        if (_containerInfo.length > 1)
                          _buildContainerDetailItem(
                            _getIconFromBootstrap(_containerInfo[1].icon),
                            _containerInfo[1].value,
                          ),
                        if (_containerInfo.length > 2)
                          _buildContainerDetailItem(
                            _getIconFromBootstrap(_containerInfo[2].icon),
                            _containerInfo[2].value,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (_containerInfo.length > 3)
                          _buildContainerDetailItem(
                            _getIconFromBootstrap(_containerInfo[3].icon),
                            _containerInfo[3].value,
                          ),
                        if (_containerInfo.length > 4)
                          _buildContainerDetailItem(
                            _getIconFromBootstrap(_containerInfo[4].icon),
                            _containerInfo[4].value,
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerDetailItem(IconData icon, String text) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromBootstrap(String bootstrapIcon) {
    final iconMap = {
      'bi-calendar-minus-fill': Icons.calendar_today,
      'bi-person-fill': Icons.person,
      'bi-speedometer': Icons.speed,
      'bi-fuel-pump-fill': Icons.local_gas_station,
      'bi-gear-fill': Icons.settings,
    };
    return iconMap[bootstrapIcon] ?? Icons.info_outline;
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
          debugPrint(
            'Locations fetched: ${_locations.map((loc) => "${loc.id}: ${loc.name}").toList()}',
          );
        });
      } else {
        throw Exception('Invalid API response format');
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _fetchAttributesData() async {
    setState(() {
      _isLoading = true;
      attributesErrorMessage = '';
    });

    try {
      const token = '5cb2c9b569416b5db1604e0e12478ded';
      final headers = {'token': token};
      final url =
          'https://lelamonline.com/admin/api/v1/post-attribute-values.php?token=$token&post_id=$id';
      debugPrint('Fetching attributes: $url');

      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('Attributes API response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        final sellerComments = SellerCommentsModel.fromJson(responseData);

        final Map<String, SellerComment> uniqueAttributes = {};
        final List<SellerComment> orderedComments = [];

        for (var comment in sellerComments.data) {
          final key = comment.attributeName.toLowerCase().replaceAll(
            RegExp(r'\s+'),
            '',
          );
          if (!uniqueAttributes.containsKey(key)) {
            uniqueAttributes[key] = comment;
            orderedComments.add(comment);
          }
        }

        setState(() {
          uniqueSellerComments = orderedComments;
          detailComments = uniqueSellerComments.where((comment) {
            final name = comment.attributeName.toLowerCase().trim();
            return [
              'year',
              'no of owners',
              'fuel type',
              'transmission',
              'km range',
            ].contains(name);
          }).toList();
          debugPrint(
            'Ordered uniqueSellerComments: ${uniqueSellerComments.map((c) => "${c.attributeName}: ${c.attributeValue}").toList()}',
          );
          debugPrint(
            'Filtered detailComments: ${detailComments.map((c) => "${c.attributeName}: ${c.attributeValue}").toList()}',
          );
        });
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching attributes: $e');
      setState(() {
        attributesErrorMessage = 'Failed to load attributes: $e';
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _isLoadingLocations = true;
    });

    try {
      await Future.wait([
        _fetchLocations(),
        _fetchAttributesData(),
        _auctionService.fetchBidHistory(id).then((value) {
          _bidHistory = value;
        }),
        _auctionService.fetchMinBidIncrement(id).then((value) {
          _minBidIncrement = value.toDouble();
        }),
      ]);

      setState(() {
        if (_bidHistory.isNotEmpty) {
          _currentHighestBid =
              _bidHistory[0]['amount']
                  ?.replaceAll('₹', '')
                  .replaceAll(',', '') ??
              '0';
          _currentBid = int.tryParse(_currentHighestBid) ?? 0;
        } else {
          _currentHighestBid = auctionStartingPrice;
          _currentBid = int.tryParse(auctionStartingPrice) ?? 0;
        }
        _isLoading = false;
        _isLoadingLocations = false;
      });
    } catch (e) {
      debugPrint('Error fetching auction data: $e');
      setState(() {
        _isLoading = false;
        _isLoadingLocations = false;
        _currentHighestBid = 'Error: Failed to fetch bid data';
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
            sellerName = data['user_name'] ?? 'Unknown';
            sellerProfileImage = data['profile_image'];
            sellerNoOfPosts = data['no_post'] ?? 0;
            sellerActiveFrom = data['active_from'] ?? '';
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
        return owners.isNotEmpty ? owners : '';
    }
  }

  String _formatNumber(String value) {
    if (value == '') return '';
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

  void _showBidDialog(BuildContext context, {bool isIncrease = false}) {
    final TextEditingController bidAmountController = TextEditingController();
    if (isIncrease) {
      bidAmountController.text =
          (_currentBid + _minBidIncrement).toInt().toString();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isIncrease ? 'Increase Your Bid' : 'Place Your Bid'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your bid amount in rupees'),
              const SizedBox(height: 16),
              if (isIncrease) ...[
                const SizedBox(height: 8),
                Text(
                  'Min. increment: ₹${NumberFormat('#,##,###').format(_minBidIncrement)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: bidAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  prefixText: '₹',
                  hintText: '0',
                  labelText: 'Enter bid amount',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
                  showDialog(
                    context: context,
                    builder: (context) => ChatOptionsDialog(
                      onChatWithSupport: () {
                        debugPrint("Support contacted");
                      },
                      onChatWithSeller: () {
                        debugPrint("Chat with seller started");
                      },
                      baseUrl: baseUrl,
                      token: token,
                    ),
                  );
                  return;
                }

                try {
                  final success = await _auctionService.placeBid(
                    id,
                    userId!,
                    bidAmount,
                  );
                  if (success) {
                    setState(() {
                      _currentBid = bidAmount;
                      _currentHighestBid = bidAmount.toString();
                      _bidHistory.insert(0, {
                        'bidder': 'You',
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
              child: Text(isIncrease ? 'Increase Bid' : 'Submit Bid'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _moveToMarketplace(BuildContext context) async {
    const String token = '5cb2c9b569416b5db1604e0e12478ded';
    final String url = '$baseUrl/auction-back-to-marketplace.php?token=$token&post_id=$id';

    try {
      final response = await http.get(Uri.parse(url));
      debugPrint('Move to Marketplace API response: ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'true' && jsonResponse['data'] is List && jsonResponse['data'].isNotEmpty) {
          final message = jsonResponse['data'][0]['message'] ?? 'Product moved to Market place!';
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          throw Exception('Invalid API response');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error moving to marketplace: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to move to marketplace: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _agreeBidProceedMeeting(BuildContext context) async {
    const String token = '5cb2c9b569416b5db1604e0e12478ded';
    final String url = '$baseUrl/auction-agree-bidding.php?token=$token&post_id=$id&user_id=$userId';

    try {
      final response = await http.get(Uri.parse(url));
      debugPrint('Agree Bid Proceed Meeting API response: ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'true' && jsonResponse['data'] is List && jsonResponse['data'].isNotEmpty) {
          final message = jsonResponse['data'][0]['message'] ?? 'You Agree Bid and Proceed Meeting also Product moved to Market place';
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          throw Exception('Invalid API response');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error agreeing bid: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to agree bid and proceed meeting: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

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
    final isSeller = userId != null && userId == createdBy;

    return CustomSafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SingleChildScrollView(
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
                              icon: const Icon(
                                Icons.share,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                // TODO: Implement share functionality
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                              _currentHighestBid.startsWith('Error')
                                  ? _currentHighestBid
                                  : '₹${NumberFormat('#,##0').format(int.tryParse(_currentHighestBid) ?? 0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    _currentHighestBid.startsWith('Error')
                                        ? Colors.red
                                        : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
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
                                showDialog(
                                  context: context,
                                  builder: (context) => ChatOptionsDialog(
                                    onChatWithSupport: () {
                                      debugPrint("Support contacted");
                                    },
                                    onChatWithSeller: () {
                                      debugPrint("Chat with seller started");
                                    },
                                    baseUrl: baseUrl,
                                    token: token,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.support_agent),
                              label: const Text('Contact Seller'),
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
                  _buildContainerInfo(),
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
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (attributesErrorMessage.isNotEmpty)
                          Center(
                            child: Text(
                              attributesErrorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        else if (uniqueSellerComments.isEmpty)
                          const Center(
                            child: Text('No seller comments available'),
                          )
                        else
                          Column(
                            children: uniqueSellerComments
                                .where(
                                  (comment) =>
                                      comment.attributeName
                                          .toLowerCase()
                                          .trim() !=
                                      'co driver side rear tyre',
                                )
                                .map(
                                  (comment) => _buildSellerCommentItem(
                                    comment.attributeName,
                                    comment.attributeName
                                                .toLowerCase()
                                                .trim() ==
                                            'no of owners'
                                        ? _getOwnerText(
                                            comment.attributeValue,
                                          )
                                        : comment.attributeValue,
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
                        _buildSellerInformationItem(context),
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
                                    bid['bidder'] ?? 'Guest User',
                                    bid['amount'] ?? 'N/A',
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
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
                        onPressed: isSeller
                            ? () => _moveToMarketplace(context)
                            : () => _showBidDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.primarypink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: Text(isSeller ? 'Back to Market Place' : 'Enter Price'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSeller
                            ? () => _agreeBidProceedMeeting(context)
                            : () => _showBidDialog(context, isIncrease: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.primaryblue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: Text(isSeller ? 'Agree Bid Proceed meeting' : 'Increase minimum Bid',textAlign: TextAlign.center,),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildBidHistoryItem(String bidder, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(
              bidder.isNotEmpty ? bidder.substring(0, 1) : '?',
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