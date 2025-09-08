import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'my_bids_widget.dart' as AttributeValueService;


  Future<List<Map<String, dynamic>>> fetchDistricts() async {
    try {
      final headers = {
        'token': token,
        'Cookie': 'PHPSESSID=sgju9bt1ljebrc8sbca4bcn64a',
      };
      final request = http.Request(
        'GET',
        Uri.parse('$baseUrl/list-district.php?token=$token'),
      );
      request.headers.addAll(headers);
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        debugPrint('Districts API response: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        debugPrint('No districts found');
        return [
          {
            "id": "1",
            "slug": "thiruvananthapuram-bwmuosmfkfdc2g2",
            "parent_id": "0",
            "name": "Thiruvananthapuram",
            "image": "",
            "description": "",
            "latitude": "",
            "longitude": "",
            "popular": "0",
            "status": "1",
            "allstore_onoff": "1",
            "created_on": "2024-12-04 10:58:13",
            "updated_on": "2024-12-04 11:06:32"
          }
        ];
      }
      debugPrint('Failed to fetch districts: ${response.statusCode} $responseBody');
      return [
        {
          "id": "1",
          "slug": "thiruvananthapuram-bwmuosmfkfdc2g2",
          "parent_id": "0",
          "name": "Thiruvananthapuram",
          "image": "",
          "description": "",
          "latitude": "",
          "longitude": "",
          "popular": "0",
          "status": "1",
          "allstore_onoff": "1",
          "created_on": "2024-12-04 10:58:13",
          "updated_on": "2024-12-04 11:06:32"
        }
      ];
    } catch (e) {
      debugPrint('Error fetching districts: $e');
      return [
        {
          "id": "1",
          "slug": "thiruvananthapuram-bwmuosmfkfdc2g2",
          "parent_id": "0",
          "name": "Thiruvananthapuram",
          "image": "",
          "description": "",
          "latitude": "",
          "longitude": "",
          "popular": "0",
          "status": "1",
          "allstore_onoff": "1",
          "created_on": "2024-12-04 10:58:13",
          "updated_on": "2024-12-04 11:06:32"
        }
      ];
    }
  }


class MyBidsWidget extends StatefulWidget {
  final String baseUrl;
  final String token;
  final String? userId;

  const MyBidsWidget({
    super.key,
    this.baseUrl = 'https://lelamonline.com/admin/api/v1',
    this.token = '5cb2c9b569416b5db1604e0e12478ded',
    this.userId,
  });

  @override
  State<MyBidsWidget> createState() => _MyBidsWidgetState();
}

class _MyBidsWidgetState extends State<MyBidsWidget> {
  String? selectedBidType = 'Low Bids';
  List<Map<String, dynamic>> bids = [];
  List<Map<String, dynamic>> districts = [];
  bool isLoading = true;
  String? error;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndBids();
  }

  Future<void> _loadUserIdAndBids() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = widget.userId ?? prefs.getString('userId') ?? 'Unknown';
    });
    debugPrint('MyBidsWidget - Loaded userId: $_userId');
    // Fetch districts
    districts = await AttributeValueService.fetchDistricts();
    debugPrint('Loaded districts: ${districts.map((d) => d['name']).toList()}');
    await _loadBids();
  }

  Future<Map<String, dynamic>?> _fetchPostDetails(String postId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/post-details.php?token=${widget.token}&post_id=$postId',
        ),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=g6nr0pkfdnp6o573mn9srq20b4',
        },
      );

      debugPrint(
        'post-details.php full response for post_id $postId: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == true || data['status'] == 'true') {
          Map<String, dynamic>? postData;

          if (data['data'] is List && data['data'].isNotEmpty) {
            postData = data['data'][0];
          } else if (data['data'] is Map) {
            postData = data['data'];
          }

          if (postData != null) {
            debugPrint('Post details extracted: ${postData.toString()}');

            String imagePath = postData['image'] ?? '';
            String fullImageUrl = '';

            if (imagePath.isNotEmpty) {
              if (imagePath.startsWith('http')) {
                fullImageUrl = imagePath;
              } else if (imagePath.startsWith('/')) {
                fullImageUrl = 'https://lelamonline.com$imagePath';
              } else {
                fullImageUrl = 'https://lelamonline.com/admin/$imagePath';
              }
            }

            // Map parent_zone_id to district name
            String location = 'Unknown Location';
            final parentZoneId = postData['parent_zone_id']?.toString();
            if (parentZoneId != null) {
              final district = districts.firstWhere(
                (d) => d['id'] == parentZoneId,
                orElse: () => {'name': 'Unknown District'},
              );
              location = district['name'] as String;
              if (postData['land_mark'] != null && postData['land_mark'].isNotEmpty) {
                location += ', ${postData['land_mark']}';
              }
            } else if (postData['land_mark'] != null && postData['land_mark'].isNotEmpty) {
              location = postData['land_mark'];
            }

            return {
              'title': postData['title'] ?? 'Unknown Vehicle (ID: $postId)',
              'price': postData['price'] ?? '0',
              'image': fullImageUrl,
              'parent_zone_id': parentZoneId ?? 'Unknown',
              'by_dealer': postData['by_dealer'] ?? '0',
              'land_mark': postData['land_mark'] ?? '',
              'location': location,
            };
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching post details for post_id $postId: $e');
      return null;
    }
  }

  Future<int> _fetchMeetingAttempts(String bidId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/meetings.php?token=${widget.token}&bid_id=$bidId',
        ),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=g6nr0pkfdnp6o573mn9srq20b4',
        },
      );
      debugPrint('meetings.php response for bid_id $bidId: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] is List) {
          return data['data'].length;
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching meeting attempts for bid_id $bidId: $e');
      return 0;
    }
  }

  Future<String> _fetchBidAmount(String bidId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/bid-details.php?token=${widget.token}&bid_id=$bidId',
        ),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=g6nr0pkfdnp6o573mn9srq20b4',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          if (data['data'] is Map) {
            return data['data']['bid_amount'] ??
                data['data']['amount'] ??
                data['data']['price'] ??
                '0';
          }
        }
      }
      return '0';
    } catch (e) {
      debugPrint('Error fetching bid amount for bid_id $bidId: $e');
      return '0';
    }
  }

  Future<void> _loadBids() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    if (_userId == null || _userId == 'Unknown') {
      setState(() {
        isLoading = false;
        error = 'Please log in to view your bids';
      });
      return;
    }

    try {
      final headers = {
        'token': widget.token,
        'Cookie': 'PHPSESSID=g6nr0pkfdnp6o573mn9srq20b4',
      };

      List<Map<String, dynamic>> allBids = [];

      final lowBidsResponse = await http.get(
        Uri.parse(
          '${widget.baseUrl}/my-bids-low.php?token=${widget.token}&user_id=$_userId',
        ),
        headers: headers,
      );

      debugPrint('my-bids-low.php status: ${lowBidsResponse.statusCode}');
      final lowBidsBody = lowBidsResponse.body;
      debugPrint('my-bids-low.php response: $lowBidsBody');

      if (lowBidsResponse.statusCode == 200) {
        final lowBidsData = jsonDecode(lowBidsBody);
        if (lowBidsData['status'] == true && lowBidsData['data'] is List) {
          final lowBids = List<Map<String, dynamic>>.from(lowBidsData['data']);
          for (var bid in lowBids) {
            bid['fromLowBids'] = true;
            allBids.add(bid);
          }
        }
      }

      final highBidsResponse = await http.get(
        Uri.parse(
          '${widget.baseUrl}/my-bids-high.php?token=${widget.token}&user_id=$_userId',
        ),
        headers: headers,
      );

      debugPrint('my-bids-high.php status: ${highBidsResponse.statusCode}');
      final highBidsBody = highBidsResponse.body;
      debugPrint('my-bids-high.php response: $highBidsBody');

      if (highBidsResponse.statusCode == 200) {
        final highBidsData = jsonDecode(highBidsBody);
        if (highBidsData['status'] == true && highBidsData['data'] is List) {
          final highBids = List<Map<String, dynamic>>.from(highBidsData['data']);
          for (var bid in highBids) {
            bid['fromHighBids'] = true;
            allBids.add(bid);
          }
        }
      }

      debugPrint('Total bids fetched: ${allBids.length}');

      for (var bid in allBids) {
        debugPrint('Processing bid: ${bid['id']} for post: ${bid['post_id']}');

        final postDetails = await _fetchPostDetails(bid['post_id']);
        if (postDetails != null) {
          bid['title'] = postDetails['title'];
          bid['carImage'] = postDetails['image'];
          bid['targetPrice'] = postDetails['price'];
          bid['location'] = postDetails['location'];
          bid['store'] = postDetails['by_dealer'] == '1' ? 'Dealer' : 'Individual';
          bid['appId'] = 'APP_${bid['post_id']}';

          try {
            final createdDate = DateTime.parse(bid['created_on']);
            bid['bidDate'] = DateFormat('yyyy-MM-dd').format(createdDate);
            bid['expirationDate'] = DateFormat('yyyy-MM-dd').format(createdDate.add(Duration(days: 7)));
          } catch (e) {
            bid['bidDate'] = 'N/A';
            bid['expirationDate'] = 'N/A';
          }

          bid['meetingAttempts'] = await _fetchMeetingAttempts(bid['id']);
          bid['bidPrice'] = await _fetchBidAmount(bid['id']);
        } else {
          bid['title'] = 'Unknown Vehicle (ID: ${bid['post_id']})';
          bid['carImage'] = '';
          bid['targetPrice'] = '0';
          bid['location'] = 'Unknown Location';
          bid['store'] = 'Individual';
          bid['appId'] = 'APP_${bid['post_id']}';
          bid['bidDate'] = bid['created_on']?.split(' ')[0] ?? 'N/A';
          bid['expirationDate'] = 'N/A';
          bid['meetingAttempts'] = 0;
          bid['bidPrice'] = '0';
        }

        debugPrint('Bid processed: ${bid['title']}');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'userBids',
        allBids.map((b) => jsonEncode(b)).toList(),
      );

      setState(() {
        bids = allBids;
        isLoading = false;
      });

      debugPrint('Bids loaded successfully: ${bids.length} items');
    } catch (e) {
      debugPrint('Error loading bids: $e');
      setState(() {
        isLoading = false;
        error = 'Error loading bids: $e';
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredBids() {
    return bids.where((bid) {
      final double bidPrice = double.tryParse(bid['bidPrice'] ?? '0') ?? 0;
      final double targetPrice = double.tryParse(bid['targetPrice'] ?? '0') ?? 0;

      if (selectedBidType == 'Low Bids') {
        return bidPrice < targetPrice ||
            (bid.containsKey('fromLowBids') && bid['fromLowBids'] == true);
      } else {
        return bidPrice >= targetPrice ||
            (bid.containsKey('fromHighBids') && bid['fromHighBids'] == true);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBids = _getFilteredBids();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: MyBidItem(
                          title: 'Low Bids',
                          isSelected: selectedBidType == 'Low Bids',
                          onTap: () {
                            setState(() => selectedBidType = 'Low Bids');
                            _loadBids();
                          },
                        ),
                      ),
                      Expanded(
                        child: MyBidItem(
                          title: 'High Bids',
                          isSelected: selectedBidType == 'High Bids',
                          onTap: () {
                            setState(() => selectedBidType = 'High Bids');
                            _loadBids();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                error!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadUserIdAndBids,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : filteredBids.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.gavel_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No ${selectedBidType?.toLowerCase()} found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your bids will appear here once you start bidding',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredBids.length,
                              itemBuilder: (context, index) {
                                final bid = filteredBids[index];
                                return BidCard(
                                  bid: bid,
                                  baseUrl: widget.baseUrl,
                                  token: widget.token,
                                  userId: _userId ?? bid['user_id'] ?? '482',
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class BidCard extends StatelessWidget {
  final Map<String, dynamic> bid;
  final String baseUrl;
  final String token;
  final String userId;

  const BidCard({
    super.key,
    required this.bid,
    required this.baseUrl,
    required this.token,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final double bidPrice = double.tryParse(bid['bidPrice'] ?? '0') ?? 0;
    final double targetPrice = double.tryParse(bid['targetPrice'] ?? '0') ?? 0;
    final bool isLowBid =
        bidPrice < targetPrice ||
        (bid.containsKey('fromLowBids') && bid['fromLowBids'] == true);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: bid['carImage'] ?? '',
                        width: 100,
                        height: 150,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          debugPrint('Image load error: $error for URL: $url');
                          return Container(
                            width: 90,
                            height: 90,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.directions_car,
                              size: 40,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  bid['title'] ??
                                      'Unknown Vehicle (ID: ${bid['post_id']})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'App Id: ${bid['appId'] ?? 'LAD_${bid['post_id']}'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
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
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Location: ${bid['location'] ?? 'Unknown Location'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Row(
                          //   children: [
                          //     Icon(
                          //       Icons.store,
                          //       size: 14,
                          //       color: Colors.grey[500],
                          //     ),
                          //     const SizedBox(width: 4),
                          //     Text(
                          //       'Seller: ${bid['store'] ?? 'Unknown Seller'}',
                          //       style: TextStyle(
                          //         fontSize: 12,
                          //         color: Colors.grey[600],
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.meeting_room,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Meeting Attempts: ${bid['meetingAttempts'] ?? 0}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.more_vert, size: 16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'increase_bid',
                          child: Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              SizedBox(width: 8),
                              Text('Increase Bid'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'proceed_with_bid',
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 8),
                              Text('Meeting with Bid'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'proceed_without_bid',
                          child: Row(
                            children: [
                              Icon(
                                Icons.event,
                                size: 16,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 8),
                              Text('Meeting without Bid'),
                            ],
                          ),
                        ),
                      ],
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
                          Text(
                            'Bid Date',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            bid['bidDate'] ??
                                bid['created_on']?.split(' ')[0] ??
                                'N/A',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expiration Date',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            bid['expirationDate'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Price',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            targetPrice == 0
                                ? 'N/A'
                                : '₹${NumberFormat('#,##0').format(targetPrice)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Bid',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            bidPrice == 0
                                ? 'N/A'
                                : '₹${NumberFormat('#,##0').format(bidPrice)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isLowBid ? Colors.orange[700] : Colors.green[700],
                            ),
                          ),
                        ],
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
              color: Colors.grey[50],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          'Schedule meeting with bid',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'For high bid meeting, Meeting must be done in 24hrs if seller accepts the bid.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
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
}

class MyBidItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const MyBidItem({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}