import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/categories/models/details_model.dart';
import 'package:lelamonline_flutter/feature/categories/seller%20info/seller_info_page.dart';
import 'package:lelamonline_flutter/feature/categories/services/attribute_valuePair_service.dart';
import 'package:lelamonline_flutter/feature/categories/services/details_service.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/feature/home/view/services/location_service.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/my_bids_widget.dart';
import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:lelamonline_flutter/utils/palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarketPlaceProductDetailsPage extends StatefulWidget {
  final dynamic product;
  final bool isAuction;
  final String? userId;

  const MarketPlaceProductDetailsPage({
    super.key,
    required this.product,
    this.isAuction = false,
    this.userId,
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
  String sellerName = 'Unknown';
  String? sellerProfileImage;
  int sellerNoOfPosts = 0;
  String sellerActiveFrom = 'N/A';
  bool isLoadingSeller = true;
  String sellerErrorMessage = '';
  String? userId;
  double _minBidIncrement = 1000;
  final String _baseUrl = 'https://lelamonline.com/admin/api/v1';
  final String _token = '5cb2c9b569416b5db1604e0e12478ded';
  bool _isLoadingBid = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchDetailsData();
    _fetchSellerInfo();
    _checkShortlistStatus();
  }

  Future<void> _loadUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? widget.userId ?? 'Unknown';
    });
    debugPrint('MarketPlaceProductDetailsPage - Loaded userId: $userId');
  }

  Future<void> _checkShortlistStatus() async {
    if (userId == null || userId == 'Unknown') return;

    try {
      final headers = {
        'token': _token,
        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
      };
      final url = '$_baseUrl/list-shortlist.php?token=$_token&user_id=$userId';
      debugPrint('Checking shortlist status: $url');
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('list-shortlist.php response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        if (responseData['status'] == true && responseData['data'] is List) {
          final shortlisted = responseData['data'].any(
            (item) => item['post_id'] == id && item['user_id'] == userId,
          );
          setState(() {
            _isFavorited = shortlisted;
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('shortlist_$userId', responseBody);
          debugPrint('Shortlist status cached for userId: $userId');
        }
      } else {
        debugPrint('Failed to check shortlist: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error checking shortlist status: $e');
      final prefs = await SharedPreferences.getInstance();
      final cachedShortlist = prefs.getString('shortlist_$userId');
      if (cachedShortlist != null) {
        final responseData = jsonDecode(cachedShortlist);
        if (responseData['status'] == true && responseData['data'] is List) {
          final shortlisted = responseData['data'].any(
            (item) => item['post_id'] == id && item['user_id'] == userId,
          );
          setState(() {
            _isFavorited = shortlisted;
          });
        }
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (userId == null || userId == 'Unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add to shortlist'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final headers = {
        'token': _token,
        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
      };
      final url =
          '$_baseUrl/add-to-shortlist.php?token=$_token&user_id=$userId&post_id=$id';
      debugPrint('Adding to shortlist: $url');
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('add-to-shortlist.php response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        if (responseData['status'] == true) {
          setState(() {
            _isFavorited = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to shortlist'),
              backgroundColor: Colors.green,
            ),
          );

          final prefs = await SharedPreferences.getInstance();
          final cachedShortlist = prefs.getString('shortlist_$userId');
          List<dynamic> shortlistData = [];
          if (cachedShortlist != null) {
            final data = jsonDecode(cachedShortlist);
            if (data['status'] == true && data['data'] is List) {
              shortlistData = data['data'];
            }
          }
          shortlistData.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'user_id': userId,
            'post_id': id,
            'created_on': DateFormat(
              'yyyy-MM-dd HH:mm:ss',
            ).format(DateTime.now()),
            'updated_on': DateFormat(
              'yyyy-MM-dd HH:mm:ss',
            ).format(DateTime.now()),
          });
          await prefs.setString(
            'shortlist_$userId',
            jsonEncode({'status': true, 'data': shortlistData, 'code': 0}),
          );
          debugPrint('Shortlist updated in SharedPreferences');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add to shortlist'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.reasonPhrase}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding to shortlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<String> _saveBidData(int bidAmount) async {
    if (userId == null || userId == 'Unknown') {
      throw Exception('Please log in to place a bid');
    }

    try {
      setState(() {
        _isLoadingBid = true;
      });

      final headers = {
        'token': _token,
        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
      };
      final url =
          '$_baseUrl/place-bid.php?token=$_token&post_id=$id&user_id=$userId&bidamt=$bidAmount';
      debugPrint('Placing bid: $url');
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('place-bid.php response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        if (responseData['status'] == true) {
          // Cache the bid locally
          final prefs = await SharedPreferences.getInstance();
          final cachedBids = prefs.getStringList('userBids') ?? [];
          final newBid = {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'user_id': userId,
            'post_id': id,
            'if_auction': widget.isAuction ? '1' : '0',
            'if_auction_end': '0',
            'status': '1',
            'created_on': DateFormat(
              'yyyy-MM-dd HH:mm:ss',
            ).format(DateTime.now()),
            'updated_on': DateFormat(
              'yyyy-MM-dd HH:mm:ss',
            ).format(DateTime.now()),
            'bidPrice': bidAmount.toString(),
            'targetPrice': price,
            'title': title,
            'carImage': image,
            'appId': 'AD_$id',
            'bidDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'expirationDate': DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime.now().add(Duration(days: 7))),
            'location': landMark,
            'store': byDealer == '1' ? 'Dealer' : 'Individual',
            'fromHighBids': bidAmount >= (double.tryParse(price) ?? 0),
            'fromLowBids': bidAmount < (double.tryParse(price) ?? 0),
          };
          cachedBids.add(jsonEncode(newBid));
          await prefs.setStringList('userBids', cachedBids);
          debugPrint('Bid cached: $newBid');

          return responseData['data'] ?? 'Bid placed successfully';
        } else {
          throw Exception('Failed to place bid: ${responseData['data']}');
        }
      } else {
        throw Exception('Failed to place bid: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error placing bid: $e');
      throw e;
    } finally {
      setState(() {
        _isLoadingBid = false;
      });
    }
  }

  void showProductBidDialog(BuildContext context) {
    final TextEditingController _bidController = TextEditingController();
    bool isDialogOpen = true;

    void showResponseDialog(String message, bool isSuccess) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              isSuccess ? 'Thank You' : 'Error',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: Text(message, style: const TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (isDialogOpen) {
                    Navigator.of(context).pop();
                    isDialogOpen = false;
                    _bidController.dispose();
                  }
                  if (isSuccess) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MyBidsWidget(
                              baseUrl: _baseUrl,
                              token: _token,
                              userId: userId,
                            ),
                      ),
                    );
                  }
                },
                child: const Text('OK', style: TextStyle(color: Colors.grey)),
              ),
              if (isSuccess)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (isDialogOpen) {
                      Navigator.of(context).pop();
                      isDialogOpen = false;
                      _bidController.dispose();
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MyBidsWidget(
                              baseUrl: _baseUrl,
                              token: _token,
                              userId: userId,
                            ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Call Support'),
                ),
            ],
          );
        },
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Place Your Bid Amount',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bid Amount *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bidController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Enter amount',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              if (_isLoadingBid)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                isDialogOpen = false;
                _bidController.dispose();
              },
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed:
                  _isLoadingBid
                      ? null
                      : () async {
                        final String amount = _bidController.text;
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
                        if (bidAmount < _minBidIncrement) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Minimum bid amount is ₹${NumberFormat('#,##0').format(_minBidIncrement)}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (userId == null || userId == 'Unknown') {
                          showResponseDialog(
                            'Please log in to place a bid',
                            false,
                          );
                          return;
                        }

                        try {
                          final String responseMessage = await _saveBidData(
                            bidAmount,
                          );
                          showResponseDialog(responseMessage, true);
                        } catch (e) {
                          showResponseDialog('Error placing bid: $e', false);
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    ).then((_) {
      if (isDialogOpen) {
        isDialogOpen = false;
        _bidController.dispose();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _fetchSellerInfo() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/post-seller-information.php?token=$_token&user_id=${widget.product.createdBy}',
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
      debugPrint('Error fetching details: $e');
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

    debugPrint('Attribute Value Pairs: $attributeValuePairs');
    debugPrint(
      'Attribute Variations: ${attributeVariations.map((v) => {'id': v.id, 'attribute_id': v.attributeId, 'name': v.name}).toList()}',
    );
    debugPrint('Filters: $filters');

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
        debugPrint(
          'Added from API: ${pair.attributeName} = ${pair.attributeValue}',
        );
      } else {
        debugPrint(
          'Skipped API pair: ${pair.attributeName} (duplicate or invalid)',
        );
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
        debugPrint('Added KM Range from filters: $variationId');
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
          debugPrint(
            'Skipped filter: attribute_id=$attributeId (empty or invalid)',
          );
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
            debugPrint(
              'Attribute ID: $attributeId, Variation ID: $variationId, Name: ${variationObj.name}',
            );
            if (variationObj.name.isNotEmpty &&
                variationObj.name != variationId) {
              attributeValues[attribute.name] = variationObj.name;
              orderedAttributeValues.add(
                MapEntry(attribute.name, variationObj.name),
              );
              processedAttributes.add(attribute.name);
              debugPrint(
                'Added from variations: ${attribute.name} = ${variationObj.name}',
              );
            } else {
              debugPrint(
                'Skipped variation: ${attribute.name} (invalid name or ID match)',
              );
            }
          }
        }
      }
    });

    debugPrint('Final attributeValues: $attributeValues');
    debugPrint('Final orderedAttributeValues: $orderedAttributeValues');
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
                                fit: BoxFit.fill,
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
                                        fit: BoxFit.fill,
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
                debugPrint(
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
                builder:
                    (context) =>
                        SellerInformationPage(userId: widget.product.createdBy),
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
  final isUserLoggedIn = userId != null && userId != 'Unknown';
  return CustomSafeArea(
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        // Removed bottom padding since buttons are now part of the Column
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'User ID: ${userId ?? 'Unknown'}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
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
                              fit: BoxFit.fitWidth,
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
                        onPressed: _toggleFavorite,
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
                              Expanded(
                                child: _buildDetailItem(
                                  Icons.build,
                                  attributeValues['Engine Condition'] ?? 'N/A',
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
            // Added the buttons as part of the Column
            Container(
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
                      onPressed: () => showProductBidDialog(context),
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
          ],
        ),
      ),
    ),
  );
}
}
