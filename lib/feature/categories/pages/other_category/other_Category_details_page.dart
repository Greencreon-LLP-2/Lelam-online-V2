import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/feature/Support/views/support_page.dart';
import 'package:lelamonline_flutter/feature/categories/pages/other_category/other_categoty.dart';
import 'package:lelamonline_flutter/feature/categories/seller%20info/seller_info_page.dart';
import 'package:lelamonline_flutter/feature/categories/widgets/bid_dialog.dart';
import 'package:lelamonline_flutter/feature/chat/views/chat_page.dart'
    show ChatPage;
import 'package:lelamonline_flutter/feature/chat/views/widget/chat_dialog.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/buying_status_page.dart';
import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:lelamonline_flutter/utils/palette.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';

import 'package:lelamonline_flutter/utils/review_dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BikeDetailsPage extends StatefulWidget {
  final Bike bike;

  const BikeDetailsPage({super.key, required this.bike});

  @override
  State<BikeDetailsPage> createState() => _BikeDetailsPageState();
}

class _BikeDetailsPageState extends State<BikeDetailsPage> {
  bool _isLoadingLocations = true;
  List<LocationData> _locations = [];

  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  final TransformationController _transformationController =
      TransformationController();
  bool _isFavorited = false;
  final String _baseUrl = 'https://lelamonline.com/admin/api/v1';
  final String _token = '5cb2c9b569416b5db1604e0e12478ded';

  String sellerName = 'Unknown';
  String? sellerProfileImage;
  int sellerNoOfPosts = 0;
  String sellerActiveFrom = 'N/A';
  bool isLoadingSeller = true;
  String sellerErrorMessage = '';
   late final LoggedUserProvider _userProvider;

   String? userId;
bool _isLoadingFavorite = false;
bool _isBidDialogOpen = false;
bool _isLoadingBid = false;
double _minBidIncrement = 1000;
String _currentHighestBid = '0';
bool _isMeetingDialogOpen = false;
bool _isSchedulingMeeting = false;

  @override
  void initState() {
    super.initState();
_userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
_initialize();
  }

Future<void> _initialize() async {
  _loadUserId();
  await Future.wait([
    _fetchLocations(),
    _fetchSellerInfo(),
    if (userId != null && userId != 'Unknown') _checkShortlistStatus(),
  ]);
}




Future<void> _loadUserId() async {
  final userData = _userProvider.userData;
  setState(() {
    userId = userData?.userId ?? '';
  });
}
  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

Future<void> _checkShortlistStatus() async {
  if (userId == null || userId == 'Unknown') {
    setState(() {
      _isFavorited = false;
      _isLoadingFavorite = false;
    });
    return;
  }
  setState(() => _isLoadingFavorite = true);
  try {
    final response = await ApiService().get(
      url: shortlist,
      queryParams: {"user_id": userId},
    );
    if (response['status'] == 'true' && response['data'] is List) {
      final List<dynamic> shortlistData = response['data'];
      final bool isShortlisted = shortlistData.any(
        (item) => item['post_id'].toString() == widget.bike.id,
      );
      setState(() {
        _isFavorited = isShortlisted;
        _isLoadingFavorite = false;
      });
    } else {
      setState(() {
        _isFavorited = false;
        _isLoadingFavorite = false;
      });
    }
  } catch (e) {
    setState(() {
      _isFavorited = false;
      _isLoadingFavorite = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to check shortlist: $e'), backgroundColor: Colors.red),
    );
  }
}

Future<void> _toggleFavorite() async {
  if (userId == null || userId == 'Unknown') {
    _showLoginPromptDialog(context, 'add or remove from shortlist');
    return;
  }
  if (_isLoadingFavorite) return;
  setState(() => _isLoadingFavorite = true);
  try {
    final headers = {'token': _token};
    final url = '$_baseUrl/add-to-shortlist.php?token=$_token&user_id=$userId&post_id=${widget.bike.id}';
    final request = http.Request('GET', Uri.parse(url));
    request.headers.addAll(headers);
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final responseData = jsonDecode(responseBody);
      if (responseData['status'] == 'true') {
        final bool wasAdded = responseData['data'].toString().toLowerCase().contains('added') || !_isFavorited;
        setState(() => _isFavorited = wasAdded);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(wasAdded ? 'Added to shortlist' : 'Removed from shortlist'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update shortlist'), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.reasonPhrase}'), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
  } finally {
    setState(() => _isLoadingFavorite = false);
  }
}

void _showLoginPromptDialog(BuildContext context, String action) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Login Required'),
        content: Text('Please log in to $action.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.pushNamed(RouteNames.loginPage);
            },
            child: const Text('Log In'),
          ),
        ],
      );
    },
  );
}

Future<void> _fetchCurrentHighestBid() async {
  setState(() => _isLoadingBid = true);
  try {
    final headers = {'token': _token};
    final url = '$_baseUrl/current-highest-bid-for-post.php?token=$_token&post_id=${widget.bike.id}';
    final request = http.Request('GET', Uri.parse(url));
    request.headers.addAll(headers);
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final responseData = jsonDecode(responseBody);
      if (responseData['status'] == 'true') {
        setState(() => _currentHighestBid = responseData['data'].toString());
      } else {
        setState(() => _currentHighestBid = '0');
      }
    } else {
      setState(() => _currentHighestBid = '0');
    }
  } catch (e) {
    setState(() => _currentHighestBid = '0');
  } finally {
    setState(() => _isLoadingBid = false);
  }
}

Future<String> _saveBidData(int bidAmount) async {
  if (userId == null || userId == 'Unknown') {
    throw Exception('Please log in to place a bid');
  }
  try {
    final headers = {'token': _token};
    final url = '$_baseUrl/place-bid.php?token=$_token&post_id=${widget.bike.id}&user_id=$userId&bidamt=$bidAmount';
    final request = http.Request('GET', Uri.parse(url));
    request.headers.addAll(headers);
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final responseData = jsonDecode(responseBody);
      if (responseData['status'] == 'true') {
        return responseData['data'] ?? 'Bid placed successfully';
      } else {
        throw Exception('Failed to place bid: ${responseData['data']}');
      }
    } else {
      throw Exception('Failed to place bid: ${response.reasonPhrase}');
    }
  } catch (e) {
    throw Exception('Error placing bid: $e');
  }
}

void showProductBidDialog(BuildContext context) async {
  if (userId == null || userId == 'Unknown') {
    _showLoginPromptDialog(context, 'place a bid');
    return;
  }
  setState(() => _isBidDialogOpen = true);
  await _fetchCurrentHighestBid();
  final TextEditingController _bidController = TextEditingController();

  Future<void> _showResponseDialog(String message, bool isSuccess) async {
    final String formattedBid = _currentHighestBid == '0'
        ? 'No bids yet'
        : '₹${NumberFormat('#,##0').format(double.parse(_currentHighestBid))}';
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(isSuccess ? 'Thank You' : 'Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$message\n\nFor further proceedings, call support.'),
            const SizedBox(height: 16),
            Text('Last Highest Bid: $formattedBid'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (isSuccess) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyingStatusPage()));
              }
            },
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: _launchPhoneCall,
            child: const Text('Call Support'),
          ),
        ],
      ),
    );
  }

  final Map<String, dynamic>? result = await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Place Your Bid'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _bidController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: 'Enter amount', prefixText: '₹'),
          ),
          if (_isLoadingBid) const CircularProgressIndicator(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(null),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _isLoadingBid
              ? null
              : () async {
                  final amount = _bidController.text;
                  if (amount.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a bid amount')),
                    );
                    return;
                  }
                  final bidAmount = int.tryParse(amount) ?? 0;
                  if (bidAmount < _minBidIncrement) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Minimum bid is ₹$_minBidIncrement')),
                    );
                    return;
                  }
                  setState(() => _isLoadingBid = true);
                  try {
                    final message = await _saveBidData(bidAmount);
                    Navigator.of(dialogContext).pop({'success': true, 'message': message});
                  } catch (e) {
                    Navigator.of(dialogContext).pop({'success': false, 'message': e.toString()});
                  } finally {
                    setState(() => _isLoadingBid = false);
                  }
                },
          child: const Text('Submit'),
        ),
      ],
    ),
  );

  _bidController.dispose();
  if (result != null) {
    await _showResponseDialog(result['message'], result['success']);
  }
  setState(() => _isBidDialogOpen = false);
}



  Future<void> _fetchSellerInfo() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/post-seller-information.php?token=$_token&user_id=${widget.bike.createdBy}',
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
          print(
            'Locations fetched: ${_locations.map((loc) => "${loc.id}: ${loc.name}").toList()}',
          );
        });
      } else {
        throw Exception('Invalid API response format');
      }
    } catch (e) {
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  String _getLocationName(String zoneId) {
    if (zoneId == 'all') return 'All Kerala';
    if (zoneId == '0') return 'All Kerala';
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

  String get id => widget.bike.id;
  String get title => widget.bike.title;
  String get image => widget.bike.image;
  String get price => widget.bike.price;
  String get landMark => widget.bike.landMark;
  String get createdOn => widget.bike.createdOn.split(' ')[0];
  String get createdBy => widget.bike.createdBy;
  bool get isFinanceAvailable => widget.bike.ifFinance == '1';
  bool get isFeatured => widget.bike.feature == '1';

  List<String> get _images {
    if (image.isNotEmpty) {
      return [getImageUrl(image)];
    }
    return [
      'https://images.pexels.com/photos/106399/pexels-photo-106399.jpeg?cs=srgb&dl=pexels-binyamin-mellish-106399.jpg&fm=jpg',
    ];
  }

  String getImageUrl(String imagePath) {
    final cleanedPath =
        imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return 'https://lelamonline.com/admin/$cleanedPath';
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
  if (userId == null || userId == 'Unknown') {
    _showLoginPromptDialog(context, 'schedule a meeting');
    return;
  }
  if (_isMeetingDialogOpen) return;
  setState(() => _isMeetingDialogOpen = true);
  DateTime selectedDate = DateTime.now();
  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Schedule Meeting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: dialogContext,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null && picked != selectedDate) {
                  setDialogState(() => selectedDate = picked);
                }
              },
            ),
            if (_isSchedulingMeeting) const CircularProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSchedulingMeeting ? null : () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSchedulingMeeting
                ? null
                : () async {
                    setDialogState(() => _isSchedulingMeeting = true);
                    try {
                      await _fixMeeting(selectedDate);
                      Navigator.of(dialogContext).pop();
                    } finally {
                      setDialogState(() => _isSchedulingMeeting = false);
                    }
                  },
            child: const Text('Schedule'),
          ),
        ],
      ),
    ),
  ).whenComplete(() => setState(() => _isMeetingDialogOpen = false));
}

Future<void> _fixMeeting(DateTime selectedDate) async {
  setState(() => _isSchedulingMeeting = true);
  try {
    final headers = {'token': _token};
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final url = '$_baseUrl/post-fix-meeting.php?token=$_token&post_id=${widget.bike.id}&user_id=$userId&meeting_date=$formattedDate';
    final request = http.Request('GET', Uri.parse(url));
    request.headers.addAll(headers);
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final responseData = jsonDecode(responseBody);
      if (responseData['status'] == 'true') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['data'] ?? 'Meeting scheduled')),
        );
        await _showMeetingConfirmationDialog(selectedDate);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule meeting'), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.reasonPhrase}'), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
  } finally {
    setState(() => _isSchedulingMeeting = false);
  }
}

Future<void> _showMeetingConfirmationDialog(DateTime selectedDate) async {
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Meeting Scheduled'),
      content: Text('Scheduled for ${DateFormat('dd/MM/yyyy').format(selectedDate)}. Check status or call support.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyingStatusPage()));
          },
          child: const Text('Check Status'),
        ),
        ElevatedButton(
          onPressed: _launchPhoneCall,
          child: const Text('Call Support'),
        ),
      ],
    ),
  );
}

void _launchPhoneCall() async {
  const phoneNumber = 'tel:+919626040738';
  if (await canLaunchUrl(Uri.parse(phoneNumber))) {
    await launchUrl(Uri.parse(phoneNumber));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not launch phone call'), backgroundColor: Colors.red),
    );
  }
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
                        SellerInformationPage(userId: widget.bike.createdBy),
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
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) => const ReviewDialog( postId: ''),
                );
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

  // Parse filters from the API response
  Map<String, dynamic> _parseFilters(String filtersJson) {
    try {
      if (filtersJson == 'null' || filtersJson.isEmpty) {
        return {};
      }
      return jsonDecode(filtersJson);
    } catch (e) {
      print('Error parsing filters: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    // final filters = _parseFilters(widget.bike.filters);

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
                                  fit: BoxFit.contain,
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
_isLoadingFavorite
    ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
    : IconButton(
        tooltip: _isFavorited ? 'Remove from Shortlist' : 'Add to Shortlist',
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            _isFavorited ? Icons.favorite : Icons.favorite_border,
            key: ValueKey<bool>(_isFavorited),
            color: _isFavorited ? Colors.red : Colors.white,
          ),
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
                        '₹${formatPriceInt(double.tryParse(price) ?? 0)}',
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
    if (userId == null || userId == 'Unknown') {
      _showLoginPromptDialog(context, 'contact the seller');
      return;
    }
    showDialog(
      context: context,
      builder: (context) => ChatOptionsDialog(
        onChatWithSupport: _launchPhoneCall,
        onChatWithSeller: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                listenerId: widget.bike.createdBy,
                listenerName: sellerName,
                listenerImage: sellerProfileImage ?? 'seller.jpg',
              ),
            ),
          );
        },
        baseUrl: _baseUrl,
        token: _token,
      ),
    );
  },
  icon: const Icon(Icons.call),
  label: const Text('Contact Seller'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
                        Column(
                          children: [
                            _buildDetailItem(
                              Icons.person,
                              widget.bike.byDealer == '1' ? 'Dealer' : 'Owner',
                            ),
                            if (widget.bike.brand.isNotEmpty)
                              _buildDetailItem(
                                Icons.branding_watermark,
                                'Brand: ${widget.bike.brand}',
                              ),
                            if (widget.bike.model.isNotEmpty)
                              _buildDetailItem(
                                Icons.directions_bike,
                                'Model: ${widget.bike.model}',
                              ),
                            // if (filters.isNotEmpty)
                            //   ...filters.entries.map((entry) => _buildDetailItem(
                            //         Icons.info,
                            //         '${entry.key}: ${entry.value}',
                            //       )),
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
                        'Description',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.bike.description.isNotEmpty
                            ? widget.bike.description
                            : 'No description available',
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
                const SizedBox(height: 12),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -5,
            child: CustomSafeArea(
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
  onPressed: () => showProductBidDialog(context),
  style: ElevatedButton.styleFrom(
    backgroundColor: Palette.primarypink,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 0),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
          ),
        ],
      ),
    );
  }
}
