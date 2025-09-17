import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/model/user_model.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/Support/views/support_page.dart';
import 'package:lelamonline_flutter/feature/categories/models/seller_comment_model.dart';
import 'package:lelamonline_flutter/feature/categories/seller%20info/seller_info_page.dart'
    hide token, baseUrl;
import 'package:lelamonline_flutter/feature/chat/views/chat_page.dart';
import 'package:lelamonline_flutter/feature/chat/views/widget/chat_dialog.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/buying_status_page.dart';
import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:lelamonline_flutter/utils/palette.dart';
import 'package:lelamonline_flutter/utils/review_dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketPlaceProductDetailsPage extends StatefulWidget {
  final dynamic product;
  final bool isAuction;

  const MarketPlaceProductDetailsPage({
    super.key,
    required this.product,
    this.isAuction = false,
  });

  @override
  State<MarketPlaceProductDetailsPage> createState() =>
      _MarketPlaceProductDetailsPageState();
}

class _MarketPlaceProductDetailsPageState
    extends State<MarketPlaceProductDetailsPage> {
  bool isLoadingDetails = false;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  final TransformationController _transformationController =
      TransformationController();
  bool _isFavorited = false;
  bool _isBidDialogOpen = false;
  bool _isLoadingLocations = true;
  List<LocationData> _locations = [];

  String sellerName = 'Unknown';
  String? sellerProfileImage;
  int sellerNoOfPosts = 0;
  String sellerActiveFrom = 'N/A';
  bool isLoadingSeller = true;
  String sellerErrorMessage = '';

  double _minBidIncrement = 1000;
  bool _isLoadingBid = false;
  String _currentHighestBid = '0';
  bool _isLoadingGallery = true;
  List<String> _galleryImages = [];
  String _galleryError = '';
  late LoggedUserProvider _userProvider;

  SellerCommentsModel? sellerComments;
  bool isLoadingSellerComments = false;
  String sellerCommentsError = '';
  List<SellerComment> uniqueSellerComments = [];

  String? _bannerImageUrl;
  bool _isLoadingBanner = false;
  String _bannerError = '';

  bool _isMeetingDialogOpen = false;
  bool _isSchedulingMeeting = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
      'MarketPlaceProductDetailsPage - initState: Starting initialization',
    );
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
    debugPrint(
      'MarketPlaceProductDetailsPage - initState: userProvider initialized, userId=${_userProvider.userId}',
    );

    try {
      _fetchLocations();
      debugPrint(
        'MarketPlaceProductDetailsPage - initState: _fetchLocations completed',
      );
    } catch (e, stackTrace) {
      debugPrint('Error in _fetchLocations: $e\n$stackTrace');
    }

    try {
      _fetchSellerComments();
      debugPrint(
        'MarketPlaceProductDetailsPage - initState: _fetchSellerComments completed',
      );
    } catch (e, stackTrace) {
      debugPrint('Error in _fetchSellerComments: $e\n$stackTrace');
    }

    try {
      _fetchSellerInfo();
      debugPrint(
        'MarketPlaceProductDetailsPage - initState: _fetchSellerInfo completed',
      );
    } catch (e, stackTrace) {
      debugPrint('Error in _fetchSellerInfo: $e\n$stackTrace');
    }

    try {
      _checkShortlistStatus();
      debugPrint(
        'MarketPlaceProductDetailsPage - initState: _checkShortlistStatus completed',
      );
    } catch (e, stackTrace) {
      debugPrint('Error in _checkShortlistStatus: $e\n$stackTrace');
    }

    try {
      _fetchGalleryImages();
      debugPrint(
        'MarketPlaceProductDetailsPage - initState: _fetchGalleryImages completed',
      );
    } catch (e, stackTrace) {
      debugPrint('Error in _fetchGalleryImages: $e\n$stackTrace');
    }

    try {
      _fetchBannerImage();
      debugPrint(
        'MarketPlaceProductDetailsPage - initState: _fetchBannerImage completed',
      );
    } catch (e, stackTrace) {
      debugPrint('Error in _fetchBannerImage: $e\n$stackTrace');
    }
  }

  Future<void> _fetchSellerComments() async {
    setState(() {
      isLoadingSellerComments = true;
      sellerCommentsError = '';
    });

    try {
      final headers = {'token': token};
      final url = '$baseUrl/post-attribute-values.php?token=$token&post_id=$id';
      debugPrint('Fetching seller comments: $url');

      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('Seller comments API response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        setState(() {
          sellerComments = SellerCommentsModel.fromJson(responseData);

          final Map<String, SellerComment> uniqueAttributes = {};
          final List<SellerComment> orderedComments = [];

          for (var comment in sellerComments!.data) {
            final key = comment.attributeName.toLowerCase().replaceAll(
              RegExp(r'\s+'),
              '',
            );
            if (!uniqueAttributes.containsKey(key)) {
              uniqueAttributes[key] = comment;
              orderedComments.add(comment);
            }
          }

          uniqueSellerComments = orderedComments;
          debugPrint(
            'Ordered uniqueSellerComments: ${uniqueSellerComments.map((c) => "${c.attributeName}: ${c.attributeValue}").toList()}',
          );

          isLoadingSellerComments = false;
        });
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching seller comments: $e');
      setState(() {
        sellerCommentsError = 'Failed to load seller comments: $e';
        isLoadingSellerComments = false;
      });
    }
  }

  Future<void> _fetchGalleryImages() async {
    try {
      setState(() {
        _isLoadingGallery = true;
        _galleryError = '';
      });

      final headers = {
        'token': token,
        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
      };
      final url = '$baseUrl/post-gallery.php?token=$token&post_id=$id';
      debugPrint('Fetching gallery: $url');

      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('Gallery API response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        debugPrint('Parsed responseData type: ${responseData.runtimeType}');

        if (responseData['status'] == 'true' &&
            responseData['data'] is List &&
            (responseData['data'] as List).isNotEmpty) {
          _galleryImages =
              (responseData['data'] as List)
                  .map(
                    (item) =>
                        'https://lelamonline.com/admin/${item['image'] ?? ''}',
                  )
                  .where((img) => img.isNotEmpty && img.contains('uploads/'))
                  .toList();
          debugPrint(
            'Fetched ${_galleryImages.length} gallery images: $_galleryImages',
          );
        } else {
          throw Exception(
            'Invalid gallery data: Status is ${responseData['status']}, data is ${responseData['data']?.runtimeType ?? 'null'}',
          );
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching gallery: $e');
      setState(() {
        _galleryError = 'Failed to load gallery: $e';
      });
    } finally {
      setState(() {
        _isLoadingGallery = false;
      });
    }
  }

  Future<void> _fetchCurrentHighestBid() async {
    try {
      setState(() {
        _isLoadingBid = true;
      });

      final headers = {'token': token};
      final url =
          '$baseUrl/current-higest-bid-for-post.php?token=$token&post_id=$id';
      debugPrint('Fetching highest bid: $url');
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('Full API response body: $responseBody');
      debugPrint('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        debugPrint('Parsed response data: $responseData');

        if (responseData['status'] == true) {
          final dataValue = (responseData['data']?.toString() ?? '0').trim();
          final parsed = double.tryParse(dataValue);
          if (parsed != null) {
            setState(() {
              _currentHighestBid = parsed.toString();
            });
            debugPrint('Successfully fetched highest bid: $dataValue');
          } else {
            debugPrint(
              'API returned non-numeric data (possible error): $dataValue',
            );
            setState(() {
              _currentHighestBid = 'Error: $dataValue';
            });
          }
        } else {
          debugPrint('API status false: ${responseData['data']}');
          setState(() {
            _currentHighestBid = '0';
          });
        }
      } else {
        debugPrint(
          'HTTP error: ${response.statusCode} - ${response.reasonPhrase}',
        );
        setState(() {
          _currentHighestBid = '0';
        });
      }
    } catch (e) {
      debugPrint('Exception in fetch highest bid: $e');
      setState(() {
        _currentHighestBid = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoadingBid = false;
      });
    }
  }

  Future<void> _checkShortlistStatus() async {
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);

    try {
      final response = await ApiService().get(
        url: shortlist,
        queryParams: {"user_id": _userProvider.userId, "post_id": id},
      );

      if (response['status'] == 'true' && response['data'].isNotEmpty) {
        setState(() {
          _isFavorited = true;
        });
      } else {
        setState(() {
          _isFavorited = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking shortlist status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_userProvider.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add to shortlist'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final headers = {'token': token};
      final url =
          '$baseUrl/add-to-shortlist.php?token=$token&user_id=${_userProvider.userId}&post_id=$id';
      debugPrint('Adding to shortlist: $url');

      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('add-to-shortlist.php response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        final statusRaw = responseData['status'];
        final bool statusIsTrue =
            statusRaw == true || statusRaw == 'true' || statusRaw == '1';

        if (statusIsTrue) {
          setState(() {
            _isFavorited = !_isFavorited; // toggle state
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isFavorited ? 'Added to shortlist' : 'Removed from shortlist',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // ✅ Optional: also update global state / provider here
          // context.read<ShortlistProvider>().refresh();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed: ${responseData['message'] ?? 'Unknown error'}',
              ),
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
    if (_userProvider.userId == null) {
      throw Exception('Please log in to place a bid');
    }

    try {
      final headers = {
        'token': token,
        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
      };
      final url =
          '$baseUrl/place-bid.php?token=$token&post_id=$id&user_id=${_userProvider.userId}&bidamt=$bidAmount';
      debugPrint('Placing bid: $url');
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('place-bid.php response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        debugPrint('Parsed place-bid response: $responseData');
        final statusRaw = responseData['status'];
        final bool statusIsTrue =
            statusRaw == true || statusRaw == 'true' || statusRaw == '1';

        final dataMessage = responseData['data']?.toString() ?? '';
        final bool dataLooksLikeSuccess =
            dataMessage.toLowerCase().contains('success') ||
            dataMessage.toLowerCase().contains('placed successfully');
        if (statusIsTrue || dataLooksLikeSuccess) {
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

  Future<void> _fetchBannerImage() async {
    debugPrint('MarketPlaceProductDetailsPage - _fetchBannerImage: Starting');
    try {
      setState(() {
        _isLoadingBanner = true;
        _bannerError = '';
      });
      debugPrint(
        'MarketPlaceProductDetailsPage - _fetchBannerImage: Token=$token, BaseUrl=$baseUrl',
      );

      final headers = {
        'token': token,
        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
      };
      final url = '$baseUrl/post-ads-image.php?token=$token';
      debugPrint(
        'MarketPlaceProductDetailsPage - _fetchBannerImage: Fetching banner image: $url',
      );

      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint(
        'MarketPlaceProductDetailsPage - _fetchBannerImage: Banner API response (status: ${response.statusCode}): $responseBody',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        debugPrint(
          'MarketPlaceProductDetailsPage - _fetchBannerImage: Parsed banner response: $responseData',
        );

        if (responseData['status'] == 'true' && responseData['data'] != null) {
          final bannerImage = responseData['data']['inner_post_image'] ?? '';
          debugPrint(
            'MarketPlaceProductDetailsPage - _fetchBannerImage: Banner image path: $bannerImage',
          );
          setState(() {
            _bannerImageUrl =
                bannerImage.isNotEmpty
                    ? 'https://lelamonline.com/admin/$bannerImage'
                    : null;
            debugPrint(
              'MarketPlaceProductDetailsPage - _fetchBannerImage: Set _bannerImageUrl=$_bannerImageUrl',
            );
          });
        } else {
          throw Exception('Invalid banner data: ${responseData['data']}');
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint(
        'MarketPlaceProductDetailsPage - _fetchBannerImage: Error fetching banner image: $e\n$stackTrace',
      );
      setState(() {
        _bannerError = 'Failed to load banner: $e';
      });
    } finally {
      setState(() {
        _isLoadingBanner = false;
      });
      debugPrint(
        'MarketPlaceProductDetailsPage - _fetchBannerImage: Completed',
      );
    }
  }

  Widget _buildBannerAd() {
    debugPrint(
      'Building banner ad: isLoadingBanner=$_isLoadingBanner, bannerError=$_bannerError, bannerImageUrl=$_bannerImageUrl',
    );

    if (_isLoadingBanner) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_bannerError.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(_bannerError, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_bannerImageUrl == null || _bannerImageUrl!.isEmpty) {
      debugPrint('No banner image available');
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CachedNetworkImage(
        imageUrl: _bannerImageUrl!,
        width: double.infinity,
        height: 35,
        fit: BoxFit.fill,
        placeholder:
            (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget:
            (context, url, error) => const Center(
              child: Icon(Icons.error_outline, size: 50, color: Colors.red),
            ),
      ),
    );
  }

  void _showLoginPromptDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Login Required',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Please log in to $action.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.pushNamed(RouteNames.loginPage);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Log In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    );
  }

  void showProductBidDialog(BuildContext context) async {
    if (!_userProvider.isLoggedIn) {
      _showLoginPromptDialog(context, 'place a bid');
      return;
    }

    setState(() => _isBidDialogOpen = true);
    await _fetchCurrentHighestBid(); // Fetch the current highest bid
    final TextEditingController _bidController = TextEditingController();

    Future<void> _showResponseDialog(String message, bool isSuccess) {
      // Format the current highest bid
      final String formattedBid =
          _currentHighestBid.startsWith('Error')
              ? _currentHighestBid
              : '₹ ${NumberFormat('#,##0').format(double.tryParse(_currentHighestBid.replaceAll(',', ''))?.round() ?? 0)}';

      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              isSuccess ? 'Thank You' : 'Error',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                const Text(
                  'Last Highest Bid:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          _currentHighestBid.startsWith('Error')
                              ? Colors.red
                              : Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    formattedBid,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          _currentHighestBid.startsWith('Error')
                              ? Colors.red
                              : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (isSuccess) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BuyingStatusPage(),
                      ),
                    );
                  }
                },
                child: const Text('OK', style: TextStyle(color: Colors.grey)),
              ),
            ],
          );
        },
      );
    }

    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return WillPopScope(
          onWillPop: () async {
            return true;
          },
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
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
                      'Your Bid Amount *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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
                      Navigator.of(dialogContext).pop(null);
                    },
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.grey),
                    ),
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

                              setDialogState(() {
                                _isLoadingBid = true;
                              });

                              try {
                                FocusScope.of(dialogContext).unfocus();
                                final String responseMessage =
                                    await _saveBidData(bidAmount);
                                Navigator.of(dialogContext).pop({
                                  'success': true,
                                  'message': responseMessage,
                                });
                              } catch (e) {
                                Navigator.of(dialogContext).pop({
                                  'success': false,
                                  'message': 'Error placing bid: $e',
                                });
                              } finally {
                                setDialogState(() {
                                  _isLoadingBid = false;
                                });
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
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 200));
    FocusScope.of(context).unfocus();
    _bidController.dispose();

    if (result != null) {
      final bool ok = result['success'] == true;
      final String msg =
          result['message']?.toString() ??
          (ok ? 'Bid placed successfully' : 'Failed to place bid');
      await _showResponseDialog(msg, ok);
    }
    if (mounted) setState(() => _isBidDialogOpen = false);
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
          '$baseUrl/post-seller-information.php?token=$token&user_id=${widget.product.createdBy}',
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
    if (!_isLoadingGallery && _galleryImages.isNotEmpty) {
      return _galleryImages;
    }
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
                                fit: BoxFit.cover,
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
                                    onPressed: () => Navigator.pop(context),
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

  void _launchPhoneCall() async {
    const phoneNumber = 'tel:+1234567890'; // Replace with actual support number
    if (await canLaunch(phoneNumber)) {
      await launch(phoneNumber);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch phone call'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fixMeeting(DateTime selectedDate) async {
    if (!mounted) return;

    setState(() {
      _isSchedulingMeeting = true;
    });

    try {
      final headers = {'token': token};
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final url =
          '$baseUrl/post-fix-meeting.php?token=$token&post_id=$id&user_id=${_userProvider.userId}&meeting_date=$formattedDate';
      debugPrint('Scheduling meeting: $url');
      debugPrint(
        'User state before API call: isLoggedIn=${_userProvider.isLoggedIn}, userId=${_userProvider.userId}',
      );

      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('post-fix-meeting.php response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        debugPrint('Parsed response: $responseData');
        if (responseData['status'] == true) {
          // Show success snackbar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  responseData['data'] ?? 'Meeting scheduled successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Show confirmation dialog if still mounted
          if (mounted) {
            await _showMeetingConfirmationDialog(selectedDate);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to schedule meeting: ${responseData['data']}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.reasonPhrase}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error scheduling meeting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSchedulingMeeting = false;
        });
      }
      debugPrint(
        'User state after API call: isLoggedIn=${_userProvider.isLoggedIn}, userId=${_userProvider.userId}',
      );
    }
  }

  Future<void> _showMeetingConfirmationDialog(DateTime selectedDate) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Meeting Scheduled',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Your meeting is scheduled on ${DateFormat('dd/MM/yyyy').format(selectedDate)}. '
            'For further information, check My Bids in Status or call support.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BuyingStatusPage()),
                  );
                }
              },
              child: const Text(
                'Check Status',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: _launchPhoneCall, // Fixed: Correct method call
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Call Support',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    );
  }

  void _showMeetingDialog(BuildContext context) {
    if (!_userProvider.isLoggedIn) {
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
              title: Column(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Schedule Meeting',
                    style: TextStyle(fontSize: 24),
                  ),
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
            overflow: TextOverflow.fade,
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
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.right,
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

  Widget _buildQuestionsSection(BuildContext context, String id) {
    void _showLoginDialog() {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Login Required',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              content: const Text('Please log in to ask a question.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.pushNamed(RouteNames.loginPage);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Log In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
      );
    }

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
                final userProvider = Provider.of<LoggedUserProvider>(
                  context,
                  listen: false,
                );
                if (!userProvider.isLoggedIn) {
                  _showLoginDialog();
                } else {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => ReviewDialog(postId: id),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.question_answer, color: Colors.white, size: 20.0),
                  SizedBox(width: 8.0),
                  Text('Ask a question'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build seller comments section using the new API
  Widget _buildSellerCommentsSection() {
    if (isLoadingSellerComments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sellerCommentsError.isNotEmpty) {
      return Center(
        child: Text(
          sellerCommentsError,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (uniqueSellerComments.isEmpty) {
      return const Center(child: Text('No seller comments available'));
    }

    // Helper function to format attribute names (e.g., "no of owners" -> "No of Owners")
    String formatAttributeName(String name) {
      return name
          .split(' ')
          .map(
            (word) =>
                word.isNotEmpty
                    ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                    : '',
          )
          .join(' ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seller Comments',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Ensure the comments are rendered in the order of uniqueSellerComments
        ...uniqueSellerComments
            .map(
              (comment) => _buildSellerCommentItem(
                formatAttributeName(comment.attributeName),
                comment.attributeValue,
              ),
            )
            .toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                            if (_isLoadingGallery)
                              const Center(child: CircularProgressIndicator())
                            else if (_galleryError.isNotEmpty)
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 50,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _galleryError,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                    TextButton(
                                      onPressed: _fetchGalleryImages,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            else
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
                                    onTap:
                                        () => _showFullScreenGallery(context),
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
                            if (!_isLoadingGallery && _galleryError.isEmpty)
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
                              onPressed: () {
                                if (_isBidDialogOpen) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please close the bid dialog first',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(context);
                              },
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
                              icon: const Icon(
                                Icons.share,
                                color: Colors.white,
                              ),
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
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return ChatOptionsDialog(
                                      onChatWithSupport: () {
                                        // Navigator.push(
                                        //   context,
                                        //   MaterialPageRoute(
                                        //     builder:
                                        //         (context) => SupportTicketPage(

                                        //         ),
                                        //   ),
                                        // );
                                      },
                                      onChatWithSeller: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => ChatPage(
                                                  listenerId:
                                                      widget.product.createdBy,
                                                  listenerName: sellerName,
                                                  listenerImage:
                                                      sellerProfileImage ??
                                                      'seller.jpg',
                                                ),
                                          ),
                                        );
                                      },
                                      baseUrl: baseUrl,
                                      token: token,
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.call),
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
                          if (isLoadingSellerComments)
                            const Center(child: CircularProgressIndicator())
                          else if (uniqueSellerComments.isEmpty)
                            const Center(child: Text('No details available'))
                          else
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailItem(
                                        Icons.calendar_today,
                                        uniqueSellerComments
                                            .firstWhere(
                                              (comment) =>
                                                  comment.attributeName
                                                      .toLowerCase()
                                                      .trim() ==
                                                  'year',
                                              orElse:
                                                  () => SellerComment(
                                                    attributeName: 'Year',
                                                    attributeValue: 'N/A',
                                                  ),
                                            )
                                            .attributeValue,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildDetailItem(
                                        Icons.person,
                                        uniqueSellerComments
                                            .firstWhere(
                                              (comment) =>
                                                  comment.attributeName
                                                      .toLowerCase()
                                                      .trim() ==
                                                  'no of owners',
                                              orElse:
                                                  () => SellerComment(
                                                    attributeName:
                                                        'No of owners',
                                                    attributeValue: 'N/A',
                                                  ),
                                            )
                                            .attributeValue,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildDetailItem(
                                        Icons.settings,
                                        uniqueSellerComments
                                            .firstWhere(
                                              (comment) =>
                                                  comment.attributeName
                                                      .toLowerCase()
                                                      .trim() ==
                                                  'transmission',
                                              orElse:
                                                  () => SellerComment(
                                                    attributeName:
                                                        'Transmission',
                                                    attributeValue: 'N/A',
                                                  ),
                                            )
                                            .attributeValue,
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
                                        uniqueSellerComments
                                            .firstWhere(
                                              (comment) =>
                                                  comment.attributeName
                                                      .toLowerCase()
                                                      .trim() ==
                                                  'fuel type',
                                              orElse:
                                                  () => SellerComment(
                                                    attributeName: 'Fuel Type',
                                                    attributeValue: 'N/A',
                                                  ),
                                            )
                                            .attributeValue,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildDetailItem(
                                        Icons.speed,
                                        uniqueSellerComments
                                            .firstWhere(
                                              (comment) =>
                                                  comment.attributeName
                                                      .toLowerCase()
                                                      .trim() ==
                                                  'km range',
                                              orElse:
                                                  () => SellerComment(
                                                    attributeName: 'KM Range',
                                                    attributeValue: 'N/A',
                                                  ),
                                            )
                                            .attributeValue,
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
                  // Seller Comments Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildSellerCommentsSection(),
                  ),
                  const Divider(),
                  _buildBannerAd(),
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
                        _buildQuestionsSection(context, id),
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
            ),
          ],
        ),
      ),
    );
  }
}
