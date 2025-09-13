import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';


import 'package:lelamonline_flutter/feature/chat/model/chat_room_model.dart';

class ChatRoomCreationService {
  Future<ChatRoom?> createChatRoom({
    required String userId,
    required String listenerId,
  }) async {
    final url = Uri.parse(
      '${baseUrl}/chat-room-list.php?token=${token}&user_id=$userId',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
          final chatRooms = (jsonResponse['data'] as List)
              .map((json) => ChatRoom.fromJson(json))
              .toList();
          // Find chat room with matching user_id_to (listenerId)
          return chatRooms.firstWhere(
            (room) => room.userIdTo == listenerId,
            orElse: () => ChatRoom(
              id: '0',
              userIdFrom: userId,
              userIdTo: listenerId,
              createdOn: DateTime.now().toString(),
              updatedOn: DateTime.now().toString(),
          
            ),
          );
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to fetch chat rooms');
        }
      } else {
        throw Exception('Failed to fetch chat rooms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating chat room: $e');
    }
  }
}