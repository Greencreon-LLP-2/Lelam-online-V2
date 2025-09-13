import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:lelamonline_flutter/feature/chat/model/chat_message_model.dart';
import 'package:lelamonline_flutter/feature/chat/model/chat_room_model.dart';
import 'package:lelamonline_flutter/feature/chat/views/widget/chat_dialog.dart';



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
                  const SnackBar(
                    content: Text('Failed to create or find chat room.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
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
                content: Text('Error loading chat: $e'),
                backgroundColor: Colors.red,
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
              const SnackBar(
                content: Text('Please enter a message'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else if (chatRoom.value == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot send message: No chat room available'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
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
              content: Text('Failed to send message: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } finally {
        isSending.value = false;
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
              const SnackBar(
                content: Text('Message deleted successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
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
              content: Text('Error deleting message: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
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
              const SnackBar(
                content: Text('Chat deleted successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          if (context.mounted) {
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
              content: Text('Error deleting chat: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }

    return CustomSafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              // CircleAvatar(
              //   backgroundImage: listenerImage.isNotEmpty
              //       ? NetworkImage("${ApiConstant.imageurl}$listenerImage")
              //       : const AssetImage('assets/images/avatar.gif') as ImageProvider,
              //   radius: 20,
              // ),
              const SizedBox(width: 12),
              Text(listenerName),
            ],
          ),
          actions: [
          
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: deleteChat,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : chatRoom.value == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No chat room available',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please contact the seller to start a chat.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: messages.value.isEmpty
                            ? const Center(
                                child: Text(
                                  'No messages yet',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: messages.value.length,
                                itemBuilder: (context, index) {
                                  final message = messages.value[index];
                                  final isMe = message.userIdFrom == userId;
                                  return GestureDetector(
                                    onLongPress: isMe ? () => deleteMessage(message.id) : null,
                                    child: Align(
                                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isMe ? Colors.blue : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          message.message,
                                          style: TextStyle(
                                            color: isMe ? Colors.white : Colors.black,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                decoration: InputDecoration(
                                  hintText: chatRoom.value == null
                                      ? 'Chat unavailable'
                                      : 'Type a message...',
                                  border: const OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: chatRoom.value == null ? Colors.grey : Colors.blue,
                                    ),
                                  ),
                                ),
                                enabled: chatRoom.value != null,
                                onSubmitted: (value) {
                                  if (chatRoom.value != null && !isSending.value) {
                                    sendMessage();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: isSending.value
                                  ? const CircularProgressIndicator()
                                  : const Icon(Icons.send, color: Colors.blue),
                              onPressed: (chatRoom.value == null || isSending.value) ? null : sendMessage,
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