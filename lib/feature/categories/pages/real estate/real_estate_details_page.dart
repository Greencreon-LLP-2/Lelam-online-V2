import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/categories/models/market_place_detail.dart';

import 'package:lelamonline_flutter/feature/categories/pages/real%20estate/real_estate_categories.dart';
import 'package:lelamonline_flutter/feature/categories/seller%20info/seller_info_page.dart'
    hide baseUrl, token;

import 'package:lelamonline_flutter/feature/chat/views/chat_page.dart';
import 'package:lelamonline_flutter/feature/chat/views/widget/chat_dialog.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:lelamonline_flutter/feature/categories/models/seller_comment_model.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/buying_status_page.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/selling_status_page.dart'
    show SellingStatusPage;

import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:lelamonline_flutter/utils/login_dialog.dart';
import 'package:lelamonline_flutter/utils/palette.dart';
import 'package:lelamonline_flutter/utils/review_dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

class RealEstateProductDetailsPage extends StatefulWidget {
  final MarketplacePost product;
  final bool isAuction;

  const RealEstateProductDetailsPage({
    super.key,
    required this.product,
    this.isAuction = false,
  });

  @override
  State<RealEstateProductDetailsPage> createState() =>
      _RealEstateProductDetailsPageState();
}

class _RealEstateProductDetailsPageState
    extends State<RealEstateProductDetailsPage> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  final TransformationController _transformationController =
      TransformationController();
  final String _baseUrl = 'https://lelamonline.com/admin/api/v1';
  final String _token = '5cb2c9b569416b5db1604e0e12478ded';
  bool _isFavorited = false;
  bool _isLoadingFavorite = false;
  bool _isLoadingLocations = true;
  bool isLoadingDetails = true;
  String attributesErrorMessage = '';
  List<LocationData> _locations = [];
  List<SellerComment> uniqueSellerComments = [];
  List<SellerComment> detailComments = [];

  String sellerName = 'Unknown';
  String? sellerProfileImage;
  int sellerNoOfPosts = 0;
  String sellerActiveFrom = 'N/A';
  bool isLoadingSeller = true;
  String sellerErrorMessage = '';
  String? userId;
  late LoggedUserProvider _userProvider;

  bool _isBidDialogOpen = false;
  bool _isLoadingBid = false;
  final double _minBidIncrement = 1000;
  String _currentHighestBid = '0';

  bool _isMeetingDialogOpen = false;
  bool _isSchedulingMeeting = false;

  bool _isLoadingGallery = true;
  List<String> _galleryImages = [];
  String _galleryError = '';

  String? _bannerImageUrl;
  bool _isLoadingBanner = false;
  String _bannerError = '';
  String _moveToAuctionButtonText = 'Move to Auction';

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
      _fetchAttributesData(),
      _fetchSellerInfo(),
      _fetchGalleryImages(),
      _fetchBannerImage(),

      if (userId != null && userId != 'Unknown') _checkShortlistStatus(),
    ]);
  }

  Future<bool> _checkAuctionTermsStatus() async {
    if (_userProvider.userId == null) {
      developer.log('User not logged in, cannot check auction terms.');
      return false;
    }

    final url =
        '${MarketplaceService2.baseUrl}/sell-check-auction-terms-accept.php?token=${MarketplaceService2.token}&post_id=$id';
    try {
      developer.log('Checking auction terms status: $url');
      final response = await http.get(Uri.parse(url));
      developer.log(
        'Terms check response: status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        bool termsAccepted = decodedBody['status'] == 'true';
        developer.log('Terms accepted: $termsAccepted');

        if (!termsAccepted) {
          // Terms not accepted, call seller-accept-terms.php
          final acceptUrl =
              '${MarketplaceService2.baseUrl}/seller-accept-terms.php?token=${MarketplaceService2.token}&post_id=$id&user_id=${_userProvider.userId}';
          developer.log('Accepting terms: $acceptUrl');
          final acceptResponse = await http.get(Uri.parse(acceptUrl));
          developer.log(
            'Accept terms response: status=${acceptResponse.statusCode}, body=${acceptResponse.body}',
          );

          if (acceptResponse.statusCode == 200) {
            final acceptDecodedBody = jsonDecode(acceptResponse.body);
            if (acceptDecodedBody['status'] == 'true' &&
                acceptDecodedBody['data'] is List &&
                acceptDecodedBody['data'].isNotEmpty) {
              developer.log('Terms accepted successfully');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    acceptDecodedBody['data'][0]['message'] ?? 'Terms accepted',
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
              return true;
            } else {
              developer.log(
                'Failed to accept terms: ${acceptDecodedBody['data']?[0]['message'] ?? 'Unknown error'}',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to accept terms: ${acceptDecodedBody['data']?[0]['message'] ?? 'Unknown error'}',
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
              return false;
            }
          } else {
            developer.log(
              'Failed to accept terms: HTTP ${acceptResponse.statusCode}',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to accept terms: HTTP ${acceptResponse.statusCode}',
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
            return false;
          }
        }
        return termsAccepted;
      } else {
        developer.log(
          'Failed to check auction terms: HTTP ${response.statusCode}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to check auction terms: HTTP ${response.statusCode}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return false;
      }
    } catch (e) {
      developer.log('Error checking auction terms: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking auction terms: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return false;
    }
  }

  Future<bool> _showTermsAndConditionsDialog(BuildContext context) async {
    bool isAccepted = false;
    String termsHtml = '';
    bool isLoadingTerms = true;
    String? termsError;

    developer.log('Attempting to fetch auction terms');
    try {
      termsHtml = await MarketplaceService2().fetchAuctionTerms();
      developer.log('Terms fetched successfully: $termsHtml');
      isLoadingTerms = false;
    } catch (e) {
      developer.log('Error fetching auction terms: $e');
      termsError = e.toString();
      isLoadingTerms = false;
    }

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool dialogIsAccepted = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            developer.log(
              'Showing terms dialog, isLoadingTerms=$isLoadingTerms, termsError=$termsError',
            );
            return AlertDialog(
              title: const Text('Auction Terms & Conditions'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoadingTerms)
                      const Center(child: CircularProgressIndicator())
                    else if (termsError != null)
                      Text(
                        'Error loading terms: $termsError',
                        style: const TextStyle(fontSize: 14, color: Colors.red),
                      )
                    else
                      Html(
                        data: termsHtml,
                        style: {'body': Style(fontSize: FontSize(14))},
                      ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('I accept the terms and conditions'),
                      value: dialogIsAccepted,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          dialogIsAccepted = value ?? false;
                          developer.log(
                            'Checkbox changed: dialogIsAccepted=$dialogIsAccepted',
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    developer.log('Terms dialog cancelled');
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      dialogIsAccepted && !isLoadingTerms && termsError == null
                          ? () async {
                            developer.log('Attempting to accept terms');
                            try {
                              final url =
                                  '${MarketplaceService2.baseUrl}/seller-accept-terms.php?token=${MarketplaceService2.token}&post_id=$id&user_id=${_userProvider.userId}';
                              developer.log('Accepting terms: $url');
                              final response = await http.get(Uri.parse(url));
                              developer.log(
                                'Accept terms response: status=${response.statusCode}, body=${response.body}',
                              );

                              if (response.statusCode == 200) {
                                final decodedBody = jsonDecode(response.body);
                                if (decodedBody['status'] == 'true' &&
                                    decodedBody['data'] is List &&
                                    decodedBody['data'].isNotEmpty) {
                                  developer.log('Terms accepted successfully');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        decodedBody['data'][0]['message'] ??
                                            'Terms accepted',
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                  Navigator.pop(dialogContext, true);
                                } else {
                                  setDialogState(() {
                                    termsError =
                                        'Failed to accept terms: ${decodedBody['data']?[0]['message'] ?? 'Unknown error'}';
                                    developer.log(
                                      'Failed to accept terms: ${decodedBody['data']?[0]['message']}',
                                    );
                                  });
                                }
                              } else {
                                setDialogState(() {
                                  termsError =
                                      'Failed to accept terms: HTTP ${response.statusCode}';
                                  developer.log(
                                    'Failed to accept terms: HTTP ${response.statusCode}',
                                  );
                                });
                              }
                            } catch (e) {
                              setDialogState(() {
                                termsError = 'Error accepting terms: $e';
                                developer.log('Error accepting terms: $e');
                              });
                            }
                          }
                          : null,
                  child: const Text('Accept'),
                ),
              ],
            );
          },
        );
      },
    ).then((value) {
      isAccepted = value ?? false;
      developer.log('Terms dialog closed, isAccepted=$isAccepted');
    });

    return isAccepted;
  }

  Future<void> _moveToAuction() async {
    if (_userProvider.userId == null) {
      developer.log('User not logged in, showing login prompt');
      _showLoginPromptDialog(context, 'move to auction');
      return;
    }

    setState(() {
      _isLoadingBid = true;
    });

    try {
      developer.log('Showing terms dialog before moving to auction');
      final accepted = await _showTermsAndConditionsDialog(context);
      if (!accepted) {
        developer.log('User did not accept terms, aborting move to auction');
        setState(() {
          _isLoadingBid = false;
        });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('You must accept the auction terms to proceed.'),
        //     backgroundColor: Colors.red,
        //     behavior: SnackBarBehavior.floating,
        //     shape: RoundedRectangleBorder(
        //      // borderRadius: BorderRadius.circular(8),
        //     ),
        //     margin: EdgeInsets.all(16),
        //   ),
        // );
        return;
      }

      developer.log('Terms accepted, proceeding to move to auction');

      final url =
          '$baseUrl/sell-move-to-auction.php?token=$token}&post_id=$id';
      developer.log('Moving to auction: $url');

      final request = http.Request('GET', Uri.parse(url));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      developer.log(
        'sell-move-to-auction.php response: status=${response.statusCode}, body=$responseBody',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        final bool isSuccess =
            responseData['status'] == 'true' &&
            responseData['data'] is List &&
            responseData['data'].isNotEmpty &&
            responseData['data'][0]['check'] == 1;
        final String message =
            responseData['data']?[0]['message']?.toString() ?? '';

        if (isSuccess) {
          developer.log('Successfully moved to auction');
          setState(() {
            _moveToAuctionButtonText = 'Auction Waiting for Approval';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message.isNotEmpty ? message : 'Successfully moved to auction',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context);
        } else {
          throw Exception('');
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      developer.log('Error moving to auction: $e');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Error: $e'),
      //     backgroundColor: Colors.red,
      //     behavior: SnackBarBehavior.floating,
      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      //     margin: const EdgeInsets.all(16),
      //   ),
      // );
    } finally {
      setState(() {
        _isLoadingBid = false;
      });
    }
  }

  Future<void> _fetchBannerImage() async {
    developer.log('RealEstateProductDetailsPage - _fetchBannerImage: Starting');
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
      developer.log('Fetching banner image: $url');

      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      developer.log(
        'Banner API response (status: ${response.statusCode}): $responseBody',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        developer.log('Parsed banner response: $responseData');

        if (responseData['status'] == 'true' && responseData['data'] != null) {
          final bannerImage = responseData['data']['inner_post_image'] ?? '';
          setState(() {
            _bannerImageUrl =
                bannerImage.isNotEmpty
                    ? 'https://lelamonline.com/admin/$bannerImage'
                    : null;
          });
          developer.log('Set _bannerImageUrl=$_bannerImageUrl');
        } else {
          throw Exception('Invalid banner data: ${responseData['data']}');
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      developer.log('Error fetching banner image: $e');
      setState(() {
        _bannerError = 'Failed to load banner: $e';
        _isLoadingBanner = false;
      });
    } finally {
      setState(() {
        _isLoadingBanner = false;
      });
      developer.log(
        'RealEstateProductDetailsPage - _fetchBannerImage: Completed',
      );
    }
  }

  Future<void> _fetchGalleryImages() async {
    try {
      setState(() {
        _isLoadingGallery = true;
        _galleryError = '';
      });

      final headers = {
        'token': _token,
        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
      };
      final url =
          '$_baseUrl/post-gallery.php?token=$_token&post_id=${widget.product.id}';
      developer.log('Fetching gallery: $url');

      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      developer.log('Gallery API response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        developer.log('Parsed responseData type: ${responseData.runtimeType}');

        if (responseData['status'] == 'true' &&
            responseData['data'] is List &&
            (responseData['data'] as List).isNotEmpty) {
          setState(() {
            _galleryImages =
                (responseData['data'] as List)
                    .map(
                      (item) =>
                          'https://lelamonline.com/admin/${item['image'] ?? ''}',
                    )
                    .where((img) => img.isNotEmpty && img.contains('uploads/'))
                    .toList();
            _isLoadingGallery = false;
          });
          developer.log(
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
      developer.log('Error fetching gallery: $e');
      setState(() {
        _galleryError = 'Failed to load gallery: $e';
        _isLoadingGallery = false;
      });
    }
  }

  void _launchPhoneCall() async {
    const phoneNumber = 'tel:+919626040738';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
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
      final headers = {'token': _token};
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final url =
          '$_baseUrl/post-fix-meeting.php?token=$_token&post_id=${widget.product.id}&user_id=$userId&meeting_date=$formattedDate';
      developer.log('Scheduling meeting: $url');

      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      developer.log('post-fix-meeting.php response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        developer.log('Parsed response: $responseData');
        if (responseData['status'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  responseData['data'] ?? 'Meeting scheduled successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
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
      developer.log('Error scheduling meeting: $e');
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
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Meeting Scheduled',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your meeting is scheduled for ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)}.\n\n'
                  'For further information, check My Bids in Status or call support.',
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                  semanticsLabel:
                      'Your meeting is scheduled for ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)}. '
                      'For further information, check My Bids in Status or call support.',
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BuyingStatusPage(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Check Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      semanticsLabel: 'Check bid status',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _launchPhoneCall(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          semanticsLabel: 'Call support team',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    );
  }

  Future<void> _fetchCurrentHighestBid() async {
    try {
      setState(() {
        _isLoadingBid = true;
      });

      final headers = {'token': _token};
      final url =
          '$_baseUrl/current-highest-bid-for-post.php?token=$_token&post_id=${widget.product.id}';
      developer.log('Fetching highest bid: $url');
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      developer.log('Full API response body: $responseBody');
      developer.log('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        developer.log('Parsed response data: $responseData');

        if (responseData['status'] == true) {
          final dataValue = (responseData['data']?.toString() ?? '0').trim();
          final parsed = double.tryParse(dataValue);
          if (parsed != null) {
            setState(() {
              _currentHighestBid = parsed.toString();
            });
            developer.log('Successfully fetched highest bid: $dataValue');
          } else {
            developer.log('API returned non-numeric data: $dataValue');
            setState(() {
              _currentHighestBid = 'Error: $dataValue';
            });
          }
        } else {
          developer.log('API status false: ${responseData['data']}');
          setState(() {
            _currentHighestBid = '0';
          });
        }
      } else {
        developer.log(
          'HTTP error: ${response.statusCode} - ${response.reasonPhrase}',
        );
        setState(() {
          _currentHighestBid = '0';
        });
      }
    } catch (e) {
      developer.log('Exception in fetch highest bid: $e');
      setState(() {
        _currentHighestBid = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoadingBid = false;
      });
    }
  }

  Future<String> _saveBidData(int bidAmount) async {
    if (userId == null || userId == 'Unknown') {
      throw Exception('Please log in to place a bid');
    }

    try {
      final headers = {
        'token': _token,
        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
      };
      final url =
          '$_baseUrl/place-bid.php?token=$_token&post_id=${widget.product.id}&user_id=$userId&bidamt=$bidAmount';
      developer.log('Placing bid: $url');
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      developer.log('place-bid.php response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        developer.log('Parsed place-bid response: $responseData');
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
      developer.log('Error placing bid: $e');
      rethrow;
    }
  }

  void showProductBidDialog(BuildContext context) async {
    if (!_userProvider.isLoggedIn) {
      _showLoginPromptDialog(context, 'place a bid');
      return;
    }

    setState(() => _isBidDialogOpen = true);
    await _fetchCurrentHighestBid(); // Fetch the current highest bid
    final TextEditingController bidController = TextEditingController();

    Future<void> showResponseDialog(
      String message,
      bool isSuccess,
      bool isHighestBid,
    ) async {
      // Format the current highest bid
      final String formattedBid =
          _currentHighestBid.startsWith('Error')
              ? _currentHighestBid
              : '₹ ${NumberFormat('#,##0').format(double.tryParse(_currentHighestBid.replaceAll(',', ''))?.round() ?? 0)}';

      // Support phone number (replace with your actual support number)
      const String supportPhoneNumber = '+919876543210';

      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
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
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  splashRadius: 24,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  tooltip: 'Close dialog',
                ),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
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
                    ],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            _currentHighestBid.startsWith('Error')
                                ? Colors.red
                                : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color:
                          _currentHighestBid.startsWith('Error')
                              ? Colors.red[50]
                              : Colors.green[50],
                    ),
                    child: Text(
                      formattedBid,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            _currentHighestBid.startsWith('Error')
                                ? Colors.red[800]
                                : Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BuyingStatusPage(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final Uri phoneUri = Uri(
                          scheme: 'tel',
                          path: supportPhoneNumber,
                        );
                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri);
                        } else {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Unable to initiate call. Please try again or contact support via other channels.',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red[800],
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return WillPopScope(
          onWillPop: () async => true,
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                backgroundColor: Colors.white,
                titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Text(
                  'Place Your Bid Amount',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Bid Amount *',
                      style: Theme.of(
                        dialogContext,
                      ).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                      semanticsLabel: 'Your Bid Amount (required)',
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bidController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Text(
                            '₹',
                            style: Theme.of(
                              dialogContext,
                            ).textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: Theme.of(dialogContext).textTheme.bodyMedium
                          ?.copyWith(fontSize: 16, color: Colors.grey[800]),
                    ),
                    if (_isLoadingBid)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
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
                            Navigator.of(dialogContext).pop(null);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            semanticsLabel: 'Close dialog',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _isLoadingBid
                                  ? null
                                  : () async {
                                    final String amount = bidController.text;
                                    if (amount.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Please enter a bid amount',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.red[800],
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                        ),
                                      );
                                      return;
                                    }

                                    final int bidAmount =
                                        int.tryParse(amount) ?? 0;
                                    if (bidAmount < _minBidIncrement) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Minimum bid amount is ₹${NumberFormat('#,##0').format(_minBidIncrement)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.red[800],
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          margin: const EdgeInsets.all(16),
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
                                      // Parse current highest bid and user's bid for comparison
                                      final double currentHighest =
                                          double.tryParse(_currentHighestBid) ??
                                          0;
                                      final bool isHighestBid =
                                          bidAmount > currentHighest;
                                      Navigator.of(dialogContext).pop({
                                        'success': true,
                                        'message': responseMessage,
                                        'isHighestBid': isHighestBid,
                                      });
                                    } catch (e) {
                                      Navigator.of(dialogContext).pop({
                                        'success': false,
                                        'message': 'Error placing bid: $e',
                                        'isHighestBid': false,
                                      });
                                    } finally {
                                      setDialogState(() {
                                        _isLoadingBid = false;
                                      });
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                semanticsLabel: 'Submit bid amount',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              );
            },
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 200));
    FocusScope.of(context).unfocus();
    bidController.dispose();

    if (result != null) {
      final bool ok = result['success'] == true;
      final String msg =
          result['message']?.toString() ??
          (ok ? 'Bid placed successfully' : 'Failed to place bid');
      final bool isHighestBid = result['isHighestBid'] ?? false;
      await showResponseDialog(msg, ok, isHighestBid);
    }
    if (mounted) setState(() => _isBidDialogOpen = false);
  }

  void _showLoginPromptDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return LoginDialog(
          onSuccess: () {
            _fetchLocations();
            _fetchAttributesData();
            _fetchSellerInfo();
            _fetchGalleryImages();
            _fetchBannerImage();
          },
        );
      },
    );
  }

  Future<void> _toggleFavorite() async {
    if (userId == null || userId == 'Unknown') {
      _showLoginPromptDialog(context, 'add or remove from shortlist');
      return;
    }

    if (_isLoadingFavorite) return;

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final headers = {'token': _token};
      final url =
          '$_baseUrl/add-to-shortlist.php?token=$_token&user_id=$userId&post_id=${widget.product.id}';
      developer.log('Toggling shortlist: $url');
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      developer.log('add-to-shortlist.php response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        final bool isSuccess =
            responseData['status'] == true || responseData['status'] == 'true';
        final String message = responseData['data']?.toString() ?? '';

        if (isSuccess) {
          final bool wasAdded =
              message.toLowerCase().contains('added') || !_isFavorited;
          setState(() {
            _isFavorited = wasAdded;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                wasAdded ? 'Added to shortlist' : 'Removed from shortlist',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update shortlist: $message'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.reasonPhrase}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      developer.log('Error toggling shortlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() {
        _isLoadingFavorite = false;
      });
    }
  }

  Future<void> _checkShortlistStatus() async {
    if (userId == null || userId == 'Unknown') {
      setState(() {
        _isFavorited = false;
        _isLoadingFavorite = false;
      });
      return;
    }

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final response = await ApiService().get(
        url: shortlist,
        queryParams: {"user_id": userId},
      );

      developer.log('Shortlist API response: $response');

      if (response['status'] == 'true' && response['data'] is List) {
        final List<dynamic> shortlistData = response['data'];
        final bool isShortlisted = shortlistData.any(
          (item) => item['post_id'].toString() == widget.product.id,
        );
        setState(() {
          _isFavorited = isShortlisted;
          _isLoadingFavorite = false;
        });
        developer.log(
          'Product ${widget.product.id} isShortlisted: $isShortlisted',
        );
      } else {
        setState(() {
          _isFavorited = false;
          _isLoadingFavorite = false;
        });
        developer.log('Invalid shortlist data: ${response['data']}');
      }
    } catch (e) {
      developer.log('Error checking shortlist status: $e');
      setState(() {
        _isFavorited = false;
        _isLoadingFavorite = false;
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Failed to check shortlist status: $e'),
      //     backgroundColor: Colors.red,
      //     behavior: SnackBarBehavior.floating,
      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      //     margin: const EdgeInsets.all(16),
      //   ),
      // );
    }
  }

  void _loadUserId() {
    final userProvider = Provider.of<LoggedUserProvider>(
      context,
      listen: false,
    );
    final userData = userProvider.userData;
    setState(() {
      userId = userData?.userId ?? '';
    });
    developer.log('RealEstateProductDetailsPage - Loaded userId: $userId');
  }

  // Future<void> _checkShortlistStatus() async {
  //   if (userId == null || userId == 'Unknown') {
  //     setState(() {
  //       _isFavorited = false;
  //     });
  //     return;
  //   }

  //   setState(() {
  //     _isLoadingFavorite = true;
  //   });

  //   try {
  //     final response = await http.get(
  //       Uri.parse('$_baseUrl/list-shortlist.php?token=$_token&user_id=$userId'),
  //       headers: {
  //         'token': _token,
  //         'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final responseData = jsonDecode(response.body);
  //       if (responseData['status'] == 'true' && responseData['data'] is List) {
  //         final shortlistData = List<Map<String, dynamic>>.from(
  //           responseData['data'],
  //         );
  //         final isShortlisted = shortlistData.any(
  //           (item) => item['post_id'].toString() == widget.product.id,
  //         );
  //         setState(() {
  //           _isFavorited = isShortlisted;
  //           _isLoadingFavorite = false;
  //         });
  //       } else {
  //         setState(() {
  //           _isFavorited = false;
  //           _isLoadingFavorite = false;
  //         });
  //       }
  //     } else {
  //       throw Exception(
  //         'Failed to check shortlist status: ${response.reasonPhrase}',
  //       );
  //     }
  //   } catch (e) {
  //     developer.log('Error checking shortlist status: $e');
  //     setState(() {
  //       _isLoadingFavorite = false;
  //     });
  //   }
  // }

  Future<void> _toggleShortlist() async {
    if (userId == null || userId == 'Unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to manage your shortlist')),
      );
      return;
    }

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final action = _isFavorited ? 'remove' : 'add';
      final response = await http.post(
        Uri.parse('$_baseUrl/$action-shortlist.php?token=$_token'),
        headers: {
          'token': _token,
          'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': userId, 'post_id': widget.product.id}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'true') {
          setState(() {
            _isFavorited = !_isFavorited;
            _isLoadingFavorite = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isFavorited ? 'Added to shortlist' : 'Removed from shortlist',
              ),
            ),
          );
        } else {
          throw Exception(
            'Failed to update shortlist: ${responseData['data']}',
          );
        }
      } else {
        throw Exception('Failed to update shortlist: ${response.reasonPhrase}');
      }
    } catch (e) {
      developer.log('Error toggling shortlist: $e');
      setState(() {
        _isLoadingFavorite = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
          developer.log(
            'Locations fetched: ${_locations.map((loc) => "${loc.id}: ${loc.name}").toList()}',
          );
        });
      } else {
        throw Exception('Invalid API response format');
      }
    } catch (e) {
      developer.log('Error fetching locations: $e');
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _fetchAttributesData() async {
    setState(() {
      isLoadingDetails = true;
      attributesErrorMessage = '';
    });

    try {
      final url =
          '$_baseUrl/post-attribute-values.php?token=$_token&post_id=${widget.product.id}';
      developer.log('Fetching attributes: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'token': _token},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final sellerComments = SellerCommentsModel.fromJson(responseData);

        final Map<String, SellerComment> uniqueAttributes = {};
        final List<SellerComment> orderedComments = [];

        // Process attributes for uniqueness
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

        // Add Seller Type from byDealer
        orderedComments.add(
          SellerComment(
            attributeName: 'Seller Type',
            attributeValue: widget.product.byDealer == '1' ? 'Dealer' : 'Owner',
          ),
        );
        uniqueAttributes['sellertype'] = SellerComment(
          attributeName: 'Seller Type',
          attributeValue: widget.product.byDealer == '1' ? 'Dealer' : 'Owner',
        );

        // Add auction-specific attributes if isAuction is true
        if (widget.isAuction) {
          orderedComments.add(
            SellerComment(
              attributeName: 'Auction Starting Price',
              attributeValue: formatPriceInt(
                double.tryParse(widget.product.auctionStartingPrice) ?? 0,
              ),
            ),
          );
          orderedComments.add(
            SellerComment(
              attributeName: 'Auction Attempts',
              attributeValue: widget.product.auctionAttempt,
            ),
          );
          uniqueAttributes['auctionstartingprice'] = SellerComment(
            attributeName: 'Auction Starting Price',
            attributeValue: formatPriceInt(
              double.tryParse(widget.product.auctionStartingPrice) ?? 0,
            ),
          );
          uniqueAttributes['auctionattempts'] = SellerComment(
            attributeName: 'Auction Attempts',
            attributeValue: widget.product.auctionAttempt,
          );
        }

        setState(() {
          uniqueSellerComments = orderedComments;
          // Filter for Details section
          detailComments =
              uniqueSellerComments.where((comment) {
                final name = comment.attributeName.toLowerCase().trim();
                return [
                  'seller type',
                  if (widget.isAuction) 'auction attempts',
                ].contains(name);
              }).toList();

          developer.log(
            'Ordered uniqueSellerComments: ${uniqueSellerComments.map((c) => "${c.attributeName}: ${c.attributeValue}").toList()}',
          );
          developer.log(
            'Filtered detailComments: ${detailComments.map((c) => "${c.attributeName}: ${c.attributeValue}").toList()}',
          );
          isLoadingDetails = false;
        });
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      developer.log('Error fetching attributes: $e');
      setState(() {
        attributesErrorMessage = 'Failed to load attributes: $e';
        isLoadingDetails = false;
      });
    }
  }

  Widget _buildBannerAd() {
    developer.log(
      'Building banner ad: isLoadingBanner=$_isLoadingBanner, bannerError=$_bannerError, bannerImageUrl=$_bannerImageUrl',
    );

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
      developer.log('No banner image available');
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(0),
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

  String get id => widget.product.id;
  String get title => widget.product.title;
  String get image => widget.product.image;
  String get price => widget.product.price;
  String get landMark => _getLocationName(widget.product.parentZoneId);
  String get createdOn => widget.product.createdOn;
  String get createdBy => widget.product.createdBy;
  bool get isFinanceAvailable => widget.product.ifFinance == '1';
  bool get isFeatured => widget.product.feature == '1';

  List<String> get _images {
    if (!_isLoadingGallery && _galleryImages.isNotEmpty) {
      return _galleryImages;
    }
    if (image.isNotEmpty) {
      return ['https://lelamonline.com/admin/$image'];
    }
    return [
      'https://images.pexels.com/photos/106399/pexels-photo-106399.jpeg?cs=srgb&dl=pexels-binyamin-mellish-106399.jpg&fm=jpg',
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
    if (_isMeetingDialogOpen) {
      developer.log('Meeting dialog already open');
      return;
    }

    final userProvider = Provider.of<LoggedUserProvider>(
      context,
      listen: false,
    );
    if (!userProvider.isLoggedIn) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return LoginDialog(
            onSuccess: () {
              if (mounted) {
                Navigator.of(dialogContext).pop(); // Close login dialog
                _showMeetingDialog(context); // Re-open meeting dialog
              }
            },
          );
        },
      );
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
                          : () => Navigator.of(dialogContext).pop(),
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

Widget _buildQuestionsSection(BuildContext context, String id) {
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
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (dialogContext) {
                    return LoginDialog(
                      onSuccess: () {
                        if (mounted) {
                          Navigator.of(dialogContext).pop();
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => ReviewDialog(postId: id),
                          );
                        }
                      },
                    );
                  },
                );
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

  String _stripHtmlTags(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '').trim();
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : IconButton(
                                tooltip:
                                    _isFavorited
                                        ? 'Remove from Shortlist'
                                        : 'Add to Shortlist',
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder:
                                      (child, animation) => ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      ),
                                  child: Icon(
                                    _isFavorited
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    key: ValueKey<bool>(_isFavorited),
                                    color:
                                        _isFavorited
                                            ? Colors.red
                                            : Colors.white,
                                    size: 28,
                                    semanticLabel:
                                        _isFavorited
                                            ? 'Remove from Shortlist'
                                            : 'Add to Shortlist',
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
                        widget.isAuction
                            ? 'Starting Bid: ₹${formatPriceInt(double.tryParse(widget.product.auctionStartingPrice) ?? 0)}'
                            : '₹${formatPriceInt(double.tryParse(price) ?? 0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      if (widget.isAuction) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Max Bid: ₹${formatPriceInt(double.tryParse(price) ?? 0)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please log in to chat with the seller',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return ChatOptionsDialog(
                                    onChatWithSupport: () {
                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (context) => const SupportPage(),
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
                                    baseUrl: _baseUrl,
                                    token: _token,
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.call),
                            label: const Text(
                              'Contact Seller',
                            ), // Changed from 'Call Support'
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
                        if (isLoadingDetails)
                          const Center(child: CircularProgressIndicator())
                        else if (attributesErrorMessage.isNotEmpty)
                          Center(
                            child: Text(
                              attributesErrorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        else if (detailComments.isEmpty)
                          const Center(child: Text('No details available'))
                        else
                          Column(
                            children: [
                              _buildDetailItem(
                                Icons.person,
                                detailComments
                                    .firstWhere(
                                      (comment) =>
                                          comment.attributeName
                                              .toLowerCase()
                                              .trim() ==
                                          'seller type',
                                      orElse:
                                          () => SellerComment(
                                            attributeName: 'Seller Type',
                                            attributeValue: 'N/A',
                                          ),
                                    )
                                    .attributeValue,
                              ),
                              if (widget.isAuction) ...[
                                const SizedBox(height: 12),
                                _buildDetailItem(
                                  Icons.gavel,
                                  'Attempts: ${detailComments.firstWhere((comment) => comment.attributeName.toLowerCase().trim() == 'auction attempts', orElse: () => SellerComment(attributeName: 'Auction Attempts', attributeValue: '0')).attributeValue}/3',
                                ),
                              ],
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
                          children:
                              uniqueSellerComments
                                  .where(
                                    (comment) =>
                                        ![
                                          'seller type',
                                          'auction starting price',
                                          'auction attempts',
                                        ].contains(
                                          comment.attributeName
                                              .toLowerCase()
                                              .trim(),
                                        ),
                                  )
                                  .map(
                                    (comment) => _buildSellerCommentItem(
                                      comment.attributeName,
                                      comment.attributeValue,
                                    ),
                                  )
                                  .toList(),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(10.0),
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
                        _stripHtmlTags(widget.product.description),
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),

                _buildBannerAd(),

                Padding(
                  padding: const EdgeInsets.all(10.0),
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
               
                
              ),
              child: Row(
                children: [
                  if (_userProvider.userId == widget.product.createdBy) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SellingStatusPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoadingBid ? null : _moveToAuction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.primaryblue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child:
                            _isLoadingBid
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Text(_moveToAuctionButtonText),
                      ),
                    ),
                  ] else ...[
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
                    const SizedBox(width: 10),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
