import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final data = await createChatRoom(context, userIdTo);
  if (data.isNotEmpty) {
    final chatRoomId = data['chat_room_id'];
    final message = data['message'];
    
    // Show SnackBar before dismissing dialog
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    // Close dialog and trigger callback if chat room created
    if (chatRoomId != null) {
      Navigator.of(context).pop(); // Move pop after SnackBar
      onSuccess(); // Call the provided callback (onChatWithSupport or onChatWithSeller)
    }
  }
}

@override
Widget build(BuildContext context) {
  return AlertDialog(
    backgroundColor: Colors.white,
    title: const Text(
      'Choose Chat Option',
      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
    ),
    content: const Text('Who would you like to chat with?'),
    actions: [
      ElevatedButton(
        onPressed: () {
          handleChat(context, 5, 'support', onChatWithSupport);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
        ),
        child: const Text('Chat with Admin'),
      ),
      ElevatedButton(
        onPressed: () {
          handleChat(context, 5, 'seller', onChatWithSeller);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
        ),
        child: const Text('Chat with Seller'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
    ],
  );
}
}