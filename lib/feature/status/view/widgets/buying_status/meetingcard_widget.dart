import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/feature/chat/views/chat_page.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/call_support/call_support.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MeetingCard extends StatefulWidget {
  final Map<String, dynamic> meeting;
  final String baseUrl;
  final String token;
  final String currentTab;
  final Function(Map<String, dynamic>) onEditDate;
  final Function(Map<String, dynamic>) onEditTime;
  final Function(Map<String, dynamic>)? onDelete;
  final VoidCallback? onRefresh;
  const MeetingCard({
    super.key,
    required this.meeting,
    required this.baseUrl,
    required this.token,
    required this.currentTab,
    required this.onEditDate,
    required this.onEditTime,
    this.onDelete,
    this.onRefresh,
  });

  static final Map<String, String> _locationCache = {};

  @override
  State<MeetingCard> createState() => _MeetingCardState();
}

class _MeetingCardState extends State<MeetingCard> {
  String _middleStatusData = 'Schedule meeting';
  String? _latitude;
  String? _longitude;

  @override
  void initState() {
    super.initState();
    _middleStatusData = _getMeetingStatus(widget.meeting);
    // Initialize with existing coordinates if available
    _latitude = widget.meeting['latitude']?.toString();
    _longitude = widget.meeting['longitude']?.toString();
    debugPrint('Initial meeting data: ${widget.meeting}');
    if (_latitude == null ||
        _latitude!.isEmpty ||
        _longitude == null ||
        _longitude!.isEmpty) {
      _fetchAndSetCoordinates();
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

  Future<Map<String, String>> fetchPostCoordinates(
    String baseUrl,
    String token,
    String postId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/post-details.php?token=$token&post_id=$postId'),
        headers: {'token': token},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'true' &&
            data['data'] is List &&
            data['data'].isNotEmpty) {
          final post = data['data'][0];
          final coords = {
            'latitude': post['latitude']?.toString() ?? '',
            'longitude': post['longitude']?.toString() ?? '',
          };
          debugPrint('Fetched coordinates for post $postId: $coords');
          return coords;
        } else {
          debugPrint(
            'Error: Invalid response or no data found for post $postId',
          );
          return {'latitude': '', 'longitude': ''};
        }
      } else {
        debugPrint(
          'Error: Failed to fetch post details, status code: ${response.statusCode}',
        );
        return {'latitude': '', 'longitude': ''};
      }
    } catch (e) {
      debugPrint('Error fetching post coordinates: $e');
      return {'latitude': '', 'longitude': ''};
    }
  }

  Future<void> _fetchAndSetCoordinates() async {
    final coords = await fetchPostCoordinates(
      widget.baseUrl,
      widget.token,
      widget.meeting['post_id']?.toString() ?? '909',
    );
    setState(() {
      _latitude = coords['latitude'];
      _longitude = coords['longitude'];
    });
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

  Future<void> _deleteMeeting(BuildContext context, String meetingId) async {
    try {
      final userId = widget.meeting['user_id']?.toString() ?? '6';
      debugPrint('Deleting meeting ID: $meetingId for user ID: $userId');
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/my-meeting-delete.php?token=${widget.token}&user_id=$userId&ads_post_customer_meeting_id=$meetingId',
        ),
        headers: {'token': widget.token},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Delete response: $data');
        if (data['status'] == true || data['status'] == 'true') {
          // SUCCESS: Just call onDelete - let parent handle refresh and SnackBar
          widget.onDelete?.call(widget.meeting);
        } else {
          // Only show error SnackBar here since we're not navigating away
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed: ${data['message'] ?? 'Unknown error'}'),
              ),
            );
          }
        }
      } else {
        debugPrint('Delete failed with status code: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete meeting')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting meeting: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error deleting meeting')));
      }
    }
  }

  // Add this helper method to force refresh the parent
  void _forceRefreshParent() {
    // This will depend on how your parent widget is structured
    // If your parent has a refresh method, you might need to pass it down
    // For now, let's use a simpler approach - just call the onDelete callback
    // which should trigger a refresh in the parent
    widget.onDelete?.call(widget.meeting);
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
    if (meeting['meeting_done'] == '1') {
      return 'Meeting Completed';
    } else if (meeting['seller_approvel'] == '1') {
      return 'Seller Confirmed';
    } else if (meeting['meeting_time'] != 'N/A' &&
        meeting['meeting_time']?.isNotEmpty == true &&
        meeting['meeting_time'] != '00:00:00') {
      return 'Waiting for Seller Confirmation';
    } else if (meeting['meeting_date'] != 'N/A' &&
        meeting['meeting_date']?.isNotEmpty == true &&
        meeting['meeting_date'] != '1970-01-01') {
      return 'Please Fix Time';
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
    Color color =
        isCompleted ? Colors.green : (isActive ? Colors.blue : Colors.grey);
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
          child:
              isCompleted
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : (isActive
                      ? const Icon(Icons.circle, size: 8, color: Colors.white)
                      : null),
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
    final userProvider = Provider.of<LoggedUserProvider>(
      context,
      listen: false,
    );
    final buyerName = userProvider.userData?.name ?? 'Buyer';
    final productName = widget.meeting['title'] ?? 'Unknown Product';
    final meetingDate = widget.meeting['meeting_date'] ?? 'N/A';
    final meetingTime = widget.meeting['meeting_time'] ?? 'N/A';
    final sellerApproval = widget.meeting['seller_approvel']?.toString() ?? '0';
    final sellerId = widget.meeting['created_by']?.toString() ?? 'Unknown';
    final sellerName = widget.meeting['seller_name']?.toString() ?? 'Seller';
    final sellerImage = widget.meeting['seller_image']?.toString() ?? '';

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

    bool isDateSet =
        widget.meeting['meeting_date'] != 'N/A' &&
        widget.meeting['meeting_date']?.isNotEmpty == true &&
        widget.meeting['meeting_date'] != '1970-01-01';
    bool isTimeSet =
        widget.meeting['meeting_time'] != 'N/A' &&
        widget.meeting['meeting_time']?.isNotEmpty == true &&
        widget.meeting['meeting_time'] != '00:00:00';
    bool isSellerConfirmed = widget.meeting['seller_approvel'] == '1';
    bool isMeetingDone = widget.meeting['meeting_done'] == '1';

    bool step1Completed = isDateSet;
    bool step1Active = !isDateSet;

    bool step2Completed = isTimeSet;
    bool step2Active = step1Completed && !isTimeSet;

    bool step3Completed = isSellerConfirmed && step2Completed;
    bool step3Active = step2Completed && !isSellerConfirmed;

    bool step4Completed = isMeetingDone && step3Completed;
    bool step4Active = step3Completed && !isMeetingDone;

    String step1Message =
        step1Completed
            ? widget.meeting['meeting_date'] ?? ''
            : (step1Active ? 'Select Date' : '');
    String step2Message =
        step2Completed
            ? (widget.meeting['meeting_time'] ?? 'Time Set')
            : (step2Active ? 'Fix Time' : '');
    String step3Message =
        step3Completed
            ? 'Confirmed'
            : (step3Active ? 'Awaiting Confirmation' : '');
    String step4Message =
        step4Completed ? 'Completed' : (step4Active ? 'Ready' : '');

    return FutureBuilder<Map<String, dynamic>>(
      future:
          status == 'Meeting Completed'
              ? _fetchMeetingDoneStatus(widget.meeting['id'])
              : Future.value({
                'middleStatus_data': _middleStatusData,
                'footerStatus_data': widget.meeting['footerStatus_data'] ?? '',
                'timer': widget.meeting['timer'] ?? '0',
              }),
      builder: (context, statusSnapshot) {
        final statusData =
            statusSnapshot.data ??
            {
              'middleStatus_data': _middleStatusData,
              'footerStatus_data': widget.meeting['footerStatus_data'] ?? '',
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
                          if (status == 'Meeting Completed' &&
                              decisionPendingStatus.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.grey[50]),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    size: 14,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      decisionPendingStatus,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      constraints: const BoxConstraints(
                                        maxWidth: 200,
                                      ),
                                      child: Text(
                                        statusData['middleStatus_data'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel,
                                        size: 22,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text(
                                                'Delete Meeting',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this meeting?',
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: const Text('Cancel'),
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                ),
                                                TextButton(
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    _deleteMeeting(
                                                      context,
                                                      widget.meeting['id'],
                                                    );
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.meeting['title'] ??
                                      'Unknown Vehicle (ID: ${widget.meeting['post_id']})',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.directions_car,
                                                size: 12,
                                                color: Colors.grey[500],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'App Id: ${widget.meeting['appId'] ?? 'LAD_${widget.meeting['post_id']}'}',
                                                style: TextStyle(
                                                  fontSize: 10,
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
                                                size: 12,
                                                color: Colors.grey[500],
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Location: $locationName',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[600],
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_latitude != null &&
                                              _latitude!.isNotEmpty &&
                                              _longitude != null &&
                                              _longitude!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.map,
                                                  size: 12,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () async {
                                                      final mapUrl = Uri.parse(
                                                        'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude',
                                                      );
                                                      if (await canLaunchUrl(
                                                        mapUrl,
                                                      )) {
                                                        await launchUrl(mapUrl);
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Could not open Google Maps',
                                                            ),
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: const Text(
                                                      'View on Google Maps',
                                                      style: TextStyle(
                                                        color: Colors.blue,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
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
                                                        fontSize: 9,
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                    Text(
                                                      targetPrice == 0
                                                          ? 'N/A'
                                                          : '₹${NumberFormat('#,##0').format(targetPrice)}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'My Bid',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                    Text(
                                                      bidAmount == 0 && !withBid
                                                          ? 'N/A'
                                                          : '₹${NumberFormat('#,##0').format(bidAmount)}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            isLowBid
                                                                ? Colors
                                                                    .orange[700]
                                                                : Colors
                                                                    .green[700],
                                                      ),
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
                                        imageUrl:
                                            widget.meeting['carImage']
                                                ?.toString() ??
                                            '',
                                        width: 120,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) => Container(
                                              width: 120,
                                              height: 120,
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 1.5,
                                                      color: Colors.blue,
                                                    ),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) {
                                          debugPrint(
                                            'Image load error: $error for URL: $url',
                                          );
                                          return Container(
                                            width: 120,
                                            height: 120,
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.directions_car,
                                              size: 30,
                                              color: Colors.grey,
                                            ),
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
                                if (sellerApproval == '1') ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final initialMessage =
                                            'Hi, I am $buyerName, I want to buy this $productName $meetingTime and $meetingDate';
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => ChatPage(
                                                  listenerId: sellerId,
                                                  listenerName: sellerName,
                                                  listenerImage: sellerImage,
                                                  initialMessage:
                                                      initialMessage,
                                                ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 16,
                                        ),
                                      ),
                                      child: const Text(
                                        'Chat with Seller',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(height: 1, color: Colors.grey[300]),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical:
                                  statusData['middleStatus_data'].length > 20
                                      ? 12
                                      : 8,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
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
                                      child: Divider(
                                        color:
                                            step1Completed
                                                ? Colors.green
                                                : Colors.grey,
                                        thickness: 1.5,
                                        height: 16,
                                      ),
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
                                      child: Divider(
                                        color:
                                            step2Completed
                                                ? Colors.green
                                                : Colors.grey,
                                        thickness: 1.5,
                                        height: 16,
                                      ),
                                    ),
                                    Flexible(
                                      flex: 2,
                                      child: _buildTimelineStep(
                                        title: 'Seller Availability',
                                        message: step3Message,
                                        isActive: step3Active,
                                        isCompleted: step3Completed,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Divider(
                                        color:
                                            step3Completed
                                                ? Colors.green
                                                : Colors.grey,
                                        thickness: 1.5,
                                        height: 16,
                                      ),
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
                                        onPressed:
                                            status != 'Meeting Completed'
                                                ? () => widget.onEditDate(
                                                  widget.meeting,
                                                )
                                                : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                        child: Text(
                                          step1Completed
                                              ? 'Edit Date'
                                              : 'Set Date',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed:
                                            (status != 'Meeting Completed' &&
                                                    step1Completed)
                                                ? () => widget.onEditTime(
                                                  widget.meeting,
                                                )
                                                : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              !step1Completed
                                                  ? Colors.grey
                                                  : (step2Completed
                                                      ? Colors.blue
                                                      : Colors.orange),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                        child: Text(
                                          step2Completed
                                              ? 'Edit Time'
                                              : 'Fix Time',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (status == 'Meeting Completed') ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed:
                                              () => _notInterested(
                                                context,
                                                widget.meeting['id'],
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Not Interested',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed:
                                              () => _revisit(
                                                context,
                                                widget.meeting['id'],
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Revisit',
                                            style: TextStyle(fontSize: 12),
                                          ),
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
