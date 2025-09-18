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
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/Support/views/support_page.dart';
import 'package:lelamonline_flutter/feature/categories/seller%20info/seller_info_page.dart';
import 'package:lelamonline_flutter/feature/categories/widgets/bid_dialog.dart';
import 'package:lelamonline_flutter/feature/chat/views/chat_page.dart'
    show ChatPage;
import 'package:lelamonline_flutter/feature/chat/views/widget/chat_dialog.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/buying_status_page.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/my_meetings_widget.dart';
import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:lelamonline_flutter/utils/palette.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/utils/review_dialog.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BikeDetailsPage extends StatefulWidget {
  final dynamic bike;

  const BikeDetailsPage({super.key, required this.bike});

  @override
  State<BikeDetailsPage> createState() => _BikeDetailsPageState();
}

class _BikeDetailsPageState extends State<BikeDetailsPage> {
  bool _isLoadingLocations = true;
  List<LocationData> _locations = [];
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  final TransformationController _transformationController = TransformationController();
  bool _isShortlisted = false;
  bool _isLoadingShortlist = false;
  String? _shortlistErrorMessage;
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
  bool _isLoadingBid = false;
  double _minBidIncrement = 1000;
  String _currentHighestBid = '0';
  bool _isBidDialogOpen = false;
  bool _isMeetingDialogOpen = false;
  bool _isSchedulingMeeting = false;
  bool _isLoadingBanner = false;
  String? _bannerImageUrl;
  String _bannerError = '';
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserId();
    await Future.wait([
      _fetchLocations(),
      _fetchSellerInfo(),
      _fetchBannerImage(),
      if (userId != null && userId != 'Unknown') _checkShortlistStatus(),
    ]);
  }

  Future<void> _loadUserId() async {
    try {
      final userData = _userProvider.userData;
      String? providerUserId = userData?.userId;
      String? storageUserId = await _storage.read(key: 'userId');

      if (providerUserId != null && providerUserId.isNotEmpty && providerUserId != 'Unknown') {
        setState(() {
          userId = providerUserId;
        });
        await _storage.write(key: 'userId', value: providerUserId);
      } else if (storageUserId != null && storageUserId.isNotEmpty && storageUserId != 'Unknown') {
        setState(() {
          userId = storageUserId;
        });
        // _userProvider.userId = storageUserId;
      } else {
        setState(() {
          userId = null;
        });
      }
    } catch (e) {
      setState(() {
        userId = null;
      });
    }
  }

  Future<void> _fetchBannerImage() async {
    try {
      setState(() {
        _isLoadingBanner = true;
        _bannerError = '';
      });
      final headers = {
        'token': _token,
        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
      };
      final url = '$_baseUrl/post-ads-image.php?token=$_token';
      debugPrint('Fetching banner image: $url');

      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('Banner API response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        if (responseData['status'] == 'true' && responseData['data'] != null) {
          final bannerImage = responseData['data']['inner_post_image'] ?? '';
          setState(() {
            _bannerImageUrl = bannerImage.isNotEmpty ? 'https://lelamonline.com/admin/$bannerImage' : null;
          });
        } else {
          throw Exception('Invalid banner data: ${responseData['data']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error fetching banner image: $e');
      setState(() {
        _bannerError = 'Failed to load banner: $e';
      });
    } finally {
      setState(() {
        _isLoadingBanner = false;
      });
    }
  }

  Widget _buildBannerAd() {
    if (_isLoadingBanner) {
      return const Padding(
        padding: EdgeInsets.all(0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_bannerError.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(0),
        child: Center(
          child: Text(_bannerError, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_bannerImageUrl == null || _bannerImageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(0),
      child: CachedNetworkImage(
        imageUrl: _bannerImageUrl!,
        width: double.infinity,
        height: 35,
        fit: BoxFit.fill,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error_outline, size: 50, color: Colors.red),
        ),
      ),
    );
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
        _isShortlisted = false;
        _isLoadingShortlist = false;
        _shortlistErrorMessage = 'Please log in to view shortlist status';
      });
      return;
    }
    setState(() => _isLoadingShortlist = true);
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
          _isShortlisted = isShortlisted;
          _isLoadingShortlist = false;
          _shortlistErrorMessage = null;
        });
      } else {
        setState(() {
          _isShortlisted = false;
          _isLoadingShortlist = false;
          _shortlistErrorMessage = 'Invalid shortlist data';
        });
      }
    } catch (e) {
      setState(() {
        _isShortlisted = false;
        _isLoadingShortlist = false;
        _shortlistErrorMessage = 'Failed to check shortlist: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check shortlist: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleShortlist() async {
    if (userId == null || userId == 'Unknown') {
      _showLoginPromptDialog(context, 'add or remove from shortlist');
      return;
    }
    if (_isLoadingShortlist) return;
    setState(() => _isLoadingShortlist = true);
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
          final bool wasAdded = responseData['data'].toString().toLowerCase().contains('added') || !_isShortlisted;
          setState(() {
            _isShortlisted = wasAdded;
            _shortlistErrorMessage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(wasAdded ? 'Added to shortlist' : 'Removed from shortlist'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        } else {
          setState(() {
            _shortlistErrorMessage = 'Failed to update shortlist';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update shortlist'), backgroundColor: Colors.red),
          );
        }
      } else {
        setState(() {
          _shortlistErrorMessage = 'Error: ${response.reasonPhrase}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.reasonPhrase}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() {
        _shortlistErrorMessage = 'Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoadingShortlist = false);
    }
  }

  void _showLoginPromptDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Login Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          content: Text('Please log in to $action.', style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.pushNamed(RouteNames.loginPage);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

    Future<void> _showResponseDialog(String message, bool isSuccess, bool isHighestBid) async {
      final String formattedBid = _currentHighestBid == '0'
          ? 'No bids yet'
          : '₹${NumberFormat('#,##0').format(double.parse(_currentHighestBid))}';
      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            backgroundColor: Colors.white,
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSuccess ? 'Thank You' : 'Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? AppTheme.primaryColor : Colors.red,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 28, color: Colors.grey[700]),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSuccess && isHighestBid)
                  Text(
                    'Congratulations, your bid is the highest bid! 🎉',
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                  ),
                if (isSuccess && isHighestBid) const SizedBox(height: 8),
                Text(
                  '$message\n\nFor further proceedings, you will receive a callback soon or call support now.',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Last Highest Bid:',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _currentHighestBid.startsWith('Error') ? Colors.red : Colors.grey[300]!,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _currentHighestBid.startsWith('Error') ? Colors.red[50] : Colors.green[50],
                  ),
                  child: Text(
                    formattedBid,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _currentHighestBid.startsWith('Error') ? Colors.red[800] : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (isSuccess) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyingStatusPage()));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _launchPhoneCall,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Call Support',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            actionsPadding: const EdgeInsets.all(16),
          );
        },
      );
    }

    final Map<String, dynamic>? result = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          'Place Your Bid Amount',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Bid Amount *',
              style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bidController,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Enter amount',
                prefixText: '₹',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
              style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
            ),
            if (_isLoadingBid)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
                ),
              ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoadingBid
                      ? null
                      : () async {
                          final amount = _bidController.text;
                          if (amount.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Enter a bid amount'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                            return;
                          }
                          final bidAmount = int.tryParse(amount) ?? 0;
                          if (bidAmount < _minBidIncrement) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Minimum bid is ₹$_minBidIncrement'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                            return;
                          }
                          setState(() => _isLoadingBid = true);
                          try {
                            final message = await _saveBidData(bidAmount);
                            final double currentHighest = double.tryParse(_currentHighestBid) ?? 0;
                            final bool isHighestBid = bidAmount > currentHighest;
                            Navigator.of(dialogContext).pop({
                              'success': true,
                              'message': message,
                              'isHighestBid': isHighestBid,
                            });
                          } catch (e) {
                            Navigator.of(dialogContext).pop({
                              'success': false,
                              'message': e.toString(),
                              'isHighestBid': false,
                            });
                          } finally {
                            setState(() => _isLoadingBid = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.all(16),
      ),
    );

    _bidController.dispose();
    if (result != null) {
      await _showResponseDialog(result['message'], result['success'], result['isHighestBid']);
    }
    setState(() => _isBidDialogOpen = false);
  }

  void _showMeetingDialog(BuildContext context) {
    if (userId == null || userId == 'Unknown') {
      _showLoginPromptDialog(context, 'schedule a meeting');
      return;
    }

    if (_isMeetingDialogOpen) {
      debugPrint('Meeting dialog already open');
      return;
    }

    setState(() {
      _isMeetingDialogOpen = true;
    });

    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
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
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                        );
                        if (picked != null && picked != selectedDate) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    if (_isSchedulingMeeting)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      _isSchedulingMeeting
                          ? null
                          : () {
                            Navigator.of(dialogContext).pop();
                          },
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
                  onPressed:
                      _isSchedulingMeeting
                          ? null
                          : () async {
                            setDialogState(() {
                              _isSchedulingMeeting = true;
                            });
                            try {
                              await _fixMeeting(selectedDate);
                              if (mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            } finally {
                              setDialogState(() {
                                _isSchedulingMeeting = false;
                              });
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
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
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _isMeetingDialogOpen = false;
        });
      }
    });
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
            SnackBar(content: Text(responseData['data'] ?? 'Meeting scheduled'), backgroundColor: Colors.green),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        backgroundColor: Colors.white,
        title: Text(
          'Meeting Scheduled',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
        content: Text(
          'Your meeting is scheduled for ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)}.\n\n'
          'For further information, check My Bids in Status or call support.',
          style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: Colors.grey[800],
              ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyingStatusPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Check Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _launchPhoneCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Call Support',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _fetchSellerInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/post-seller-information.php?token=$_token&user_id=${widget.bike.createdBy}'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'true' && jsonResponse['data'] is List && jsonResponse['data'].isNotEmpty) {
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
    final url = '$_baseUrl/list-location.php?token=$_token';
    debugPrint('Fetching locations from: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'token': _token,
        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
      },
    );

    debugPrint('Locations API response (status: ${response.statusCode}): ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['status'] == 'true' && responseData['data'] is List) {
        final locationResponse = LocationResponse.fromJson(responseData);
        setState(() {
          _locations = locationResponse.data;
          _isLoadingLocations = false;
          debugPrint(
            'Locations fetched: ${_locations.map((loc) => "${loc.id}: ${loc.name}").toList()}',
          );
        });
      } else {
        throw Exception('Invalid API response format: ${responseData['data']}');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  } catch (e) {
    debugPrint('Error fetching locations: $e');
    setState(() {
      _isLoadingLocations = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to load locations: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
 String _getLocationName() {
  final zoneId = widget.bike.parentZoneId;
  if (zoneId == 'all' || zoneId == '0') return 'All Kerala';
  final location = _locations.firstWhere(
    (loc) => loc.id == zoneId,
    orElse: () => LocationData(
      id: '',
      slug: '',
      parentId: '',
      name: 'Unknown Location',
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
  return location.name.isNotEmpty ? location.name : 'Unknown Location';
}

  String get id => widget.bike.id;
  String get title => widget.bike.title;
  String get image => widget.bike.image;
  String get price => widget.bike.price;
String get locationName => _getLocationName();
//String get landMark => widget.bike.landMark;
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
    final cleanedPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
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
          final PageController fullScreenController = PageController(initialPage: _currentImageIndex);
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
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(child: Icon(Icons.error_outline, size: 50, color: Colors.red)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_currentImageIndex + 1}/${_images.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    fullScreenController.animateToPage(
                                      index,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    width: 70,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _currentImageIndex == index ? Colors.blue : Colors.transparent,
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
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => const Icon(Icons.error, size: 20),
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
            ? Center(child: Text(sellerErrorMessage, style: const TextStyle(color: Colors.red)))
            : GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SellerInformationPage(userId: widget.bike.createdBy)),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: sellerProfileImage != null && sellerProfileImage!.isNotEmpty
                          ? CachedNetworkImageProvider(sellerProfileImage!)
                          : const AssetImage('assets/images/avatar.gif') as ImageProvider,
                      radius: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sellerName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              onPressed: () async {
                final userId = await _storage.read(key: 'userId');
                if (userId == null || userId == 'Unknown') {
                  _showLoginPromptDialog(context, 'ask a question');
                  return;
                }
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => ReviewDialog(postId: id),
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
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1}/${_images.length}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          if (isFeatured)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white),
                                ),
                                child: const Text(
                                  'FEATURED',
                                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
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
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const Spacer(),
                          _isLoadingShortlist
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : IconButton(
                                  tooltip: _isShortlisted ? 'Remove from Shortlist' : 'Add to Shortlist',
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      _isShortlisted ? Icons.favorite : Icons.favorite_border,
                                      key: ValueKey<bool>(_isShortlisted),
                                      color: _isShortlisted ? Colors.red : Colors.white,
                                    ),
                                  ),
                                  onPressed: _toggleShortlist,
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
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Icon(Icons.location_on, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          _isLoadingLocations
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(
                  locationName, // Changed from landMark
                  style: const TextStyle(color: Colors.grey),
                ),
          const Spacer(),
          const Icon(Icons.access_time, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(createdOn, style: const TextStyle(color: Colors.grey)),
        ],
      ),
      // Optional: Display landMark separately if not empty
      // if (landMark.isNotEmpty)
      //   Padding(
      //     padding: const EdgeInsets.only(top: 8),
      //     child: Row(
      //       children: [
      //         const Icon(Icons.place, size: 16, color: Colors.grey),
      //         const SizedBox(width: 4),
      //         Flexible(
      //           child: Text(
      //             landMark,
      //             style: const TextStyle(color: Colors.grey),
      //             overflow: TextOverflow.ellipsis,
      //           ),
      //         ),
      //       ],
      //     ),
      //   ),
      const SizedBox(height: 16),
      Text(
        '₹${formatPriceInt(double.tryParse(price) ?? 0)}',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('#AD ID $id', style: const TextStyle(color: Colors.grey)),
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
                              Icon(Icons.account_balance, size: 16, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Finance Available',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
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
                        const Text('Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Column(
                          children: [
                            _buildDetailItem(Icons.person, widget.bike.byDealer == '1' ? 'Dealer' : 'Owner'),
                            if (widget.bike.brand.isNotEmpty) _buildDetailItem(Icons.branding_watermark, 'Brand: ${widget.bike.brand}'),
                            if (widget.bike.model.isNotEmpty) _buildDetailItem(Icons.directions_bike, 'Model: ${widget.bike.model}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        widget.bike.description.isNotEmpty ? widget.bike.description : 'No description available',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                _buildBannerAd(),
               
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Seller Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      const Text('Questions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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