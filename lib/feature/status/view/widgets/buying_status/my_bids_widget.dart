import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/my_meetings_widget.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/call_support/call_support.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:developer' as developer;

import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';
import 'package:talker_dio_logger/talker_dio_logger_settings.dart';

class MyBidsWidget extends StatefulWidget {
  final String baseUrl;
  final String token;
  final String? userId;
  final Function(String, String?, String?, bool)? onNavigateToMeetings;

  const MyBidsWidget({
    super.key,
    this.baseUrl = 'https://lelamonline.com/admin/api/v1',
    this.token = '5cb2c9b569416b5db1604e0e12478ded',
    this.userId,
    this.onNavigateToMeetings,
  });

  static void clearCache() {
    _MyBidsWidgetState._staticBidCache['Low Bids']?.clear();
    _MyBidsWidgetState._staticBidCache['High Bids']?.clear();
    _MyBidsWidgetState._staticPostCache.clear();
    _MyBidsWidgetState._lastCacheUpdate = null;
    print('MyBidsWidget static cache cleared');
  }

  @override
  State<MyBidsWidget> createState() => _MyBidsWidgetState();
}

class _MyBidsWidgetState extends State<MyBidsWidget> {
  static final Map<String, List<Map<String, dynamic>>> _staticBidCache = {
    'Low Bids': [],
    'High Bids': [],
  };
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  static final Map<String, dynamic> _staticPostCache = {};
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  late final LoggedUserProvider userProvider;
  List<Map<String, dynamic>> bids = [];
  List<Map<String, dynamic>> districts = [];
  bool isLoading = true;
  String? error;
  String? _userId;
  final Map<String, List<Map<String, dynamic>>> _bidCache = {
    'Low Bids': [],
    'High Bids': [],
  };
  final Map<String, dynamic> _postCache = {};
  late final Logger logger;
  late final Dio dio;
  bool _isProcessing = false;
  @override
  void initState() {
    userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
    super.initState();

    logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: false,
      ),
    );
    dio = Dio(BaseOptions(headers: {'token': widget.token}));
    dio.interceptors.add(
      TalkerDioLogger(
        settings: const TalkerDioLoggerSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
          printResponseMessage: true,
        ),
      ),
    );

    _checkAndUseStaticCache();
    _loadUserIdAndBids();
  }

  void _checkAndUseStaticCache() {
    final now = DateTime.now();
    final cacheValid =
        _lastCacheUpdate != null &&
        now.difference(_lastCacheUpdate!) < _cacheExpiry &&
        _staticBidCache['Low Bids']!.isNotEmpty &&
        _staticBidCache['High Bids']!.isNotEmpty;
    if (cacheValid) {
      print(
        'Using static cache - valid until ${_lastCacheUpdate!.add(_cacheExpiry)}',
      );
      _bidCache['Low Bids'] = List.from(_staticBidCache['Low Bids']!);
      _bidCache['High Bids'] = List.from(_staticBidCache['High Bids']!);
      _postCache.addAll(_staticPostCache);
      List<Map<String, dynamic>> allBids = [];
      allBids.addAll(_bidCache['Low Bids']!);
      allBids.addAll(_bidCache['High Bids']!);
      // Sort bids by created_on (newest first)
      allBids.sort((a, b) {
        final dateA =
            DateTime.tryParse(
              a['created_on']?.toString() ?? '1900-01-01 00:00:00',
            ) ??
            DateTime(1900);
        final dateB =
            DateTime.tryParse(
              b['created_on']?.toString() ?? '1900-01-01 00:00:00',
            ) ??
            DateTime(1900);
        return dateB.compareTo(dateA); // Newest first
      });
      if (mounted) {
        setState(() {
          bids = allBids;
          isLoading = false;
        });
      }
      return;
    }
    print('Static cache invalid or empty, will fetch fresh data');
  }

  void _updateStaticCache() {
    _staticBidCache['Low Bids'] = List.from(_bidCache['Low Bids']!);
    _staticBidCache['High Bids'] = List.from(_bidCache['High Bids']!);
    _staticPostCache.clear();
    _staticPostCache.addAll(_postCache);
    _lastCacheUpdate = DateTime.now();
    print('Static cache updated at $_lastCacheUpdate');
  }

  Future<void> _forceRefresh() async {
    print('Force refreshing - clearing static cache');
    _staticBidCache['Low Bids']?.clear();
    _staticBidCache['High Bids']?.clear();
    _staticPostCache.clear();
    _lastCacheUpdate = null;
    _bidCache['Low Bids']?.clear();
    _bidCache['High Bids']?.clear();
    _postCache.clear();
    await _loadBids();
  }

  // Add this method to _MyBidsWidgetState class
  Future<String?> _fetchCurrentHighestBid(String postId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/current-higest-bid-for-post.php?token=${widget.token}&post_id=$postId',
        ),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=g6nr0pkfdnp6o573mn9srq20b4',
        },
      );

      developer.log(
        'Highest bid API response for post $postId: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          return data['data']?.toString() ??
              data['highest_bid']?.toString() ??
              data['current_highest_bid']?.toString();
        }
      }
      return null;
    } catch (e) {
      developer.log('Error fetching current highest bid for post $postId: $e');
      return null;
    }
  }

  // ADDED: Delete bid function
  Future<void> _deleteBid(String bidId, String postId, int index) async {
    try {
      final userIdToUse = _userId ?? widget.userId;
      if (userIdToUse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User ID not found')),
        );
        return;
      }

      final deleteUrl =
          '${widget.baseUrl}/bid-delete.php?token=${widget.token}&user_id=$userIdToUse&post_id=$postId';
      print('Delete bid URL: $deleteUrl');

      final response = await http.get(
        Uri.parse(deleteUrl),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=g6nr0pkfdnp6o573mn9srq20b4',
        },
      );

      print('bid-delete.php response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          // Remove the bid from the UI immediately
          if (mounted) {
            setState(() {
              bids.removeAt(index);
            });
          }

          // Also remove from cache
          _removeBidFromCache(bidId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bid deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete bid: ${data['message'] ?? 'Unknown error'}',
              ),
            ),
          );
        }
      } else {
        print('bid-delete.php failed with status ${response.statusCode}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete bid')));
      }
    } catch (e) {
      print('Error deleting bid: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error deleting bid')));
    }
  }

  // ADDED: Helper function to remove bid from cache
  void _removeBidFromCache(String bidId) {
    // Remove from low bids cache
    _bidCache['Low Bids']?.removeWhere((bid) => bid['id'] == bidId);
    _staticBidCache['Low Bids']?.removeWhere((bid) => bid['id'] == bidId);

    // Remove from high bids cache
    _bidCache['High Bids']?.removeWhere((bid) => bid['id'] == bidId);
    _staticBidCache['High Bids']?.removeWhere((bid) => bid['id'] == bidId);

    print('Bid $bidId removed from cache');
  }

  Future<void> _loadUserIdAndBids() async {
    setState(() {
      _userId = userProvider.userData?.userId ?? "";
    });
    print(
      'MyBidsWidget - Loaded userId: $_userId (fallback from widget: ${widget.userId})',
    );

    if (_userId == 'Unknown') {
      print('MyBidsWidget - User ID unknown; prompting login');
      if (mounted) {
        error = 'Please log in to view your bids';
        setState(() => isLoading = false);
      }
      return;
    }

    if (bids.isNotEmpty && !isLoading) {
      print('Using existing valid cache');
      return;
    }

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

      print('post-details.php response for post_id $postId: ${response.body}');

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
            String imagePath = postData['image']?.toString() ?? '';
            String fullImageUrl =
                imagePath.isNotEmpty
                    ? (imagePath.startsWith('http')
                        ? imagePath
                        : imagePath.startsWith('/')
                        ? 'https://lelamonline.com$imagePath'
                        : 'https://lelamonline.com/admin/$imagePath')
                    : '';

            String location = 'Unknown Location';
            final parentZoneId = postData['parent_zone_id']?.toString();
            if (parentZoneId != null) {
              final district = districts.firstWhere(
                (d) => d['id'] == parentZoneId,
                orElse: () => {'name': ''},
              );
              location = district['name'] as String;
              if (postData['land_mark']?.isNotEmpty ?? false) {
                location += ', ${postData['land_mark']}';
              }
            } else if (postData['land_mark']?.isNotEmpty ?? false) {
              location = postData['land_mark'];
            }

            return {
              'title': postData['title'] ?? 'Unknown Vehicle (ID: $postId)',
              'price': postData['price']?.toString() ?? '0',
              'image': fullImageUrl,
              'parent_zone_id': parentZoneId ?? 'Unknown',
              'by_dealer': postData['by_dealer']?.toString() ?? '0',
              'land_mark': postData['land_mark']?.toString() ?? '',
              'location': location,
            };
          }
        }
      }
      print('No valid post data for post_id $postId');
      return null;
    } catch (e) {
      print('Error fetching post details for post_id $postId: $e');
      return null;
    }
  }

  Future<int> _fetchMeetingAttempts(String bidId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/my-meeting-request.php?token=${widget.token}&user_id=${widget.userId}',
        ),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
        },
      );
      print(
        'my-meeting-request.php response for bid_id $bidId: ${response.body}',
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List meetings = [];
        if (responseData is List) {
          meetings = responseData;
        } else if (responseData is Map &&
            (responseData['status'] == true ||
                responseData['status'] == 'true')) {
          meetings = responseData['data'] as List;
        }
        final count =
            meetings
                .where((m) => m['bid_id'] == bidId && m['status'] == '1')
                .length;
        print('Meeting attempts for bid_id $bidId: $count');
        return count;
      } else {
        print(
          'my-meeting-request.php failed with status ${response.statusCode} for bid_id $bidId',
        );
      }
      return 0;
    } catch (e) {
      print('Error fetching meeting attempts for bid_id $bidId: $e');
      return 0;
    }
  }

  Future<List<Map<String, String>>> _fetchMeetingTimes() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/meeting-times.php?token=${widget.token}'),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=g6nr0pkfdnp6o573mn9srq20b4',
        },
      );
      print('meeting-times.php response: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          if (data['data'] is List && data['data'].isNotEmpty) {
            return List<Map<String, String>>.from(
              data['data'].map(
                (item) => {
                  'name': item['name']?.toString() ?? '',
                  'value': item['value']?.toString() ?? '',
                },
              ),
            );
          }
        }
        print('Invalid meeting times data: ${data.toString()}');
      } else {
        print('meeting-times.php failed with status ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('Error fetching meeting times: $e');
      return [];
    }
  }

  Future<void> _proccedWithBid(
    BuildContext context,
    String bidId,
    String postId,
  ) async {
    print('Opening time dialog for bid_id: $bidId, post_id: $postId');

    final bid = bids.firstWhere(
      (b) => b['id'] == bidId && b['post_id'] == postId,
      orElse: () => {},
    );
    if (bid.isEmpty) {
      print(
        'Invalid bid: bid_id=$bidId, post_id=$postId not found in bids list',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Invalid bid or post ID')),
      );
      return;
    }

    final meetingTimes = await _fetchMeetingTimes();
    if (meetingTimes.isEmpty) {
      print('No meeting times available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No meeting times available')),
      );
      return;
    }

    String? selectedTimeValue;
    String? selectedTimeName;

    await showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Select Meeting Time'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<String>(
                        isExpanded: true,
                        value: selectedTimeValue,
                        hint: const Text('Choose a time'),
                        items:
                            meetingTimes.map((time) {
                              return DropdownMenuItem<String>(
                                value: time['value'],
                                child: Text(time['name']!),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTimeValue = value;
                            selectedTimeName =
                                meetingTimes.firstWhere(
                                  (time) => time['value'] == value,
                                  orElse: () => {'name': ''},
                                )['name'];
                            print(
                              'Selected time: $selectedTimeName ($selectedTimeValue)',
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        print('Time dialog cancelled');
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed:
                          selectedTimeValue == null
                              ? null
                              : () async {
                                print(
                                  'Submitting meeting time: $selectedTimeValue for bid_id: $bidId',
                                );
                                try {
                                  final userIdToUse = widget.userId ?? _userId;
                                  final requestUrl =
                                      '${widget.baseUrl}/procced-meeting-with-bid.php?token=${widget.token}&user_id=$userIdToUse&post_id=$postId&customerbid_id=$bidId&meeting_times=$selectedTimeValue';
                                  print('Request URL: $requestUrl');
                                  final response = await http.get(
                                    Uri.parse(requestUrl),
                                    headers: {
                                      'token': widget.token,
                                      'Cookie':
                                          'PHPSESSID=g6nr0pkfdnp6o573mn9srq20b4',
                                    },
                                  );
                                  print(
                                    'procced-meeting-with-bid.php response: ${response.body}',
                                  );
                                  if (response.statusCode == 200) {
                                    final data = jsonDecode(response.body);
                                    if (data['status'] == true ||
                                        data['status'] == 'true') {
                                      if (data['code'] == 2) {
                                        print(
                                          'Bid not found for bid_id: $bidId',
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Error: Bid not found on server',
                                            ),
                                          ),
                                        );
                                      } else if (data['code'] == 1) {
                                        print(
                                          'Post not found for post_id: $postId',
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Error: Post not found',
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Meeting scheduled for $selectedTimeName',
                                            ),
                                          ),
                                        );
                                        await _forceRefresh();
                                        print(
                                          'Meeting scheduled, navigating to My Meetings tab with Meeting Request',
                                        );
                                        context.pushNamed(
                                          RouteNames.buyingStatusPage,
                                          queryParameters: {
                                            'initialTab':
                                                '1', // Select "My Meetings" tab
                                            'initialStatus':
                                                'Meeting Request', // Set to "Meeting Request" status
                                            'postId': postId,
                                            'bidId': bidId,
                                            'forceRefresh':
                                                'true', // Add flag to force refresh
                                          },
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to schedule meeting: ${data['message'] ?? 'Unknown error'}',
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    print(
                                      'procced-meeting-with-bid.php failed with status ${response.statusCode}',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Failed to schedule meeting',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print(
                                    'Error scheduling meeting with bid: $e',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Error scheduling meeting'),
                                    ),
                                  );
                                }
                                Navigator.pop(dialogContext);
                              },
                      child: const Text('OK'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _proccedWithoutBid(BuildContext context, String postId) async {
    print('=== PROCEED WITHOUT BID STARTED ===');
    print('Post ID: $postId');
    print('User ID: $_userId');

    try {
      final meetingDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final requestUrl =
          '${widget.baseUrl}/procced-meeting-without-bid.php?token=${widget.token}&user_id=$_userId&post_id=$postId&meeting_date=$meetingDate';

      print('API URL: $requestUrl');

      final response = await http.get(
        Uri.parse(requestUrl),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=g6nr0pkfdnp6o573mn9srq20b4',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          print('=== MEETING CREATION SUCCESSFUL ===');

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Meeting scheduled successfully')),
            );
          }

          // Clear cache
          print('Clearing MyMeetingsWidget cache...');
          MyMeetingsWidget.clearCache();

          // Small delay to ensure UI updates
          await Future.delayed(const Duration(milliseconds: 100));

          print('=== CALLING NAVIGATION CALLBACK ===');
          print('Callback is null: ${widget.onNavigateToMeetings == null}');

          // Use the callback to navigate to meetings tab
          if (widget.onNavigateToMeetings != null) {
            print(
              'Calling onNavigateToMeetings with: Date Fixed, $postId, null, true',
            );
            widget.onNavigateToMeetings!('Date Fixed', postId, null, true);
            print('=== NAVIGATION CALLBACK CALLED SUCCESSFULLY ===');
          } else {
            print('ERROR: onNavigateToMeetings callback is null!');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigation failed - callback is null'),
                ),
              );
            }
          }
        } else {
          print('API returned error: ${data['message']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed: ${data['message'] ?? 'Unknown error'}'),
              ),
            );
          }
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to schedule meeting')),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Exception: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error scheduling meeting')),
        );
      }
    }

    print('=== PROCEED WITHOUT BID COMPLETED ===');
  }

  void _handleSuccessfulMeeting(BuildContext context, String postId) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meeting scheduled successfully')),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.pushNamed(
          RouteNames.buyingStatusPage,
          queryParameters: {
            'initialTab': '1',
            'initialStatus': 'Date Fixed',
            'postId': postId,
            'forceRefresh': 'true',
          },
        );
      }
    });
  }

  void _showError(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _increaseBid(
    BuildContext context,
    String postId,
    String currentBidAmount,
  ) async {
    final TextEditingController bidController = TextEditingController(
      text: currentBidAmount,
    );
    await showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Increase Bid'),
            content: TextField(
              controller: bidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Bid Amount',
                prefixText: '₹',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final newBidAmount = bidController.text;
                  if (newBidAmount.isNotEmpty &&
                      double.tryParse(newBidAmount) != null) {
                    try {
                      final response = await http.get(
                        Uri.parse(
                          '${widget.baseUrl}/increase-bid.php?token=${widget.token}&user_id=$_userId&post_id=$postId&bidamt=$newBidAmount',
                        ),
                        headers: {
                          'token': widget.token,
                          'Cookie': 'PHPSESSID=g6nr0pkfdnp6o573mn9srq20b4',
                        },
                      );
                      print('increase-bid.php response: ${response.body}');
                      if (response.statusCode == 200) {
                        final data = jsonDecode(response.body);
                        if (data['status'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bid increased successfully'),
                            ),
                          );
                          await _forceRefresh();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to increase bid: ${data['message'] ?? 'Unknown error'}',
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print('Error increasing bid: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error increasing bid')),
                      );
                    }
                    Navigator.pop(dialogContext);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid bid amount'),
                      ),
                    );
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _cancelBid(BuildContext context, String bidId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/cancel-bid.php?token=${widget.token}&user_id=$_userId&customerbid_id=$bidId',
        ),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=g6nr0pkfdnp6o573mn9srq20b4',
        },
      );
      print('cancel-bid.php response for bid_id $bidId: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bid cancelled successfully')),
          );
          await _forceRefresh();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to cancel bid: ${data['message'] ?? 'Unknown error'}',
              ),
            ),
          );
        }
      } else {
        print('cancel-bid.php failed with status ${response.statusCode}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to cancel bid')));
      }
    } catch (e) {
      print('Error cancelling bid: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error cancelling bid')));
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
      bool cacheUpdated = false;
      bool needLowFetch = _staticBidCache['Low Bids']!.isEmpty;
      bool needHighFetch = _staticBidCache['High Bids']!.isEmpty;
      if (needLowFetch) {
        final lowBidsResponse = await http.get(
          Uri.parse(
            '${widget.baseUrl}/my-bids-low.php?token=${widget.token}&user_id=$_userId',
          ),
          headers: headers,
        );
        print('my-bids-low.php status: ${lowBidsResponse.statusCode}');
        print('my-bids-low.php response: ${lowBidsResponse.body}');
        if (lowBidsResponse.statusCode == 200) {
          final lowBidsData = jsonDecode(lowBidsResponse.body);
          if (lowBidsData['status'] == true && lowBidsData['data'] is List) {
            final lowBids = List<Map<String, dynamic>>.from(
              lowBidsData['data'],
            );
            for (var bid in lowBids) {
              bid['fromLowBids'] = true;
              bid['fromHighBids'] = false;
              allBids.add(bid);
              _bidCache['Low Bids']!.add(bid);
            }
            cacheUpdated = true;
            print('Low bids fetched and cached: ${lowBids.length} items');
          }
        }
      } else {
        allBids.addAll(_staticBidCache['Low Bids']!);
        _bidCache['Low Bids'] = List.from(_staticBidCache['Low Bids']!);
        print(
          'Using static cache for Low Bids: ${_staticBidCache['Low Bids']!.length} items',
        );
      }
      if (needHighFetch) {
        final highBidsResponse = await http.get(
          Uri.parse(
            '${widget.baseUrl}/my-bids-high.php?token=${widget.token}&user_id=$_userId',
          ),
          headers: headers,
        );
        print('my-bids-high.php status: ${highBidsResponse.statusCode}');
        print('my-bids-high.php response: ${highBidsResponse.body}');
        if (highBidsResponse.statusCode == 200) {
          final highBidsData = jsonDecode(highBidsResponse.body);
          if (highBidsData['status'] == true && highBidsData['data'] is List) {
            final highBids = List<Map<String, dynamic>>.from(
              highBidsData['data'],
            );
            for (var bid in highBids) {
              bid['fromHighBids'] = true;
              bid['fromLowBids'] = false;
              allBids.add(bid);
              _bidCache['High Bids']!.add(bid);
            }
            cacheUpdated = true;
            print('High bids fetched and cached: ${highBids.length} items');
          }
        }
      } else {
        allBids.addAll(_staticBidCache['High Bids']!);
        _bidCache['High Bids'] = List.from(_staticBidCache['High Bids']!);
        print(
          'Using static cache for High Bids: ${_staticBidCache['High Bids']!.length} items',
        );
      }
      // Sort bids by created_on (newest first)
      allBids.sort((a, b) {
        final dateA =
            DateTime.tryParse(
              a['created_on']?.toString() ?? '1900-01-01 00:00:00',
            ) ??
            DateTime(1900);
        final dateB =
            DateTime.tryParse(
              b['created_on']?.toString() ?? '1900-01-01 00:00:00',
            ) ??
            DateTime(1900);
        return dateB.compareTo(dateA); // Newest first
      });
      print('Total bids: ${allBids.length}');
      // Inside the bid processing loop in _loadBids() method
      for (var bid in allBids) {
        print('Processing bid: ${bid['id']} for post: ${bid['post_id']}');

        final postDetails =
            _staticPostCache[bid['post_id']] ?? _postCache[bid['post_id']];
        if (postDetails != null) {
          bid['title'] = postDetails['title'];
          bid['carImage'] = postDetails['image'];
          bid['targetPrice'] = postDetails['price'];
          bid['location'] = postDetails['location'];
          bid['store'] =
              postDetails['by_dealer'] == '1' ? 'Dealer' : 'Individual';
        } else {
          final fetchedPostDetails = await _fetchPostDetails(bid['post_id']);
          if (fetchedPostDetails == null) {
            print('Skipping bid ${bid['id']} due to missing post details');
            continue;
          }
          _postCache[bid['post_id']] = fetchedPostDetails;
          bid['title'] = fetchedPostDetails['title'];
          bid['carImage'] = fetchedPostDetails['image'];
          bid['targetPrice'] = fetchedPostDetails['price'];
          bid['location'] = fetchedPostDetails['location'];
          bid['store'] =
              fetchedPostDetails['by_dealer'] == '1' ? 'Dealer' : 'Individual';
        }

        bid['appId'] = 'APP_${bid['post_id']}';
        bid['bidPrice'] = bid['my_bid_amount']?.toString() ?? '0';
        bid['expirationDate'] = bid['exp_date']?.toString() ?? 'N/A';
        bid['bidDate'] = bid['created_on']?.split(' ')[0] ?? 'N/A';

        // ADD THIS: Fetch highest bid for low bids
        final bool isLowBid = bid['fromLowBids'] == true;
        if (isLowBid && bid['post_id'] != null) {
          developer.log(
            'Fetching highest bid for low bid ${bid['id']} on post ${bid['post_id']}',
          );
          final highestBid = await _fetchCurrentHighestBid(bid['post_id']);
          bid['current_highest_bid'] = highestBid;
          developer.log('Highest bid for post ${bid['post_id']}: $highestBid');
        }

        print(
          'Bid processed: ${bid['title']}, bid_id: ${bid['id']}, fromLowBids: ${bid['fromLowBids']}, fromHighBids: ${bid['fromHighBids']}',
        );
      }
      if (cacheUpdated) {
        _updateStaticCache();
      }
      setState(() {
        bids = allBids;
        isLoading = false;
      });
      print('Bids loaded successfully: ${bids.length} items');
    } catch (e) {
      print('Error loading bids: $e');
      setState(() {
        isLoading = false;
        error = 'Error loading bids: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child:
                  isLoading
                      ? const ShimmerLoading()
                      : error != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.attach_money,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              error!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _forceRefresh,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                      : bids.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No bids found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Place your first bid to see it here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _forceRefresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: bids.length,
                          itemBuilder: (context, index) {
                            final bid = bids[index];
                            return BidCard(
                              bid: bid,
                              baseUrl: widget.baseUrl,
                              token: widget.token,
                              userId: _userId ?? '',
                              onproccedWithBid:
                                  () => _proccedWithBid(
                                    context,
                                    bid['id'],
                                    bid['post_id'],
                                  ),
                              onproccedWithoutBid:
                                  () => _proccedWithoutBid(
                                    context,
                                    bid['post_id'],
                                  ),
                              onIncreaseBid:
                                  () => _increaseBid(
                                    context,
                                    bid['post_id'],
                                    bid['bidPrice'],
                                  ),
                              onCancelBid: () => _cancelBid(context, bid['id']),
                              // ADDED: Delete bid function
                              onDeleteBid:
                                  () => _deleteBid(
                                    bid['id'],
                                    bid['post_id'],
                                    index,
                                  ),
                            );
                          },
                        ),
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
  final VoidCallback onproccedWithBid;
  final VoidCallback onproccedWithoutBid;
  final VoidCallback onIncreaseBid;
  final VoidCallback onCancelBid;
  final VoidCallback onDeleteBid; // ADDED: Delete bid callback

  const BidCard({
    super.key,
    required this.bid,
    required this.baseUrl,
    required this.token,
    required this.userId,
    required this.onproccedWithBid,
    required this.onproccedWithoutBid,
    required this.onIncreaseBid,
    required this.onCancelBid,
    required this.onDeleteBid, // ADDED: Delete bid parameter
  });

  bool get isHighBid => bid['fromHighBids'] == true;

  @override
  Widget build(BuildContext context) {
    print(
      'BidCard - Bid ID: ${bid['id']}, Post ID: ${bid['post_id']}, Type: ${isHighBid ? "High" : "Low"}',
    );

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
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isHighBid ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isHighBid
                                  ? Colors.green[300]!
                                  : Colors.orange[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHighBid ? Icons.trending_up : Icons.trending_down,
                            size: 12,
                            color:
                                isHighBid
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isHighBid ? 'High Bid' : 'Low Bid',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  isHighBid
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // MODIFIED: Added delete button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            size: 22,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _showDeleteConfirmationDialog(context);
                          },
                          tooltip: 'Delete Bid',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bid['title'] ??
                                'Unknown Vehicle (ID: ${bid['post_id']})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
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
                          Row(
                            children: [
                              Icon(
                                Icons.meeting_room,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Meeting Attempts: ${bid['meetingAttempts']?.toString() ?? '0'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 30,
                            child: CallSupportButton(
                              label: 'Call Support',
                              phoneNumber: '+918089308048',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: bid['carImage']?.toString() ?? '',
                        width: 100,
                        height: 150,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              width: 100,
                              height: 150,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                        errorWidget: (context, url, error) {
                          print('Image load error: $error for URL: $url');
                          return Container(
                            width: 100,
                            height: 150,
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
                            bid['bidDate']?.toString() ?? 'N/A',
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
                            bid['expirationDate']?.toString() ?? 'N/A',
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
                // In BidCard's build method, replace the price Row with this:
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
                            bid['targetPrice'] == null ||
                                    double.tryParse(
                                          bid['targetPrice']?.toString() ?? '0',
                                        ) ==
                                        0
                                ? 'N/A'
                                : '₹${NumberFormat('#,##0').format(double.parse(bid['targetPrice'].toString()))}',
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
                            bid['bidPrice'] == null ||
                                    double.tryParse(
                                          bid['bidPrice']?.toString() ?? '0',
                                        ) ==
                                        0
                                ? 'N/A'
                                : '₹${NumberFormat('#,##0').format(double.parse(bid['bidPrice'].toString()))}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  isHighBid
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ADD THIS SECTION: Show current highest bid for low bids
                if (!isHighBid &&
                    bid['current_highest_bid'] != null &&
                    bid['current_highest_bid'] != '0') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 16,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Highest Bid',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${NumberFormat('#,##0').format(double.tryParse(bid['current_highest_bid']) ?? 0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            height: 1.3,
            width: double.infinity,
            color: Colors.grey[300],
          ),
          SizedBox(
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      isHighBid ? 'Schedule meeting' : 'Book a meeting',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu, size: 22),
                  onSelected: (value) {
                    if (value == 'increase_bid') {
                      onIncreaseBid();
                    } else if (value == 'procced_with_bid') {
                      onproccedWithBid();
                    } else if (value == 'procced_without_bid') {
                      onproccedWithoutBid();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    final items = <PopupMenuItem<String>>[
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
                        value: 'procced_without_bid',
                        child: Row(
                          children: [
                            Icon(Icons.event, size: 16, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Meeting without Bid'),
                          ],
                        ),
                      ),
                    ];
                    if (isHighBid) {
                      items.insert(
                        1,
                        const PopupMenuItem<String>(
                          value: 'procced_with_bid',
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
                      );
                    }
                    return items;
                  },
                ),
              ],
            ),
          ),
          Container(
            height: 1.3,
            width: double.infinity,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isHighBid
                        ? 'For high bid meeting, Meeting must be done in 24hrs if seller accepts the bid.'
                        : 'For low bids, schedule a meeting to discuss further with the seller.',
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
    );
  }

  // ADDED: Delete confirmation dialog
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Bid'),
          content: const Text(
            'Are you sure you want to delete this bid? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDeleteBid();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 80,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 16,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 100,
                                  height: 12,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 150,
                                  height: 12,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 80,
                                  height: 12,
                                  color: Colors.grey[300],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 100,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                                Container(
                                  width: 80,
                                  height: 10,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 100,
                                  height: 12,
                                  color: Colors.grey[300],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 80,
                                  height: 10,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 100,
                                  height: 12,
                                  color: Colors.grey[300],
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
                                Container(
                                  width: 80,
                                  height: 10,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 100,
                                  height: 14,
                                  color: Colors.grey[300],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 80,
                                  height: 10,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 100,
                                  height: 14,
                                  color: Colors.grey[300],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1.3,
                  width: double.infinity,
                  color: Colors.grey[300],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  height: 30,
                  color: Colors.grey[300],
                ),
                Container(
                  height: 1.3,
                  width: double.infinity,
                  color: Colors.grey[300],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  height: 40,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
