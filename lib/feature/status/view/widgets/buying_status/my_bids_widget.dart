// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/my_meetings_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class MyBidsWidget extends StatefulWidget {
  final String baseUrl;
  final String token;
  final String? userId;

  const MyBidsWidget({
    super.key,
    this.baseUrl = 'https://lelamonline.com/admin/api/v1',
    this.token = '5cb2c9b569416b5db1604e0e12478ded',
    this.userId,
  });

  @override
  State<MyBidsWidget> createState() => _MyBidsWidgetState();
}

class _MyBidsWidgetState extends State<MyBidsWidget> {
  String? selectedBidType = 'Low Bids';
  List<Map<String, dynamic>> bids = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadBids();
  }

  Future<void> _loadBids() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> bidStrings = prefs.getStringList('userBids') ?? [];
      bids = bidStrings.map((bid) => jsonDecode(bid) as Map<String, dynamic>).toList();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'Error loading bids: $e';
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredBids() {
    return bids.where((bid) {
      final double bidPrice = double.tryParse(bid['bidPrice'] ?? '0') ?? 0;
      final double targetPrice = double.tryParse(bid['targetPrice'] ?? '0') ?? 0;

      if (selectedBidType == 'Low Bids') {
        return bidPrice < targetPrice;
      } else {
        return bidPrice >= targetPrice;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBids = _getFilteredBids();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header with tab selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'My Bids',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: MyBidItem(
                          title: 'Low Bids',
                          isSelected: selectedBidType == 'Low Bids',
                          onTap: () => setState(() => selectedBidType = 'Low Bids'),
                        ),
                      ),
                      Expanded(
                        child: MyBidItem(
                          title: 'High Bids',
                          isSelected: selectedBidType == 'High Bids',
                          onTap: () => setState(() => selectedBidType = 'High Bids'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content area
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : error != null
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
                                error!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : filteredBids.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.gavel_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No ${selectedBidType?.toLowerCase()} found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your bids will appear here once you start bidding',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredBids.length,
                              itemBuilder: (context, index) {
                                return BidCard(
                                  bid: filteredBids[index],
                                  baseUrl: widget.baseUrl,
                                  token: widget.token,
                                  userId: widget.userId ?? filteredBids[index]['userId'],
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class BidCard extends StatelessWidget {
  final Map<String, dynamic> bid;
  final String baseUrl;
  final String token;
  final String userId;

  const BidCard({
    super.key,
    required this.bid,
    required this.baseUrl,
    required this.token,
    required this.userId,
  });

  Future<void> _increaseBid(BuildContext context) async {
    final TextEditingController bidController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Increase Bid'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current bid: ₹${NumberFormat('#,##0').format(double.tryParse(bid['bidPrice'] ?? '0') ?? 0)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bidController,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                decoration: InputDecoration(
                  hintText: 'Enter new bid amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final String amount = bidController.text;
                if (amount.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a bid amount')),
                  );
                  return;
                }
                final int newBidAmount = int.tryParse(amount) ?? 0;
                if (newBidAmount <= (double.tryParse(bid['bidPrice'] ?? '0') ?? 0)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New bid must be higher than current bid')),
                  );
                  return;
                }

                try {
                  final response = await http.get(
                    Uri.parse('$baseUrl/increase-bid.php?token=$token&user_id=$userId&post_id=${bid['post_id']}&bidamt=$newBidAmount'),
                    headers: {
                      'token': token,
                      'Cookie': 'PHPSESSID=gbqbiugaqg3gco8kaespjf8lnp',
                    },
                  );

                  debugPrint('Increase bid response: ${response.body}');
                  try {
                    final responseData = jsonDecode(response.body);
                    if (response.statusCode == 200 && responseData['status'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(responseData['data'] ?? 'Bid increased successfully')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to increase bid: ${responseData['data'] ?? 'Unknown error'}')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error parsing response: ${response.body}')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error increasing bid: $e')),
                  );
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _proceedMeetingWithBid(BuildContext context) async {
    final TextEditingController timeController = TextEditingController(text: '07:30:00');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Schedule Meeting'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Set meeting time with your current bid'),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  hintText: 'Enter meeting time (HH:mm:ss)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
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
                    Uri.parse('$baseUrl/procced-meeting-with-bid.php?token=$token&user_id=$userId&post_id=${bid['post_id']}&customerbid_id=${bid['id']}&meeting_times=$meetingTime'),
                    headers: {
                      'token': token,
                      'Cookie': 'PHPSESSID=gbqbiugaqg3gco8kaespjf8lnp',
                    },
                  );

                  debugPrint('Proceed meeting with bid response: ${response.body}');
                  try {
                    final responseData = jsonDecode(response.body);
                    if (response.statusCode == 200 && responseData['status'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(responseData['data'] ?? 'Meeting scheduled successfully')),
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyMeetingsWidget(
                            baseUrl: baseUrl,
                            token: token,
                            userId: userId,
                            initialStatus: 'Meeting Request',
                            postId: bid['post_id'],
                            bidId: bid['id'],
                            bid: {
                              ...bid,
                              'meeting_time': meetingTime,
                              'meeting_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                            },
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to schedule meeting: ${responseData['data'] ?? 'Unknown error'}')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error parsing response: ${response.body}')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error scheduling meeting: $e')),
                  );
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _proceedMeetingWithoutBid(BuildContext context) async {
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
          Uri.parse('$baseUrl/procced-meeting-without-bid.php?token=$token&user_id=$userId&post_id=${bid['post_id']}&meeting_date=$meetingDate'),
          headers: {
            'token': token,
            'Cookie': 'PHPSESSID=gbqbiugaqg3gco8kaespjf8lnp',
          },
        );

        debugPrint('Proceed meeting without bid response: ${response.body}');
        try {
          final responseData = jsonDecode(response.body);
          if (response.statusCode == 200 && responseData['status'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['data'] ?? 'Meeting scheduled successfully')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MyMeetingsWidget(
                  baseUrl: baseUrl,
                  token: token,
                  userId: userId,
                  initialStatus: 'Meeting Request',
                  postId: bid['post_id'],
                  bid: {
                    ...bid,
                    'meeting_date': meetingDate,
                    'meeting_time': 'N/A',
                  },
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to schedule meeting: ${responseData['data'] ?? 'Unknown error'}')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error parsing response: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling meeting: $e')),
        );
      }
    }
  }

  Future<void> _scheduleMeeting(BuildContext context) async {
    DateTime selectedDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meeting scheduled for ${DateFormat('yyyy-MM-dd').format(picked)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bidPrice = double.tryParse(bid['bidPrice'] ?? '0') ?? 0;
    final double targetPrice = double.tryParse(bid['targetPrice'] ?? '0') ?? 0;
    final bool isLowBid = bidPrice < targetPrice;

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
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: bid['carImage'] ?? '',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
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
                        errorWidget: (context, url, error) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.car_rental,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  bid['title'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLowBid ? Colors.orange[50] : Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isLowBid ? 'Low Bid' : 'High Bid',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: isLowBid ? Colors.orange[700] : Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.directions_car, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                'Model: ${bid['appId'] ?? 'N/A'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${bid['location'] ?? 'N/A'} • ${bid['store'] ?? 'N/A'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                                    Text(
                                      'Target Price',
                                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                    ),
                                    Text(
                                      '₹${NumberFormat('#,##0').format(targetPrice)}',
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Bid',
                                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                    ),
                                    Text(
                                      '₹${NumberFormat('#,##0').format(bidPrice)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isLowBid ? Colors.orange[700] : Colors.green[700],
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
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.more_vert, size: 16),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) async {
                        if (value == 'increase_bid') {
                          await _increaseBid(context);
                        } else if (value == 'proceed_with_bid') {
                          await _proceedMeetingWithBid(context);
                        } else if (value == 'proceed_without_bid') {
                          await _proceedMeetingWithoutBid(context);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'increase_bid',
                          child: Row(
                            children: [
                              Icon(Icons.trending_up, size: 16, color: AppTheme.primaryColor),
                              SizedBox(width: 8),
                              Text('Increase Bid'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'proceed_with_bid',
                          child: Row(
                            children: [
                              Icon(Icons.schedule, size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Meeting with Bid'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'proceed_without_bid',
                          child: Row(
                            children: [
                              Icon(Icons.event, size: 16, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Meeting without Bid'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              'Bid: ${bid['bidDate'] ?? 'N/A'}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              'Expires: ${bid['expirationDate'] ?? 'N/A'}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _scheduleMeeting(context),
                    icon: const Icon(Icons.event, size: 18),
                    label: const Text('Schedule Meeting'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Meeting location can be requested 24 hrs before meeting time only.',
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

class MyBidItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const MyBidItem({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}