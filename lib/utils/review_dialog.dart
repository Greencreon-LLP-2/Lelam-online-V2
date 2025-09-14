import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'dart:convert';

import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:provider/provider.dart';

class ReviewDialog extends StatefulWidget {
  final String postId;

  const ReviewDialog({super.key, required this.postId});

  @override
  ReviewDialogState createState() => ReviewDialogState();
}

class ReviewDialogState extends State<ReviewDialog> {
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  late final LoggedUserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<bool> _submitReview() async {
    if (token.isEmpty || token.contains('?')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid authentication token. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final url = Uri.parse(
      '$addPostReview?token=$token&user_id=${_userProvider.userId}&post_id=${widget.postId}&rating=0&comment=${Uri.encodeComponent(_reviewController.text)}',
    );

    try {
      print('Submitting review to: $url');

      final response = await http.get(url);

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody['status'] == 'true') {
          return true;
        } else {
          print('API Error: ${decodedBody['data']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit review: ${decodedBody['data']}'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
      } else if (response.statusCode == 401) {
        print('HTTP Error: Unauthorized (401)');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unauthorized: Invalid or expired token. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      } else {
        print('HTTP Error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: HTTP ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      print('Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting review: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ask Your Question',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write your question here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), 
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (_reviewController.text.isNotEmpty) {
                    setState(() {
                      _isSubmitting = true;
                    });

                    await _submitReview(); 

                    setState(() {
                      _isSubmitting = false;
                    });

                    Navigator.of(context).pop();

                    if (await _submitReview()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Question submitted successfully.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please write a question before submitting.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}