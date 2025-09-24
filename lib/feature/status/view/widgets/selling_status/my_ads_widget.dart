import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/seller_tab_bar_widget.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:developer' as developer;

class MyAdsWidget extends StatefulWidget {
  final Map<String, dynamic>? adData;

  const MyAdsWidget({super.key, this.adData});

  @override
  State<MyAdsWidget> createState() => _MyAdsWidgetState();
}

class _MyAdsWidgetState extends State<MyAdsWidget> {
  List<Map<String, dynamic>> ads = [];
  bool isLoading = true;
  String? errorMessage;
  Map<String, bool> _expandedImages = {};
  Map<String, String> _adStatuses = {};

  late final LoggedUserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
    _loadAds();
  }

Future<void> _loadAds() async {
  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  // If adData is passed, add it to the ads list immediately
  if (widget.adData != null) {
    setState(() {
      final passedAdId = widget.adData!['id'];
      if (!ads.any((ad) => ad['id'] == passedAdId)) {
        ads.add(widget.adData!);
        _expandedImages[passedAdId] = false;
        print('Added passed adData to ads list: ${widget.adData}');
      } else {
        final adIndex = ads.indexWhere((ad) => ad['id'] == passedAdId);
        ads[adIndex] = {...ads[adIndex], ...widget.adData!};
        print('Updated existing ad with passed adData: ${widget.adData}');
      }
      isLoading = false; // Show the ad immediately
    });
  }

  // Fetch ads from API with a slight delay to allow server processing
  await Future.delayed(const Duration(seconds: 2)); // Adjust delay as needed
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/sell.php?token=$token&user_id=${_userProvider.userId}'),
      headers: {'token': token},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('API response: $responseData');
      if (responseData['status'] == 'true' && responseData['data'] is List) {
        final fetchedAds = List<Map<String, dynamic>>.from(responseData['data']);

        // Merge passed adData with fetched ads
        if (widget.adData != null) {
          final passedAdId = widget.adData!['id'];
          final isAlreadyIncluded = fetchedAds.any((ad) => ad['id'] == passedAdId);
          if (!isAlreadyIncluded) {
            fetchedAds.add(widget.adData!);
            print('Added passed adData to fetched ads: ${widget.adData}');
          } else {
            final adIndex = fetchedAds.indexWhere((ad) => ad['id'] == passedAdId);
            fetchedAds[adIndex] = {...fetchedAds[adIndex], ...widget.adData!};
            print('Updated fetched ad with passed adData: ${widget.adData}');
          }
        }

        // Sort ads by created_on date (newest first)
        fetchedAds.sort((a, b) {
          try {
            final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
            final dateA = dateFormat.parse(a['created_on'] as String);
            final dateB = dateFormat.parse(b['created_on'] as String);
            return dateB.compareTo(dateA);
          } catch (e) {
            print('Error parsing dates for sorting: $e');
            return 0;
          }
        });

        setState(() {
          ads = fetchedAds;
          _expandedImages = {for (var ad in ads) ad['id']: false};
          isLoading = false;
        });
        print('Fetched ${ads.length} ads');

        // Check approval and status for each ad
        for (var ad in ads) {
          if (ad['admin_approval'] == '0') {
            _checkApprovalStatus(ad['id']);
          }
          _loadAdStatus(ad['id']);
        }
      } else {
        throw Exception(responseData['message'] ?? 'No ads found');
      }
    } else {
      throw Exception('Failed to fetch ads: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Error fetching ads: $e');
    setState(() {
      errorMessage = '$e';
      isLoading = false;
    });
  }
}

  Future<void> _loadAdStatus(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sell-post-status.php?token=$token&post_id=$postId'),
        headers: {'token': token},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Status response for post $postId: $responseData');
        if (responseData['status'] == 'true') {
          setState(() {
            _adStatuses[postId] = responseData['data'] ?? 'Unknown';
          });
        }
      }
    } catch (e) {
      print('Error loading status for post $postId: $e');
    }
  }

  Future<void> _checkApprovalStatus(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sell-post-status.php?token=$token&post_id=$postId'),
        headers: {'token': token},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Approval status response for post $postId: $responseData');
        if (responseData['status'] == 'true' && responseData['data'] is List) {
          final statusData = responseData['data'][0];
          if (statusData['admin_approval'] == '1') {
            setState(() {
              final adIndex = ads.indexWhere((ad) => ad['id'] == postId);
              if (adIndex != -1) {
                ads[adIndex]['admin_approval'] = '1';
                ads[adIndex]['status'] = '1';
              }
            });
            Fluttertoast.showToast(
              msg: 'Ad $postId has been approved',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
            _checkAuctionTerms(postId);
          }
        }
      }
    } catch (e) {
      print('Error checking approval status for post $postId: $e');
    }
  }

  Future<void> _checkAuctionTerms(String postId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/sell-check-auction-terms-accept.php?token=$token&post_id=$postId',
        ),
        headers: {'token': token},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Auction terms response for post $postId: $responseData');
        if (responseData['status'] == 'true' && responseData['data'] is List) {
          final termsData = responseData['data'][0];
          if (termsData['check'] == 0) {
            _promptAcceptTerms(postId);
          } else {
            _moveToAuction(postId);
          }
        }
      }
    } catch (e) {
      print('Error checking auction terms for post $postId: $e');
    }
  }

  Future<void> _promptAcceptTerms(String postId) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Accept Auction Terms'),
            content: const Text(
              'Please accept the terms and conditions to proceed with the auction.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _acceptTerms(postId);
                },
                child: const Text('Accept'),
              ),
            ],
          ),
    );
  }

  Future<void> _acceptTerms(String postId) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/seller-accept-terms.php?token=$token&post_id=$postId&user_id=${_userProvider.userId}',
        ),
        headers: {
          'token': token,

          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Accept terms response for post $postId: $responseData');
        if (responseData['status'] == 'true') {
          Fluttertoast.showToast(
            msg: 'Terms accepted for ad $postId',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
          _moveToAuction(postId);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to accept terms');
        }
      } else {
        throw Exception('Failed to accept terms: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error accepting terms for post $postId: $e');
      Fluttertoast.showToast(
        msg: 'Error accepting terms: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _moveToAuction(String postId) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/sell-move-to-auction.php?token=$token&post_id=$postId',
        ),
        headers: {
          'token': token,

          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Move to auction response for post $postId: $responseData');
        if (responseData['status'] == 'true') {
          setState(() {
            final adIndex = ads.indexWhere((ad) => ad['id'] == postId);
            if (adIndex != -1) {
              ads[adIndex]['if_auction'] = '1';
              ads[adIndex]['auction_status'] = '1';
            }
          });
          Fluttertoast.showToast(
            msg: 'Ad $postId moved to auction',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to move to auction',
          );
        }
      } else {
        throw Exception('Failed to move to auction: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error moving to auction for post $postId: $e');
      Fluttertoast.showToast(
        msg: 'Error moving to auction: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _markAsDelivered(String postId) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/sell-delivered-marked-as-sold.php?token=$token&post_id=$postId',
        ),
        headers: {
          'token': token,

          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Mark as delivered response for post $postId: $responseData');
        if (responseData['status'] == 'true') {
          setState(() {
            final adIndex = ads.indexWhere((ad) => ad['id'] == postId);
            if (adIndex != -1) {
              ads[adIndex]['if_sold'] = '1';
              ads[adIndex]['status'] = '2';
            }
          });
          Fluttertoast.showToast(
            msg: 'Ad $postId marked as delivered',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to mark as delivered',
          );
        }
      } else {
        throw Exception(
          'Failed to mark as delivered: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error marking ad $postId as delivered: $e');
      Fluttertoast.showToast(
        msg: 'Error marking as delivered: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _deleteAd(String adId) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/sell.php?token=$token&user_id=${_userProvider.userId}',
        ),
        headers: {
          'token': token,

          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'id': adId, 'action': 'delete'},
      );

      print(
        'Delete ad request URL: $baseUrl/sell.php?token=$token&user_id=${_userProvider.userId}',
      );
      print('Delete ad request body: id=$adId, action=delete');
      print('Delete ad response status: ${response.statusCode}');
      print('Delete ad response body: ${response.body}');

      if (response.statusCode == 200) {
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
            Fluttertoast.showToast(
              msg: 'Ad deleted successfully',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
          } else {
            throw Exception(responseData['data'] ?? 'Failed to delete ad');
          }
        } else {
          throw Exception('No valid JSON found in response');
        }
      } else {
        throw Exception(
          'Failed to delete ad: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error deleting ad: $e');
      setState(() {
        errorMessage = 'Error deleting ad: $e';
      });
      Fluttertoast.showToast(
        msg: 'Error deleting ad: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    String? imageUrl;
    if (ad['image'] != null && (ad['image'] as String).isNotEmpty) {
      if ((ad['image'] as String).startsWith('http')) {
        imageUrl = '$getImagePostImageUrl${ad['image'] as String}';
      } else {
        imageUrl =
            '$getImagePostImageUrl${ad['image'].startsWith('/') ? ad['image'].substring(1) : ad['image']}';
      }
    } else {
      imageUrl = '$getImagePostImageUrl${ad['id']}.jpg';
      print(
        'Warning: Image field empty for ad ${ad['id']}, using fallback URL: $imageUrl',
      );
    }
    final isExpanded = _expandedImages[ad['id']] ?? false;

    print(imageUrl);

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        ad['status'] == '0'
                            ? Colors.red.shade100
                            : ad['status'] == '1'
                            ? Colors.blue
                            : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ad['status'] == '0'
                        ? 'Pending'
                        : ad['status'] == '1'
                        ? 'Live'
                        : 'Sold',
                    style: TextStyle(
                      color:
                          ad['status'] == '0'
                              ? Colors.red
                              : ad['status'] == '1'
                              ? Colors.white
                              : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.remove_red_eye,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${ad['visiter_count'] ?? 0}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 12),
                Icon(Icons.comment, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                const Text('0', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 12),
                // PopupMenuButton<String>(
                //   icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                //   onSelected: (value) {
                //     if (value == 'edit') {
                //       context.pushNamed(
                //         RouteNames.adPostPage,
                //         extra: {
                //           'categoryId': ad['category_id']?.toString() ?? '',
                //           'adData': ad,
                //         },
                //       );

                //       print(
                //         'Navigating to edit ad ${ad['id']} with categoryId ${ad['category_id']}',
                //       );
                //     } else if (value == 'delete') {
                //       _deleteAd(ad['id'] as String);
                //     } else if (value == 'mark_delivered') {
                //       _markAsDelivered(ad['id'] as String);
                //     } else if (value == 'check_auction') {
                //       _checkAuctionTerms(ad['id'] as String);
                //     }
                //   },
                //   itemBuilder:
                //       (context) => [
                //         const PopupMenuItem(value: 'edit', child: Text('Edit')),
                //         const PopupMenuItem(
                //           value: 'delete',
                //           child: Text('Delete'),
                //         ),
                //         if (ad['status'] == '1')
                //           const PopupMenuItem(
                //             value: 'mark_delivered',
                //             child: Text('Mark as Delivered'),
                //           ),
                //         if (ad['status'] == '1' && ad['if_auction'] == '0')
                //           const PopupMenuItem(
                //             value: 'check_auction',
                //             child: Text('Move to Auction'),
                //           ),
                //       ],
                // ),
              ],
            ),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _adDetail('App ID', ad['id'] as String),
                      _adDetail(
                        'Posted Date',
                        _formatDate(ad['created_on'] as String),
                      ),
                      _adDetail(
                        'Exp Date',
                        _formatExpDate(ad['created_on'] as String),
                      ),
                      _adDetail('Price', '₹${ad['price']}', highlight: true),
                      _adDetail(
                        'Category',
                        _getCategoryName(ad['category_id'] as String),
                      ),
                      _adDetail(
                        'Item In',
                        ad['if_auction'] == '1' ? 'Auction' : 'Market Place',
                      ),
                      _adDetail(
                        'Auction Attempt',
                        ad['auction_attempt'] ?? '0/3',
                      ),
                      _adDetail(
                        'Auction Price',
                        ad['auction_starting_price'] ?? 'N/A',
                      ),
                      _adDetail('Meetings Done', '0'),
                      _adDetail('Location', ad['district'] ?? 'Unknown'),
                    ],
                  ),
                ),
                Column(
                  children: [

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedImages[ad['id']] = !isExpanded;
                          print(
                            'Toggled image expansion for ad ${ad['id']}: ${!isExpanded}',
                          );
                        });
                      },
                      child: Container(
                        width: 120,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.brown.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            imageUrl != null
                                ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  httpHeaders: {'token': token},
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                  errorWidget: (context, url, error) {
                                    print(
                                      'Error loading image for ad ${ad['id']}: $error',
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
                    ),
                  ],
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
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: () {},
                    icon: const Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Call Support',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Container(color: Colors.grey, height: 1.5, width: double.infinity),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (ad['rejectionMsg'] != null) ...[
                  const SizedBox(height: 1),
                  Center(
                    child: Text(
                      ad['rejectionMsg'] as String,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                SizedBox(width: 1),
                if (_adStatuses[ad['id']] != null &&
                    _adStatuses[ad['id']]!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0.0),
                    child: Center(
                      child: Text(
                        _adStatuses[ad['id']]!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
             PopupMenuButton<String>(
  icon: Icon(Icons.menu, color: Colors.grey.shade600),
  position: PopupMenuPosition.over,
  onSelected: (value) {
    if (value == 'edit') {
      context.pushNamed(
        RouteNames.adPostPage,
        extra: {
          'categoryId': ad['category_id']?.toString() ?? '',
          'postId': ad['id']?.toString() ?? '', 
          'adData': ad,
        },
      );
      developer.log(
        'Navigating to edit ad ${ad['id']} with categoryId ${ad['category_id']}, postId: ${ad['id']}',
      );
    } else if (value == 'delete') {
      _deleteAd(ad['id'] as String);
    } else if (value == 'mark_delivered') {
      _markAsDelivered(ad['id'] as String);
    } else if (value == 'check_auction') {
      _checkAuctionTerms(ad['id'] as String);
    }
  },
  itemBuilder: (context) => [
    const PopupMenuItem(value: 'edit', child: Text('Edit')),
    const PopupMenuItem(value: 'delete', child: Text('Delete')),
    if (ad['status'] == '1')
      const PopupMenuItem(value: 'mark_delivered', child: Text('Mark as Delivered')),
    if (ad['status'] == '1' && ad['if_auction'] == '0')
      const PopupMenuItem(value: 'check_auction', child: Text('Move to Auction')),
  ],
),
              ],
            ),
            Container(color: Colors.grey, height: 1.5, width: double.infinity),

            SizedBox(
              height: 250,
              child: SellerTabBarWidget(adData: ad, postId: ad['id'] as String),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerAdCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
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
                    width: 80,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const Spacer(),
                  Container(width: 18, height: 18, color: Colors.grey[300]),
                  const SizedBox(width: 4),
                  Container(width: 20, height: 13, color: Colors.grey[300]),
                  const SizedBox(width: 12),
                  Container(width: 18, height: 18, color: Colors.grey[300]),
                  const SizedBox(width: 4),
                  Container(width: 20, height: 13, color: Colors.grey[300]),
                  const SizedBox(width: 12),
                  Container(width: 24, height: 24, color: Colors.grey[300]),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: 110,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 6),
                  for (var i = 0; i < 6; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 12,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 120,
                            height: 12,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 36,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adDetail(String label, String value, {bool highlight = false}) {
    const double labelWidth =95;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: labelWidth,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            ':',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: highlight ? Colors.green : Colors.black87,
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
      return date;
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
    if (isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 3, // Show 3 shimmer placeholders
        itemBuilder: (context, index) => _buildShimmerAdCard(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No ads found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (ads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 64, color: Colors.grey),
            const SizedBox(height: 16),

            Text(
              'No ads found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
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

  @override
  void dispose() {
    super.dispose();
  }
}
