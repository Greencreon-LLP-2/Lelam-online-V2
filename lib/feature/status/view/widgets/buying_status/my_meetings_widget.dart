import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/meetingcard_widget.dart';
import 'package:provider/provider.dart';
import 'package:retry/retry.dart';
import 'dart:developer' as developer;
import 'package:url_launcher/url_launcher.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback? onTap;

  const StatusPill({
    super.key,
    required this.label,
    this.isActive = false,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? activeColor : inactiveColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : Colors.black,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class PillConnector extends StatelessWidget {
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  const PillConnector({
    super.key,
    this.isActive = false,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class MyMeetingsWidget extends StatefulWidget {
  final String baseUrl;
  final String token;
  final String? initialStatus;
  final String? postId;
  final String? bidId;
  final Map<String, dynamic>? bid;
  final VoidCallback? onRefreshMeetings;

  const MyMeetingsWidget({
    super.key,
    this.baseUrl = 'https://lelamonline.com/admin/api/v1',
    this.token = '5cb2c9b569416b5db1604e0e12478ded',
    this.initialStatus,
    this.postId,
    this.bidId,
    this.bid,
    this.onRefreshMeetings,
  });

  @override
  State<MyMeetingsWidget> createState() => _MyMeetingsWidgetState();
}

class _MyMeetingsWidgetState extends State<MyMeetingsWidget> {
  final List<String> statuses = [
    'Date Fixed',
    'Meeting Request',
    'Awaiting Location',
    'Ready For Meeting',
    'Meeting Completed',
  ];
  int selectedIndex = 0;
  List<Map<String, dynamic>> meetings = [];
  String? errorMessage;
  bool isLoading = true;
  String? _userId;
  Timer? _debounce;
  final Map<String, Map<String, dynamic>> _postDetailsCache = {};
  List<Map<String, String>> _meetingTimesCache = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null &&
        statuses.contains(widget.initialStatus)) {
      selectedIndex = statuses.indexOf(widget.initialStatus!);
    }
    _loadUserId();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  List<Widget> _buildPillRow() {
    List<Widget> pillRow = [];
    for (var i = 0; i < statuses.length; i++) {
      pillRow.add(
        StatusPill(
          label: statuses[i],
          isActive: i == selectedIndex,
          activeColor: Colors.blue,
          onTap: () {
            if (mounted) {
              setState(() {
                selectedIndex = i;
                developer.log('Selected tab: ${statuses[i]}');
              });
              _loadMeetings();
            }
          },
        ),
      );
      // Add the connector if not the last pill
      if (i != statuses.length - 1) {
        pillRow.add(
          PillConnector(
            isActive: (i == selectedIndex || i + 1 == selectedIndex),
            activeColor: Colors.blue,
            inactiveColor: Colors.grey,
          ),
        );
      }
    }
    return pillRow;
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
          errorMessage = 'User ID not found. Please log in again.';
          isLoading = false;
        }
      });
      if (_userId != 'Unknown') {
        await _loadMeetings();
      }
    } catch (e) {
      developer.log('Error loading userId: $e');
      setState(() {
        errorMessage = 'Error loading user ID: $e';
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchPostDetails(String postId) async {
    if (_postDetailsCache.containsKey(postId)) {
      developer.log('Returning cached post details for post_id $postId');
      return _postDetailsCache[postId];
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
        onRetry: (e) {
          developer.log('Retrying post-details for post_id $postId: $e');
        },
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
            };

            return postDetails;
          }
        }
      } else if (response.statusCode == 429) {
        developer.log('Rate limit exceeded for post-details.php');
        setState(() {
          errorMessage = 'Too many requests. Please try again later.';
        });
      }
      developer.log('No valid post data for post_id $postId');
      return null;
    } catch (e) {
      developer.log('Error fetching post details for post_id $postId: $e');
      return null;
    }
  }

  Future<List<Map<String, String>>> _fetchMeetingTimes() async {
    if (_meetingTimesCache.isNotEmpty) {
      developer.log('Returning cached meeting times');
      return _meetingTimesCache;
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
        onRetry: (e) {
          developer.log('Retrying meeting-times: $e');
        },
      );
      developer.log('meeting-times.php response: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          if (data['data'] is List && data['data'].isNotEmpty) {
            _meetingTimesCache = List<Map<String, String>>.from(
              data['data'].map(
                (item) => {
                  'name': item['name']?.toString() ?? '',
                  'value': item['value']?.toString() ?? '',
                },
              ),
            );

            return _meetingTimesCache;
          }
        }
      } else if (response.statusCode == 429) {
        developer.log('Rate limit exceeded for meeting-times.php');
        setState(() {
          errorMessage = 'Too many requests. Please try again later.';
        });
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
        onRetry: (e) {
          developer.log('Retrying $endpoint for meeting_id $meetingId: $e');
        },
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
                  'Click call support for full details',
              'timer': statusData['timer']?.toString() ?? '0',
            };
          }
        }
      } else if (response.statusCode == 429) {
        developer.log('Rate limit exceeded for $endpoint');
        setState(() {
          errorMessage = 'Too many requests. Please try again later.';
        });
      }
      developer.log('No valid status data for meeting_id $meetingId');
      return {
        'middleStatus_data': 'Schedule meeting',
        'footerStatus_data': 'Click call support for full details',
        'timer': '0',
      };
    } catch (e) {
      developer.log(
        'Error fetching meeting status for meeting_id $meetingId: $e',
      );
      return {
        'middleStatus_data': 'Schedule meeting',
        'footerStatus_data': 'Click call support for full details',
        'timer': '0',
      };
    }
  }

  Future<void> _loadMeetings() async {
    if (!mounted || _userId == null || _userId == 'Unknown') {
      setState(() {
        isLoading = false;
        errorMessage = 'Cannot load meetings: Invalid user ID';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      meetings = [];
    });

    try {
      final headers = {
        'token': widget.token,
        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
      };
      String url;
      switch (selectedIndex) {
        case 0:
          url =
              '${widget.baseUrl}/my-meeting-date-fix.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}';
          break;
        case 1:
          url =
              '${widget.baseUrl}/my-meeting-request.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}';
          break;
        case 2:
          url =
              '${widget.baseUrl}/my-meeting-awaiting-location.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}';
          break;
        case 3:
          url =
              '${widget.baseUrl}/my-meeting-ready-for-meeting.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}';
          break;
        default:
          url =
              '${widget.baseUrl}/my-meeting-done.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}';
          break;
      }
      developer.log('Fetching meetings from: $url');
      final response = await retry(
        () => http.get(Uri.parse(url), headers: headers),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 2),
        randomizationFactor: 0.25,
        onRetry: (e) {
          developer.log('Retrying meetings fetch: $e');
        },
      );
      developer.log('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic> &&
            (responseData['status'] == true ||
                responseData['status'] == 'true') &&
            responseData['data'] is List) {
          final List<dynamic> meetingData = responseData['data'];
          developer.log('Found ${meetingData.length} meetings in API response');

          for (var meeting in meetingData) {
            developer.log(
              'Processing meeting: id=${meeting['id']}, bid_id=${meeting['bid_id']}, post_id=${meeting['post_id']}, user_id=${meeting['user_id'] ?? _userId}, seller_approvel=${meeting['seller_approvel']}, admin_approvel=${meeting['admin_approvel']}, meeting_done=${meeting['meeting_done']}, meeting_date=${meeting['meeting_date']}, meeting_time=${meeting['meeting_time']}',
            );
            final postDetails = await _fetchPostDetails(meeting['post_id']);
            if (postDetails == null) {
              developer.log(
                'Skipping meeting ${meeting['id']} due to missing post details',
              );
              continue;
            }
            final statusData = await _fetchMeetingStatus(
              meeting['id'],
              statuses[selectedIndex],
            );
            final meetingData = <String, dynamic>{
              'id': meeting['id']?.toString() ?? 'N/A',
              'user_id': meeting['user_id']?.toString() ?? _userId,
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
              'middleStatus_data':
                  statusData?['middleStatus_data'] ?? 'Schedule meeting',
              'footerStatus_data':
                  statusData?['footerStatus_data'] ??
                  'Click call support for full details',
              'timer': statusData?['timer'] ?? '0',
            };
            developer.log(
              'Added meeting ${meeting['id']} to list: $meetingData',
            );
            developer.log(
              'Meeting ${meeting['id']}: bid_amount=${meetingData['bid_amount']}, bid_id=${meetingData['bid_id']}, post_id=${meetingData['post_id']}',
            );
            meetings.add(meetingData);
            await Future.delayed(const Duration(milliseconds: 200));
          }
        } else {
          developer.log(
            'Unexpected response format: ${responseData.toString()}',
          );
          errorMessage = 'Currently No Meeting';
        }

        developer.log('Total meetings loaded: ${meetings.length}');
      } else if (response.statusCode == 429) {
        developer.log('Rate limit exceeded for meetings fetch');
        errorMessage = 'Too many requests. Please try again later.';
      } else {
        developer.log('Failed to fetch meetings: ${response.reasonPhrase}');
        errorMessage = 'Failed to fetch meetings: ${response.reasonPhrase}';
      }
    } catch (e) {
      developer.log('Error loading meetings: $e');
      errorMessage = 'Error loading meetings: $e';
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onLocationRequestSent(String meetingId) {
    if (mounted) {
      setState(() {
        selectedIndex = 2;
        developer.log(
          'Switched to Awaiting Location tab for meeting $meetingId',
        );
      });
      _loadMeetings();
    }
  }

  List<Map<String, dynamic>> _getFilteredMeetings() {
    final status = statuses[selectedIndex];
    developer.log('Filtering for status: $status');

    return meetings.where((meeting) {
      developer.log(
        'Meeting ${meeting['id']} - status: ${meeting['status']}, '
        'seller_approvel: ${meeting['seller_approvel']}, '
        'admin_approvel: ${meeting['admin_approvel']}, '
        'meeting_done: ${meeting['meeting_done']}, '
        'if_location_request: ${meeting['if_location_request']}, '
        'meeting_date: ${meeting['meeting_date']}',
      );

      if (status == 'Date Fixed') {
        return meeting['status'] == '1' &&
            meeting['meeting_done'] == '0' &&
            meeting['meeting_date'] != 'N/A' &&
            meeting['meeting_date']?.isNotEmpty == true &&
            meeting['if_location_request'] != '1';
      } else if (status == 'Meeting Request') {
        return meeting['status'] == '1' &&
            meeting['meeting_done'] == '0' &&
            meeting['if_location_request'] == '0';
      } else if (status == 'Awaiting Location') {
        return meeting['if_location_request'] == '0' &&
            meeting['status'] == '1' &&
            meeting['meeting_done'] == '0' &&
            (meeting['location_link'] == null ||
                meeting['location_link'] == '' ||
                meeting['latitude'] == null ||
                meeting['latitude'] == '' ||
                meeting['longitude'] == null ||
                meeting['longitude'] == '');
      } else if (status == 'Ready For Meeting') {
        return meeting['seller_approvel'] == '1' &&
            meeting['admin_approvel'] == '1' &&
            meeting['meeting_done'] == '0' &&
            meeting['if_location_request'] != '0' &&
            meeting['location_link']?.isNotEmpty == true;
      } else if (status == 'Meeting Completed') {
        return meeting['meeting_done'] == '1';
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMeetings = _getFilteredMeetings();
    developer.log(
      'Filtered meetings for ${statuses[selectedIndex]}: ${filteredMeetings.length}',
    );
    for (var meeting in filteredMeetings) {
      developer.log(
        'Filtered meeting ${meeting['id']}: status=${meeting['status']}, '
        'seller=${meeting['seller_approvel']}, admin=${meeting['admin_approvel']}, '
        'done=${meeting['meeting_done']}, location=${meeting['if_location_request']}, '
        'date=${meeting['meeting_date']}',
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _buildPillRow()),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child:
                    isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: Colors.blue),
                        )
                        : errorMessage != null
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.handshake,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No ${statuses[selectedIndex].toLowerCase()} found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                        : filteredMeetings.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.handshake,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No ${statuses[selectedIndex].toLowerCase()} found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You have no ${statuses[selectedIndex].toLowerCase()} at this time',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredMeetings.length,
                          itemBuilder: (context, index) {
                            final meeting = filteredMeetings[index];
                            developer.log(
                              'Displaying meeting: ${meeting['id']}',
                            );
                            return MeetingCard(
                              meeting: meeting,
                              baseUrl: widget.baseUrl,
                              token: widget.token,
                              // onCancel: () {
                              //   if (mounted) {
                              //     setState(() {
                              //       meetings.removeWhere(
                              //         (m) => m['id'] == meeting['id'],
                              //       );

                              //       _loadMeetings();
                              //     });
                              //   }
                              // },
                              onLocationRequestSent: _onLocationRequestSent,
                              onProceedWithBid: () {
                                developer.log(
                                  'Proceed with Bid triggered for meeting ${meeting['id']}',
                                );
                                _proceedWithBid(context, meeting);
                              },
                              // onIncreaseBid: () => _increaseBid(context, meeting),
                              onEditDate:
                                  (meeting) => _editDate(context, meeting),
                              onEditTime:
                                  (meeting) => _editTime(context, meeting),
                              // onCancelMeeting:
                              //     (meeting) => _cancelMeeting(context, meeting),
                              onSendLocationRequest:
                                  (meeting) =>
                                      _sendLocationRequest(context, meeting),
                              onViewLocation:
                                  (meeting) => _viewLocation(context, meeting),
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _proceedWithBid(
    BuildContext context,
    Map<String, dynamic> meeting,
  ) async {
    developer.log('Proceed with Bid called for meeting ${meeting['id']}');
    if (_userId == null || _userId == 'Unknown') {
      developer.log('Invalid user ID');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid user ID. Please log in again.')),
      );
      return;
    }
    if (meeting['bid_amount'] == null ||
        meeting['bid_amount'] == '0.00' ||
        meeting['bid_id'] == '0') {
      developer.log(
        'Proceed with Bid failed: bid_amount=${meeting['bid_amount']}, bid_id=${meeting['bid_id']}',
      );
      await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('No Bid Found'),
              content: const Text(
                'No valid bid exists for this meeting. Would you like to place a bid?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Place Bid'),
                ),
              ],
            ),
      );
      // if (_ignorePlaceBid == true) {
      //   await _increaseBid(context, meeting);
      // }
      return;
    }

    final double bidAmount =
        double.tryParse(meeting['bid_amount']?.toString() ?? '0.00') ?? 0.00;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Bid'),
            content: Text(
              'Do you want to proceed with a bid of ₹${NumberFormat('#,##0').format(bidAmount)}?',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OK'),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      developer.log('Bid confirmation cancelled by user');
      return;
    }

    try {
      final response = await retry(
        () => http.get(
          Uri.parse(
            '${widget.baseUrl}/my-meeting-proceed-with-bid.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}&post_id=${meeting['post_id']}&bidamt=${meeting['bid_amount']}',
          ),
          headers: {
            'token': widget.token,
            'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
          },
        ),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 2),
        randomizationFactor: 0.25,
        onRetry: (e) {
          developer.log('Retrying proceed with bid: $e');
        },
      );
      developer.log(
        'my-meeting-proceed-with-bid.php response: ${response.body}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proceeded with bid successfully')),
          );

          await _loadMeetings();
          widget.onRefreshMeetings?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to proceed with bid: ${data['message'] ?? 'Unknown error'}',
              ),
            ),
          );
        }
      } else if (response.statusCode == 429) {
        developer.log('Rate limit exceeded for proceed with bid');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Too many requests. Please try again later.'),
          ),
        );
      } else {
        developer.log(
          'my-meeting-proceed-with-bid.php failed with status ${response.statusCode}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to proceed with bid')),
        );
      }
    } catch (e) {
      developer.log('Error proceeding with bid: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error proceeding with bid')),
      );
    }
  }

  // Future<void> _increaseBid(
  //   BuildContext context,
  //   Map<String, dynamic> meeting,
  // ) async {
  //   if (_userId == null || _userId == 'Unknown') {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Invalid user ID. Please log in again.')),
  //     );
  //     return;
  //   }
  //   final TextEditingController bidController = TextEditingController();
  //   double? newBidAmount;

  //   await showDialog(
  //     context: context,
  //     builder:
  //         (context) => AlertDialog(
  //           title: const Text('Increase Bid'),
  //           content: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               TextField(
  //                 controller: bidController,
  //                 keyboardType: TextInputType.number,
  //                 decoration: const InputDecoration(
  //                   labelText: 'New Bid Amount',
  //                   hintText: 'Enter new bid amount',
  //                   border: OutlineInputBorder(),
  //                 ),
  //                 onChanged: (value) {
  //                   newBidAmount = double.tryParse(value);
  //                 },
  //               ),
  //             ],
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('Cancel'),
  //             ),
  //             TextButton(
  //               onPressed: () async {
  //                 if (newBidAmount == null || newBidAmount! <= 0) {
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     const SnackBar(
  //                       content: Text('Please enter a valid bid amount'),
  //                     ),
  //                   );
  //                   return;
  //                 }
  //                 try {
  //                   final response = await retry(
  //                     () => http.get(
  //                       Uri.parse(
  //                         '${widget.baseUrl}/my-meeting-increase-bid.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}&post_id=${meeting['post_id']}&bid_id=${meeting['bid_id']}&bidamt=$newBidAmount',
  //                       ),
  //                       headers: {
  //                         'token': widget.token,
  //                         'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
  //                       },
  //                     ),
  //                     maxAttempts: 3,
  //                     delayFactor: const Duration(seconds: 2),
  //                     randomizationFactor: 0.25,
  //                     onRetry: (e) {
  //                       developer.log('Retrying increase bid: $e');
  //                     },
  //                   );
  //                   developer.log(
  //                     'my-meeting-increase-bid.php response: ${response.body}',
  //                   );
  //                   if (response.statusCode == 200) {
  //                     final data = jsonDecode(response.body);
  //                     if (data['status'] == true || data['status'] == 'true') {
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(
  //                           content: Text('Bid increased successfully'),
  //                         ),
  //                       );

  //                       await _loadMeetings();
  //                       widget.onRefreshMeetings?.call();
  //                     } else {
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         SnackBar(
  //                           content: Text(
  //                             'Failed to increase bid: ${data['message'] ?? 'Unknown error'}',
  //                           ),
  //                         ),
  //                       );
  //                     }
  //                   } else if (response.statusCode == 429) {
  //                     developer.log('Rate limit exceeded for increase bid');
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       const SnackBar(
  //                         content: Text(
  //                           'Too many requests. Please try again later.',
  //                         ),
  //                       ),
  //                     );
  //                   } else {
  //                     developer.log(
  //                       'my-meeting-increase-bid.php failed with status ${response.statusCode}',
  //                     );
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       const SnackBar(content: Text('Failed to increase bid')),
  //                     );
  //                   }
  //                 } catch (e) {
  //                   developer.log('Error increasing bid: $e');
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     const SnackBar(content: Text('Error increasing bid')),
  //                   );
  //                 }
  //                 Navigator.pop(context);
  //               },
  //               child: const Text('OK'),
  //             ),
  //           ],
  //         ),
  //   );
  // }

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

                                      await _loadMeetings();
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
          onRetry: (e) {
            developer.log('Retrying edit date: $e');
          },
        );
        developer.log('my-meeting-edit-date.php response: ${response.body}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == true || data['status'] == 'true') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Date updated successfully')),
            );

            await _loadMeetings();
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

  Future<void> _sendLocationRequest(
    BuildContext context,
    Map<String, dynamic> meeting,
  ) async {
    if (_userId == null || _userId == 'Unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid user ID. Please log in again.')),
      );
      return;
    }
    try {
      final response = await retry(
        () => http.get(
          Uri.parse(
            '${widget.baseUrl}/my-meeting-send-location-request.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}&post_id=${meeting['post_id']}&ads_post_customer_meeting_id=${meeting['id']}',
          ),
          headers: {
            'token': widget.token,
            'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
          },
        ),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 2),
        randomizationFactor: 0.25,
        onRetry: (e) {
          developer.log('Retrying send location request: $e');
        },
      );
      developer.log(
        'my-meeting-send-location-request.php response: ${response.body}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location request sent successfully')),
          );

          final statusData = await _fetchMeetingStatus(
            meeting['id'],
            'Awaiting Location',
          );
          if (statusData != null && statusData['if_location_request'] == '1') {
            _onLocationRequestSent(meeting['id']);
          }
          await _loadMeetings();
          widget.onRefreshMeetings?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to send location request: ${data['message'] ?? 'Unknown error'}',
              ),
            ),
          );
        }
      } else if (response.statusCode == 429) {
        developer.log('Rate limit exceeded for send location request');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Too many requests. Please try again later.'),
          ),
        );
      } else {
        developer.log(
          'my-meeting-send-location-request.php failed with status ${response.statusCode}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send location request')),
        );
      }
    } catch (e) {
      developer.log('Error sending location request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending location request')),
      );
    }
  }

  // Future<void> _cancelMeeting(
  //   BuildContext context,
  //   Map<String, dynamic> meeting,
  // ) async {
  //   if (_userId == null || _userId == 'Unknown') {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Invalid user ID. Please log in again.')),
  //     );
  //     return;
  //   }
  //   try {
  //     final response = await http.get(
  //       Uri.parse(
  //         '${widget.baseUrl}/my-meeting-cancel.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}&post_id=${meeting['post_id']}&ads_post_customer_meeting_id=${meeting['id']}',
  //       ),
  //       headers: {
  //         'token': widget.token,
  //         'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
  //       },
  //     );
  //     developer.log('my-meeting-cancel.php response: ${response.body}');
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       if (data['status'] == true || data['status'] == 'true') {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Meeting cancelled successfully')),
  //         );

  //         await _loadMeetings();
  //         widget.onRefreshMeetings?.call();
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(
  //               'Failed to cancel meeting: ${data['message'] ?? 'Unknown error'}',
  //             ),
  //           ),
  //         );
  //       }
  //     } else {
  //       developer.log(
  //         'my-meeting-cancel.php failed with status ${response.statusCode}',
  //       );
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Failed to cancel meeting')),
  //       );
  //     }
  //   } catch (e) {
  //     developer.log('Error cancelling meeting: $e');
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text('Error cancelling meeting')));
  //   }
  // }

  Future<void> _viewLocation(
    BuildContext context,
    Map<String, dynamic> meeting,
  ) async {
    final locationLink = meeting['location_link'];
    if (locationLink != null && locationLink.isNotEmpty) {
      final Uri url = Uri.parse(locationLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open location link')),
        );
      }
    } else {
      final latitude = meeting['latitude'];
      final longitude = meeting['longitude'];
      if (latitude != null &&
          longitude != null &&
          latitude.isNotEmpty &&
          longitude.isNotEmpty) {
        final Uri mapUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
        );
        if (await canLaunchUrl(mapUrl)) {
          await launchUrl(mapUrl);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open map')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location data available')),
        );
      }
    }
  }
}
