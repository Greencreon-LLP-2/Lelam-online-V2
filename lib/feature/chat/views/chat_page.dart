import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:lelamonline_flutter/feature/chat/model/chat_message_model.dart';
import 'package:lelamonline_flutter/feature/chat/model/chat_room_model.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:provider/provider.dart';

class ChatRoomService {
  Future<ChatRoom> getOrCreateChatRoom({
    required String userId,
    required String listenerId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/chat-room-list.php?token=$token&user_id=$userId',
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
          final room = rooms.firstWhere(
            (r) =>
                (r['user_id_from'].toString() == userId &&
                    r['user_id_to'].toString() == listenerId) ||
                (r['user_id_from'].toString() == listenerId &&
                    r['user_id_to'].toString() == userId),
            orElse: () => null,
          );
          if (room != null) {
            debugPrint(
              'ChatRoomService: Found existing room: ${room['chat_room_id']}',
            );
            return ChatRoom(
              id: room['chat_room_id'].toString(), // Convert to string
              userIdFrom: room['user_id_from'].toString(), // Convert to string
              userIdTo: room['user_id_to'].toString(), // Convert to string
              createdOn: room['created_on']?.toString() ?? '',
              updatedOn: room['updated_on']?.toString() ?? '',
            );
          }
        }
      } else {
        throw Exception('Failed to fetch chat rooms: ${response.statusCode}');
      }

      debugPrint('ChatRoomService: No room found, creating new room');
      final createUrl = Uri.parse(
        '$baseUrl/chat-room-create.php?token=$token&user_id_from=$userId&user_id_to=$listenerId',
      );
      final createResponse = await http.get(createUrl);
      debugPrint('ChatRoomService: Creating chat room: $createUrl');
      debugPrint(
        'ChatRoomService: Create response status: ${createResponse.statusCode}',
      );
      debugPrint(
        'ChatRoomService: Create response body: ${createResponse.body}',
      );

      if (createResponse.statusCode == 200) {
        final createJson = jsonDecode(createResponse.body);
        if (createJson['status'] == true && createJson['data'] is Map) {
          final newRoom = createJson['data'];
          debugPrint(
            'ChatRoomService: Created room: ${newRoom['chat_room_id']}',
          );
          return ChatRoom(
            id: newRoom['chat_room_id'].toString(), // Convert to string
            userIdFrom: newRoom['user_id_from']?.toString() ?? userId,
            userIdTo: newRoom['user_id_to']?.toString() ?? listenerId,
            createdOn:
                newRoom['created_on']?.toString() ??
                DateTime.now().toIso8601String(),
            updatedOn:
                newRoom['updated_on']?.toString() ??
                DateTime.now().toIso8601String(),
          );
        } else {
          throw Exception(
            'Failed to create chat room: ${createJson['message']}',
          );
        }
      } else {
        throw Exception(
          'Failed to create chat room: ${createResponse.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('ChatRoomService: Error: $e');
      throw Exception('Error fetching/creating chat room: $e');
    }
  }
}

class MessageService {
  Future<List<ChatMessage>> fetchMessages(String chatRoomId) async {
    final url = Uri.parse(
      '$baseUrl/chat-message-list.php?token=$token&chat_room_id=$chatRoomId',
    );
    try {
      final response = await http.get(
        url,
        headers: {'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76'},
      );
      debugPrint('MessageService: Fetching messages: $url');
      debugPrint('MessageService: Response status: ${response.statusCode}');
      debugPrint('MessageService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true && jsonResponse['data'] is List) {
          return (jsonResponse['data'] as List)
              .map(
                (item) => ChatMessage(
                  id: item['message_id']?.toString() ?? '',
                  chatRoomId: item['chat_room_id']?.toString() ?? '',
                  userIdFrom: item['user_id_from']?.toString() ?? '',
                  userIdTo: item['user_id_to']?.toString() ?? '',
                  message: item['message']?.toString() ?? '',
                  chatFrom: item['chat_from']?.toString() ?? '',
                  status: item['status']?.toString() ?? '',
                  createdOn: item['created_on']?.toString() ?? '',
                  updatedOn: item['updated_on']?.toString() ?? '',
                ),
              )
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('MessageService: Error fetching messages: $e');
      return [];
    }
  }

  Future<bool> sendMessage({
    required String userId,
    required String chatRoomId,
    required String message,
  }) async {
    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse(
      '$baseUrl/chat-message-send.php?token=$token&user_id=$userId&chat_room_id=$chatRoomId&message=$encodedMessage',
    );
    try {
      final response = await http.get(
        url,
        headers: {'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76'},
      );
      debugPrint('MessageService: Sending message: $url');
      debugPrint('MessageService: Response status: ${response.statusCode}');
      debugPrint('MessageService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('MessageService: Error sending message: $e');
      throw Exception('Error sending message: $e');
    }
  }

  Future<bool> deleteMessage({
    required String messageId,
    required String userId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/chat-message-delete.php?token=$token&message_id=$messageId&user_id=$userId',
    );
    try {
      final response = await http.get(
        url,
        headers: {'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76'},
      );
      debugPrint('MessageService: Deleting message: $url');
      debugPrint('MessageService: Response status: ${response.statusCode}');
      debugPrint('MessageService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true) {
          return true;
        } else {
          debugPrint(
            'MessageService: Delete failed: ${jsonResponse['message']}',
          );
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('MessageService: Error deleting message: $e');
      throw Exception('Error deleting message: $e');
    }
  }

  Future<bool> deleteChat({
    required String chatRoomId,
    required String userId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/chat-message-delete.php?token=$token&chat_room_id=$chatRoomId&user_id=$userId',
    );
    try {
      final response = await http.get(
        url,
        headers: {'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76'},
      );
      debugPrint('MessageService: Deleting chat: $url');
      debugPrint('MessageService: Response status: ${response.statusCode}');
      debugPrint('MessageService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('MessageService: Error deleting chat: $e');
      throw Exception('Error deleting chat: $e');
    }
  }
}

class ChatPage extends HookWidget {
  final String listenerId;
  final String listenerName;
  final String listenerImage;
  final String? initialMessage;

  const ChatPage({
    super.key,
    required this.listenerId,
    required this.listenerName,
    required this.listenerImage,
    this.initialMessage,
  });

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(date.year, date.month, date.day);

      if (messageDate == today) {
        return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      } else {
        return "${date.day}/${date.month}";
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<LoggedUserProvider>(
      context,
      listen: false,
    );
    final userId = userProvider.userId ?? '';
    final userName = userProvider.userData?.name ?? 'User';

    final messageController = useTextEditingController();
    final messages = useState<List<ChatMessage>>([]);
    final chatRoom = useState<ChatRoom?>(null);
    final isLoading = useState(true);
    final isSending = useState(false);
    final scrollController = useScrollController();
    final hasSentInitialMessage = useState(false);

    Future<void> scrollToBottom() async {
      if (scrollController.hasClients) {
        await Future.delayed(const Duration(milliseconds: 100));
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }

    Future<void> fetchMessages(String chatRoomId) async {
      final messageService = MessageService();
      final fetchedMessages = await messageService.fetchMessages(chatRoomId);
      messages.value = fetchedMessages;
      await scrollToBottom();
    }

    Future<void> sendInitialMessage(String chatRoomId) async {
      if (initialMessage != null &&
          !hasSentInitialMessage.value &&
          userId.isNotEmpty) {
        final messageService = MessageService();
        final success = await messageService.sendMessage(
          userId: userId,
          chatRoomId: chatRoomId,
          message: initialMessage!,
        );
        if (success) {
          hasSentInitialMessage.value = true;
          await fetchMessages(chatRoomId);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to send initial message')),
            );
          }
        }
      }
    }

    Future<void> initializeChatRoom() async {
      if (userId.isEmpty) {
        isLoading.value = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User ID is missing. Please log in again.'),
            ),
          );
        }
        return;
      }

      try {
        final chatRoomService = ChatRoomService();
        final room = await chatRoomService.getOrCreateChatRoom(
          userId: userId, // Buyer
          listenerId: listenerId, // Seller
        );
        chatRoom.value = room;
        await fetchMessages(room.id);
        if (initialMessage != null && !hasSentInitialMessage.value) {
          await sendInitialMessage(room.id);
        }
      } catch (e) {
        debugPrint('ChatPage: Error initializing chat room: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error initializing chat: $e')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> sendMessage() async {
      if (messageController.text.trim().isEmpty ||
          chatRoom.value == null ||
          userId.isEmpty) {
        return;
      }

      isSending.value = true;
      try {
        final messageService = MessageService();
        final success = await messageService.sendMessage(
          userId: userId,
          chatRoomId: chatRoom.value!.id,
          message: messageController.text.trim(),
        );
        if (success) {
          messageController.clear();
          await fetchMessages(chatRoom.value!.id);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to send message')),
            );
          }
        }
      } catch (e) {
        debugPrint('ChatPage: Error sending message: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
        }
      } finally {
        isSending.value = false;
      }
    }

    Future<void> deleteMessage(String messageId) async {
      if (userId.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User ID is missing. Please log in again.'),
            ),
          );
        }
        return;
      }

      try {
        final messageService = MessageService();
        final success = await messageService.deleteMessage(
          messageId: messageId,
          userId: userId,
        );
        if (success) {
          messages.value =
              messages.value.where((m) => m.id != messageId).toList();
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Message deleted')));
          }
        } else {
          throw Exception('Failed to delete message');
        }
      } catch (e) {
        debugPrint('ChatPage: Error deleting message: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting message: $e')));
        }
      }
    }

    Future<void> deleteChat() async {
      if (chatRoom.value == null || userId.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User ID or chat room is missing.')),
          );
        }
        return;
      }

      try {
        final messageService = MessageService();
        final success = await messageService.deleteChat(
          chatRoomId: chatRoom.value!.id,
          userId: userId,
        );
        if (success) {
          messages.value = [];
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Chat deleted')));
            Navigator.pop(context);
          }
        } else {
          throw Exception('Failed to delete chat');
        }
      } catch (e) {
        debugPrint('ChatPage: Error deleting chat: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting chat: $e')));
        }
      }
    }

    Future<void> _showDeleteConfirmation(String messageId) async {
      if (!context.mounted) return;
      final bool? shouldDelete = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text('Delete Message'),
                ],
              ),
              content: const Text(
                'This message will be permanently deleted. This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
      );

      if (shouldDelete == true) {
        await deleteMessage(messageId);
      }
    }

    Future<void> _showDeleteChatConfirmation() async {
      if (!context.mounted || chatRoom.value == null) return;
      final bool? shouldDelete = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text('Delete Chat'),
                ],
              ),
              content: const Text(
                'This chat will be permanently deleted. This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
      );

      if (shouldDelete == true) {
        await deleteChat();
      }
    }

    useEffect(() {
      initializeChatRoom();
      return () {};
    }, const []);

    return CustomSafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    listenerImage.isNotEmpty
                        ? NetworkImage(listenerImage)
                        : const AssetImage('assets/images/default_avatar.png')
                            as ImageProvider,
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  listenerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteChatConfirmation,
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'lelam online is a default member in all chats. Please don’t ask or share phone numbers before fix meeting.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : messages.value.isEmpty
                      ? const Center(child: Text('No messages yet'))
                      : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: messages.value.length,
                        itemBuilder: (context, index) {
                          final message = messages.value[index];
                          final isMe = message.userIdFrom == userId;
                          return GestureDetector(
                            onLongPress:
                                isMe
                                    ? () => _showDeleteConfirmation(message.id)
                                    : null,
                            child: Align(
                              alignment:
                                  isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      isMe
                                          ? Colors.blue[100]
                                          : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      isMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.message,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(message.createdOn),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  isSending.value
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: sendMessage,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
