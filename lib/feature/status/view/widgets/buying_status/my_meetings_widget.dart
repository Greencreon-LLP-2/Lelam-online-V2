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
    if (widget.initialStatus != null &&
        statuses.contains(widget.initialStatus)) {
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
      // Fetch meetings from my-meeting-request.php
      final headers = {
        'token': widget.token,
        'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
      };
      final request = http.Request(
        'GET',
        Uri.parse(
          '${widget.baseUrl}/my-meeting-request.php?token=${widget.token}&user_id=${widget.userId}',
        ),
      );
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('my-meeting-request.php response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        if (responseData is List) {
          meetings =
              responseData.map((meeting) {
                return {
                  'id': meeting['id']?.toString() ?? 'N/A',
                  'user_id': meeting['user_id']?.toString() ?? widget.userId,
                  'post_id': meeting['post_id']?.toString() ?? 'N/A',
                  'bid_id': meeting['bid_id']?.toString() ?? 'N/A',
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
                  'seller_approvel':
                      meeting['seller_approvel']?.toString() ?? '0',
                  'admin_approvel':
                      meeting['admin_approvel']?.toString() ?? '0',
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
                  'price_offered':
                      meeting['price_offered']?.toString() ?? '0.00',
                  'created_on':
                      meeting['created_on']?.toString() ??
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
                  'updated_on':
                      meeting['updated_on']?.toString() ??
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
                  'title': widget.bid?['title'] ?? meeting['title'] ?? 'N/A',
                  'carImage':
                      widget.bid?['carImage'] ?? meeting['carImage'] ?? '',
                  'appId': widget.bid?['appId'] ?? meeting['appId'] ?? 'N/A',
                  'bidDate':
                      widget.bid?['bidDate'] ?? meeting['bidDate'] ?? 'N/A',
                  'expirationDate':
                      widget.bid?['expirationDate'] ??
                      meeting['expirationDate'] ??
                      'N/A',
                  'targetPrice':
                      widget.bid?['targetPrice'] ??
                      meeting['targetPrice'] ??
                      '0',
                  'bidPrice':
                      widget.bid?['bidPrice'] ??
                      meeting['bidPrice'] ??
                      meeting['bid_amount'] ??
                      '0',
                  'location':
                      widget.bid?['location'] ?? meeting['location'] ?? 'N/A',
                  'store': widget.bid?['store'] ?? meeting['store'] ?? 'N/A',
                  'if_auction':
                      widget.bid?['if_auction'] ?? meeting['if_auction'] ?? '0',
                };
              }).toList();

          // Update SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(
            'userMeetings',
            meetings.map((m) => jsonEncode(m)).toList(),
          );
        }
      } else {
        debugPrint('Failed to fetch meetings: ${response.reasonPhrase}');
      }

      // Load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final List<String> meetingStrings =
          prefs.getStringList('userMeetings') ?? [];
      meetings =
          meetingStrings
              .map((meeting) => jsonDecode(meeting) as Map<String, dynamic>)
              .toList();

      // Filter by postId and bidId if provided
      if (widget.postId != null) {
        meetings =
            meetings
                .where((meeting) => meeting['post_id'] == widget.postId)
                .toList();
      }
      if (widget.bidId != null) {
        meetings =
            meetings
                .where((meeting) => meeting['bid_id'] == widget.bidId)
                .toList();
      }

      // Add bid data if provided and in "Meeting Request" tab
      if (widget.bid != null && statuses[selectedIndex] == 'Meeting Request') {
        final exists = meetings.any(
          (m) =>
              m['post_id'] == widget.postId &&
              (widget.bidId == null || m['bid_id'] == widget.bidId),
        );
        if (!exists) {
          meetings.add({
            'id':
                widget.bidId ??
                'TEMP_${widget.postId}_${DateTime.now().millisecondsSinceEpoch}',
            'post_id': widget.postId,
            'bid_id': widget.bidId,
            'user_id': widget.userId,
            'status': '1',
            'meeting_done': '0',
            'if_location_request': widget.bid!['if_location_request'] ?? '0',
            'seller_approvel': widget.bid!['seller_approvel'] ?? '0',
            'admin_approvel': widget.bid!['admin_approvel'] ?? '0',
            'meeting_date':
                widget.bid!['meeting_date'] ??
                DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'meeting_time': widget.bid!['meeting_time'] ?? 'N/A',
            'bid_amount':
                widget.bid!['bidPrice'] ?? widget.bid!['bid_amount'] ?? '0',
            'with_bid': widget.bid!['with_bid'] ?? '0',
            'title': widget.bid!['title'] ?? 'N/A',
            'carImage': widget.bid!['carImage'] ?? '',
            'appId': widget.bid!['appId'] ?? 'N/A',
            'bidDate': widget.bid!['bidDate'] ?? 'N/A',
            'expirationDate': widget.bid!['expirationDate'] ?? 'N/A',
            'targetPrice': widget.bid!['targetPrice'] ?? '0',
            'bidPrice':
                widget.bid!['bidPrice'] ?? widget.bid!['bid_amount'] ?? '0',
            'location': widget.bid!['location'] ?? 'N/A',
            'store': widget.bid!['store'] ?? 'N/A',
            'if_auction': widget.bid!['if_auction'] ?? '0',
            'latitude': widget.bid!['latitude'] ?? '',
            'longitude': widget.bid!['longitude'] ?? '',
            'location_link': widget.bid!['location_link'] ?? '',
            'location_request_count':
                widget.bid!['location_request_count'] ?? '0',
            'if_junk': widget.bid!['if_junk'] ?? '0',
            'if_reschedule': widget.bid!['if_reschedule'] ?? '0',
            'if_skipped': widget.bid!['if_skipped'] ?? '0',
            'if_not_intersect': widget.bid!['if_not_intersect'] ?? '0',
            'if_revisit': widget.bid!['if_revisit'] ?? '0',
            'if_decisionpedding': widget.bid!['if_decisionpedding'] ?? '0',
            'if_expired': widget.bid!['if_expired'] ?? '0',
            'if_cancel': widget.bid!['if_cancel'] ?? '0',
            'if_sold': widget.bid!['if_sold'] ?? '0',
            'if_reject_bid': widget.bid!['if_reject_bid'] ?? '0',
            'price_offered': widget.bid!['price_offered'] ?? '0.00',
            'created_on':
                widget.bid!['created_on'] ??
                DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
            'updated_on':
                widget.bid!['updated_on'] ??
                DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          });
          final meetingStrings = meetings.map((m) => jsonEncode(m)).toList();
          await prefs.setStringList('userMeetings', meetingStrings);
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading meetings: $e';
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredMeetings() {
    final status = statuses[selectedIndex];
    return meetings.where((meeting) {
      if (status == 'Date Fixed') {
        return meeting['status'] == '1' &&
            meeting['meeting_done'] == '0' &&
            meeting['if_location_request'] == '0' &&
            meeting['seller_approvel'] == '0' &&
            meeting['admin_approvel'] == '0' &&
            !meeting['id'].toString().startsWith('TEMP_');
      } else if (status == 'Meeting Request') {
        return meeting['status'] == '1' &&
            meeting['if_location_request'] == '0' &&
            meeting['seller_approvel'] == '0' &&
            meeting['admin_approvel'] == '0';
      } else if (status == 'Awaiting Location') {
        return meeting['status'] == '1' &&
            meeting['if_location_request'] == '1';
      } else if (status == 'Ready For Meeting') {
        return meeting['status'] == '1' &&
            meeting['seller_approvel'] == '1' &&
            meeting['admin_approvel'] == '1' &&
            meeting['meeting_done'] == '0';
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
      // appBar: AppBar(
      //   title: const Text('My Meetings'),
      //   backgroundColor: AppTheme.primaryColor,
      //   foregroundColor: Colors.white,
      // ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(statuses.length * 2 - 1, (i) {
                if (i.isEven) {
                  final index = i ~/ 2;
                  return StatusPill(
                    label: statuses[index],
                    isActive: index == selectedIndex,
                    activeColor: AppTheme.primaryColor,
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                        _loadMeetings();
                      });
                    },
                  );
                } else {
                  final leftIndex = (i - 1) ~/ 2;
                  final isActive = leftIndex == selectedIndex - 1;
                  return PillConnector(
                    isActive: isActive,
                    activeColor: AppTheme.primaryColor,
                    inactiveColor: Colors.grey,
                  );
                }
              }),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
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
                        ],
                      ),
                    )
                    : filteredMeetings.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No meetings found for ${statuses[selectedIndex]}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredMeetings.length,
                      itemBuilder: (context, index) {
                        return MeetingCard(
                          meeting: filteredMeetings[index],
                          baseUrl: widget.baseUrl,
                          token: widget.token,
                          userId:
                              widget.userId ??
                              filteredMeetings[index]['user_id'] ??
                              'N/A',
                          onCancel: () {
                            setState(() {
                              meetings.removeWhere(
                                (m) => m['id'] == filteredMeetings[index]['id'],
                              );
                              SharedPreferences.getInstance().then((prefs) {
                                prefs.setStringList(
                                  'userMeetings',
                                  meetings.map((m) => jsonEncode(m)).toList(),
                                );
                              });
                              _loadMeetings();
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
      builder: (BuildContext dialogContext) {
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final String meetingTime = timeController.text;
                if (!RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(meetingTime)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid time format. Use HH:mm:ss'),
                    ),
                  );
                  return;
                }

                final prefs = await SharedPreferences.getInstance();
                final meetings =
                    (prefs.getStringList('userMeetings') ?? [])
                        .map((m) => jsonDecode(m) as Map<String, dynamic>)
                        .toList();
                meetings.removeWhere((m) => m['id'] == meeting['id']);
                meetings.add({...meeting, 'meeting_time': meetingTime});
                await prefs.setStringList(
                  'userMeetings',
                  meetings.map((m) => jsonEncode(m)).toList(),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Time updated successfully')),
                );
                Navigator.pop(dialogContext);
                await _loadMeetings(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date updated successfully')),
      );
      await _loadMeetings(context);
    }
  }

  Future<void> _sendLocationRequest(BuildContext context) async {
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
          (int.parse(meeting['location_request_count'] ?? '0') + 1).toString(),
    });
    await prefs.setStringList(
      'userMeetings',
      meetings.map((m) => jsonEncode(m)).toList(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location request sent successfully')),
    );
    await _loadMeetings(context);
  }

  Future<void> _proceedWithBid(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final meetings =
        (prefs.getStringList('userMeetings') ?? [])
            .map((m) => jsonDecode(m) as Map<String, dynamic>)
            .toList();
    meetings.removeWhere((m) => m['id'] == meeting['id']);
    meetings.add({...meeting, 'seller_approvel': '1', 'admin_approvel': '1'});
    await prefs.setStringList(
      'userMeetings',
      meetings.map((m) => jsonEncode(m)).toList(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proceeded with bid successfully')),
    );
    await _loadMeetings(context);
  }

  Future<void> _cancelMeeting(BuildContext context) async {
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meeting cancelled successfully')),
    );
    onCancel();
  }

  Future<void> _callSupport(BuildContext context) async {
    const String supportPhone = 'tel:+1234567890';
    if (await canLaunchUrl(Uri.parse(supportPhone))) {
      await launchUrl(Uri.parse(supportPhone));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch support call')),
      );
    }
  }

  Future<void> _loadMeetings(BuildContext context) async {
    await (context.findAncestorStateOfType<_MyMeetingsWidgetState>()
            as _MyMeetingsWidgetState)
        ._loadMeetings();
  }

  @override
  Widget build(BuildContext context) {
    final bool withBid = meeting['with_bid'] == '1';
    final double bidAmount =
        double.tryParse(meeting['bid_amount'] ?? meeting['bidPrice'] ?? '0') ??
        0;
    final bool sellerNotResponding =
        meeting['seller_approvel'] != '1' && meeting['if_reschedule'] == '0';
    final bool needsReschedule = meeting['if_reschedule'] == '1';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meeting Date and Time Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meeting Date: ${meeting['meeting_date'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Time: ${meeting['meeting_time'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (meeting['id'].toString().startsWith('TEMP_'))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pending Sync',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Meeting Card
        Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: meeting['carImage'] ?? '',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                        errorWidget:
                            (context, url, error) => Icon(
                              Icons.car_rental,
                              color: Colors.grey[400],
                              size: 40,
                            ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meeting['title'] ??
                                'Meeting ID: ${meeting['id'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('APP ID', meeting['appId'] ?? 'N/A'),
                          _buildInfoRow('Bid ID', meeting['bid_id'] ?? 'N/A'),
                          _buildInfoRow('Post ID', meeting['post_id'] ?? 'N/A'),
                          _buildInfoRow(
                            'Applied Date',
                            meeting['bidDate'] ?? 'N/A',
                          ),
                          _buildInfoRow(
                            'Expiration Date',
                            meeting['expirationDate'] ?? 'N/A',
                          ),
                          _buildInfoRow(
                            'Target Price',
                            '₹${NumberFormat('#,##0').format(double.tryParse(meeting['targetPrice'] ?? '0') ?? 0)}',
                          ),
                          _buildInfoRow(
                            'My Bid Price',
                            '₹${NumberFormat('#,##0').format(bidAmount)}',
                          ),
                          _buildInfoRow(
                            'Location Request Count',
                            meeting['location_request_count'] ?? '0',
                          ),
                          _buildInfoRow(
                            'Location',
                            meeting['location'] ?? 'N/A',
                          ),
                          _buildInfoRow('Store', meeting['store'] ?? 'N/A'),
                          _buildInfoRow(
                            'Auction',
                            meeting['if_auction'] == '1' ? 'Yes' : 'No',
                          ),
                          _buildInfoRow('With Bid', withBid ? 'Yes' : 'No'),
                          _buildInfoRow(
                            'Status',
                            meeting['status'] == '1' ? 'Active' : 'Inactive',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.menu, color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                      itemBuilder:
                          (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'edit_time',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Edit Time'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'edit_date',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Edit Date'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'send_location_request',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Send Location Request'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'proceed_with_bid',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.gavel,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Proceed with Bid'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'cancel',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cancel,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Cancel'),
                                ],
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
        // Seller Status Messages
        if (sellerNotResponding)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seller not responding, inconvenience regretted.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We are trying to reach the seller, you will receive a reschedule request if the seller responds in 24 hours. If the seller does not respond, the ad will be held thereafter.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        if (needsReschedule)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Reschedule request sent. Awaiting seller response.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        // Call Support Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: () => _callSupport(context),
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('Call Support'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
