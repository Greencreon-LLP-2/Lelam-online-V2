import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:lelamonline_flutter/feature/chat/model/chat_message_model.dart';
import 'package:lelamonline_flutter/feature/chat/model/chat_room_model.dart';

class ChatRoomService {
  Future<ChatRoom?> createChatRoom({
    required String userIdFrom,
    required String userIdTo,
  }) async {
    final url = Uri.parse(
      '${baseUrl}/chat-room-create.php?token=${token}&user_id_from=$userIdFrom&user_id_to=$userIdTo',
    );
    try {
      final response = await http.get(
        url,
        headers: {'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76'},
      );
      debugPrint('ChatRoomService: Creating chat room: $url');
      debugPrint('ChatRoomService: Response status: ${response.statusCode}');
      debugPrint('ChatRoomService: Raw response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
          final room = jsonResponse['data'];
          debugPrint('ChatRoomService: Created room: ${room['chat_room_id']}');
          return ChatRoom(
            id: room['chat_room_id'].toString(),
            userIdFrom: userIdFrom,
            userIdTo: userIdTo,
            createdOn: DateTime.now().toString(),
            updatedOn: DateTime.now().toString(),
          );
        }
        debugPrint('ChatRoomService: Failed to create chat room');
        return null;
      } else {
        throw Exception('Failed to create chat room: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ChatRoomService: Error creating chat room: $e');
      throw Exception('Error creating chat room: $e');
    }
  }

  Future<ChatRoom?> getChatRoom({
    required String userId,
    required String listenerId,
  }) async {
    final url = Uri.parse(
      '${baseUrl}/chat-room-list.php?token=${token}&user_id=$userId',
    );
    try {
      final response = await http.get(
        url,
        headers: {'Cookie': 'PHPSESSID=a99k454ctjeu4sp52ie9dgua76'},
      );
      debugPrint('ChatRoomService: Fetching chat rooms: $url');
      debugPrint('ChatRoomService: Response status: ${response.statusCode}');
      debugPrint('ChatRoomService: Raw response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true && jsonResponse['data'] is List) {
          final rooms = jsonResponse['data'] as List;
          final room = rooms.firstWhere(
            (r) =>
                (r['user_id_from'] == userId && r['user_id_to'] == listenerId) ||
                (r['user_id_from'] == listenerId && r['user_id_to'] == userId),
            orElse: () => null,
          );
          if (room != null) {
            debugPrint('ChatRoomService: Found room: ${room['chat_room_id']}');
            return ChatRoom(
              id: room['chat_room_id'].toString(),
              userIdFrom: room['user_id_from'].toString(),
              userIdTo: room['user_id_to'].toString(),
              createdOn: room['created_on'],
              updatedOn: room['updated_on'],
            );
          }
        }
        debugPrint('ChatRoomService: No matching room found');
        return null;
      } else {
        throw Exception('Failed to fetch chat rooms: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ChatRoomService: Error: $e');
      throw Exception('Error fetching chat room: $e');
    }
  }
}

class MessageService {
  Future<List<ChatMessage>> fetchMessages(String chatRoomId) async {
    final url = Uri.parse(
      '${baseUrl}/chat-message-list.php?token=${token}&chat_room_id=$chatRoomId',
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
              .map((item) => ChatMessage(
                    id: item['message_id']?.toString() ?? '',
                    chatRoomId: item['chat_room_id']?.toString() ?? '',
                    userIdFrom: item['user_id_from']?.toString() ?? '',
                    userIdTo: item['user_id_to']?.toString() ?? '',
                    message: item['message']?.toString() ?? '',
                    chatFrom: item['chat_from']?.toString() ?? '',
                    status: item['status']?.toString() ?? '',
                    createdOn: item['created_on']?.toString() ?? '',
                    updatedOn: item['updated_on']?.toString() ?? '',
                  ))
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
    final url = Uri.parse('${baseUrl}/chat-message-send.php?token=${token}&user_id=$userId&chat_room_id=$chatRoomId&message=$message');
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
      '${baseUrl}/chat-message-delete.php?token=${token}&message_id=$messageId&user_id=$userId',
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
          debugPrint('MessageService: Delete failed: ${jsonResponse['message']}');
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
      '${baseUrl}/chat-message-delete.php?token=${token}&chat_room_id=$chatRoomId&user_id=$userId',
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
  final String userId;

  const ChatPage({
    super.key,
    required this.listenerId,
    required this.listenerName,
    required this.listenerImage,
    required this.userId,
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
    final messageController = useTextEditingController();
    final messages = useState<List<ChatMessage>>([]);
    final chatRoom = useState<ChatRoom?>(null);
    final isLoading = useState(true);
    final isSending = useState(false);
    final scrollController = useScrollController();

    Future<void> scrollToBottom() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }

    Future<void> deleteMessage(String messageId) async {
      try {
        final messageService = MessageService();
        final success = await messageService.deleteMessage(
          messageId: messageId,
          userId: userId,
        );
        if (success) {
          messages.value = messages.value.where((m) => m.id != messageId).toList();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Message deleted'),
                  ],
                ),
                backgroundColor: Colors.green[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Failed to delete message');
        }
      } catch (e) {
        debugPrint('ChatPage: Error deleting message: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Error deleting message: $e')),
                ],
              ),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    Future<void> deleteChat() async {
      if (chatRoom.value == null) return;
      try {
        final messageService = MessageService();
        final success = await messageService.deleteChat(
          chatRoomId: chatRoom.value!.id,
          userId: userId,
        );
        if (success) {
          messages.value = [];
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Chat deleted'),
                  ],
                ),
                backgroundColor: Colors.green[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception('Failed to delete chat');
        }
      } catch (e) {
        debugPrint('ChatPage: Error deleting chat: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Error deleting chat: $e')),
                ],
              ),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    Future<void> _showDeleteConfirmation(String messageId) async {
      if (!context.mounted) return;
      final bool? shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('Delete Message'),
            ],
          ),
          content: const Text('This message will be permanently deleted. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('Delete Chat'),
            ],
          ),
          content: const Text('All messages in this chat will be permanently deleted. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      final chatRoomService = ChatRoomService();
      final messageService = MessageService();
      Timer? timer;

      Future<void> initializeChat() async {
        debugPrint('ChatPage: Initializing chat with userId=$userId, listenerId=$listenerId');
        try {
          ChatRoom? room = await chatRoomService.getChatRoom(
            userId: userId,
            listenerId: listenerId,
          );

          if (room == null) {
            room = await chatRoomService.createChatRoom(
              userIdFrom: userId,
              userIdTo: listenerId,
            );
            if (room == null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Failed to create or find chat room'),
                      ],
                    ),
                    backgroundColor: Colors.red[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              isLoading.value = false;
              return;
            }
          }
          chatRoom.value = room;

          final fetchedMessages = await messageService.fetchMessages(room.id);
          messages.value = fetchedMessages;
          await scrollToBottom();

          timer = Timer.periodic(const Duration(seconds: 2), (_) async {
            if (chatRoom.value != null) {
              try {
                final newMessages = await messageService.fetchMessages(chatRoom.value!.id);
                final oldLen = messages.value.length;
                messages.value = newMessages;
                if (newMessages.length != oldLen) {
                  await scrollToBottom();
                }
              } catch (e) {
                debugPrint('ChatPage: Error fetching messages: $e');
              }
            }
          });
        } catch (e) {
          debugPrint('ChatPage: Error initializing chat: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Error loading chat: $e')),
                  ],
                ),
                backgroundColor: Colors.red[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } finally {
          isLoading.value = false;
        }
      }

      initializeChat();
      return () => timer?.cancel();
    }, []);

    Future<void> sendMessage() async {
      final messageText = messageController.text.trim();
      if (messageText.isEmpty || chatRoom.value == null) {
        if (messageText.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Please enter a message'),
                  ],
                ),
                backgroundColor: Colors.orange[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else if (chatRoom.value == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Cannot send message: No chat room available'),
                  ],
                ),
                backgroundColor: Colors.red[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
        return;
      }

      isSending.value = true;
      try {
        final messageService = MessageService();
        final success = await messageService.sendMessage(
          userId: userId,
          chatRoomId: chatRoom.value!.id,
          message: messageText,
        );
        debugPrint('ChatPage: SendMessage Success: $success');
        if (success) {
          messages.value = [
            ...messages.value,
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              chatRoomId: chatRoom.value!.id,
              userIdFrom: userId,
              userIdTo: listenerId,
              message: messageText,
              chatFrom: '0',
              status: '1',
              createdOn: DateTime.now().toString(),
              updatedOn: DateTime.now().toString(),
            ),
          ];
          messageController.clear();
          await scrollToBottom();
        } else {
          throw Exception('API returned false status');
        }
      } catch (e) {
        debugPrint('ChatPage: SendMessage Exception: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Failed to send message: $e')),
                ],
              ),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } finally {
        isSending.value = false;
      }
    }

    return CustomSafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                radius: 20,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listenerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red[600],
                  size: 20,
                ),
              ),
              onPressed: _showDeleteChatConfirmation,
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey[200],
            ),
          ),
        ),
        body: isLoading.value
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading chat...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : chatRoom.value == null
                ? Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chat Unavailable',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please contact the seller to start a chat.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: messages.value.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.forum_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No messages yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Start the conversation with a message',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: messages.value.length,
                                itemBuilder: (context, index) {
                                  final message = messages.value[index];
                                  final isMe = message.userIdFrom == userId;
                                  final showTime = _formatTime(message.createdOn);
                                  
                                  return GestureDetector(
                                    onLongPress: isMe ? () => _showDeleteConfirmation(message.id) : null,
                                    child: Align(
                                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        margin: EdgeInsets.only(
                                          top: 4,
                                          bottom: 4,
                                          left: isMe ? 48 : 0,
                                          right: isMe ? 0 : 48,
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isMe 
                                              ? CrossAxisAlignment.end 
                                              : CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isMe 
                                                    ? Theme.of(context).primaryColor
                                                    : Colors.white,
                                                borderRadius: BorderRadius.only(
                                                  topLeft: const Radius.circular(16),
                                                  topRight: const Radius.circular(16),
                                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.05),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                message.message,
                                                style: TextStyle(
                                                  color: isMe ? Colors.white : Colors.black87,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            if (showTime.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  showTime,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[500],
                                                  ),
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: chatRoom.value == null 
                                        ? Colors.grey[300]! 
                                        : Colors.grey[200]!,
                                  ),
                                ),
                                child: TextField(
                                  controller: messageController,
                                  decoration: InputDecoration(
                                    hintText: chatRoom.value == null
                                        ? 'Chat unavailable'
                                        : 'Type a message...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 15,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  enabled: chatRoom.value != null,
                                  maxLines: 4,
                                  minLines: 1,
                                  style: const TextStyle(fontSize: 15),
                                  onSubmitted: (value) {
                                    if (chatRoom.value != null && !isSending.value) {
                                      sendMessage();
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: (chatRoom.value == null || isSending.value)
                                    ? Colors.grey[300]
                                    : Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: (chatRoom.value == null || isSending.value) 
                                      ? null 
                                      : sendMessage,
                                  child: Center(
                                    child: isSending.value
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.grey[600]!,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.send_rounded,
                                            color: (chatRoom.value == null || isSending.value)
                                                ? Colors.grey[600]
                                                : Colors.white,
                                            size: 20,
                                          ),
                                  ),
                                ),
                              ),
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