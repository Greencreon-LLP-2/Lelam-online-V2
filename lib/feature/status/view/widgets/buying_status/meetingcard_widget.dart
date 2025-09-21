import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/call_support/call_support.dart';

class MeetingCard extends StatelessWidget {
  final Map<String, dynamic> meeting;
  final String baseUrl;
  final String token;
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
    required this.onLocationRequestSent,
    required this.onProceedWithBid,
    required this.onEditDate,
    required this.onEditTime,
    required this.onSendLocationRequest,
    required this.onViewLocation,
  });

  // Cache for location data
  static final Map<String, String> _locationCache = {};

  Future<Map<String, String>> _fetchLocations() async {
    if (_locationCache.isNotEmpty) {
      return _locationCache;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/list-location.php?token=$token'),
        headers: {'token': token},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'true' && data['data'] is List) {
          for (var location in data['data']) {
            if (location['status'] == '1') {
              _locationCache[location['id']] = location['name'];
            }
          }
          return _locationCache;
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
          '$baseUrl/my-meeting-done-post-status.php?token=$token&ads_post_customer_meeting_id=$meetingId',
        ),
        headers: {'token': token},
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
          '$baseUrl/my-meetings-offer-price.php?token=$token&user_id=$userId&post_id=$postId&ads_post_customer_meeting_id=$meetingId&price_offered=${meeting['price_offered']}',
        ),
        headers: {'token': token},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          return data['data']['price_offered']?.toString() ??
              meeting['price_offered'] ??
              '0.00';
        }
      }
      return meeting['price_offered'] ?? '0.00';
    } catch (e) {
      debugPrint('Error fetching offer price: $e');
      return meeting['price_offered'] ?? '0.00';
    }
  }

  Future<String> _fetchDecisionPendingStatus(String meetingId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/my-meetings-decision-pendding.php?token=$token&ads_post_customer_meeting_id=$meetingId',
        ),
        headers: {'token': token},
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
          '$baseUrl/my-meetings-not-intersted.php?token=$token&ads_post_customer_meeting_id=$meetingId',
        ),
        headers: {'token': token},
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
          '$baseUrl/my-meetings-revisit.php?token=$token&ads_post_customer_meeting_id=$meetingId',
        ),
        headers: {'token': token},
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
      'admin_approvel=${meeting['admin_approvel']}, '
      'location_link=${meeting['location_link']}',
    );
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
    if ((meeting['status'] == '1' || meeting['status'] == true) &&
        meeting['meeting_done'] == '0' &&
        meeting['if_location_request'] == '0') {
      debugPrint('Meeting ${meeting['id']} status: Meeting Request');
      return 'Meeting Request';
    }
    if ((meeting['status'] == '1' || meeting['status'] == true) &&
        meeting['meeting_done'] == '0' &&
        meeting['if_location_request'] != '0' &&
        meeting['meeting_date'] != 'N/A' &&
        meeting['meeting_date']?.isNotEmpty == true) {
      debugPrint('Meeting ${meeting['id']} status: Date Fixed');
      return 'Date Fixed';
    }
    debugPrint('Meeting ${meeting['id']} status: Unknown');
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

    return FutureBuilder<Map<String, dynamic>>(
      future:
          status == 'Meeting Completed'
              ? _fetchMeetingDoneStatus(meeting['id'])
              : Future.value({
                  'middleStatus_data':
                      meeting['middleStatus_data'] ?? 'Schedule meeting',
                  'footerStatus_data':
                      meeting['footerStatus_data'] ??
                      'Click call support for full details',
                  'timer': meeting['timer'] ?? '0',
                }),
      builder: (context, statusSnapshot) {
        final statusData =
            statusSnapshot.data ??
            {
              'middleStatus_data':
                  meeting['middleStatus_data'] ?? 'Schedule meeting',
              'footerStatus_data':
                  meeting['footerStatus_data'] ??
                  'Click call support for full details',
              'timer': meeting['timer'] ?? '0',
            };

        return FutureBuilder<String>(
          future:
              status == 'Meeting Completed'
                  ? _fetchOfferPrice(
                      meeting['user_id'],
                      meeting['post_id'],
                      meeting['id'],
                    )
                  : Future.value(meeting['price_offered'] ?? '0.00'),
          builder: (context, offerPriceSnapshot) {
            final offerPrice =
                offerPriceSnapshot.data ?? meeting['price_offered'] ?? '0.00';

            return FutureBuilder<String>(
              future:
                  status == 'Meeting Completed'
                      ? _fetchDecisionPendingStatus(meeting['id'])
                      : Future.value(''),
              builder: (context, decisionPendingSnapshot) {
                final decisionPendingStatus =
                    decisionPendingSnapshot.data ?? '';

                return FutureBuilder<Map<String, String>>(
                  future: _fetchLocations(),
                  builder: (context, locationSnapshot) {
                    final locations = locationSnapshot.data ?? {};
                    final locationName =
                        locations[meeting['parent_zone_id']] ??
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
                                            meeting['carImage']?.toString() ??
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
                                                    : 'Location Requests: ${meeting['location_request_count'] ?? '0'}/2',
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
                                                label: 'Call Support',
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
                                            meeting['meeting_date']
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
                                            meeting['meeting_time']
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
                                    if (withBid)
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
                                    meeting['location_link']?.isNotEmpty ==
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
                                                  () => onViewLocation(meeting),
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
                                          statusData['middleStatus_data'],
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(Icons.menu, size: 22),
                                      ),
                                      position: PopupMenuPosition.over,
                                      offset: const Offset(0, -200),
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      onSelected: (value) {
                                        debugPrint(
                                          'Menu option selected: $value for meeting ${meeting['id']}',
                                        );
                                        if (value == 'edit_date' &&
                                            status != 'Meeting Completed') {
                                          onEditDate(meeting);
                                        } else if (value == 'edit_time' &&
                                            status != 'Meeting Completed') {
                                          onEditTime(meeting);
                                        } else if (value ==
                                            'proceed_with_bid') {
                                          onProceedWithBid();
                                        } else if (value == 'send_location') {
                                          onSendLocationRequest(meeting);
                                        } else if (value == 'view_location') {
                                          onViewLocation(meeting);
                                        } else if (value == 'not_interested') {
                                          _notInterested(
                                            context,
                                            meeting['id'],
                                          );
                                        } else if (value == 'revisit') {
                                          _revisit(context, meeting['id']);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        final currentStatus = _getMeetingStatus(
                                          meeting,
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
                                          ]);
                                        }

                                        if (currentStatus ==
                                            'Meeting Request') {
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
                                          ]);
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
                                            meeting['location_link']
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
                                const Divider(),
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