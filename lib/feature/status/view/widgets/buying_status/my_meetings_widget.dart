import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final String? userId;
  final String? initialStatus;
  final String? postId;
  final String? bidId;
  final Map<String, dynamic>? bid;
  final VoidCallback? onRefreshMeetings;

  const MyMeetingsWidget({
    super.key,
    this.baseUrl = 'https://lelamonline.com/admin/api/v1',
    this.token = '5cb2c9b569416b5db1604e0e12478ded',
    this.userId,
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

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null &&
        statuses.contains(widget.initialStatus)) {
      selectedIndex = statuses.indexOf(widget.initialStatus!);
    }
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userId = prefs.getString('userId') ?? widget.userId ?? 'Unknown';
        debugPrint('Loaded userId: $_userId');
        if (_userId == 'Unknown') {
          errorMessage = 'User ID not found. Please log in again.';
          isLoading = false;
        }
      });
      if (_userId != 'Unknown') {
        await _loadMeetings();
      }
    } catch (e) {
      debugPrint('Error loading userId: $e');
      setState(() {
        errorMessage = 'Error loading user ID: $e';
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchPostDetails(String postId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/post-details.php?token=${widget.token}&post_id=$postId',
        ),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
        },
      );
      debugPrint(
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
            debugPrint(
              'Constructed postDetails for post_id $postId: $postDetails',
            );
            return postDetails;
          }
        }
      }
      debugPrint('No valid post data for post_id $postId');
      return null;
    } catch (e) {
      debugPrint('Error fetching post details for post_id $postId: $e');
      return null;
    }
  }

  Future<List<Map<String, String>>> _fetchMeetingTimes() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/meeting-times.php?token=${widget.token}'),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
        },
      );
      debugPrint('meeting-times.php response: ${response.body}');
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
        debugPrint('Invalid meeting times data: ${data.toString()}');
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching meeting times: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchMeetingStatus(String meetingId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/my-meeting-request-post-status.php?token=${widget.token}&ads_post_customer_meeting_id=$meetingId',
        ),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
        },
      );
      debugPrint(
        'my-meeting-request-post-status.php response for meeting_id $meetingId: ${response.body}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          return data['data'] is Map ? data['data'] : null;
        }
      }
      debugPrint('No valid status data for meeting_id $meetingId');
      return null;
    } catch (e) {
      debugPrint('Error fetching meeting status for meeting_id $meetingId: $e');
      return null;
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
              '${widget.baseUrl}/my-meeting-completed.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}';
          break;
      }
      debugPrint('Fetching meetings from: $url');
      final response = await http.get(Uri.parse(url), headers: headers);
      debugPrint('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic> &&
            (responseData['status'] == true ||
                responseData['status'] == 'true') &&
            responseData['data'] is List) {
          final List<dynamic> meetingData = responseData['data'];
          debugPrint('Found ${meetingData.length} meetings in API response');

          for (var meeting in meetingData) {
            debugPrint(
              'Processing meeting: id=${meeting['id']}, bid_id=${meeting['bid_id']}, post_id=${meeting['post_id']}, user_id=${meeting['user_id'] ?? _userId}, seller_approvel=${meeting['seller_approvel']}, admin_approvel=${meeting['admin_approvel']}, meeting_done=${meeting['meeting_done']}, meeting_date=${meeting['meeting_date']}, meeting_time=${meeting['meeting_time']}',
            );
            final postDetails = await _fetchPostDetails(meeting['post_id']);
            if (postDetails == null) {
              debugPrint(
                'Skipping meeting ${meeting['id']} due to missing post details',
              );
              continue;
            }
            final statusData = await _fetchMeetingStatus(meeting['id']);
            final middleStatus =
                statusData?['middleStatus_data']?.toString() ??
                'Schedule meeting';
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
              'middleStatus_data': middleStatus,
            };
            debugPrint('Added meeting ${meeting['id']} to list: $meetingData');
            meetings.add(meetingData);
          }
        } else {
          debugPrint('Unexpected response format: ${responseData.toString()}');
          errorMessage = 'Unexpected response format from server';
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'userMeetings',
          meetings.map((m) => jsonEncode(m)).toList(),
        );
        debugPrint('Total meetings loaded: ${meetings.length}');
      } else {
        debugPrint('Failed to fetch meetings: ${response.reasonPhrase}');
        errorMessage = 'Failed to fetch meetings: ${response.reasonPhrase}';
      }
    } catch (e) {
      debugPrint('Error loading meetings: $e');
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
        debugPrint('Switched to Awaiting Location tab for meeting $meetingId');
      });
      _loadMeetings();
    }
  }

  List<Map<String, dynamic>> _getFilteredMeetings() {
    final status = statuses[selectedIndex];
    debugPrint('Filtering for status: $status');

    return meetings.where((meeting) {
      debugPrint(
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
    debugPrint(
      'Filtered meetings for ${statuses[selectedIndex]}: ${filteredMeetings.length}',
    );
    for (var meeting in filteredMeetings) {
      debugPrint(
        'Filtered meeting ${meeting['id']}: status=${meeting['status']}, '
        'seller=${meeting['seller_approvel']}, admin=${meeting['admin_approvel']}, '
        'done=${meeting['meeting_done']}, location=${meeting['if_location_request']}, '
        'date=${meeting['meeting_date']}',
      );
    }

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
                children:
                    statuses.map((status) {
                      final index = statuses.indexOf(status);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: StatusPill(
                          label: status,
                          isActive: index == selectedIndex,
                          activeColor: AppTheme.primaryColor,
                          onTap: () {
                            if (mounted) {
                              setState(() {
                                selectedIndex = index;
                                debugPrint('Selected tab: $status');
                              });
                              _loadMeetings();
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
              color: Colors.grey[50],
              child:
                  isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      )
                      : errorMessage != null
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
                              errorMessage!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
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
                      )
                      : filteredMeetings.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No meetings found for ${statuses[selectedIndex]}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total meetings in system: ${meetings.length}',
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
                          debugPrint('Displaying meeting: ${meeting['id']}');
                          return MeetingCard(
                            meeting: meeting,
                            baseUrl: widget.baseUrl,
                            token: widget.token,
                            userId: _userId ?? 'Unknown',
                            onCancel: () {
                              if (mounted) {
                                setState(() {
                                  meetings.removeWhere(
                                    (m) => m['id'] == meeting['id'],
                                  );
                                  SharedPreferences.getInstance().then((prefs) {
                                    prefs.setStringList(
                                      'userMeetings',
                                      meetings
                                          .map((m) => jsonEncode(m))
                                          .toList(),
                                    );
                                  });
                                  _loadMeetings();
                                });
                              }
                            },
                            onLocationRequestSent: _onLocationRequestSent,
                            onProceedWithBid:
                                () => _proceedWithBid(context, meeting),
                            // onProceedWithoutBid:
                            //     () => _proceedWithoutBid(context, meeting),
                            onIncreaseBid: () => _increaseBid(context, meeting),
                            onEditDate:
                                (meeting) => _editDate(context, meeting),
                            onEditTime:
                                (meeting) => _editTime(context, meeting),
                            onCancelMeeting:
                                (meeting) => _cancelMeeting(context, meeting),
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
    );
  }

  Future<void> _proceedWithBid(
    BuildContext context,
    Map<String, dynamic> meeting,
  ) async {
    if (_userId == null || _userId == 'Unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid user ID. Please log in again.')),
      );
      return;
    }
    if (meeting['bid_amount'] == null ||
        meeting['bid_amount'] == '0.00' ||
        meeting['bid_id'] == '0') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No valid bid found')));
      return;
    }

    // Show confirmation dialog with bid amount
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
      debugPrint('Bid confirmation cancelled by user');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/my-meeting-proceed-with-bid.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}&post_id=${meeting['post_id']}&bidamt=${meeting['bid_amount']}',
        ),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
        },
      );
      debugPrint('my-meeting-proceed-with-bid.php response: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proceeded with bid successfully')),
          );
          final prefs = await SharedPreferences.getInstance();
          final meetings =
              (prefs.getStringList('userMeetings') ?? [])
                  .map((m) => jsonDecode(m) as Map<String, dynamic>)
                  .toList();
          meetings.removeWhere((m) => m['id'] == meeting['id']);
          meetings.add({
            ...meeting,
            'seller_approvel': '1',
            'admin_approvel': '1',
          });
          await prefs.setStringList(
            'userMeetings',
            meetings.map((m) => jsonEncode(m)).toList(),
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
      } else {
        debugPrint(
          'my-meeting-proceed-with-bid.php failed with status ${response.statusCode}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to proceed with bid')),
        );
      }
    } catch (e) {
      debugPrint('Error proceeding with bid: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error proceeding with bid')),
      );
    }
  }

  // Future<void> _proceedWithoutBid(
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
  //         '${widget.baseUrl}/my-meeting-proceed-without-bid.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}&post_id=${meeting['post_id']}',
  //       ),
  //       headers: {
  //         'token': widget.token,
  //         'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
  //       },
  //     );
  //     debugPrint(
  //       'my-meeting-proceed-without-bid.php response: ${response.body}',
  //     );
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       if (data['status'] == true || data['status'] == 'true') {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Proceeded without bid successfully')),
  //         );
  //         final prefs = await SharedPreferences.getInstance();
  //         final meetings =
  //             (prefs.getStringList('userMeetings') ?? [])
  //                 .map((m) => jsonDecode(m) as Map<String, dynamic>)
  //                 .toList();
  //         meetings.removeWhere((m) => m['id'] == meeting['id']);
  //         meetings.add({
  //           ...meeting,
  //           'seller_approvel': '1',
  //           'admin_approvel': '1',
  //         });
  //         await prefs.setStringList(
  //           'userMeetings',
  //           meetings.map((m) => jsonEncode(m)).toList(),
  //         );
  //         await _loadMeetings();
  //         widget.onRefreshMeetings?.call();
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(
  //               'Failed to proceed without bid: ${data['message'] ?? 'Unknown error'}',
  //             ),
  //           ),
  //         );
  //       }
  //     } else {
  //       debugPrint(
  //         'my-meeting-proceed-without-bid.php failed with status ${response.statusCode}',
  //       );
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Failed to proceed without bid')),
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint('Error proceeding without bid: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Error proceeding without bid')),
  //     );
  //   }
  // }

  Future<void> _increaseBid(
    BuildContext context,
    Map<String, dynamic> meeting,
  ) async {
    if (_userId == null || _userId == 'Unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid user ID. Please log in again.')),
      );
      return;
    }
    final TextEditingController bidController = TextEditingController();
    double? newBidAmount;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Increase Bid'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bidController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'New Bid Amount',
                    hintText: 'Enter new bid amount',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    newBidAmount = double.tryParse(value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (newBidAmount == null || newBidAmount! <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid bid amount'),
                      ),
                    );
                    return;
                  }
                  try {
                    final response = await http.get(
                      Uri.parse(
                        '${widget.baseUrl}/my-meeting-increase-bid.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}&post_id=${meeting['post_id']}&bid_id=${meeting['bid_id']}&bidamt=$newBidAmount',
                      ),
                      headers: {
                        'token': widget.token,
                        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
                      },
                    );
                    debugPrint(
                      'my-meeting-increase-bid.php response: ${response.body}',
                    );
                    if (response.statusCode == 200) {
                      final data = jsonDecode(response.body);
                      if (data['status'] == true || data['status'] == 'true') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bid increased successfully'),
                          ),
                        );
                        final prefs = await SharedPreferences.getInstance();
                        final meetings =
                            (prefs.getStringList('userMeetings') ?? [])
                                .map(
                                  (m) => jsonDecode(m) as Map<String, dynamic>,
                                )
                                .toList();
                        meetings.removeWhere((m) => m['id'] == meeting['id']);
                        meetings.add({
                          ...meeting,
                          'bid_amount': newBidAmount.toString(),
                        });
                        await prefs.setStringList(
                          'userMeetings',
                          meetings.map((m) => jsonEncode(m)).toList(),
                        );
                        await _loadMeetings();
                        widget.onRefreshMeetings?.call();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to increase bid: ${data['message'] ?? 'Unknown error'}',
                            ),
                          ),
                        );
                      }
                    } else {
                      debugPrint(
                        'my-meeting-increase-bid.php failed with status ${response.statusCode}',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to increase bid')),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error increasing bid: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error increasing bid')),
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
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
      debugPrint('No meeting times available');
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
                            debugPrint(
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
                                debugPrint(
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
                                  debugPrint(
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
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final meetings =
                                          (prefs.getStringList(
                                                    'userMeetings',
                                                  ) ??
                                                  [])
                                              .map(
                                                (m) =>
                                                    jsonDecode(m)
                                                        as Map<String, dynamic>,
                                              )
                                              .toList();
                                      meetings.removeWhere(
                                        (m) => m['id'] == meeting['id'],
                                      );
                                      meetings.add({
                                        ...meeting,
                                        'meeting_time': selectedTimeValue,
                                      });
                                      await prefs.setStringList(
                                        'userMeetings',
                                        meetings
                                            .map((m) => jsonEncode(m))
                                            .toList(),
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
                                    debugPrint(
                                      'my-meeting-fix-time.php failed with status ${response.statusCode}',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to update time'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Error updating meeting time: $e');
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
        final response = await http.get(
          Uri.parse(
            '${widget.baseUrl}/my-meeting-edit-date.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}&post_id=${meeting['post_id']}&meeting_id=${meeting['id']}&meeting_date=$meetingDate',
          ),
          headers: {
            'token': widget.token,
            'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
          },
        );
        debugPrint('my-meeting-edit-date.php response: ${response.body}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == true || data['status'] == 'true') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Date updated successfully')),
            );
            final prefs = await SharedPreferences.getInstance();
            final meetings =
                (prefs.getStringList('userMeetings') ?? [])
                    .map((m) => jsonDecode(m) as Map<String, dynamic>)
                    .toList();
            meetings.removeWhere((m) => m['id'] == meeting['id']);
            meetings.add({...meeting, 'meeting_date': meetingDate});
            await prefs.setStringList(
              'userMeetings',
              meetings.map((m) => jsonEncode(m)).toList(),
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
        } else {
          debugPrint(
            'my-meeting-edit-date.php failed with status ${response.statusCode}',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update date')),
          );
        }
      } catch (e) {
        debugPrint('Error updating meeting date: $e');
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
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/my-meeting-send-location-request.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}&post_id=${meeting['post_id']}&ads_post_customer_meeting_id=${meeting['id']}',
        ),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
        },
      );
      debugPrint(
        'my-meeting-send-location-request.php response: ${response.body}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location request sent successfully')),
          );
          final prefs = await SharedPreferences.getInstance();
          final meetings =
              (prefs.getStringList('userMeetings') ?? [])
                  .map((m) => jsonDecode(m) as Map<String, dynamic>)
                  .toList();
          meetings.removeWhere((m) => m['id'] == meeting['id']);
          meetings.add({
            ...meeting,
            'if_location_request': '1',
            'location_request_count':
                (int.parse(meeting['location_request_count'] ?? '0') + 1)
                    .toString(),
          });
          await prefs.setStringList(
            'userMeetings',
            meetings.map((m) => jsonEncode(m)).toList(),
          );
          final statusData = await _fetchMeetingStatus(meeting['id']);
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
      } else {
        debugPrint(
          'my-meeting-send-location-request.php failed with status ${response.statusCode}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send location request')),
        );
      }
    } catch (e) {
      debugPrint('Error sending location request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending location request')),
      );
    }
  }

  Future<void> _cancelMeeting(
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
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/my-meeting-cancel.php?token=${widget.token}&user_id=${Uri.encodeComponent(_userId!)}&post_id=${meeting['post_id']}&ads_post_customer_meeting_id=${meeting['id']}',
        ),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
        },
      );
      debugPrint('my-meeting-cancel.php response: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meeting cancelled successfully')),
          );
          final prefs = await SharedPreferences.getInstance();
          final meetings =
              (prefs.getStringList('userMeetings') ?? [])
                  .map((m) => jsonDecode(m) as Map<String, dynamic>)
                  .toList();
          meetings.removeWhere((m) => m['id'] == meeting['id']);
          meetings.add({...meeting, 'if_cancel': '1', 'status': '0'});
          await prefs.setStringList(
            'userMeetings',
            meetings.map((m) => jsonEncode(m)).toList(),
          );
          await _loadMeetings();
          widget.onRefreshMeetings?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to cancel meeting: ${data['message'] ?? 'Unknown error'}',
              ),
            ),
          );
        }
      } else {
        debugPrint(
          'my-meeting-cancel.php failed with status ${response.statusCode}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel meeting')),
        );
      }
    } catch (e) {
      debugPrint('Error cancelling meeting: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error cancelling meeting')));
    }
  }

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

class MeetingCard extends StatelessWidget {
  final Map<String, dynamic> meeting;
  final String baseUrl;
  final String token;
  final String userId;
  final VoidCallback onCancel;
  final Function(String) onLocationRequestSent;
  final VoidCallback onProceedWithBid;
 // final VoidCallback onProceedWithoutBid;
  final VoidCallback onIncreaseBid;
  final Function(Map<String, dynamic>) onEditDate;
  final Function(Map<String, dynamic>) onEditTime;
  final Function(Map<String, dynamic>) onCancelMeeting;
  final Function(Map<String, dynamic>) onSendLocationRequest;
  final Function(Map<String, dynamic>) onViewLocation;

  const MeetingCard({
    super.key,
    required this.meeting,
    required this.baseUrl,
    required this.token,
    required this.userId,
    required this.onCancel,
    required this.onLocationRequestSent,
    required this.onProceedWithBid,
  //  required this.onProceedWithoutBid,
    required this.onIncreaseBid,
    required this.onEditDate,
    required this.onEditTime,
    required this.onCancelMeeting,
    required this.onSendLocationRequest,
    required this.onViewLocation,
  });

  String _getMeetingStatus(Map<String, dynamic> meeting) {
    if (meeting['meeting_done'] == '1') return 'Meeting Completed';
    if (meeting['seller_approvel'] == '1' &&
        meeting['admin_approvel'] == '1' &&
        meeting['meeting_done'] == '0' &&
        meeting['if_location_request'] == '1' &&
        meeting['location_link']?.isNotEmpty == true) {
      return 'Ready For Meeting';
    }
    if (meeting['if_location_request'] == '1' &&
        meeting['status'] == '1' &&
        meeting['meeting_done'] == '0' &&
        (meeting['location_link'] == null ||
            meeting['location_link'] == '' ||
            meeting['latitude'] == '' ||
            meeting['longitude'] == '')) {
      return 'Awaiting Location';
    }
    if (meeting['status'] == '1' &&
        meeting['meeting_done'] == '0' &&
        meeting['meeting_date'] != 'N/A' &&
        meeting['meeting_date']?.isNotEmpty == true &&
        meeting['if_location_request'] != '1') {
      return 'Date Fixed';
    }
    if (meeting['status'] == '1' &&
        meeting['meeting_done'] == '0' &&
        meeting['if_location_request'] == '0') {
      return 'Meeting Request';
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final status = _getMeetingStatus(meeting);
    final bool withBid = meeting['with_bid'] == '1';
    final double bidAmount =
        double.tryParse(meeting['bid_amount'] ?? meeting['bidPrice'] ?? '0') ??
        0;
    final double targetPrice =
        double.tryParse(meeting['targetPrice']?.toString() ?? '0') ?? 0;
    final bool isLowBid = bidAmount > 0 && bidAmount < targetPrice;
    final bool isReadyForMeeting =
        meeting['seller_approvel'] == '1' &&
        meeting['admin_approvel'] == '1' &&
        meeting['meeting_done'] == '0';
    final bool isMeetingRequest =
        meeting['status'] == '1' &&
        meeting['meeting_done'] == '0' &&
        meeting['seller_approvel'] == '0' &&
        meeting['admin_approvel'] == '0';
    final String locationRequestCount =
        '${meeting['location_request_count'] ?? '0'}/2';

    debugPrint(
      'Rendering MeetingCard: id=${meeting['id']}, bid_id=${meeting['bid_id']}, title=${meeting['title']}, date=${meeting['meeting_date']}, time=${meeting['meeting_time']}, middleStatus_data=${meeting['middleStatus_data']}, status=$status',
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
                        imageUrl: meeting['carImage']?.toString() ?? '',
                        width: 100,
                        height: 150,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
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
                          Text(
                            meeting['title'] ??
                                'Unknown Vehicle (ID: ${meeting['post_id']})',
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
                                'App Id: ${meeting['appId'] ?? 'LAD_${meeting['post_id']}'}',
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
                                  'Location: ${meeting['location'] ?? 'Unknown Location'}',
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
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Location Requests: $locationRequestCount',
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
                      onSelected: (value) {
                        if (value == 'edit_date') {
                          onEditDate(meeting);
                        } else if (value == 'edit_time') {
                          onEditTime(meeting);
                        } else if (value == 'proceed_with_bid') {
                          onProceedWithBid();
                        // } else if (value == 'proceed_without_bid') {
                        //   onProceedWithoutBid();
                        } else if (value == 'increase_bid') {
                          onIncreaseBid();
                        } else if (value == 'cancel_meeting') {
                          onCancelMeeting(meeting);
                        } else if (value == 'send_location') {
                          onSendLocationRequest(meeting);
                        } else if (value == 'view_location') {
                          onViewLocation(meeting);
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        final currentStatus = _getMeetingStatus(meeting);
                        List<PopupMenuItem<String>> items = [
                          const PopupMenuItem<String>(
                            value: 'edit_date',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                                SizedBox(width: 8),
                                Text('Edit Date'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'edit_time',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                                SizedBox(width: 8),
                                Text('Edit Time'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'cancel_meeting',
                            child: Row(
                              children: [
                                Icon(Icons.cancel, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Cancel Meeting'),
                              ],
                            ),
                          ),
                        ];

                        if (currentStatus == 'Meeting Request') {
                          items.add(
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
                                  Text('Proceed with Bid'),
                                ],
                              ),
                            ),
                          );
                          items.add(
                            const PopupMenuItem<String>(
                              value: 'send_location',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Send Location Request'),
                                ],
                              ),
                            ),
                          );
                        } else if (currentStatus == 'Date Fixed') {
                          items.add(
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
                                  Text('Proceed with Bid'),
                                ],
                              ),
                            ),
                          );
                          if (withBid && isLowBid) {
                            items.add(
                              const PopupMenuItem<String>(
                                value: 'increase_bid',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_upward,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Increase Bid'),
                                  ],
                                ),
                              ),
                            );
                          }
                          if (meeting['if_location_request'] != '1') {
                            items.add(
                              const PopupMenuItem<String>(
                                value: 'send_location',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Send Location Request'),
                                  ],
                                ),
                              ),
                            );
                          }
                        } else if (currentStatus == 'Awaiting Location') {
                          items.add(
                            const PopupMenuItem<String>(
                              value: 'send_location',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Resend Location Request'),
                                ],
                              ),
                            ),
                          );
                          if (withBid) {
                            items.add(
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
                                    Text('Proceed with Bid'),
                                  ],
                                ),
                              ),
                            );
                          }
                        } else if (currentStatus == 'Ready For Meeting') {
                          if (meeting['location_link']?.isNotEmpty == true) {
                            items.add(
                              const PopupMenuItem<String>(
                                value: 'view_location',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.map,
                                      size: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                    SizedBox(width: 8),
                                    Text('View Location'),
                                  ],
                                ),
                              ),
                            );
                          }
                        }
                        return items;
                      },
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
                            'Meeting Date',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            meeting['meeting_date']?.toString() ?? 'N/A',
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
                            'Meeting Time',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            meeting['meeting_time']?.toString() ?? 'N/A',
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
                    if (withBid)
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
                              bidAmount == 0
                                  ? 'N/A'
                                  : '₹${NumberFormat('#,##0').format(bidAmount)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    isLowBid
                                        ? Colors.orange[700]
                                        : Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (isReadyForMeeting &&
                    meeting['location_link']?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meeting Location',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => onViewLocation(meeting),
                              child: Text(
                                // Show the full Google Maps link
                                'Open in Google Maps',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            // Optionally show the coordinates as well
                            Text(
                              'Coordinates: ${meeting['latitude']}, ${meeting['longitude']}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          Container(
            decoration: BoxDecoration(color: Colors.grey[50]),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          meeting['middleStatus_data'] ?? 'Schedule meeting',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.blue,
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
                          isReadyForMeeting
                              ? 'Meeting location and time confirmed. Please attend the meeting as scheduled.'
                              : 'For high bid meeting, Meeting must be done in 24hrs if seller accepts the bid.',
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
