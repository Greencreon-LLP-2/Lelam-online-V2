import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart' as ApiConstant;
import 'dart:convert';
import 'package:lelamonline_flutter/feature/chat/model/chat_room_model.dart';

class ChatRoomService {
  Future<ChatRoom> getOrCreateChatRoom({
    required String userId,
    required String listenerId,
  }) async {
    // Fetch existing chat rooms
    final url = Uri.parse(
      '${ApiConstant.baseUrl}/chat-room-list.php?token=${ApiConstant.token}&user_id=$userId',
    );
    try {
      final response = await http.get(url);
      debugPrint('ChatRoomService: Fetching chat rooms: $url');
      debugPrint('ChatRoomService: Response status: ${response.statusCode}');
      debugPrint('ChatRoomService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true && jsonResponse['data'] is List) {
          final rooms = jsonResponse['data'] as List;
          // Check for rooms with user_id_from=userId and user_id_to=listenerId
          // Also check reverse direction (user_id_from=listenerId and user_id_to=userId)
          final room = rooms.firstWhere(
            (r) =>
                (r['user_id_from'] == userId && r['user_id_to'] == listenerId) ||
                (r['user_id_from'] == listenerId && r['user_id_to'] == userId),
            orElse: () => null,
          );
          if (room != null) {
            debugPrint('ChatRoomService: Found existing room: ${room['chat_room_id']}');
            return ChatRoom(
              id: room['chat_room_id'],
              userIdFrom: room['user_id_from'],
              userIdTo: room['user_id_to'],
              createdOn: room['created_on'],
              updatedOn: room['updated_on'],
            );
          }
        }
      } else {
        throw Exception('Failed to fetch chat rooms: ${response.statusCode}');
      }

      // No room found, create a new one
      debugPrint('ChatRoomService: No room found, creating new room');
      final createUrl = Uri.parse(
        '${ApiConstant.baseUrl}/chat-room-create.php?token=${ApiConstant.token}&user_id_from=$userId&user_id_to=$listenerId',
      );
      final createResponse = await http.get(createUrl);
      debugPrint('ChatRoomService: Creating chat room: $createUrl');
      debugPrint('ChatRoomService: Create response status: ${createResponse.statusCode}');
      debugPrint('ChatRoomService: Create response body: ${createResponse.body}');

      if (createResponse.statusCode == 200) {
        final createJson = jsonDecode(createResponse.body);
        if (createJson['status'] == true && createJson['data'] is Map) {
          final newRoom = createJson['data'];
          debugPrint('ChatRoomService: Created room: ${newRoom['chat_room_id']}');
          return ChatRoom(
            id: newRoom['chat_room_id'],
            userIdFrom: newRoom['user_id_from'],
            userIdTo: newRoom['user_id_to'],
            createdOn: newRoom['created_on'],
            updatedOn: newRoom['updated_on'],
          );
        } else {
          throw Exception('Failed to create chat room: ${createJson['message']}');
        }
      } else {
        throw Exception('Failed to create chat room: ${createResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('ChatRoomService: Error: $e');
      throw Exception('Error fetching/creating chat room: $e');
    }
  }
}