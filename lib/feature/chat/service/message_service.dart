import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:lelamonline_flutter/core/api/api_constant.dart' as ApiSecrets;
import 'package:lelamonline_flutter/feature/chat/model/chat_message_model.dart';

class MessageService {
  Future<List<ChatMessage>> fetchMessages(String chatRoomId) async {
    final url = Uri.parse(
      '${ApiSecrets.baseUrl}/chat-message-list.php?token=${ApiSecrets.token}&chat_room_id=$chatRoomId',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] != null) {
          return (jsonResponse['data'] as List)
              .map((json) => ChatMessage.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  Future<bool> sendMessage({
    required String userId,
    required String chatRoomId,
    required String message,
  }) async {
    final url = Uri.parse(
      '${ApiSecrets.baseUrl}/chat-message-send.php?token=${ApiSecrets.token}&user_id=$userId&chat_room_id=$chatRoomId&message=${Uri.encodeComponent(message)}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  Future<bool> deleteMessage({required String messageId, required String userId}) async {
    final url = Uri.parse(
      '${ApiSecrets.baseUrl}/chat-message-delete.php?token=${ApiSecrets.token}&message_id=$messageId&user_id=$userId',
    );

    try {
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}