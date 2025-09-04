import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/selling_status/tab_bar_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> adStrings = prefs.getStringList('userAds') ?? [];

      print('Found ${adStrings.length} ads in SharedPreferences');

      final List<Map<String, dynamic>> savedAds = [];
      for (var adString in adStrings) {
        try {
          final ad = jsonDecode(adString) as Map<String, dynamic>;
          if (ad['userId'] == widget.userId) {
            savedAds.add(ad);
            _expandedImages[ad['appId']] = false; // Initialize expanded state
          }
        } catch (e) {
          print('Error decoding ad: $e');
        }
      }

      print('Found ${savedAds.length} ads for user ${widget.userId}');

      if (widget.adData != null) {
        final passedAdId = widget.adData!['appId'];
        final isAlreadySaved = savedAds.any((ad) => ad['appId'] == passedAdId);

        if (!isAlreadySaved) {
          print('Adding passed ad data: ${widget.adData}');
          savedAds.add(widget.adData!);
          _expandedImages[widget.adData!['appId']] = false;
        } else {
          print('Passed ad already exists in saved ads');
        }
      }

      // Sort ads by postedDate in descending order (newest first)
      final dateFormat = DateFormat('dd-MM-yyyy');
      savedAds.sort((a, b) {
        try {
          final dateA = dateFormat.parse(a['postedDate'] as String);
          final dateB = dateFormat.parse(b['postedDate'] as String);
          return dateB.compareTo(dateA); // Newest first
        } catch (e) {
          print('Error parsing dates for sorting: $e');
          return 0; // Keep original order if parsing fails
        }
      });

      setState(() {
        ads = savedAds;
      });

      print('Total ads after loading: ${ads.length}');
    } catch (e) {
      print('Error loading ads: $e');
      errorMessage = 'Error loading ads: $e';
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _deleteAd(String adId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> adStrings = prefs.getStringList('userAds') ?? [];

      // Remove the ad with the given adId
      adStrings.removeWhere((adString) {
        try {
          final ad = jsonDecode(adString) as Map<String, dynamic>;
          return ad['appId'] == adId;
        } catch (e) {
          return false;
        }
      });

      await prefs.setStringList('userAds', adStrings);
      print('Deleted ad $adId from SharedPreferences');

      // Reload ads to update UI
      await _loadAds();

      Fluttertoast.showToast(
        msg: 'Ad deleted successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      print('Error deleting ad: $e');
      Fluttertoast.showToast(
        msg: 'Error deleting ad: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  DecorationImage? _getImageDecoration(Map<String, dynamic> ad, int imageIndex) {
    // Prioritize imagePathList (preferred for storage efficiency)
    if (ad['imagePathList'] != null && (ad['imagePathList'] as List).isNotEmpty) {
      final imageList = ad['imagePathList'] as List;
      if (imageIndex < imageList.length) {
        final file = File(imageList[imageIndex] as String);
        if (file.existsSync()) {
          return DecorationImage(
            image: FileImage(file),
            fit: BoxFit.cover,
          );
        } else {
          print('Image file not found: ${imageList[imageIndex]}');
        }
      }
    }

    // Fallback to imageBase64List
    if (ad['imageBase64List'] != null && (ad['imageBase64List'] as List).isNotEmpty) {
      final imageList = ad['imageBase64List'] as List;
      if (imageIndex < imageList.length) {
        try {
          final imageBytes = base64Decode(imageList[imageIndex] as String);
          return DecorationImage(
            image: MemoryImage(imageBytes),
            fit: BoxFit.cover,
          );
        } catch (e) {
          print('Error decoding base64 image at index $imageIndex: $e');
        }
      }
    }

    // Fallback for single image (backward compatibility)
    if (imageIndex == 0) {
      if (ad['imagePath'] != null && (ad['imagePath'] as String).isNotEmpty) {
        final file = File(ad['imagePath'] as String);
        if (file.existsSync()) {
          return DecorationImage(
            image: FileImage(file),
            fit: BoxFit.cover,
          );
        } else {
          print('Image file not found: ${ad['imagePath']}');
        }
      }
      if (ad['imageBase64'] != null && (ad['imageBase64'] as String).isNotEmpty) {
        try {
          final imageBytes = base64Decode(ad['imageBase64'] as String);
          return DecorationImage(
            image: MemoryImage(imageBytes),
            fit: BoxFit.cover,
          );
        } catch (e) {
          print('Error decoding single base64 image: $e');
        }
      }
    }

    return null;
  }

  Widget _getImagePlaceholder(Map<String, dynamic> ad, int imageIndex) {
    final hasImages =
        (ad['imagePathList'] != null && imageIndex < (ad['imagePathList'] as List).length) ||
        (ad['imageBase64List'] != null && imageIndex < (ad['imageBase64List'] as List).length) ||
        (imageIndex == 0 &&
            ((ad['imagePath'] != null && (ad['imagePath'] as String).isNotEmpty) ||
             (ad['imageBase64'] != null && (ad['imageBase64'] as String).isNotEmpty)));

    if (hasImages) {
      return const SizedBox.shrink();
    }

    return const Center(
      child: Icon(
        Icons.image,
        size: 40,
        color: Colors.brown,
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    // Calculate image count
    int imageCount = 0;
    if (ad['imagePathList'] != null && (ad['imagePathList'] as List).isNotEmpty) {
      imageCount = (ad['imagePathList'] as List).length;
    } else if (ad['imageBase64List'] != null && (ad['imageBase64List'] as List).isNotEmpty) {
      imageCount = (ad['imageBase64List'] as List).length;
    } else if (ad['imagePath'] != null || ad['imageBase64'] != null) {
      imageCount = 1; // Single image for backward compatibility
    }

    final coverImageIndex = ad['coverImageIndex'] != null ? ad['coverImageIndex'] as int : 0;
    final isExpanded = _expandedImages[ad['appId']] ?? false;

    print('Ad ${ad['appId']}: imageCount=$imageCount, coverImageIndex=$coverImageIndex, isExpanded=$isExpanded');

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
                    ad['status'] as String,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.remove_red_eye, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${ad['views']}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 12),
                Icon(Icons.comment, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${ad['comments']}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  onSelected: (value) {
                    if (value == 'edit') {
                      // Navigate to AdPostForm with categoryId and adData
                      context.pushNamed(
                        RouteNames.adPostPage,
                        extra: {
                          'userId': widget.userId ?? 'Unknown',
                          'categoryId': ad['categoryId']?.toString() ?? '', // Ensure categoryId is passed
                          'adData': ad, // Pass full ad details for editing
                        },
                      );
                      print('Navigating to edit ad ${ad['appId']} with categoryId ${ad['categoryId']}');
                    } else if (value == 'delete') {
                      _deleteAd(ad['appId'] as String);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Show cover image or all images based on expanded state
            GestureDetector(
              onTap: () {
                setState(() {
                  _expandedImages[ad['appId']] = !isExpanded;
                  print('Toggled image expansion for ad ${ad['appId']}: ${!isExpanded}');
                });
              },
              child: isExpanded && imageCount > 1
                  ? SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageCount,
                        itemBuilder: (context, index) {
                          if (index >= imageCount) {
                            return const SizedBox.shrink(); // Prevent range error
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Container(
                              width: 110,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.brown.shade100,
                                borderRadius: BorderRadius.circular(8),
                                image: _getImageDecoration(ad, index),
                              ),
                              child: _getImagePlaceholder(ad, index),
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 110,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.brown.shade100,
                        borderRadius: BorderRadius.circular(8),
                        image: _getImageDecoration(ad, coverImageIndex < imageCount ? coverImageIndex : 0),
                      ),
                      child: _getImagePlaceholder(ad, coverImageIndex < imageCount ? coverImageIndex : 0),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _adDetail('App ID', ad['appId'] as String),
                      _adDetail('Posted Date', ad['postedDate'] as String),
                      _adDetail('Exp Date', ad['expDate'] as String),
                      _adDetail('Price', ad['price'] as String, highlight: true),
                      _adDetail('Category', ad['category'] as String),
                      _adDetail('Item In', ad['itemIn'] as String),
                      _adDetail('Auction Attempt', ad['auctionAttempt'] as String),
                      _adDetail('Auction Price', ad['auctionPrice'] as String),
                      _adDetail('Meetings Done', ad['meetingsDone'] as String),
                      _adDetail('Location', ad['location'] as String),
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
                      shape: RoundedRectangleBorder(
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
            if (ad['rejectionMsg'] != null) ...[
              const SizedBox(height: 8),
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
            TabBarWidget(),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    if (ads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No ads found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAds,
              child: const Text('Refresh'),
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
}