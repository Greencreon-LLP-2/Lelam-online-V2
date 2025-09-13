import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:lelamonline_flutter/core/api/api_constant.dart' ;

class MessageSendingService {
  Future<bool> sendMessage({
    required String userId,
    required String listenerId,
    required String chatRoomId,
    required String message,
  }) async {
    final url = Uri.parse(
      '${baseUrl}/chat-message-send.php?token=${token}&user_id=$userId&chat_room_id=$chatRoomId&message=${Uri.encodeComponent(message)}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }
}