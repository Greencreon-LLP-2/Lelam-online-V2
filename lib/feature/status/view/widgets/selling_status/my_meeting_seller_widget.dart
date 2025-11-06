import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
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
  final bool showError;

  const StatusPill({
    super.key,
    required this.label,
    this.isActive = false,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
    this.onTap,
    this.postId,
    this.showError = false,
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
    return Row(
      children: [
        Transform.scale(
          scaleX: 1.5,
          child: Icon(
            Icons.arrow_forward,
            size: 14,
            color: isActive ? activeColor : inactiveColor,
          ),
        ),
      ],
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
    'Ongoing Meeting',
    'Meeting Done',
  ];
  int selectedIndex = 0;
  List<Map<String, dynamic>> meetings = [];
  String? errorMessage;
  bool isLoading = true;
  String? _userId;
  Timer? _debounce;

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

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  List<Widget> _buildPillRow() {
    List<Widget> pillRow = [];
    for (var i = 0; i < statuses.length; i++) {
      final bool isThisActive = i <= selectedIndex;
      final bool showErrorOnThis = false;

      pillRow.add(
        StatusPill(
          label: statuses[i],
          isActive: isThisActive,
          activeColor: Colors.blue,
          showError: showErrorOnThis,
          onTap: () {
            if (mounted) {
              setState(() {
                selectedIndex = i;
                print('Selected tab: ${statuses[i]}');
              });
              _loadMeetings();
            }
          },
        ),
      );

      if (i != statuses.length - 1) {
        pillRow.add(
          PillConnector(
            isActive: i < selectedIndex,
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
        debugPrint('Loaded userId: "$_userId"');
        if (_userId == 'Unknown') {
          errorMessage = ' Please log in .';
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
        case 2: // Ongoing Meeting
          url =
              '${widget.baseUrl}/sell-waiting-for-meeting.php?token=${widget.token}&post_id=${widget.postId}';
          break;
        case 3: // Meeting Done
          url =
              '${widget.baseUrl}/sell-meeting-done-list.php?token=${widget.token}&post_id=${widget.postId}';
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
        // Clean the response by removing HTML tags and extracting JSON
        String cleanedResponse = _cleanApiResponse(response.body);
        debugPrint('Cleaned response: $cleanedResponse');

        final responseData = jsonDecode(cleanedResponse);
        debugPrint('Response data type: ${responseData.runtimeType}');
        debugPrint('Response data: $responseData');

        List<Map<String, dynamic>> loadedMeetings = [];

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
              'mobile': meeting['mobile']?.toString() ?? '',
              'post_id': widget.postId,
              'bid_amount': meeting['bid_amount']?.toString() ?? '',
              'meeting_date': meeting['meeting_date']?.toString() ?? '',
              'location_link': meeting['location_link']?.toString() ?? '',
              'created_date':
                  meeting['created_date']?.toString() ??
                  DateTime.now().toIso8601String(),
              // Add specific fields for ongoing meetings
              'meeting_done': meeting['meeting_done'] ?? 0,
              'skip_meeting': meeting['skip_meeting'] ?? 0,
            };
            loadedMeetings.add(meetingDataMap);
          }

          // Reverse the list to show newest first (assuming API returns oldest first)
          loadedMeetings = loadedMeetings.reversed.toList();
          debugPrint('Reversed list to show newest first');
        } else {
          debugPrint(
            'Unexpected response format or empty data: ${responseData.toString()}',
          );
          loadedMeetings = [];
        }

        if (mounted) {
          setState(() {
            meetings = loadedMeetings;
            errorMessage = null;
          });
        }

        debugPrint('Total meetings loaded: ${meetings.length}');
      } else {
        debugPrint(
          'No meetings: ${response.statusCode} - ${response.reasonPhrase}',
        );
        if (mounted) {
          setState(() {
            errorMessage = 'No meetings';
            meetings = [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading meetings: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'No meeting found';
          meetings = [];
        });
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper method to clean API response by removing HTML and extracting JSON
  String _cleanApiResponse(String rawResponse) {
    try {
      // If the response starts with HTML tags, try to extract JSON
      if (rawResponse.trim().startsWith('<')) {
        // Find the first occurrence of '{' which should be the start of JSON
        final jsonStartIndex = rawResponse.indexOf('{');
        if (jsonStartIndex != -1) {
          // Find the last occurrence of '}' which should be the end of JSON
          final jsonEndIndex = rawResponse.lastIndexOf('}');
          if (jsonEndIndex != -1 && jsonEndIndex > jsonStartIndex) {
            final jsonString = rawResponse.substring(
              jsonStartIndex,
              jsonEndIndex + 1,
            );
            debugPrint('Extracted JSON: $jsonString');
            return jsonString;
          }
        }
        // If we can't extract JSON properly, return empty JSON object
        return '{"status":false,"data":[]}';
      }
      // If no HTML tags, return the response as is
      return rawResponse;
    } catch (e) {
      debugPrint('Error cleaning API response: $e');
      return '{"status":false,"data":[]}';
    }
  }

  Future<void> _approveMeeting(
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
          '${widget.baseUrl}/my-meeting-approvel.php?token=${widget.token}&post_id=${meeting['post_id']}&ads_post_customer_meeting_id=${meeting['id']}&user_id=$_userId',
        ),
        headers: {'token': widget.token},
      );
      debugPrint(
        'my-meeting-approvel.php response for meeting_id ${meeting['id']}: ${response.body}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meeting approved successfully')),
          );

          await _loadMeetings();
          widget.onRefreshMeetings?.call();
        } else {
          debugPrint(
            'Failed to approve meeting: ${data['message'] ?? 'Unknown error'}',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to approve meeting: ${data['message'] ?? 'Unknown error'}',
              ),
            ),
          );
        }
      } else {
        debugPrint(
          'my-meeting-approvel.php failed with status ${response.statusCode}: ${response.reasonPhrase}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve meeting: Server error'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error approving meeting for meeting_id ${meeting['id']}: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error approving meeting')));
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

    // Store the meeting ID for removal
    final String meetingId = meeting['id'];

    // Remove the meeting from the list immediately before API call
    if (mounted) {
      setState(() {
        meetings.removeWhere((m) => m['id'] == meetingId);
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/sell-skip-meeting.php?token=${widget.token}&ads_post_customer_meeting_id=$meetingId',
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

          // Refresh the list to get updated data from server
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
          // If API failed, reload the original list
          await _loadMeetings();
        }
      } else {
        debugPrint(
          'sell-skip-meeting.php failed with status ${response.statusCode}',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to skip meeting')));
        // If API failed, reload the original list
        await _loadMeetings();
      }
    } catch (e) {
      debugPrint('Error skipping meeting: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error skipping meeting')));
      // If API failed, reload the original list
      await _loadMeetings();
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
              child: Row(children: _buildPillRow()),
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
                              const SizedBox(height: 12),
                              Text(
                                errorMessage!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
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
                                      const SizedBox(height: 8),

                                      // Display meeting information
                                      if (meeting['meeting_date'] != null &&
                                          meeting['meeting_date'].isNotEmpty)
                                        Text(
                                          'Meeting Date: ${meeting['meeting_date']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),

                                      if (meeting['bid_amount'] != null &&
                                          meeting['bid_amount'].isNotEmpty)
                                        Text(
                                          'Bid Amount: ${meeting['bid_amount']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),

                                      // Ongoing Meeting specific buttons
                                      if (selectedIndex == 2) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed:
                                                    () => _markMeetingDone(
                                                      context,
                                                      meeting,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                ),
                                                child: const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Yes',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed:
                                                    () => _skipMeeting(
                                                      context,
                                                      meeting,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                ),
                                                child: const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.cancel,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'No',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],

                                      // Other status buttons (existing code)
                                      if (selectedIndex == 0 &&
                                          meeting['mobile'] != null &&
                                          meeting['mobile'].isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final phoneNumber =
                                                meeting['mobile'];
                                            final Uri phoneUri = Uri(
                                              scheme: 'tel',
                                              path: phoneNumber,
                                            );
                                            try {
                                              if (await canLaunchUrl(
                                                phoneUri,
                                              )) {
                                                await launchUrl(
                                                  phoneUri,
                                                  mode:
                                                      LaunchMode
                                                          .externalApplication,
                                                );
                                                debugPrint(
                                                  'Initiated call to: $phoneNumber',
                                                );
                                              } else {
                                                debugPrint(
                                                  'Cannot initiate call to: $phoneNumber',
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Could not initiate call',
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              debugPrint(
                                                'Error initiating call: $e',
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Error initiating call',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Call Buyer',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (selectedIndex == 1) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed:
                                                    () => _approveMeeting(
                                                      context,
                                                      meeting,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppTheme.primaryColor,
                                                ),
                                                child: const Text(
                                                  'Approve Meeting',
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
                                                    () => _skipMeeting(
                                                      context,
                                                      meeting,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.orange,
                                                ),
                                                child: const Text(
                                                  'Skip Meeting',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // ADD THIS SECTION FOR MOBILE NUMBER IN UPCOMING MEETINGS
                                        // ADD THIS SECTION FOR MOBILE NUMBER IN UPCOMING MEETINGS
                                        if (meeting['mobile'] != null &&
                                            meeting['mobile'].isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width:
                                                double.infinity, // Full width
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                final phoneNumber =
                                                    meeting['mobile'];
                                                final Uri phoneUri = Uri(
                                                  scheme: 'tel',
                                                  path: phoneNumber,
                                                );
                                                try {
                                                  if (await canLaunchUrl(
                                                    phoneUri,
                                                  )) {
                                                    await launchUrl(
                                                      phoneUri,
                                                      mode:
                                                          LaunchMode
                                                              .externalApplication,
                                                    );
                                                    debugPrint(
                                                      'Initiated call to: $phoneNumber',
                                                    );
                                                  } else {
                                                    debugPrint(
                                                      'Cannot initiate call to: $phoneNumber',
                                                    );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Could not initiate call',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  debugPrint(
                                                    'Error initiating call: $e',
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Error initiating call',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                              ),
                                              child: const Text(
                                                'Call Buyer',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                      if (selectedIndex == 3) ...[
                                        // Meeting Done - No buttons needed
                                        const SizedBox(height: 8),
                                        Text(
                                          'Meeting Completed',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.bold,
                                          ),
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
