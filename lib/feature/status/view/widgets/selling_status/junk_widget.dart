import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/my_meetings_widget.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class JunkWidget extends StatefulWidget {
  final String? postId;
  final String? userId;
  final String baseUrl;
  final String token;

  const JunkWidget({
    super.key,
    this.postId,
    this.userId,
    this.baseUrl = 'https://lelamonline.com/admin/api/v1',
    this.token = '5cb2c9b569416b5db1604e0e12478ded',
  });

  @override
  State<JunkWidget> createState() => _JunkWidgetState();
}

class _JunkWidgetState extends State<JunkWidget> {
  final List<String> statuses = [
    'Reschedule Request',
    'Expired',
    'Skipped',
    'Attempts Over',
    'Inactive',
    'Cancelled',
    'Sold Out',
  ];

  int selectedIndex = 0;
  List<Map<String, dynamic>> junkItems = [];
  bool isLoading = true;
  String? errorMessage;
  String? _userId;
  Timer? _refreshTimer;
  static const String phpSessId = 'g6nr0pkfdnp6o573mn9srq20b4';

  @override
  void initState() {
    super.initState();
    debugPrint('JunkWidget init - postId: "${widget.postId}", userId: "${widget.userId}"');
    _loadUserId();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _loadJunkItems();
    });
  }

  Future<void> _loadUserId() async {
    try {
      final userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
      final userData = userProvider.userData;
      setState(() {
        _userId = widget.userId ?? userData?.userId ?? 'Unknown';
        debugPrint('Loaded userId: "$_userId"');
        if (_userId == 'Unknown') {
          errorMessage = ' Please log in again';
          isLoading = false;
        }
      });
      if (_userId != 'Unknown') {
        await _loadJunkItems();
      }
    } catch (e) {
      debugPrint('Error loading userId: $e');
      setState(() {
        errorMessage = 'Error loading user ID: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadJunkItems() async {
    debugPrint('Starting _loadJunkItems - userId: "$_userId", postId: "${widget.postId}"');

    if (!mounted || _userId == null || _userId == 'Unknown') {
      debugPrint('Early exit: Invalid user ID');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Cannot load junk items: Invalid user ID';
        });
      }
      return;
    }

    if (widget.postId == null || widget.postId!.isEmpty) {
      debugPrint('WARNING: postId is null/empty - APIs will fail, showing empty list');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Please select a post to load junk items';
          junkItems = [];
        });
      }
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      junkItems = [];
    });

    try {
      final headers = {'token': widget.token, 'Cookie': 'PHPSESSID=$phpSessId'};
      String url;
      switch (selectedIndex) {
        case 0:
          url = '${widget.baseUrl}/sell-junk-reschedule-request.php?token=${widget.token}&post_id=${widget.postId}';
          break;
        case 1:
          url = '${widget.baseUrl}/sell-junk-expired.php?token=${widget.token}&post_id=${widget.postId}';
          break;
        case 2:
          url = '${widget.baseUrl}/sell-junk-skipped.php?token=${widget.token}&post_id=${widget.postId}';
          break;
        case 3:
          url = '${widget.baseUrl}/sell-junk-attemps-over.php?token=${widget.token}&post_id=${widget.postId}';
          break;
        case 4:
          url = '${widget.baseUrl}/sell-junk-inactive.php?token=${widget.token}&post_id=${widget.postId}';
          break;
        case 5:
          url = '${widget.baseUrl}/sell-junk-canceled.php?token=${widget.token}&post_id=${widget.postId}';
          break;
        case 6:
          url = '${widget.baseUrl}/sell-junk-sold-out.php?token=${widget.token}&post_id=${widget.postId}';
          break;
        default:
          url = '${widget.baseUrl}/sell-junk-reschedule-request.php?token=${widget.token}&post_id=${widget.postId}';
      }

      debugPrint('Fetching junk items from: $url');
      final response = await http.get(Uri.parse(url), headers: headers);
      debugPrint('HTTP Status: ${response.statusCode}');
      debugPrint('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Response data: $responseData');

        if (responseData is Map<String, dynamic> &&
            (responseData['status'] == true || responseData['status'] == 'true') &&
            responseData['data'] is List) {
          final List<dynamic> itemData = responseData['data'];
          debugPrint('Found ${itemData.length} junk items in API response');

          for (var item in itemData) {
            final itemDataMap = <String, dynamic>{
              'id': item['id']?.toString() ?? 'N/A',
              'title': item['title']?.toString() ?? 'Untitled',
              'image': item['image']?.toString() ?? '',
              'created_on': item['created_on']?.toString() ?? '',
              'price': item['price']?.toString() ?? 'N/A',
              'category_id': item['category_id']?.toString() ?? '',
              'district': item['district']?.toString() ?? 'Unknown',
              'visiter_count': item['visiter_count']?.toString() ?? '0',
              'rejectionMsg': item['rejectionMsg']?.toString(),
            };
            debugPrint('Added junk item ${itemDataMap['id']}: $itemDataMap');
            junkItems.add(itemDataMap);
          }
        } else {
          debugPrint('Unexpected response format or empty data: ${responseData.toString()}');
          junkItems = [];
        }

        debugPrint('Total junk items loaded: ${junkItems.length}');
      } else {
        debugPrint('Failed to fetch junk items: ${response.statusCode} - ${response.reasonPhrase}');
        errorMessage = 'Failed to fetch junk items';
      }
    } catch (e) {
      debugPrint('Error loading junk items: $e');
      errorMessage = 'Error loading junk items: $e';
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> _fetchMainImageUrl(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/get-post-main-image.php?token=${widget.token}&post_id=$postId'),
        headers: {'token': widget.token, 'Cookie': 'PHPSESSID=$phpSessId'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Fetch main image response for post $postId: $responseData');
        if (responseData['status'] == 'true' && responseData['data'] is Map) {
          return responseData['data']['image_url'] ?? '';
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching main image for post $postId: $e');
      return null;
    }
  }

  Widget _buildJunkCard(Map<String, dynamic> item) {
    String? imageUrl;
    if (item['image'] != null && (item['image'] as String).isNotEmpty) {
      if ((item['image'] as String).startsWith('http')) {
        imageUrl = item['image'] as String;
      } else {
        imageUrl = 'https://lelamonline.com/admin/${item['image'].startsWith('/') ? item['image'].substring(1) : item['image']}';
      }
    } else {
      imageUrl = 'https://lelamonline.com/admin/Uploads/post/${item['id']}.jpg';
      debugPrint('Warning: Image field empty for item ${item['id']}, using fallback URL: $imageUrl');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statuses[selectedIndex],
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.remove_red_eye, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${item['visiter_count'] ?? 0}', style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: 110,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.brown.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      httpHeaders: {
                        'token': widget.token,
                        'Cookie': 'PHPSESSID=$phpSessId',
                      },
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) {
                        debugPrint('Error loading image for item ${item['id']}: $error');
                        Fluttertoast.showToast(
                          msg: 'Failed to load image for item ${item['id']}',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.grey.shade800,
                          textColor: Colors.white,
                        );
                        return Image.asset(
                          'assets/placeholder_image.png',
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'assets/placeholder_image.png',
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String? ?? 'Untitled',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      _itemDetail('App ID', item['id'] as String? ?? 'N/A'),
                      _itemDetail('Posted Date', _formatDate(item['created_on'] as String? ?? '')),
                      _itemDetail('Exp Date', _formatExpDate(item['created_on'] as String? ?? '')),
                      _itemDetail('Price', '₹${item['price'] ?? 'N/A'}', highlight: true),
                      _itemDetail('Category', _getCategoryName(item['category_id'] as String? ?? '')),
                      _itemDetail('Location', item['district'] ?? 'Unknown'),
                    ],
                  ),
                ),
              ],
            ),
            if (item['rejectionMsg'] != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  item['rejectionMsg'] as String,
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _itemDetail(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: highlight ? AppTheme.primaryColor : Colors.black87,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String categoryId) {
    const categoryMap = {
      '1': 'Used Cars',
      '2': 'Real Estate',
      '3': 'Commercial Vehicles',
      '4': 'Other',
    };
    return categoryMap[categoryId] ?? 'Unknown';
  }

  String _formatDate(String date) {
    try {
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final parsedDate = dateFormat.parse(date);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return date.isEmpty ? 'Unknown' : date;
    }
  }

  String _formatExpDate(String createdOn) {
    try {
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final parsedDate = dateFormat.parse(createdOn);
      final expDate = parsedDate.add(const Duration(days: 30));
      return DateFormat('dd-MM-yyyy').format(expDate);
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statuses.map((status) {
                  final index = statuses.indexOf(status);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: StatusPill(
                      label: status,
                      isActive: index == selectedIndex,
                      activeColor: AppTheme.primaryColor,
                      inactiveColor: Colors.grey,
                      onTap: () {
                        debugPrint('StatusPill tapped: $status (index: $index)');
                        if (mounted) {
                          setState(() {
                            selectedIndex = index;
                          });
                          _loadJunkItems();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.grey[50],
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : errorMessage != null
                      ? SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                
                                const SizedBox(height: 12),
                                Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadUserId,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                  ),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : junkItems.isEmpty
                          ? SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No junk items found for ${statuses[selectedIndex]}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    if (widget.postId == null || widget.postId!.isEmpty)
                                      Text(
                                        'Select a post first to load junk items',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange[800],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: junkItems.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildJunkCard(item),
                                  );
                                }).toList(),
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}