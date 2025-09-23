import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/call_support/call_support.dart';

class MeetingCard extends StatefulWidget {
  final Map<String, dynamic> meeting;
  final String baseUrl;
  final String token;
  final String currentTab;
  final Function(String) onLocationRequestSent;
  final VoidCallback onProceedWithBid;
  final Function(Map<String, dynamic>) onEditDate;
  final Function(Map<String, dynamic>) onEditTime;
  final Function(Map<String, dynamic>) onSendLocationRequest;
  final Function(Map<String, dynamic>) onViewLocation;

  const MeetingCard({
    super.key,
    required this.meeting,
    required this.baseUrl,
    required this.token,
    required this.currentTab,
    required this.onLocationRequestSent,
    required this.onProceedWithBid,
    required this.onEditDate,
    required this.onEditTime,
    required this.onSendLocationRequest,
    required this.onViewLocation,
  });

  // Cache for location data
  static final Map<String, String> _locationCache = {};

  @override
  State<MeetingCard> createState() => _MeetingCardState();
}

class _MeetingCardState extends State<MeetingCard> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  String _middleStatusData = 'Schedule meeting';

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    debugPrint('Checking timer for meeting ${widget.meeting['id']}');
    final status = _getMeetingStatus(widget.meeting);
    debugPrint('Status: $status');
    if (status == 'Awaiting Location') {
      final createdOn = DateTime.tryParse(widget.meeting['created_on'] ?? '');
      debugPrint('Created On: $createdOn');
      if (createdOn != null) {
        final expiryTime = createdOn.add(const Duration(hours: 24));
        _remainingTime = expiryTime.difference(DateTime.now());
        debugPrint('Remaining Time: ${_remainingTime.inSeconds} seconds');
        if (_remainingTime.inSeconds > 0) {
          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() {
              _remainingTime = expiryTime.difference(DateTime.now());
              if (_remainingTime.inSeconds <= 0) {
                _middleStatusData = 'Meeting request has ended';
                timer.cancel();
                debugPrint('Timer expired for meeting ${widget.meeting['id']}');
              } else {
                _middleStatusData =
                    'Meeting request ends in ${_formatDuration(_remainingTime)}';
                debugPrint('Timer updated: $_middleStatusData');
              }
            });
          });
        } else {
          _middleStatusData = 'Meeting request has ended';
          debugPrint('Meeting already expired');
        }
      } else {
        debugPrint(
          'Error: Invalid or missing created_on for meeting ${widget.meeting['id']}',
        );
        _middleStatusData = 'Awaiting Location (Invalid Date)';
      }
    } else {
      _middleStatusData = 'Schedule meeting';
      debugPrint('No timer needed for status: $status');
    }
  }

  Future<Map<String, String>> _fetchLocations() async {
    if (MeetingCard._locationCache.isNotEmpty) {
      return MeetingCard._locationCache;
    }

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/list-location.php?token=${widget.token}'),
        headers: {'token': widget.token},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'true' && data['data'] is List) {
          for (var location in data['data']) {
            if (location['status'] == '1') {
              MeetingCard._locationCache[location['id']] = location['name'];
            }
          }
          return MeetingCard._locationCache;
        }
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _fetchMeetingDoneStatus(String meetingId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/my-meeting-done-post-status.php?token=${widget.token}&ads_post_customer_meeting_id=$meetingId',
        ),
        headers: {'token': widget.token},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          return {
            'middleStatus_data':
                data['data'][0]['middle_status'] ?? 'Enter Your Feedback',
            'footerStatus_data':
                data['data'][0]['Footer_status'] ?? 'Thanks for meeting done',
            'timer': data['data'][0]['timer']?.toString() ?? '0',
          };
        }
      }
      return {
        'middleStatus_data': 'Enter Your Feedback',
        'footerStatus_data': 'Thanks for meeting done',
        'timer': '0',
      };
    } catch (e) {
      debugPrint('Error fetching meeting done status: $e');
      return {
        'middleStatus_data': 'Enter Your Feedback',
        'footerStatus_data': 'Thanks for meeting done',
        'timer': '0',
      };
    }
  }

  Future<String> _fetchOfferPrice(
    String userId,
    String postId,
    String meetingId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/my-meetings-offer-price.php?token=${widget.token}&user_id=$userId&post_id=$postId&ads_post_customer_meeting_id=$meetingId&price_offered=${widget.meeting['price_offered']}',
        ),
        headers: {'token': widget.token},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          return data['data']['price_offered']?.toString() ??
              widget.meeting['price_offered'] ??
              '0.00';
        }
      }
      return widget.meeting['price_offered'] ?? '0.00';
    } catch (e) {
      debugPrint('Error fetching offer price: $e');
      return widget.meeting['price_offered'] ?? '0.00';
    }
  }

  Future<String> _fetchDecisionPendingStatus(String meetingId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/my-meetings-decision-pendding.php?token=${widget.token}&ads_post_customer_meeting_id=$meetingId',
        ),
        headers: {'token': widget.token},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          return data['message'] ?? 'Decision pending';
        }
      }
      return 'Decision pending';
    } catch (e) {
      debugPrint('Error fetching decision pending status: $e');
      return 'Decision pending';
    }
  }

  Future<void> _notInterested(BuildContext context, String meetingId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/my-meetings-not-intersted.php?token=${widget.token}&ads_post_customer_meeting_id=$meetingId',
        ),
        headers: {'token': widget.token},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as not interested')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${data['message'] ?? 'Unknown error'}'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark as not interested')),
        );
      }
    } catch (e) {
      debugPrint('Error marking not interested: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error marking not interested')),
      );
    }
  }

  Future<void> _revisit(BuildContext context, String meetingId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/my-meetings-revisit.php?token=${widget.token}&ads_post_customer_meeting_id=$meetingId',
        ),
        headers: {'token': widget.token},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Revisit requested successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${data['message'] ?? 'Unknown error'}'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to request revisit')),
        );
      }
    } catch (e) {
      debugPrint('Error requesting revisit: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error requesting revisit')));
    }
  }

  String _getMeetingStatus(Map<String, dynamic> meeting) {
    debugPrint(
      'Meeting ${meeting['id']}: status=${meeting['status']}, '
      'meeting_done=${meeting['meeting_done']}, '
      'if_location_request=${meeting['if_location_request']}, '
      'meeting_date=${meeting['meeting_date']}, '
      'seller_approvel=${meeting['seller_approvel']}, '
      'admin_approvel=${meeting['admin_approvel']}',
    );
    if (meeting['status'] == '1' &&
        meeting['meeting_done'] == '0' &&
        meeting['if_location_request'] == '0' &&
        meeting['meeting_date'] != 'N/A' &&
        meeting['meeting_date']?.isNotEmpty == true) {
      debugPrint('Meeting ${meeting['id']} status: Date Fixed');
      return 'Date Fixed';
    }
    if (meeting['meeting_done'] == '1') {
      debugPrint('Meeting ${meeting['id']} status: Meeting Completed');
      return 'Meeting Completed';
    }
    if (meeting['seller_approvel'] == '1' &&
        meeting['admin_approvel'] == '1' &&
        meeting['meeting_done'] == '0' &&
        meeting['if_location_request'] == '1' &&
        meeting['location_link']?.isNotEmpty == true) {
      debugPrint('Meeting ${meeting['id']} status: Ready For Meeting');
      return 'Ready For Meeting';
    }
    if (meeting['if_location_request'] == '1' &&
        (meeting['status'] == '1' || meeting['status'] == true) &&
        meeting['meeting_done'] == '0' &&
        (meeting['location_link'] == null || meeting['location_link'] == '')) {
      debugPrint('Meeting ${meeting['id']} status: Awaiting Location');
      return 'Awaiting Location';
    }
    if (meeting['status'] == '1' &&
        meeting['meeting_done'] == '0' &&
        meeting['if_location_request'] == '0' &&
        meeting['meeting_time'] != 'N/A' &&
        meeting['meeting_time']?.isNotEmpty == true) {
      debugPrint('Meeting ${meeting['id']} status: Meeting Request');
      return 'Meeting Request';
    }
    debugPrint('Meeting ${meeting['id']} status: Unknown');
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final status = _getMeetingStatus(widget.meeting);
    final bool withBid = widget.meeting['with_bid'] == '1';
    final double bidAmount =
        double.tryParse(
          widget.meeting['bid_amount'] ?? widget.meeting['bidPrice'] ?? '0',
        ) ??
        0;
    final double targetPrice =
        double.tryParse(widget.meeting['targetPrice']?.toString() ?? '0') ?? 0;
    final bool isLowBid = bidAmount > 0 && bidAmount < targetPrice;
    final bool isReadyForMeeting =
        widget.meeting['seller_approvel'] == '1' &&
        widget.meeting['admin_approvel'] == '1' &&
        widget.meeting['meeting_done'] == '0';

    return FutureBuilder<Map<String, dynamic>>(
      future:
          status == 'Meeting Completed'
              ? _fetchMeetingDoneStatus(widget.meeting['id'])
              : Future.value({
                'middleStatus_data':
                    status == 'Awaiting Location'
                        ? _middleStatusData
                        : widget.meeting['middleStatus_data'] ??
                            'Schedule meeting',
                'footerStatus_data':
                    widget.meeting['footerStatus_data'] ??
                    'Due to convenience reasons meeting location can be requested 24 hrs before meeting time only',
                'timer': widget.meeting['timer'] ?? '0',
              }),
      builder: (context, statusSnapshot) {
        final statusData =
            statusSnapshot.data ??
            {
              'middleStatus_data':
                  status == 'Awaiting Location'
                      ? _middleStatusData
                      : widget.meeting['middleStatus_data'] ??
                          'Schedule meeting',
              'footerStatus_data':
                  widget.meeting['footerStatus_data'] ??
                  'Due to convnience reasons meeting location can be requested 24 hrs before meeting time only',
              'timer': widget.meeting['timer'] ?? '0',
            };
        return FutureBuilder<String>(
          future:
              status == 'Meeting Completed'
                  ? _fetchOfferPrice(
                    widget.meeting['user_id'],
                    widget.meeting['post_id'],
                    widget.meeting['id'],
                  )
                  : Future.value(widget.meeting['price_offered'] ?? '0.00'),
          builder: (context, offerPriceSnapshot) {
            final offerPrice =
                offerPriceSnapshot.data ??
                widget.meeting['price_offered'] ??
                '0.00';

            return FutureBuilder<String>(
              future:
                  status == 'Meeting Completed'
                      ? _fetchDecisionPendingStatus(widget.meeting['id'])
                      : Future.value(''),
              builder: (context, decisionPendingSnapshot) {
                final decisionPendingStatus =
                    decisionPendingSnapshot.data ?? '';

                return FutureBuilder<Map<String, String>>(
                  future: _fetchLocations(),
                  builder: (context, locationSnapshot) {
                    final locations = locationSnapshot.data ?? {};
                    final locationName =
                        locations[widget.meeting['parent_zone_id']] ??
                        'Unknown Location';

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
                          if (status == 'Meeting Completed' &&
                              decisionPendingStatus.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(color: Colors.grey[50]),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    size: 16,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      decisionPendingStatus,
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
                                        imageUrl:
                                            widget.meeting['carImage']
                                                ?.toString() ??
                                            '',
                                        width: 100,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) => Container(
                                              width: 90,
                                              height: 90,
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.blue,
                                                    ),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) {
                                          debugPrint(
                                            'Image load error: $error for URL: $url',
                                          );
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.meeting['title'] ??
                                                'Unknown Vehicle (ID: ${widget.meeting['post_id']})',
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

                                                'App Id    : ${widget.meeting['appId'] ?? 'LAD_${widget.meeting['post_id']}'}',

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
                                                  'Location: $locationName',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.monetization_on,
                                                size: 14,
                                                color: Colors.grey[500],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                status == 'Meeting Completed'
                                                    ? 'Offer Price: ₹${NumberFormat('#,##0').format(double.tryParse(offerPrice) ?? 0)}'
                                                    : 'Location Requests: ${widget.meeting['location_request_count'] ?? '0'}/2',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: SizedBox(
                                              height: 30,
                                              child: CallSupportButton(
                                                label: 'Call Support', onPressed: () {  },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Meeting Date',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          Text(
                                            widget.meeting['meeting_date']
                                                    ?.toString() ??
                                                'N/A',
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Meeting Time',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          Text(
                                            widget.meeting['meeting_time']
                                                    ?.toString() ??
                                                'N/A',
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'My Bid',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          Text(
                                            bidAmount == 0 && !withBid
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
                                    widget
                                            .meeting['location_link']
                                            ?.isNotEmpty ==
                                        true) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Meeting Location',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap:
                                                  () => widget.onViewLocation(
                                                    widget.meeting,
                                                  ),
                                              child: const Text(
                                                'Open in Google Maps',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              'Coordinates: ${widget.meeting['latitude']}, ${widget.meeting['longitude']}',
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
                          Container(
                            height: 1.3,
                            width: double.infinity,
                            color: Colors.grey[300],
                          ),
                          Container(
                            decoration: BoxDecoration(color: Colors.grey[50]),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (status ==
                                                'Awaiting Location') ...[
                                              Icon(
                                                Icons.timer,
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                            Flexible(
                                              child: Text(
                                                statusData['middleStatus_data'],
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.menu, size: 22),
                                      position: PopupMenuPosition.over,
                                      offset: const Offset(0, -200),
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      onSelected: (value) {
                                        debugPrint(
                                          'Menu option selected: $value for meeting ${widget.meeting['id']}',
                                        );
                                        if (value == 'edit_date' &&
                                            status != 'Meeting Completed') {
                                          widget.onEditDate(widget.meeting);
                                        } else if (value == 'edit_time' &&
                                            status != 'Meeting Completed') {
                                          widget.onEditTime(widget.meeting);
                                        } else if (value ==
                                            'proceed_with_bid') {
                                          widget.onProceedWithBid();
                                        } else if (value == 'send_location' &&
                                            widget.currentTab ==
                                                'Meeting Request') {
                                          widget.onSendLocationRequest(
                                            widget.meeting,
                                          );
                                        } else if (value == 'view_location') {
                                          widget.onViewLocation(widget.meeting);
                                        } else if (value == 'not_interested') {
                                          _notInterested(
                                            context,
                                            widget.meeting['id'],
                                          );
                                        } else if (value == 'revisit') {
                                          _revisit(
                                            context,
                                            widget.meeting['id'],
                                          );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        final currentStatus = _getMeetingStatus(
                                          widget.meeting,
                                        );
                                        List<PopupMenuItem<String>> items = [];

                                        if (currentStatus !=
                                            'Meeting Completed') {
                                          items.addAll([
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
                                            PopupMenuItem<String>(
                                              value: 'edit_time',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    widget.currentTab ==
                                                            'Date Fixed'
                                                        ? 'Fix Time'
                                                        : 'Edit Time',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ]);
                                        }

                                        if (widget.currentTab ==
                                                'Meeting Request' &&
                                            widget.meeting['if_location_request'] ==
                                                '0') {
                                          items.addAll([
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
                                            const PopupMenuItem<String>(
                                              value: 'send_location',
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
                                          ]);
                                        } else if (currentStatus ==
                                            'Date Fixed') {
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
                                        } else if (currentStatus ==
                                            'Awaiting Location') {
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
                                        } else if (currentStatus ==
                                                'Ready For Meeting' &&
                                            widget
                                                    .meeting['location_link']
                                                    ?.isNotEmpty ==
                                                true) {
                                          items.add(
                                            const PopupMenuItem<String>(
                                              value: 'view_location',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.map,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('View Location'),
                                                ],
                                              ),
                                            ),
                                          );
                                        } else if (currentStatus ==
                                            'Meeting Completed') {
                                          items.addAll([
                                            const PopupMenuItem<String>(
                                              value: 'not_interested',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.cancel,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Not Interested'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'revisit',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.refresh,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Revisit'),
                                                ],
                                              ),
                                            ),
                                          ]);
                                        }
                                        return items;
                                      },
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 1.3,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue[100]!,
                                    ),
                                  ),
                                  child: Center(
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
                                            statusData['footerStatus_data'],
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
            );
          },
        );
      },
    );
  }
}
