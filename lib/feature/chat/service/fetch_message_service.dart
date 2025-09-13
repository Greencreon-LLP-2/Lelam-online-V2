import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart' ;
import 'package:lelamonline_flutter/feature/chat/model/chat_message_model.dart';

class FetchMessagesService {
  Future<List<ChatMessage>> fetchMessages(String chatRoomId) async {
    final url = Uri.parse(
      '${baseUrl}/chat-message-list.php?token=${token}&chat_room_id=$chatRoomId',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] != null) {
          return (jsonResponse['data'] as List)
              .map((json) => ChatMessage.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  Future<bool> deleteChat({required String messageId}) async {
    final url = Uri.parse(
      '${baseUrl}/chat-message-delete.php?token=${token}&message_id=$messageId&user_id=6',
    );

    try {
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}