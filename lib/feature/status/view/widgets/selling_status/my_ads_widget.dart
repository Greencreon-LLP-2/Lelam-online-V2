import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/selling_status/tab_bar_widget.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MyAdsWidget extends StatefulWidget {
  final String? userId;
  final Map<String, dynamic>? adData;

  const MyAdsWidget({super.key, this.userId, this.adData});

  @override
  State<MyAdsWidget> createState() => _MyAdsWidgetState();
}

class _MyAdsWidgetState extends State<MyAdsWidget> {
  List<Map<String, dynamic>> ads = [];
  bool isLoading = true;
  String? errorMessage;
  Map<String, bool> _expandedImages = {}; // Track expanded state for each ad
  static const String baseUrl = 'https://lelamonline.com/admin/api/v1';
  static const String token = '5cb2c9b569416b5db1604e0e12478ded';
  static const String phpSessId = 'g6nr0pkfdnp6o573mn9srq20b4';

  @override
  void initState() {
    super.initState();
    _loadAds();
  }




  Future<void> _loadAds() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    print('MyAdsWidget - userId: ${widget.userId}');
    print('MyAdsWidget - adData: ${widget.adData}');

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/sell.php?token=$token&user_id=${widget.userId ?? '482'}',
        ),
        headers: {'token': token, 'Cookie': 'PHPSESSID=$phpSessId'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('API response: $responseData');
        if (responseData['status'] == 'true' && responseData['data'] is List) {
          final fetchedAds = List<Map<String, dynamic>>.from(
            responseData['data'],
          );

          for (var ad in fetchedAds) {
            _expandedImages[ad['id']] = false;
          }

          if (widget.adData != null) {
            final passedAdId = widget.adData!['id'];
            final isAlreadyIncluded = fetchedAds.any(
              (ad) => ad['id'] == passedAdId,
            );
            if (!isAlreadyIncluded) {
              print('Adding passed ad data: ${widget.adData}');
              fetchedAds.add(widget.adData!);
              _expandedImages[passedAdId] = false;
            } else {
              print('Passed ad already exists in fetched ads');
            }
          }

          final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
          fetchedAds.sort((a, b) {
            try {
              final dateA = dateFormat.parse(a['created_on'] as String);
              final dateB = dateFormat.parse(b['created_on'] as String);
              return dateB.compareTo(dateA); // Newest first
            } catch (e) {
              print('Error parsing dates for sorting: $e');
              return 0;
            }
          });

          setState(() {
            ads = fetchedAds;
            isLoading = false;
          });
          print('Fetched ${ads.length} ads');
        } else {
          throw Exception(responseData['message'] ?? 'No ads found');
        }
      } else {
        throw Exception('Failed to fetch ads: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error loading ads: $e');
      setState(() {
        errorMessage = 'Error loading ads: $e';
        isLoading = false;
      });
    }
  }

Future<void> _deleteAd(String adId) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/sell.php?token=$token&user_id=${widget.userId ?? '482'}'),
      headers: {
        'token': token,
        'Cookie': 'PHPSESSID=$phpSessId',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'id': adId,
        'action': 'delete',
      },
    );

    print('Delete ad request URL: $baseUrl/sell.php?token=$token&user_id=${widget.userId ?? '482'}');
    print('Delete ad request body: id=$adId, action=delete');
    print('Delete ad response status: ${response.statusCode}');
    print('Delete ad response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final jsonStart = response.body.indexOf('{');
        final jsonEnd = response.body.lastIndexOf('}') + 1;
        if (jsonStart != -1 && jsonEnd != -1) {
          final jsonString = response.body.substring(jsonStart, jsonEnd);
          final responseData = jsonDecode(jsonString);
          print('Decoded delete ad response: $responseData');
          if (responseData['status'] == 'true' && responseData['code'] != 4) {
            print('Deleted ad $adId via API');
            await Future.delayed(const Duration(milliseconds: 100));
            await _loadAds();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ad deleted successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            throw Exception(responseData['data'] ?? 'Failed to delete ad');
          }
        } else {
          throw Exception('No valid JSON found in response');
        }
      } catch (e) {
        print('Error parsing delete ad response: $e');
        print('Raw response: ${response.body}');
        throw Exception('Invalid response format: $e');
      }
    } else {
      throw Exception('Failed to delete ad: ${response.statusCode} - ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Error deleting ad: $e');
    setState(() {
      errorMessage = 'Error deleting ad: $e';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error deleting ad: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

 Widget _buildAdCard(Map<String, dynamic> ad) {
  final imageUrl = ad['image'] != null && (ad['image'] as String).isNotEmpty
      ? 'https://lelamonline.com/admin/${ad['image']}'
      : null;
  final isExpanded = _expandedImages[ad['id']] ?? false;

  print('Ad ${ad['id']}: imageUrl=$imageUrl, isExpanded=$isExpanded');

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
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ad['status'] == '0' ? 'Pending' : 'Approved',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.remove_red_eye, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text('${ad['visiter_count'] ?? 0}', style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 12),
              Icon(Icons.comment, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              const Text('0', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                onSelected: (value) {
                  if (value == 'edit') {
                    context.pushNamed(
                      RouteNames.adPostPage,
                      extra: {
                        'userId': widget.userId ?? '482',
                        'categoryId': ad['category_id']?.toString() ?? '',
                        'adData': ad,
                      },
                    );
                    print('Navigating to edit ad ${ad['id']} with categoryId ${ad['category_id']}');
                  } else if (value == 'delete') {
                    _deleteAd(ad['id'] as String);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedImages[ad['id']] = !isExpanded;
                print('Toggled image expansion for ad ${ad['id']}: ${!isExpanded}');
              });
            },
            child: Container(
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
                        'token': token,
                        'Cookie': 'PHPSESSID=$phpSessId',
                      },
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) {
                        print('Error loading image for ad ${ad['id']}: $error');
                        return const Center(
                          child: Icon(Icons.broken_image, size: 40, color: Colors.red),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 40, color: Colors.brown),
                    ),
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
                      ad['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    _adDetail('App ID', ad['id'] as String),
                    _adDetail('Posted Date', _formatDate(ad['created_on'] as String)),
                    _adDetail('Exp Date', _formatExpDate(ad['created_on'] as String)),
                    _adDetail('Price', ad['price'] as String, highlight: true),
                    _adDetail('Category', _getCategoryName(ad['category_id'] as String)),
                    _adDetail('Item In', 'Market Place'),
                    _adDetail('Auction Attempt', ad['auction_attempt'] ?? '0/3'),
                    _adDetail('Auction Price', ad['auction_starting_price'] ?? 'xxxx*'),
                    _adDetail('Meetings Done', '0'),
                    _adDetail('Location', ad['district'] ?? 'Unknown'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                  label: const Text('Call Support', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          if (ad['rejectionMsg'] != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                ad['rejectionMsg'] as String,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const TabBarWidget(),
        ],
      ),
    ),
  );
}

  Widget _adDetail(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: highlight ? Colors.green : Colors.black87,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
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
      final parsedDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(date);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  String _formatExpDate(String createdOn) {
    try {
      final parsedDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(createdOn);
      final expDate = parsedDate.add(const Duration(days: 30));
      return DateFormat('dd-MM-yyyy').format(expDate);
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadAds, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (ads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No ads found'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadAds, child: const Text('Refresh')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAds,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: ads.length,
        itemBuilder: (context, index) {
          final ad = ads[index];
          return _buildAdCard(ad);
        },
      ),
    );
  }
}
