import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class ChatOptionsDialog extends StatelessWidget {
  final VoidCallback onChatWithSupport;
  final VoidCallback onChatWithSeller;
  final String baseUrl;
  final String token;

  const ChatOptionsDialog({
    super.key,
    required this.onChatWithSupport,
    required this.onChatWithSeller,
    required this.baseUrl,
    required this.token,
  });

  Future<Map<String, dynamic>> createChatRoom(
      BuildContext context, int userIdTo) async {
    final url = Uri.parse(
        '$baseUrl/chat-room-create.php?token=$token&user_id_from=6&user_id_to=$userIdTo');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data'] ?? {};
      } else {
        throw Exception('Failed to create chat room: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      return {};
    }
  }

  void handleChat(BuildContext context, int userIdTo, String chatType, VoidCallback onSuccess) async {
    if (chatType == 'support') {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Call Support',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          content: const Text('Contact support at: +918089308048'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final Uri dialerUri = Uri(scheme: 'tel', path: '9626040738');
                if (await url_launcher.canLaunchUrl(dialerUri)) {
                  await url_launcher.launchUrl(dialerUri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch dialer')),
                  );
                }
                onChatWithSupport();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Call',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      final userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
      if (!userProvider.isLoggedIn) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Login Required',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            content: const Text('Please log in to chat with the seller.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pushNamed(RouteNames.loginPage);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Log In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
        return;
      }

      final data = await createChatRoom(context, userIdTo);
      if (data.isNotEmpty) {
        final chatRoomId = data['chat_room_id'];
        final message = data['message'];

        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }

        if (chatRoomId != null) {
          Navigator.of(context).pop();
          onSuccess();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        '',
        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
      ),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                handleChat(context, 5, 'support', onChatWithSupport);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Call Sales Expert',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                handleChat(context, 5, 'seller', onChatWithSeller);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Chat with Seller',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8.0),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}