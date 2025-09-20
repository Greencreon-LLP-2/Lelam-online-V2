import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback? onTap;
  final String? postId;

  const StatusPill({
    super.key,
    required this.label,
    this.isActive = false,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
    this.onTap,
    this.postId,
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

class MyMeetingsSellerWidget extends StatefulWidget {
  final String baseUrl;
  final String token;
  final String? initialStatus;
  final String? postId;
  final VoidCallback? onRefreshMeetings;

  const MyMeetingsSellerWidget({
    super.key,
    this.baseUrl = 'https://lelamonline.com/admin/api/v1',
    this.token = '5cb2c9b569416b5db1604e0e12478ded',
    this.initialStatus,
    this.postId,
    this.onRefreshMeetings,
  });

  @override
  State<MyMeetingsSellerWidget> createState() => _MyMeetingsSellerWidget();
}

class _MyMeetingsSellerWidget extends State<MyMeetingsSellerWidget> {
  final List<String> statuses = [
    'Date Fixed',
    'Upcoming Meetings',
    'Location Request List',
    'Waiting Meetings',
    'Meeting Done',
  ];
  int selectedIndex = 0;
  List<Map<String, dynamic>> meetings = [];
  String? errorMessage;
  bool isLoading = true;
  String? _userId;
  String locationText = '';

  @override
  void initState() {
    super.initState();
    debugPrint('Widget init - postId: "${widget.postId}"');
    if (widget.initialStatus != null &&
        statuses.contains(widget.initialStatus)) {
      selectedIndex = statuses.indexOf(widget.initialStatus!);
    }
    _loadUserId();
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
        debugPrint('Loaded userId: "$_userId"');
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

  Future<void> _loadMeetings() async {
    debugPrint(
      'Starting _loadMeetings - userId: "$_userId", postId: "${widget.postId}"',
    );

    if (!mounted || _userId == null || _userId == 'Unknown') {
      debugPrint('Early exit: Invalid user ID');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Cannot load meetings: Invalid user ID';
        });
      }
      return;
    }

    // If postId is missing, log warning but continue (show empty list)
    if (widget.postId == null || widget.postId!.isEmpty) {
      debugPrint(
        'WARNING: postId is null/empty - APIs will fail, showing empty list',
      );
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Please select a post to load meetings';
          meetings = [];
        });
      }
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      meetings = [];
      locationText = '';
    });

    try {
      final headers = {'token': widget.token};
      String url;
      switch (selectedIndex) {
        case 0:
          url =
              '${widget.baseUrl}/sell-meeting-date-fixed.php?token=${widget.token}&post_id=${widget.postId}';
          break;
        case 1:
          url =
              '${widget.baseUrl}/sell-upcoming-meetings.php?token=${widget.token}&post_id=${widget.postId}';
          break;
        case 2:
          url =
              '${widget.baseUrl}/sell-location-request.php?token=${widget.token}&post_id=${widget.postId}';
          break;
        case 3:
          url =
              '${widget.baseUrl}/sell-waiting-for-meeting.php?token=${widget.token}&post_id=${widget.postId}';
          break;
        default:
          url =
              '${widget.baseUrl}/sell-meeting-done-list.php?token=${widget.token}&post_id=${widget.postId}';
          break;
      }
      debugPrint('Fetching meetings from: $url');
      final response = await http.get(Uri.parse(url), headers: headers);
      debugPrint('HTTP Status: ${response.statusCode}');
      debugPrint('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Response data type: ${responseData.runtimeType}');
        debugPrint('Response data: $responseData');

        if (responseData is Map<String, dynamic> &&
            (responseData['status'] == true ||
                responseData['status'] == 'true') &&
            responseData['data'] is List) {
          final List<dynamic> meetingData = responseData['data'];
          debugPrint('Found ${meetingData.length} meetings in API response');

          for (var meeting in meetingData) {
            final meetingDataMap = <String, dynamic>{
              'id':
                  meeting['ads_post_customer_meeting_id']?.toString() ??
                  meeting['id']?.toString() ??
                  'N/A',
              'value': meeting['value']?.toString() ?? 'No details available',
              'sharelocation_button':
                  meeting['sharelocation_button']?.toString() ?? '0',
              'reschedule_button':
                  meeting['reschedule_button']?.toString() ?? '0',
              'deny_request_button':
                  meeting['deny_request_button']?.toString() ?? '0',
              'post_id': widget.postId,
              'bid_amount': meeting['bid_amount']?.toString() ?? '',
              'meeting_date': meeting['meeting_date']?.toString() ?? '',
            };
            debugPrint(
              'Added meeting ${meetingDataMap['id']} to list: $meetingDataMap',
            );
            meetings.add(meetingDataMap);
          }
        } else {
          debugPrint(
            'Unexpected response format or empty data: ${responseData.toString()}',
          );
          // Don't set error for empty data - just show empty list
          meetings = [];
        }

        debugPrint('Total meetings loaded: ${meetings.length}');
      } else {
        debugPrint(
          'No meetings: ${response.statusCode} - ${response.reasonPhrase}',
        );
        errorMessage = 'No meetings';
      }
    } catch (e) {
      debugPrint('Error loading meetings: $e');
      errorMessage = 'Error loading meetings';
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
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
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/sell-share-location.php?token=${widget.token}&ads_post_customer_meeting_id=${meeting['id']}&currentLatitude=70.185&currentLongitude=68.386',
        ),
        headers: {'token': widget.token},
      );
      debugPrint(
        'sell-share-location.php response for meeting_id ${meeting['id']}: ${response.body}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          final locationLink =
              data['data'] is List && data['data'].isNotEmpty
                  ? data['data'][0]['link']?.toString() ?? ''
                  : '';
          final message =
              data['data'] is List && data['data'].isNotEmpty
                  ? data['data'][0]['message']?.toString() ??
                      'Location shared successfully'
                  : 'Location shared successfully';
          debugPrint('Location shared successfully with link: $locationLink');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));

          await _loadMeetings();
          widget.onRefreshMeetings?.call();
        } else {
          debugPrint(
            'Failed to share location: ${data['message'] ?? 'Unknown error'}',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to share location: ${data['message'] ?? 'Unknown error'}',
              ),
            ),
          );
        }
      } else {
        debugPrint(
          'sell-share-location.php failed with status ${response.statusCode}: ${response.reasonPhrase}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share location: Server error'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sharing location for meeting_id ${meeting['id']}: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error sharing location')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _rescheduleMeeting(
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
            '${widget.baseUrl}/sell-meeting-reschedule.php?token=${widget.token}&ads_post_customer_meeting_id=${meeting['id']}&post_id=${meeting['post_id']}&meeting_date=$meetingDate',
          ),
          headers: {'token': widget.token},
        );
        debugPrint('sell-meeting-reschedule.php response: ${response.body}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == true || data['status'] == 'true') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Meeting rescheduled successfully')),
            );

            await _loadMeetings();
            widget.onRefreshMeetings?.call();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to reschedule: ${data['message'] ?? 'Unknown error'}',
                ),
              ),
            );
          }
        } else {
          debugPrint(
            'sell-meeting-reschedule.php failed with status ${response.statusCode}',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to reschedule meeting')),
          );
        }
      } catch (e) {
        debugPrint('Error rescheduling meeting: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error rescheduling meeting')),
        );
      }
    }
  }

  Future<void> _denyRequest(
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
          '${widget.baseUrl}/my-meeting-cancel.php?token=${widget.token}&post_id=${meeting['post_id']}&ads_post_customer_meeting_id=${meeting['id']}',
        ),
        headers: {'token': widget.token},
      );
      debugPrint('my-meeting-cancel.php response: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meeting request denied successfully'),
            ),
          );

          await _loadMeetings();
          widget.onRefreshMeetings?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to deny request: ${data['message'] ?? 'Unknown error'}',
              ),
            ),
          );
        }
      } else {
        debugPrint(
          'my-meeting-cancel.php failed with status ${response.statusCode}',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to deny request')));
      }
    } catch (e) {
      debugPrint('Error denying request: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error denying request')));
    }
  }

  Future<void> _skipMeeting(
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
          '${widget.baseUrl}/sell-skip-meeting.php?token=${widget.token}&ads_post_customer_meeting_id=${meeting['id']}',
        ),
        headers: {'token': widget.token},
      );
      debugPrint('sell-skip-meeting.php response: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meeting skipped successfully')),
          );
          await _loadMeetings();
          widget.onRefreshMeetings?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to skip meeting: ${data['message'] ?? 'Unknown error'}',
              ),
            ),
          );
        }
      } else {
        debugPrint(
          'sell-skip-meeting.php failed with status ${response.statusCode}',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to skip meeting')));
      }
    } catch (e) {
      debugPrint('Error skipping meeting: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error skipping meeting')));
    }
  }

  Future<void> _markMeetingDone(
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
          '${widget.baseUrl}/sell-meeting-done.php?token=${widget.token}&ads_post_customer_meeting_id=${meeting['id']}',
        ),
        headers: {'token': widget.token},
      );
      debugPrint('sell-meeting-done.php response: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meeting marked as done successfully'),
            ),
          );
          await _loadMeetings();
          widget.onRefreshMeetings?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to mark meeting as done: ${data['message'] ?? 'Unknown error'}',
              ),
            ),
          );
        }
      } else {
        debugPrint(
          'sell-meeting-done.php failed with status ${response.statusCode}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark meeting as done')),
        );
      }
    } catch (e) {
      debugPrint('Error marking meeting as done: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error marking meeting as done')),
      );
    }
  }

  Future<void> _viewLocation(
    BuildContext context,
    Map<String, dynamic> meeting,
  ) async {
    final locationLink = meeting['location_link']?.toString();
    debugPrint(
      'Attempting to view location for meeting_id ${meeting['id']}: link=$locationLink',
    );

    if (locationLink != null && locationLink.isNotEmpty) {
      try {
        final Uri url = Uri.parse(locationLink);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          debugPrint('Opened location link: $locationLink');
        } else {
          debugPrint('Cannot launch URL: $locationLink');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open location link')),
          );
        }
      } catch (e) {
        debugPrint('Error launching location link: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening location link')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location data available')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          inactiveColor: Colors.grey,
                          onTap: () {
                            debugPrint(
                              'StatusPill tapped: $status (index: $index)',
                            );
                            if (mounted) {
                              setState(() {
                                selectedIndex = index;
                                locationText = '';
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
              padding: const EdgeInsets.all(10),
              color: Colors.grey[50],
              child:
                  isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      )
                      : errorMessage != null
                      ? SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                errorMessage!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
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
                        ),
                      )
                      : meetings.isEmpty
                      ? SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No meetings found for ${statuses[selectedIndex]}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              if (widget.postId == null ||
                                  widget.postId!.isEmpty)
                                Text(
                                  'Select a post first to load meetings',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[800],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                      )
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              meetings.map((meeting) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        meeting['value'] ??
                                            'No details available',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (selectedIndex == 2) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            if (meeting['sharelocation_button'] ==
                                                '1')
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed:
                                                      () =>
                                                          _sendLocationRequest(
                                                            context,
                                                            meeting,
                                                          ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            AppTheme
                                                                .primaryColor,
                                                      ),
                                                  child: const Text(
                                                    'Share Location',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (meeting['sharelocation_button'] ==
                                                '1')
                                              const SizedBox(width: 10),
                                            if (meeting['reschedule_button'] ==
                                                '1')
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed:
                                                      () => _rescheduleMeeting(
                                                        context,
                                                        meeting,
                                                      ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            AppTheme
                                                                .primaryColor,
                                                      ),
                                                  child: const Text(
                                                    'Reschedule',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (meeting['reschedule_button'] ==
                                                '1')
                                              const SizedBox(width: 10),
                                            if (meeting['deny_request_button'] ==
                                                '1')
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed:
                                                      () => _denyRequest(
                                                        context,
                                                        meeting,
                                                      ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                  child: const Text(
                                                    'Deny Request',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                      if (selectedIndex == 3) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed:
                                                    () => _skipMeeting(
                                                      context,
                                                      meeting,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppTheme.primaryColor,
                                                ),
                                                child: const Text(
                                                  'Skip Meeting',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed:
                                                    () => _markMeetingDone(
                                                      context,
                                                      meeting,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppTheme.primaryColor,
                                                ),
                                                child: const Text(
                                                  'Meeting Done',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (meeting['location_link'] != null &&
                                          meeting['location_link']
                                              .toString()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed:
                                              () => _viewLocation(
                                                context,
                                                meeting,
                                              ),
                                          child: Text(
                                            'View Location: ${meeting['location_link']}',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
