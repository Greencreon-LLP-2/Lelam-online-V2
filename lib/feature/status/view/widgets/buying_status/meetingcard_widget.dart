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
  final Function(Map<String, dynamic>) onEditDate;
  final Function(Map<String, dynamic>) onEditTime;

  const MeetingCard({
    super.key,
    required this.meeting,
    required this.baseUrl,
    required this.token,
    required this.currentTab,
    required this.onEditDate,
    required this.onEditTime,
  });

  static final Map<String, String> _locationCache = {};

  @override
  State<MeetingCard> createState() => _MeetingCardState();
}

class _MeetingCardState extends State<MeetingCard> {
  String _middleStatusData = 'Schedule meeting';

  @override
  void initState() {
    super.initState();
    _middleStatusData = _getMeetingStatus(widget.meeting);
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
        Uri.parse('${widget.baseUrl}/my-meeting-done-post-status.php?token=${widget.token}&ads_post_customer_meeting_id=$meetingId'),
        headers: {'token': widget.token},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          return {
            'middleStatus_data': data['data'][0]['middle_status'] ?? 'Enter Your Feedback',
            'footerStatus_data': data['data'][0]['Footer_status'] ?? 'Thanks for meeting done',
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

  Future<String> _fetchOfferPrice(String userId, String postId, String meetingId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${widget.baseUrl}/my-meetings-offer-price.php?token=${widget.token}&user_id=$userId&post_id=$postId&ads_post_customer_meeting_id=$meetingId&price_offered=${widget.meeting['price_offered']}'),
        headers: {'token': widget.token},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          return data['data']['price_offered']?.toString() ?? widget.meeting['price_offered'] ?? '0.00';
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
        Uri.parse('${widget.baseUrl}/my-meetings-decision-pendding.php?token=${widget.token}&ads_post_customer_meeting_id=$meetingId'),
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
        Uri.parse('${widget.baseUrl}/my-meetings-not-intersted.php?token=${widget.token}&ads_post_customer_meeting_id=$meetingId'),
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
            SnackBar(content: Text('Failed: ${data['message'] ?? 'Unknown error'}')),
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
        Uri.parse('${widget.baseUrl}/my-meetings-revisit.php?token=${widget.token}&ads_post_customer_meeting_id=$meetingId'),
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
            SnackBar(content: Text('Failed: ${data['message'] ?? 'Unknown error'}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to request revisit')),
        );
      }
    } catch (e) {
      debugPrint('Error requesting revisit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error requesting revisit')),
      );
    }
  }

  String _getMeetingStatus(Map<String, dynamic> meeting) {
    if (meeting['meeting_done'] == '1') {
      return 'Meeting Completed';
    } else if (meeting['seller_approvel'] == '1') {
      return 'Seller Confirmed';
    } else if (meeting['meeting_time'] != 'N/A' && meeting['meeting_time']?.isNotEmpty == true) {
      return 'Time Fixed';
    } else if (meeting['meeting_date'] != 'N/A' && meeting['meeting_date']?.isNotEmpty == true) {
      return 'Date Fixed';
    } else {
      return 'Meeting Request';
    }
  }

  Widget _buildTimelineStep({
    required String title,
    required bool isActive,
    required bool isCompleted,
    required String message,
  }) {
    Color color = isCompleted ? Colors.green : (isActive ? Colors.blue : Colors.grey);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: color, width: 1.5),
          ),
          child: isCompleted ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        if (isActive || isCompleted) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              message,
              style: TextStyle(fontSize: 8, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _getMeetingStatus(widget.meeting);
    final bool withBid = widget.meeting['with_bid'] == '1';
    final double bidAmount = double.tryParse(widget.meeting['bid_amount'] ?? widget.meeting['bidPrice'] ?? '0') ?? 0;
    final double targetPrice = double.tryParse(widget.meeting['targetPrice']?.toString() ?? '0') ?? 0;
    final bool isLowBid = bidAmount > 0 && bidAmount < targetPrice;

    bool isDateSet = widget.meeting['meeting_date'] != 'N/A' && widget.meeting['meeting_date']?.isNotEmpty == true;
    bool isTimeSet = widget.meeting['meeting_time'] != 'N/A' && widget.meeting['meeting_time']?.isNotEmpty == true;
    bool isSellerConfirmed = widget.meeting['seller_approvel'] == '1';
    bool isMeetingDone = widget.meeting['meeting_done'] == '1';

    bool step1Completed = isDateSet;
    bool step1Active = !isDateSet;
    bool step2Completed = isTimeSet;
    bool step2Active = isDateSet && !isTimeSet;
    bool step3Completed = isSellerConfirmed;
    bool step3Active = isTimeSet && !isSellerConfirmed;
    bool step4Completed = isMeetingDone;
    bool step4Active = isSellerConfirmed && !isMeetingDone;

    String step1Message = step1Completed ? widget.meeting['meeting_date'] ?? '' : (step1Active ? 'Select Date' : '');
    String step2Message = step2Completed ? widget.meeting['meeting_time'] ?? '' : (step2Active ? 'Select Time' : '');
    String step3Message = step3Completed ? 'Confirmed' : (step3Active ? 'Awaiting Confirmation' : '');
    String step4Message = step4Completed ? 'Completed' : (step4Active ? 'Ready' : '');

    return FutureBuilder<Map<String, dynamic>>(
      future: status == 'Meeting Completed'
          ? _fetchMeetingDoneStatus(widget.meeting['id'])
          : Future.value({
              'middleStatus_data': _middleStatusData,
              'footerStatus_data': widget.meeting['footerStatus_data'] ?? '',
              'timer': widget.meeting['timer'] ?? '0',
            }),
      builder: (context, statusSnapshot) {
        final statusData = statusSnapshot.data ??
            {
              'middleStatus_data': _middleStatusData,
              'footerStatus_data': widget.meeting['footerStatus_data'] ?? '',
              'timer': widget.meeting['timer'] ?? '0',
            };
        return FutureBuilder<String>(
          future: status == 'Meeting Completed'
              ? _fetchOfferPrice(widget.meeting['user_id'], widget.meeting['post_id'], widget.meeting['id'])
              : Future.value(widget.meeting['price_offered'] ?? '0.00'),
          builder: (context, offerPriceSnapshot) {
            final offerPrice = offerPriceSnapshot.data ?? widget.meeting['price_offered'] ?? '0.00';
            return FutureBuilder<String>(
              future: status == 'Meeting Completed' ? _fetchDecisionPendingStatus(widget.meeting['id']) : Future.value(''),
              builder: (context, decisionPendingSnapshot) {
                final decisionPendingStatus = decisionPendingSnapshot.data ?? '';
                return FutureBuilder<Map<String, String>>(
                  future: _fetchLocations(),
                  builder: (context, locationSnapshot) {
                    final locations = locationSnapshot.data ?? {};
                    final locationName = locations[widget.meeting['parent_zone_id']] ?? 'Unknown Location';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (status == 'Meeting Completed' && decisionPendingStatus.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.grey[50]),
                              child: Row(
                                children: [
                                  Icon(Icons.hourglass_empty, size: 14, color: Colors.blue[700]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      decisionPendingStatus,
                                      style: TextStyle(fontSize: 10, color: Colors.blue[700], fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                                      constraints: const BoxConstraints(maxWidth: 200),
                                      child: Text(
                                        statusData['middleStatus_data'],
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        debugPrint('Close button pressed for meeting ${widget.meeting['id']}');
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.meeting['title'] ?? 'Unknown Vehicle (ID: ${widget.meeting['post_id']})',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.directions_car, size: 12, color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Text(
                                                'App Id: ${widget.meeting['appId'] ?? 'LAD_${widget.meeting['post_id']}'}',
                                                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Location: $locationName',
                                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                                  overflow: TextOverflow.ellipsis,
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
                                                    Text('Target Price', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                                                    Text(
                                                      targetPrice == 0 ? 'N/A' : '₹${NumberFormat('#,##0').format(targetPrice)}',
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('My Bid', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                                                    Text(
                                                      bidAmount == 0 && !withBid
                                                          ? 'N/A'
                                                          : '₹${NumberFormat('#,##0').format(bidAmount)}',
                                                      style: TextStyle(
                                                          fontSize: 12, fontWeight: FontWeight.w600, color: isLowBid ? Colors.orange[700] : Colors.green[700]),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        imageUrl: widget.meeting['carImage']?.toString() ?? '',
                                        width: 120,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.grey[200],
                                          child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.blue)),
                                        ),
                                        errorWidget: (context, url, error) {
                                          debugPrint('Image load error: $error for URL: $url');
                                          return Container(
                                            width: 120,
                                            height: 120,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.directions_car, size: 30, color: Colors.grey),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: SizedBox(
                                    height: 28,
                                    child: CallSupportButton(
                                      label: 'Call Support',
                                      onPressed: () {},
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(height: 1, color: Colors.grey[300]),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: statusData['middleStatus_data'].length > 20 ? 12 : 8),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      flex: 2,
                                      child: _buildTimelineStep(
                                        title: 'Meeting Date',
                                        message: step1Message,
                                        isActive: step1Active,
                                        isCompleted: step1Completed,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Divider(color: Colors.grey, thickness: 1.5, height: 16),
                                    ),
                                    Flexible(
                                      flex: 2,
                                      child: _buildTimelineStep(
                                        title: 'Meeting Time',
                                        message: step2Message,
                                        isActive: step2Active,
                                        isCompleted: step2Completed,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Divider(color: Colors.grey, thickness: 1.5, height: 16),
                                    ),
                                    Flexible(
                                      flex: 2,
                                      child: _buildTimelineStep(
                                        title: 'Seller Confirmation',
                                        message: step3Message,
                                        isActive: step3Active,
                                        isCompleted: step3Completed,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Divider(color: Colors.grey, thickness: 1.5, height: 16),
                                    ),
                                    Flexible(
                                      flex: 2,
                                      child: _buildTimelineStep(
                                        title: 'Meeting Done',
                                        message: step4Message,
                                        isActive: step4Active,
                                        isCompleted: step4Completed,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: status != 'Meeting Completed' ? () => widget.onEditDate(widget.meeting) : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        child: const Text('Edit Date', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: status != 'Meeting Completed' ? () => widget.onEditTime(widget.meeting) : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        child: Text(
                                          widget.currentTab == 'Date Fixed' ? 'Fix Time' : 'Edit Time',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (status == 'Meeting Completed') ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _notInterested(context, widget.meeting['id']),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          child: const Text('Not Interested', style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _revisit(context, widget.meeting['id']),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          child: const Text('Revisit', style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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