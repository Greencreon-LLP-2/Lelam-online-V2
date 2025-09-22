import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart' as ApiConstant;
import 'dart:convert';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/utils/login_dialog.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';

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
  final _storage = const FlutterSecureStorage();
  String? userId;
  final String _token = ApiConstant.token; // Use hardcoded token from ApiConstant

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserId();
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    try {
      String? providerUserId = _userProvider.userData?.userId;
      String? storageUserId = await _storage.read(key: 'userId');

      if (providerUserId != null && providerUserId.isNotEmpty && providerUserId != 'Unknown') {
        setState(() {
          userId = providerUserId;
        });
        await _storage.write(key: 'userId', value: providerUserId);
        debugPrint('Loaded userId from provider: $userId');
      } else if (storageUserId != null && storageUserId.isNotEmpty && storageUserId != 'Unknown') {
        setState(() {
          userId = storageUserId;
        });
        debugPrint('Loaded userId from storage: $userId');
      } else {
        setState(() {
          userId = null;
        });
        debugPrint('No valid userId found');
      }
    } catch (e) {
      debugPrint('Error loading userId: $e');
      setState(() {
        userId = null;
      });
    }
  }

  // Hide the keyboard programmatically
  void _hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  // Clean response to remove PHP notices/warnings before JSON parsing
  String _cleanResponse(String responseBody) {
    // Remove any content before the first '{'
    final jsonStartIndex = responseBody.indexOf('{');
    if (jsonStartIndex != -1) {
      return responseBody.substring(jsonStartIndex);
    }
    return responseBody; // Return as-is if no JSON found
  }

  Future<bool> _submitReview() async {
    if (userId == null || userId == 'Unknown') {
      if (mounted) {
        _showLoginPromptDialog(context, 'ask a question');
      }
      return false;
    }

    final url = Uri.parse(
      '$addPostReview?token=$_token&user_id=$userId&post_id=${widget.postId}&rateing=4&comment=${Uri.encodeComponent(_reviewController.text)}',
    );
    final headers = {
      'token': _token,
      'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76',
    };

    int maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        debugPrint('Attempt ${attempt + 1}: Submitting review to: $url');
        debugPrint('Headers: $headers');

        final response = await http.get(url, headers: headers);
        debugPrint('API Response Status: ${response.statusCode}');
        debugPrint('API Response Body: ${response.body}');

        if (response.statusCode == 200) {
          // Clean the response to handle PHP notices
          final cleanedResponse = _cleanResponse(response.body);
          final decodedBody = jsonDecode(cleanedResponse);
          final bool isSuccess = decodedBody['status'] == true || decodedBody['status'] == 'true';
          if (isSuccess && decodedBody['code'] == 0) {
            return true;
          } else {
            debugPrint('API Error: ${decodedBody['data']}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to submit review: ${decodedBody['data']}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          }
        } else if (response.statusCode == 401) {
          debugPrint('HTTP Error: Unauthorized (401)');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unauthorized: Invalid or expired token. Please log in again.'),
                backgroundColor: Colors.red,
              ),
            );
            context.pushNamed(RouteNames.loginPage);
          }
          return false;
        } else {
          debugPrint('HTTP Error: ${response.statusCode}');
          attempt++;
          if (attempt == maxRetries) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to submit review after $maxRetries attempts: HTTP ${response.statusCode}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          }
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      } catch (e) {
        debugPrint('Error submitting review: $e');
        attempt++;
        if (attempt == maxRetries) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error submitting review after $maxRetries attempts: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return false;
  }

 void _showLoginPromptDialog(BuildContext context, String action) {
  debugPrint('Showing login prompt for action: $action, userId: $userId');
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return LoginDialog(
        onSuccess: () async {
          // Reload user ID after login
          await _loadUserId();
          // Re-show the ReviewDialog to allow the user to ask a question
          if (mounted) {
            Navigator.of(dialogContext).pop(); // Close login dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => ReviewDialog(postId: widget.postId),
            );
          }
        },
      );
    },
  );
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
              autofillHints: null,
              decoration: InputDecoration(
                hintText: 'Write your question here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            if (_isSubmitting)
              const Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Center(child: CircularProgressIndicator()),
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

                    debugPrint('Before hiding keyboard: mounted=$mounted');
                    _hideKeyboard(context);
                    debugPrint('After hiding keyboard: mounted=$mounted');
                    await Future.delayed(const Duration(milliseconds: 300));
                    debugPrint('After delay: mounted=$mounted');

                    final success = await _submitReview();

                    if (mounted) {
                      setState(() {
                        _isSubmitting = false;
                      });

                      Navigator.of(context).pop();

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Question submitted successfully.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please write a question before submitting.'),
                        backgroundColor: Colors.red,
                      ),
                    );
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