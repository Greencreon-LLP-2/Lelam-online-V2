import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class MyBidsSellerWidget extends StatefulWidget {
  final String baseUrl;
  final String token;
  final String? userId;
  final String? postId;

  const MyBidsSellerWidget({
    super.key,
    this.baseUrl = 'https://lelamonline.com/admin/api/v1',
    this.token = '5cb2c9b569416b5db1604e0e12478ded',
    this.userId,
    this.postId,
  });

  @override
  State<MyBidsSellerWidget> createState() => _MyBidsSellerWidget();
}

class _MyBidsSellerWidget extends State<MyBidsSellerWidget> {
  String bidsText = '';
  String bidType = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBids();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[70],
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                      bidsText.isEmpty ? 'No bids found' : bidsText,
                      style: const TextStyle(color: Colors.grey),
                    ),
          ),
          // Positioned(
          //   top: 10,
          //   right: 10,
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //     decoration: BoxDecoration(
          //       color: AppTheme.primaryColor,
          //       borderRadius: BorderRadius.circular(4),
          //     ),
          //     child: Text(
          //       bidType.isEmpty ? '' : bidType,
          //       style: const TextStyle(
          //         color: Colors.white,
          //         fontSize: 12,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Future<void> _fetchBids() async {
    setState(() {
      isLoading = true;
      bidsText = '';
      bidType = '';
    });

    // Try fetching high bids first
    try {
      final highBidResponse = await http.get(
        Uri.parse(
          '${widget.baseUrl}/sell-post-high-bid.php?token=${widget.token}&post_id=${widget.postId}&user_id=${widget.userId ?? ''}',
        ),
      );

      if (highBidResponse.statusCode == 200) {
        final highBidData = jsonDecode(highBidResponse.body);
        if (highBidData['status'] == 'true' &&
            highBidData['data'] is List &&
            highBidData['data'].isNotEmpty) {
          setState(() {
            bidsText = highBidData['data'].join('\n');
            bidType = 'High Bid';
          });
          return;
        }
      }
    } catch (e) {
      // Continue to low bids if high bids fail
    }

    // Try fetching low bids if high bids are empty or fail
    try {
      final lowBidResponse = await http.get(
        Uri.parse(
          '${widget.baseUrl}/sell-post-low-bid.php?token=${widget.token}&post_id=${widget.postId}&user_id=${widget.userId ?? ''}',
        ),
      );

      if (lowBidResponse.statusCode == 200) {
        final lowBidData = jsonDecode(lowBidResponse.body);
        if (lowBidData['status'] == 'true' && lowBidData['data'] is List) {
          setState(() {
            bidsText = lowBidData['data'].join('\n');
            bidType = lowBidData['data'].isEmpty ? '' : 'Low Bid';
          });
        } else {
          setState(() {
            bidsText = 'No bids available';
            bidType = '';
          });
        }
      } else {
        setState(() {
          bidsText = 'Error fetching bids';
          bidType = '';
        });
      }
    } catch (e) {
      setState(() {
        bidsText = 'Error: $e';
        bidType = '';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
