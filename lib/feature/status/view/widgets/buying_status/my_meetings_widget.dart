import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/meetingcard_widget.dart';
import 'package:provider/provider.dart';
import 'package:retry/retry.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/call_support/call_support.dart';

// MyMeetingsWidget
class MyMeetingsWidget extends StatefulWidget {
  final String baseUrl;
  final String token;
  final String? initialStatus;
  final String? postId;
  final String? bidId;
  final Map<String, dynamic>? bid;
  final VoidCallback? onRefreshMeetings;
  final bool showAppBar;
  final bool forceRefresh;

  const MyMeetingsWidget({
    super.key,
    this.baseUrl = 'https://lelamonline.com/admin/api/v1',
    this.token = '5cb2c9b569416b5db1604e0e12478ded',
    this.initialStatus,
    this.postId,
    this.bidId,
    this.bid,
    this.onRefreshMeetings,
    this.showAppBar = true,
    this.forceRefresh = false,
  });

  // Static method to clear cache (call on logout)
  static void clearCache() {
    _MyMeetingsWidgetState._staticMeetingsCache.clear();
    _MyMeetingsWidgetState._staticPostDetailsCache.clear();
    _MyMeetingsWidgetState._staticMeetingTimesCache.clear();
    _MyMeetingsWidgetState._lastCacheUpdate = null;
    developer.log('MyMeetingsWidget static cache cleared');
  }

  @override
  State<MyMeetingsWidget> createState() => _MyMeetingsWidgetState();
}

class _MyMeetingsWidgetState extends State<MyMeetingsWidget>
    with SingleTickerProviderStateMixin {
  // Static caches that persist across widget instances
  static final List<Map<String, dynamic>> _staticMeetingsCache = [];
  static final Map<String, Map<String, dynamic>> _staticPostDetailsCache = {};
  static final List<Map<String, String>> _staticMeetingTimesCache = [];
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(
    minutes: 3,
  ); // 3 minutes cache expiry
  final Set<String> _processedMeetingIds = <String>{};
  bool _isCurrentlyLoading = false;
  final List<String> statuses = [
    'Date Fixed',
    'Meeting Request',
    'Awaiting Location',
    'Ready For Meeting',
    'Meeting Completed',
  ];
  late TabController _tabController;
  int selectedIndex = 0;
  List<Map<String, dynamic>> meetings = [];
  String? errorMessage;
  bool isLoading = true;
  String? _userId;
  Timer? _debounce;
  final Map<String, Map<String, dynamic>> _postDetailsCache = {};
  List<Map<String, String>> _meetingTimesCache = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null &&
        statuses.contains(widget.initialStatus)) {
      selectedIndex = statuses.indexOf(widget.initialStatus!);
    }
    _tabController = TabController(
      initialIndex: selectedIndex,
      length: statuses.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (_tabController.index != selectedIndex) {
        setState(() {
          selectedIndex = _tabController.index;
        });
        _manageRefreshTimer();
        _checkAndUseStaticCache();
        _loadMeetingsIfNeeded();
      }
    });
    // Check for forceRefresh and clear cache if needed
    if (widget.forceRefresh) {
      developer.log('Force refresh triggered from widget parameter');
      _forceRefresh();
    } else {
      _checkAndUseStaticCache();
      _loadMeetingsIfNeeded();
    }
    _loadUserId();
  }

  @override
  void didUpdateWidget(MyMeetingsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle forceRefresh when widget is updated
    if (widget.forceRefresh && !oldWidget.forceRefresh) {
      developer.log('Force refresh triggered from widget update');
      _forceRefresh();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  /// Check if static cache is valid and use it
  void _checkAndUseStaticCache() {
    final now = DateTime.now();
    final cacheValid =
        _lastCacheUpdate != null &&
        now.difference(_lastCacheUpdate!) < _cacheExpiry &&
        _staticMeetingsCache.isNotEmpty;

    if (cacheValid && mounted) {
      developer.log(
        'Using static cache for meetings - valid until ${_lastCacheUpdate!.add(_cacheExpiry)}',
      );

      // Copy static cache to instance
      setState(() {
        meetings = List.from(_staticMeetingsCache);
        isLoading = false;
      });
      return;
    }

    developer.log('Static cache invalid or empty, will fetch fresh data');
  }

  /// Update static cache after successful fetch
  void _updateStaticCache() {
    _staticMeetingsCache.clear();
    _staticMeetingsCache.addAll(meetings);
    _staticPostDetailsCache.clear();
    _staticPostDetailsCache.addAll(_postDetailsCache);
    _staticMeetingTimesCache.clear();
    _staticMeetingTimesCache.addAll(_meetingTimesCache);
    _lastCacheUpdate = DateTime.now();

    developer.log(
      'Static cache updated at $_lastCacheUpdate with ${meetings.length} meetings',
    );
  }

  /// Force refresh - clears static cache and refetches
  Future<void> _forceRefresh() async {
    developer.log('Force refreshing meetings - clearing static cache');
    _staticMeetingsCache.clear();
    _staticPostDetailsCache.clear();
    _staticMeetingTimesCache.clear();
    _lastCacheUpdate = null;
    _postDetailsCache.clear();
    _meetingTimesCache.clear();

    await _loadMeetings();
  }

  /// Load meetings only if cache is invalid or empty
  Future<void> _loadMeetingsIfNeeded() async {
    if (meetings.isNotEmpty && !isLoading) {
      developer.log('Using existing valid cache');
      return;
    }
    await _loadMeetings();
  }

  void _manageRefreshTimer() {
    _refreshTimer?.cancel();
    if (selectedIndex == 2) {
      // Awaiting Location
      _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
        if (mounted && selectedIndex == 2) {
          developer.log('Periodic refresh for Awaiting Location');
          _forceRefresh(); // Use force refresh for critical tab
        } else {
          timer.cancel();
        }
      });
    }
  }

  Future<void> _loadUserId() async {
    try {
      final userProvider = Provider.of<LoggedUserProvider>(
        context,
        listen: false,
      );
      final userData = userProvider.userData;
      setState(() {
        _userId = userData?.userId ?? 'Unknown';
        developer.log('Loaded userId: $_userId');
        if (_userId == 'Unknown') {
          errorMessage = 'Please log in.';
          isLoading = false;
        }
      });
      if (_userId != 'Unknown') {
        _checkAndUseStaticCache();
        await _loadMeetingsIfNeeded();
        _manageRefreshTimer();
      }
    } catch (e) {
      developer.log('Error loading userId: $e');
      setState(() {
        errorMessage = 'Error loading user ID: $e';
        isLoading = false;
      });
    }
  }

  /// Handle meeting deletion callback from MeetingCard - triggers force refresh
  /// Handle meeting deletion callback from MeetingCard - remove immediately from UI
  /// Handle meeting deletion with immediate removal from UI
  /// Handle meeting deletion with immediate removal from UI
  /// Handle meeting deletion with page refresh
  /// Handle meeting deletion with immediate page refresh
  /// Handle meeting deletion with immediate page refresh
  void _handleMeetingDelete(Map<String, dynamic> deletedMeeting) async {
    try {
      final String meetingId = deletedMeeting['id']!.toString();
      developer.log(
        'Meeting deletion callback received for meeting: $meetingId',
      );

      // Show success message FIRST
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting deleted successfully')),
      );

      // THEN FORCE REFRESH - exactly like Fix Time does
      await _forceRefresh();

      developer.log('Page refresh completed after deletion');
    } catch (e) {
      developer.log('Error in _handleMeetingDelete: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error deleting meeting')));
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchPostDetails(String postId) async {
    // Check static cache first, then instance cache
    final cachedPost =
        _staticPostDetailsCache[postId] ?? _postDetailsCache[postId];
    if (cachedPost != null) {
      developer.log('Returning cached post details for post_id $postId');
      return cachedPost;
    }

    try {
      final response = await retry(
        () => http.get(
          Uri.parse(
            '${widget.baseUrl}/post-details.php?token=${widget.token}&post_id=$postId',
          ),
          headers: {
            'token': widget.token,
            'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
          },
        ),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 2),
        randomizationFactor: 0.25,
        onRetry:
            (e) =>
                developer.log('Retrying post-details for post_id $postId: $e'),
      );
      developer.log(
        'post-details.php response for post_id $postId: ${response.body}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          Map<String, dynamic>? postData =
              data['data'] is List && data['data'].isNotEmpty
                  ? data['data'][0]
                  : data['data'] is Map
                  ? data['data']
                  : null;
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
            final postDetails = {
              'title': postData['title'] ?? 'Unknown Vehicle (ID: $postId)',
              'price': postData['price']?.toString() ?? '0',
              'image': fullImageUrl,
              'location':
                  postData['land_mark']?.toString() ?? 'Unknown Location',
              'by_dealer': postData['by_dealer']?.toString() ?? '0',
              'created_by':
                  postData['created_by']?.toString() ?? '', // Added seller ID
            };
            _postDetailsCache[postId] = postDetails; // Cache in instance
            return postDetails;
          }
        }
      } else if (response.statusCode == 429) {
        developer.log('Rate limit exceeded for post-details.php');
        if (mounted) {
          setState(() {
            errorMessage = 'Too many requests. Please try again later.';
          });
        }
      }
      developer.log('No valid post data for post_id $postId');
      return null;
    } catch (e) {
      developer.log('Error fetching post details for post_id $postId: $e');
      return null;
    }
  }

  Future<List<Map<String, String>>> _fetchMeetingTimes() async {
    // Check static cache first, then instance cache
    if (_staticMeetingTimesCache.isNotEmpty) {
      developer.log('Returning static cached meeting times');
      return List.from(_staticMeetingTimesCache);
    }
    if (_meetingTimesCache.isNotEmpty) {
      developer.log('Returning instance cached meeting times');
      return List.from(_meetingTimesCache);
    }

    try {
      final response = await retry(
        () => http.get(
          Uri.parse(
            '${widget.baseUrl}/meeting-times.php?token=${widget.token}',
          ),
          headers: {
            'token': widget.token,
            'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
          },
        ),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 2),
        randomizationFactor: 0.25,
        onRetry: (e) => developer.log('Retrying meeting-times: $e'),
      );
      developer.log('meeting-times.php response: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          if (data['data'] is List && data['data'].isNotEmpty) {
            final times = List<Map<String, String>>.from(
              data['data'].map(
                (item) => {
                  'name': item['name']?.toString() ?? '',
                  'value': item['value']?.toString() ?? '',
                },
              ),
            );
            _meetingTimesCache = times; // Cache in instance
            return times;
          }
        }
      } else if (response.statusCode == 429) {
        developer.log('Rate limit exceeded for meeting-times.php');
        if (mounted) {
          setState(() {
            errorMessage = 'Too many requests. Please try again later.';
          });
        }
      }
      return [];
    } catch (e) {
      developer.log('Error fetching meeting times: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchMeetingStatus(
    String meetingId,
    String status,
  ) async {
    try {
      String endpoint;
      switch (status) {
        case 'Meeting Request':
          endpoint = 'my-meeting-request-post-status.php';
          break;
        case 'Awaiting Location':
          endpoint = 'my-meeting-awaitinglocation-post-status.php';
          break;
        case 'Ready For Meeting':
          endpoint = 'my-meeting-readyformeeting-post-status.php';
          break;
        case 'Meeting Completed':
          endpoint = 'my-meeting-done.php';
          break;
        case 'Date Fixed':
        default:
          endpoint = 'my-meeting-request-post-status.php';
          break;
      }
      final response = await retry(
        () => http.get(
          Uri.parse(
            '${widget.baseUrl}/$endpoint?token=${widget.token}&ads_post_customer_meeting_id=$meetingId',
          ),
          headers: {
            'token': widget.token,
            'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
          },
        ),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 2),
        randomizationFactor: 0.25,
        onRetry:
            (e) => developer.log(
              'Retrying $endpoint for meeting_id $meetingId: $e',
            ),
      );
      developer.log(
        '$endpoint response for meeting_id $meetingId: ${response.body}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          final statusData =
              data['data'] is List && data['data'].isNotEmpty
                  ? data['data'][0]
                  : data['data'] is Map
                  ? data['data']
                  : null;
          if (statusData != null) {
            return {
              'middleStatus_data':
                  statusData['middle_status']?.toString() ?? 'Schedule meeting',
              'footerStatus_data':
                  statusData['Footer_status']?.toString() ??
                  'Due to convenience reasons meeting location can be requested 24 hrs before meeting time only',
              'timer': statusData['timer']?.toString() ?? '0',
            };
          }
        }
      } else if (response.statusCode == 429) {
        developer.log('Rate limit exceeded for $endpoint');
        if (mounted) {
          setState(() {
            errorMessage = 'Too many requests. Please try again later.';
          });
        }
      }
      developer.log('No valid status data for meeting_id $meetingId');
      return {
        'middleStatus_data': 'Schedule meeting',
        'footerStatus_data':
            'Due to convenience reasons meeting location can be requested 24 hrs before meeting time only',
        'timer': '0',
      };
    } catch (e) {
      developer.log(
        'Error fetching meeting status for meeting_id $meetingId: $e',
      );
      return {
        'middleStatus_data': 'Schedule meeting',
        'footerStatus_data':
            'Due to convenience reasons meeting location can be requested 24 hrs before meeting time only',
        'timer': '0',
      };
    }
  }

  Future<void> _loadMeetings() async {
    // Prevent multiple simultaneous loads
    if (_isCurrentlyLoading) {
      developer.log('=== LOAD MEETINGS ALREADY IN PROGRESS, SKIPPING ===');
      return;
    }

    _isCurrentlyLoading = true;
    developer.log('=== LOAD MEETINGS STARTED ===');
    developer.log('Current meetings count before load: ${meetings.length}');
    developer.log('Force refresh: ${widget.forceRefresh}');

    // Clear the processed IDs tracker
    _processedMeetingIds.clear();

    if (!mounted || _userId == null || _userId == 'Unknown') {
      developer.log('Skipping load: Invalid user ID or not mounted');
      _isCurrentlyLoading = false;
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      meetings = []; // CLEAR meetings at start
    });

    try {
      final headers = {
        'token': widget.token,
        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
      };

      String url =
          '${widget.baseUrl}/my-meeting-request.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}';
      developer.log('Fetching meetings from: $url');

      final response = await retry(
        () => http.get(Uri.parse(url), headers: headers),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 2),
        randomizationFactor: 0.25,
        onRetry: (e) => developer.log('Retrying meetings fetch: $e'),
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        developer.log('Raw API response received');
        developer.log('Response data type: ${responseData.runtimeType}');

        if (responseData is Map<String, dynamic> &&
            (responseData['status'] == true ||
                responseData['status'] == 'true') &&
            responseData['data'] is List) {
          final List<dynamic> meetingData = responseData['data'];
          developer.log('Found ${meetingData.length} meetings in API response');

          final List<Map<String, dynamic>> newMeetings = [];

          for (var i = 0; i < meetingData.length; i++) {
            final meeting = meetingData[i];
            final String meetingId = meeting['id']?.toString() ?? 'unknown_$i';
            developer.log('Processing meeting [$i]: ID: $meetingId');

            // Check for duplicate meeting IDs in THIS API response
            if (_processedMeetingIds.contains(meetingId)) {
              developer.log(
                '=== DUPLICATE MEETING DETECTED IN API RESPONSE: $meetingId ===',
              );
              continue; // Skip this duplicate
            }
            _processedMeetingIds.add(meetingId);

            developer.log(
              'Processing meeting: id=${meeting['id']}, date=${meeting['meeting_date']}, time=${meeting['meeting_time']}, done=${meeting['meeting_done']}, seller_approvel=${meeting['seller_approvel']}',
            );

            Map<String, dynamic>? postDetails;
            // Only fetch post details if post_id is valid (not 0)
            if (meeting['post_id'] != null &&
                meeting['post_id'] != '0' &&
                meeting['post_id'] != 0) {
              postDetails = await _fetchPostDetails(meeting['post_id']);
            }

            // If post details fetch failed or post_id is 0, create default post details
            if (postDetails == null) {
              postDetails = {
                'title': 'Vehicle (ID: ${meeting['post_id'] ?? 'Unknown'})',
                'price': '0',
                'image': '',
                'location': 'Unknown Location',
                'by_dealer': '0',
                'created_by': '', // Default empty
              };
              developer.log(
                'Using default post details for meeting ${meeting['id']}',
              );
            }

            final meetingDataMap = <String, dynamic>{
              'id': meeting['id']?.toString() ?? 'N/A',
              'user_id':
                  meeting['user_id']?.toString() ?? _userId, // Buyer's ID
              'post_id': meeting['post_id']?.toString() ?? 'N/A',
              'bid_id': meeting['bid_id']?.toString() ?? '0',
              'with_bid': meeting['with_bid']?.toString() ?? '0',
              'bid_amount': meeting['bid_amount']?.toString() ?? '0.00',
              'meeting_date': meeting['meeting_date']?.toString() ?? 'N/A',
              'meeting_time': meeting['meeting_time']?.toString() ?? 'N/A',
              'if_location_request':
                  meeting['if_location_request']?.toString() ?? '0',
              'latitude': meeting['latitude']?.toString() ?? '',
              'longitude': meeting['longitude']?.toString() ?? '',
              'location_link': meeting['location_link']?.toString() ?? '',
              'location_request_count':
                  meeting['location_request_count']?.toString() ?? '0',
              'seller_approvel': meeting['seller_approvel']?.toString() ?? '0',
              'admin_approvel': meeting['admin_approvel']?.toString() ?? '0',
              'status': meeting['status']?.toString() ?? '1',
              'meeting_done': meeting['meeting_done']?.toString() ?? '0',
              'if_junk': meeting['if_junk']?.toString() ?? '0',
              'if_reschedule': meeting['if_reschedule']?.toString() ?? '0',
              'if_skipped': meeting['if_skipped']?.toString() ?? '0',
              'if_not_intersect':
                  meeting['if_not_intersect']?.toString() ?? '0',
              'if_revisit': meeting['if_revisit']?.toString() ?? '0',
              'if_decisionpedding':
                  meeting['if_decisionpedding']?.toString() ?? '0',
              'if_expired': meeting['if_expired']?.toString() ?? '0',
              'if_cancel': meeting['if_cancel']?.toString() ?? '0',
              'if_sold': meeting['if_sold']?.toString() ?? '0',
              'if_reject_bid': meeting['if_reject_bid']?.toString() ?? '0',
              'price_offered': meeting['price_offered']?.toString() ?? '0.00',
              'created_on':
                  meeting['created_on']?.toString() ??
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
              'updated_on':
                  meeting['updated_on']?.toString() ??
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
              'title':
                  postDetails['title'] ??
                  'Unknown Vehicle (ID: ${meeting['post_id']})',
              'carImage': postDetails['image'] ?? '',
              'appId': 'APP_${meeting['post_id']}',
              'bidDate':
                  meeting['created_on']?.toString().split(' ')[0] ?? 'N/A',
              'expirationDate': meeting['exp_date']?.toString() ?? 'N/A',
              'targetPrice': postDetails['price'] ?? '0',
              'bidPrice': meeting['bid_amount']?.toString() ?? '0',
              'location': postDetails['location'] ?? 'Unknown Location',
              'store':
                  postDetails['by_dealer'] == '1' ? 'Dealer' : 'Individual',
              'if_auction': meeting['if_auction']?.toString() ?? '0',
              'middleStatus_data': 'Schedule meeting',
              'footerStatus_data':
                  'Due to convenience reasons meeting location can be requested 24 hrs before meeting time only',
              'timer': '0',
              'parent_zone_id': meeting['parent_zone_id']?.toString() ?? '',
              'created_by': postDetails['created_by'] ?? '', // Added seller ID
            };

            developer.log(
              'Added meeting ${meeting['id']} to list: Date: ${meetingDataMap['meeting_date']}, Time: ${meetingDataMap['meeting_time']}, Seller ID: ${meetingDataMap['created_by']}',
            );
            newMeetings.add(meetingDataMap);
          }

          developer.log(
            'Total unique meetings processed: ${newMeetings.length}',
          );

          // Check for duplicates in the final list
          final meetingIds = newMeetings.map((m) => m['id']).toList();
          final uniqueIds = meetingIds.toSet();
          if (meetingIds.length != uniqueIds.length) {
            developer.log('=== FINAL DUPLICATE CHECK: DUPLICATES FOUND ===');
            developer.log(
              'Total meetings: ${meetingIds.length}, Unique meetings: ${uniqueIds.length}',
            );
            developer.log(
              'Duplicate IDs: ${meetingIds.where((id) => meetingIds.where((i) => i == id).length > 1).toSet()}',
            );
          } else {
            developer.log('=== FINAL DUPLICATE CHECK: NO DUPLICATES ===');
          }

          // Update static cache after successful fetch
          _updateStaticCache();

          // Update state with new meetings
          setState(() {
            meetings = newMeetings;
            isLoading = false;
          });

          developer.log(
            'Meetings loaded successfully: ${meetings.length} items',
          );
        } else {
          developer.log(
            'Unexpected response format: ${responseData.toString()}',
          );
          setState(() {
            errorMessage = 'Currently No Meeting';
            isLoading = false;
          });
        }
      } else if (response.statusCode == 429) {
        developer.log('Rate limit exceeded for meetings fetch');
        setState(() {
          errorMessage = 'Too many requests. Please try again later.';
          isLoading = false;
        });
      } else {
        developer.log('Failed to fetch meetings: ${response.reasonPhrase}');
        setState(() {
          errorMessage = 'Failed to fetch meetings: ${response.reasonPhrase}';
          isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading meetings: $e');
      setState(() {
        errorMessage = 'Error loading meetings: $e';
        isLoading = false;
      });
    } finally {
      _isCurrentlyLoading = false;
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }

    developer.log(
      '=== LOAD MEETINGS COMPLETED - ${meetings.length} meetings ===',
    );
  }

  List<Map<String, dynamic>> _getFilteredMeetings() {
    final status = statuses[selectedIndex];
    var filteredMeetings =
        meetings.where((meeting) {
          if (status == 'Date Fixed') {
            // REMOVED: meeting['meeting_done'] == '0' &&
            return meeting['meeting_date'] != 'N/A' &&
                meeting['meeting_date']?.isNotEmpty == true &&
                meeting['meeting_date'] != '1970-01-01';
          } else if (status == 'Meeting Request') {
            // REMOVED: meeting['meeting_done'] == '0' &&
            return (meeting['meeting_date'] == 'N/A' ||
                meeting['meeting_date']?.isEmpty == true ||
                meeting['meeting_date'] == '1970-01-01');
          } else if (status == 'Awaiting Location') {
            // REMOVED: meeting['meeting_done'] == '0' &&
            return meeting['meeting_time'] != 'N/A' &&
                meeting['meeting_time']?.isNotEmpty == true &&
                meeting['meeting_time'] != '00:00:00';
          } else if (status == 'Ready For Meeting') {
            // REMOVED: meeting['meeting_done'] == '0' &&
            return meeting['seller_approvel'] == '1';
          } else if (status == 'Meeting Completed') {
            return meeting['meeting_done'] == '1';
          }
          return false;
        }).toList();

    filteredMeetings.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['updated_on'] ?? a['created_on'] ?? '') ??
          DateTime.now();
      final bDate =
          DateTime.tryParse(b['updated_on'] ?? b['created_on'] ?? '') ??
          DateTime.now();
      return bDate.compareTo(aDate);
    });

    developer.log(
      'Filtered meetings count for $status: ${filteredMeetings.length}',
    );

    // Debug: Print all filtered meetings
    for (var meeting in filteredMeetings) {
      developer.log(
        'Filtered meeting: ${meeting['id']} - Date: ${meeting['meeting_date']}, Time: ${meeting['meeting_time']}, Meeting Done: ${meeting['meeting_done']}, Seller ID: ${meeting['created_by']}',
      );
    }

    return filteredMeetings;
  }

  Widget _buildMeetingList() {
    // Get filtered meetings dynamically each time
    final filteredMeetings = _getFilteredMeetings();

    developer.log(
      'Building meeting list for ${statuses[selectedIndex]}: ${filteredMeetings.length} meetings',
    );

    return isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.blue))
        : errorMessage != null
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.handshake, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
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
        : filteredMeetings.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.handshake, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No meetings found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have no meetings at this time',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _forceRefresh,
                child: const Text('Refresh'),
              ),
            ],
          ),
        )
        : RefreshIndicator(
          onRefresh: _forceRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredMeetings.length,
            itemBuilder: (context, index) {
              final meeting = filteredMeetings[index];
              developer.log(
                'Displaying meeting: ${meeting['id']}, seller ID: ${meeting['created_by']}',
              );
              return MeetingCard(
                meeting: meeting,
                baseUrl: widget.baseUrl,
                token: widget.token,
                currentTab: statuses[selectedIndex],
                onEditDate: (meeting) => _editDate(context, meeting),
                onEditTime: (meeting) => _editTime(context, meeting),
                onDelete: _handleMeetingDelete,
                onRefresh: _forceRefresh,
              );
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          widget.showAppBar
              ? AppBar(
                title: Row(
                  children: [
                    const Text('My Meetings'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_getFilteredMeetings().length} Meetings',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _forceRefresh,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh meetings (clears cache)',
                    ),
                  ],
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: statuses.map((status) => Tab(text: status)).toList(),
                ),
              )
              : null,
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(statuses.length, (_) => _buildMeetingList()),
        ),
      ),
    );
  }

  Future<void> _editTime(
    BuildContext context,
    Map<String, dynamic> meeting,
  ) async {
    if (_userId == null || _userId == 'Unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid user ID. Please log in again.')),
      );
      return;
    }
    final meetingTimes = await _fetchMeetingTimes();
    if (meetingTimes.isEmpty) {
      developer.log('No meeting times available');
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
                            meetingTimes
                                .map(
                                  (time) => DropdownMenuItem<String>(
                                    value: time['value'],
                                    child: Text(time['name']!),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTimeValue = value;
                            selectedTimeName =
                                meetingTimes.firstWhere(
                                  (time) => time['value'] == value,
                                  orElse: () => {'name': ''},
                                )['name'];
                            developer.log(
                              'Selected time: $selectedTimeName ($selectedTimeValue)',
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed:
                          selectedTimeValue == null
                              ? null
                              : () async {
                                developer.log(
                                  'Submitting meeting time: $selectedTimeValue for meeting_id: ${meeting['id']}',
                                );
                                try {
                                  final response = await http.get(
                                    Uri.parse(
                                      '${widget.baseUrl}/my-meeting-fix-time.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}&post_id=${meeting['post_id']}&meeting_id=${meeting['id']}&meeting_time=$selectedTimeValue',
                                    ),
                                    headers: {
                                      'token': widget.token,
                                      'Cookie':
                                          'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
                                    },
                                  );
                                  developer.log(
                                    'my-meeting-fix-time.php response: ${response.body}',
                                  );
                                  if (response.statusCode == 200) {
                                    final data = jsonDecode(response.body);
                                    if (data['status'] == true ||
                                        data['status'] == 'true') {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Time updated to $selectedTimeName',
                                          ),
                                        ),
                                      );
                                      await _forceRefresh(); // Force refresh after update
                                      widget.onRefreshMeetings?.call();
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to update time: ${data['message'] ?? 'Unknown error'}',
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    developer.log(
                                      'my-meeting-fix-time.php failed with status ${response.statusCode}',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to update time'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  developer.log(
                                    'Error updating meeting time: $e',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Error updating meeting time',
                                      ),
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

  Future<void> _editDate(
    BuildContext context,
    Map<String, dynamic> meeting,
  ) async {
    if (_userId == null || _userId == 'Unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid user ID. Please log in again.')),
      );
      return;
    }
    DateTime selectedDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      final String meetingDate = DateFormat('yyyy-MM-dd').format(picked);
      try {
        final response = await retry(
          () => http.get(
            Uri.parse(
              '${widget.baseUrl}/my-meeting-edit-date.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}&post_id=${meeting['post_id']}&meeting_id=${meeting['id']}&meeting_date=$meetingDate',
            ),
            headers: {
              'token': widget.token,
              'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
            },
          ),
          maxAttempts: 3,
          delayFactor: const Duration(seconds: 2),
          randomizationFactor: 0.25,
          onRetry: (e) => developer.log('Retrying edit date: $e'),
        );
        developer.log('my-meeting-edit-date.php response: ${response.body}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == true || data['status'] == 'true') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Date updated successfully')),
            );
            await _forceRefresh(); // Force refresh after update
            widget.onRefreshMeetings?.call();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to update date: ${data['message'] ?? 'Unknown error'}',
                ),
              ),
            );
          }
        } else if (response.statusCode == 429) {
          developer.log('Rate limit exceeded for edit date');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Too many requests. Please try again later.'),
            ),
          );
        } else {
          developer.log(
            'my-meeting-edit-date.php failed with status ${response.statusCode}',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update date')),
          );
        }
      } catch (e) {
        developer.log('Error updating meeting date: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating meeting date')),
        );
      }
    }
  }
}
