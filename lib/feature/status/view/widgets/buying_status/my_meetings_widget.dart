import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

  const MyMeetingsWidget({
    super.key,
    this.baseUrl = 'https://lelamonline.com/admin/api/v1',
    this.token = '5cb2c9b569416b5db1604e0e12478ded',
    this.userId,
    this.initialStatus,
    this.postId,
    this.bidId,
    this.bid,
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

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null && statuses.contains(widget.initialStatus)) {
      selectedIndex = statuses.indexOf(widget.initialStatus!);
    }
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      meetings = [];
    });

    try {
      // Fetch meetings from API
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/my-meeting-date-fix.php?token=${widget.token}&user_id=${widget.userId}'),
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=gbqbiugaqg3gco8kaespjf8lnp',
        },
      );

      debugPrint('Meeting response: ${response.body}');
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['status'] == true) {
        if (responseData['data'] is List) {
          meetings = List<Map<String, dynamic>>.from(responseData['data']);
          // Filter by postId and bidId if provided
          if (widget.postId != null) {
            meetings = meetings.where((meeting) => meeting['post_id'] == widget.postId).toList();
          }
          if (widget.bidId != null) {
            meetings = meetings.where((meeting) => meeting['bid_id'] == widget.bidId).toList();
          }

          // Fetch bid details from SharedPreferences
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final List<String> bidStrings = prefs.getStringList('userBids') ?? [];
          final List<Map<String, dynamic>> bids = bidStrings.map((bid) => jsonDecode(bid) as Map<String, dynamic>).toList();

          // Merge bid details into meetings
          for (var meeting in meetings) {
            final matchingBid = bids.firstWhere(
              (bid) => bid['post_id'] == meeting['post_id'] && (widget.bidId == null || bid['id'] == meeting['bid_id']),
              orElse: () => widget.bid ?? {},
            );
            if (matchingBid.isNotEmpty) {
              meeting.addAll({
                'title': matchingBid['title'] ?? 'N/A',
                'carImage': matchingBid['carImage'] ?? '',
                'appId': matchingBid['appId'] ?? 'N/A',
                'bidDate': matchingBid['bidDate'] ?? 'N/A',
                'expirationDate': matchingBid['expirationDate'] ?? 'N/A',
                'targetPrice': matchingBid['targetPrice'] ?? '0',
                'bidPrice': matchingBid['bidPrice'] ?? '0',
                'location': matchingBid['location'] ?? 'N/A',
                'store': matchingBid['store'] ?? 'N/A',
              });
            }
          }

          // If bid is passed, add it as a new meeting if no matching meeting exists
          if (widget.bid != null) {
            final exists = meetings.any((m) => m['post_id'] == widget.postId && (widget.bidId == null || m['bid_id'] == widget.bidId));
            if (!exists) {
              meetings.add({
                'id': widget.bidId ?? 'TEMP_${widget.postId}_${DateTime.now().millisecondsSinceEpoch}',
                'post_id': widget.postId,
                'bid_id': widget.bidId,
                'status': '1',
                'meeting_done': '0',
                'if_location_request': '0',
                'seller_approvel': '0',
                'admin_approvel': '0',
                'meeting_date': widget.bid!['meeting_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                'meeting_time': widget.bid!['meeting_time'] ?? 'N/A',
                'bid_amount': widget.bid!['bidPrice'] ?? '0',
                'with_bid': widget.bidId != null ? '1' : '0',
                ...widget.bid!,
              });
            }
          }
        } else if (responseData['data'] is String) {
          errorMessage = responseData['data'];
        }
      } else {
        errorMessage = responseData['data'] ?? 'Failed to load meetings';
        // Fallback to bid data if API fails
        if (widget.bid != null) {
          meetings.add({
            'id': widget.bidId ?? 'TEMP_${widget.postId}_${DateTime.now().millisecondsSinceEpoch}',
            'post_id': widget.postId,
            'bid_id': widget.bidId,
            'status': '1',
            'meeting_done': '0',
            'if_location_request': '0',
            'seller_approvel': '0',
            'admin_approvel': '0',
            'meeting_date': widget.bid!['meeting_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'meeting_time': widget.bid!['meeting_time'] ?? 'N/A',
            'bid_amount': widget.bid!['bidPrice'] ?? '0',
            'with_bid': widget.bidId != null ? '1' : '0',
            ...widget.bid!,
          });
        }
      }
    } catch (e) {
      errorMessage = 'Error loading meetings: $e';
      // Fallback to bid data if API call fails
      if (widget.bid != null) {
        meetings.add({
          'id': widget.bidId ?? 'TEMP_${widget.postId}_${DateTime.now().millisecondsSinceEpoch}',
          'post_id': widget.postId,
          'bid_id': widget.bidId,
          'status': '1',
          'meeting_done': '0',
          'if_location_request': '0',
          'seller_approvel': '0',
          'admin_approvel': '0',
          'meeting_date': widget.bid!['meeting_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'meeting_time': widget.bid!['meeting_time'] ?? 'N/A',
          'bid_amount': widget.bid!['bidPrice'] ?? '0',
          'with_bid': widget.bidId != null ? '1' : '0',
          ...widget.bid!,
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getFilteredMeetings() {
    final status = statuses[selectedIndex];
    return meetings.where((meeting) {
      // Ensure temporary meetings are only shown in "Meeting Request"
      final isNewMeeting = meeting['id'].toString().startsWith('TEMP_');
      if (status == 'Date Fixed') {
        return meeting['status'] == '1' && meeting['meeting_done'] == '0' && meeting['if_location_request'] == '0' && meeting['seller_approvel'] == '0' && meeting['admin_approvel'] == '0' && !isNewMeeting;
      } else if (status == 'Meeting Request') {
        return meeting['status'] == '1' && meeting['if_location_request'] == '0' && meeting['seller_approvel'] == '0' && meeting['admin_approvel'] == '0' && (isNewMeeting || meeting['meeting_date'] == null);
      } else if (status == 'Awaiting Location') {
        return meeting['status'] == '1' && meeting['if_location_request'] == '1';
      } else if (status == 'Ready For Meeting') {
        return meeting['status'] == '1' && meeting['seller_approvel'] == '1' && meeting['admin_approvel'] == '1' && meeting['meeting_done'] == '0';
      } else if (status == 'Meeting Completed') {
        return meeting['meeting_done'] == '1';
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMeetings = _getFilteredMeetings();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Meetings'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(statuses.length * 2 - 1, (i) {
                if (i.isEven) {
                  final index = i ~/ 2;
                  return StatusPill(
                    label: statuses[index],
                    isActive: index == selectedIndex,
                    activeColor: Colors.green,
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                  );
                } else {
                  final leftIndex = (i - 1) ~/ 2;
                  final isActive = leftIndex == selectedIndex - 1;
                  return PillConnector(
                    isActive: isActive,
                    activeColor: Colors.green,
                    inactiveColor: Colors.grey,
                  );
                }
              }),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(child: Text(errorMessage!))
                    : filteredMeetings.isEmpty
                        ? Center(child: Text('No meetings found for ${statuses[selectedIndex]}'))
                        : ListView.builder(
                            itemCount: filteredMeetings.length,
                            itemBuilder: (context, index) {
                              return MeetingCard(
                                meeting: filteredMeetings[index],
                                baseUrl: widget.baseUrl,
                                token: widget.token,
                                userId: widget.userId ?? filteredMeetings[index]['user_id'] ?? 'N/A',
                                onCancel: () {
                                  setState(() {
                                    meetings.removeWhere((m) => m['id'] == filteredMeetings[index]['id']);
                                  });
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class MeetingCard extends StatelessWidget {
  final Map<String, dynamic> meeting;
  final String baseUrl;
  final String token;
  final String userId;
  final VoidCallback onCancel;

  const MeetingCard({
    super.key,
    required this.meeting,
    required this.baseUrl,
    required this.token,
    required this.userId,
    required this.onCancel,
  });

  Future<void> _editTime(BuildContext context) async {
    final TextEditingController timeController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Meeting Time'),
          content: TextField(
            controller: timeController,
            decoration: const InputDecoration(
              hintText: 'Enter time (HH:mm:ss)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String meetingTime = timeController.text;
                if (!RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(meetingTime)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid time format. Use HH:mm:ss')),
                  );
                  return;
                }

                try {
                  final response = await http.get(
                    Uri.parse('$baseUrl/my-meeting-fix-time.php?token=$token&user_id=$userId&post_id=${meeting['post_id']}&meeting_id=${meeting['id']}&meeting_time=$meetingTime'),
                    headers: {
                      'token': token,
                      'Cookie': 'PHPSESSID=gbqbiugaqg3gco8kaespjf8lnp',
                    },
                  );

                  debugPrint('Edit time response: ${response.body}');
                  try {
                    final responseData = jsonDecode(response.body);
                    if (response.statusCode == 200 && responseData['status'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(responseData['data'] ?? 'Time updated successfully')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update time: ${responseData['data'] ?? 'Unknown error'}')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error parsing response: ${response.body}')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating time: $e')),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editDate(BuildContext context) async {
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
          Uri.parse('$baseUrl/my-meeting-edit-date.php?token=$token&user_id=$userId&post_id=${meeting['post_id']}&meeting_id=${meeting['id']}&meeting_date=$meetingDate'),
          headers: {
            'token': token,
            'Cookie': 'PHPSESSID=gbqbiugaqg3gco8kaespjf8lnp',
          },
        );

        debugPrint('Edit date response: ${response.body}');
        try {
          final responseData = jsonDecode(response.body);
          if (response.statusCode == 200 && responseData['status'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['data'] ?? 'Date updated successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update date: ${responseData['data'] ?? 'Unknown error'}')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error parsing response: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating date: $e')),
        );
      }
    }
  }

  Future<void> _sendLocationRequest(BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-meeting-send-location-request.php?token=$token&user_id=$userId&post_id=${meeting['post_id']}&ads_post_customer_meeting_id=${meeting['id']}'),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=gbqbiugaqg3gco8kaespjf8lnp',
        },
      );

      debugPrint('Send location request response: ${response.body}');
      try {
        final responseData = jsonDecode(response.body);
        if (response.statusCode == 200 && responseData['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['data'] ?? 'Location request sent successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send location request: ${responseData['data'] ?? 'Unknown error'}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing response: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending location request: $e')),
      );
    }
  }

  Future<void> _proceedWithBid(BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-meeting-request-post-status.php?token=$token&ads_post_customer_meeting_id=${meeting['id']}'),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=gbqbiugaqg3gco8kaespjf8lnp',
        },
      );

      debugPrint('Proceed with bid response: ${response.body}');
      try {
        final responseData = jsonDecode(response.body);
        if (response.statusCode == 200 && responseData['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['data'] ?? 'Proceeded with bid successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to proceed with bid: ${responseData['data'] ?? 'Unknown error'}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing response: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error proceeding with bid: $e')),
      );
    }
  }

  Future<void> _cancelMeeting(BuildContext context) async {
    // Skip API call for temporary meetings
    if (meeting['id'].toString().startsWith('TEMP_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting cancelled successfully')),
      );
      onCancel();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cancel-meeting.php?token=$token&user_id=$userId&meeting_id=${meeting['id']}'),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=gbqbiugaqg3gco8kaespjf8lnp',
        },
      );

      debugPrint('Cancel meeting response: ${response.body}');
      try {
        final responseData = jsonDecode(response.body);
        if (response.statusCode == 200 && responseData['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['data'] ?? 'Meeting cancelled successfully')),
          );
          onCancel();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel meeting: ${responseData['data'] ?? 'Unknown error'}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing response: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling meeting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl: meeting['carImage'] ?? '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting['title'] ?? 'Meeting ID: ${meeting['id'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Model: ${meeting['appId'] ?? 'N/A'}'),
                      Text('Bid Date: ${meeting['bidDate'] ?? 'N/A'}'),
                      Text('Expires: ${meeting['expirationDate'] ?? 'N/A'}'),
                      Text('Target Price: ₹${NumberFormat('#,##0').format(double.tryParse(meeting['targetPrice'] ?? '0') ?? 0)}'),
                      Text('Your Bid: ₹${NumberFormat('#,##0').format(double.tryParse(meeting['bidPrice'] ?? meeting['bid_amount'] ?? '0') ?? 0)}'),
                      Text('Location: ${meeting['location'] ?? 'N/A'}'),
                      Text('Store: ${meeting['store'] ?? 'N/A'}'),
                      Text('Post ID: ${meeting['post_id'] ?? 'N/A'}'),
                      Text('Meeting Date: ${meeting['meeting_date'] ?? 'N/A'}'),
                      Text('Meeting Time: ${meeting['meeting_time'] ?? 'N/A'}'),
                      Text('With Bid: ${meeting['with_bid'] == '1' ? 'Yes' : 'No'}'),
                      Text('Bid ID: ${meeting['bid_id'] ?? 'N/A'}'),
                      Text('Location Request: ${meeting['if_location_request'] == '1' ? 'Yes' : 'No'}'),
                      Text('Status: ${meeting['status'] == '1' ? 'Active' : 'Inactive'}'),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu),
                  onSelected: (value) async {
                    if (value == 'edit_time') {
                      await _editTime(context);
                    } else if (value == 'edit_date') {
                      await _editDate(context);
                    } else if (value == 'send_location_request') {
                      await _sendLocationRequest(context);
                    } else if (value == 'proceed_with_bid') {
                      await _proceedWithBid(context);
                    } else if (value == 'cancel') {
                      await _cancelMeeting(context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'edit_time',
                      child: Text('Edit Time'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit_date',
                      child: Text('Edit Date'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'send_location_request',
                      child: Text('Send Location Request'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'proceed_with_bid',
                      child: Text('Proceed with Bid'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'cancel',
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}