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
  String? selectedBidType = 'Low Bids';
  String bidsText = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[70],
      body: Column(
        children: [
          Container(
            color: Colors.white,
            //padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedBidType = 'Low Bids';
                      });
                      _fetchBids('');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedBidType == 'Low Bids' ? AppTheme.primaryColor : null,
                    ),
                    child: Text('Low Bids'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedBidType = 'High Bids';
                      });
                      _fetchBids('');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedBidType == 'High Bids' ? AppTheme.primaryColor : null,
                    ),
                    child: Text('High Bids'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Text(bidsText.isEmpty ? 'No bids found' : bidsText,style: TextStyle(color: Colors.red),),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchBids(String postId) async {
    setState(() {
      isLoading = true;
      bidsText = '';
    });

    String apiEndpoint = selectedBidType == 'Low Bids' 
        ? 'sell-post-low-bid.php' 
        : 'sell-post-high-bid.php';

    try {
      final response = await http.get(
    Uri.parse('${widget.baseUrl}/$apiEndpoint?token=${widget.token}&post_id=${widget.postId}&user_id=${widget.userId ?? ''}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'true' && data['data'] is List) {
          setState(() {
            bidsText = data['data'].join('\n');
          });
        } else {
          setState(() {
            bidsText = 'No bids available';
          });
        }
      } else {
        setState(() {
          bidsText = 'Error fetching bids';
        });
      }
    } catch (e) {
      setState(() {
        bidsText = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}