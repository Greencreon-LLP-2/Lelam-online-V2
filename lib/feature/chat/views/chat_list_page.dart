import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:lelamonline_flutter/feature/chat/views/chat_page.dart';

class ChatListPage extends HookWidget {
  final String userId;
  final String sessionId;

  const ChatListPage({
    super.key,
    required this.userId,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final chatRooms = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(true);
    final error = useState<String?>(null);
    final userData = useState<Map<String, Map<String, String>>>({}); 
    final isFetchingUsers = useState(false);

    useEffect(() {
      Future<void> fetchChatRooms() async {
        final url = Uri.parse('$baseUrl/chat-room-list.php?token=$token&user_id=$userId');
        try {
          final response = await http.get(
            url,
            headers: {'Cookie': 'PHPSESSID=$sessionId'},
          );
          debugPrint('ChatListPage: Fetching chat rooms: $url');
          debugPrint('ChatListPage: Response status: ${response.statusCode}');
          debugPrint('ChatListPage: Response body: ${response.body}');

          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body);
            if (jsonResponse['status'] == true && jsonResponse['data'] is List) {
              chatRooms.value = List<Map<String, dynamic>>.from(jsonResponse['data']);
              //await _fetchOtherUsers();
            } else {
              error.value = 'Failed to load chat rooms';
            }
          } else {
            error.value = 'Failed to fetch chat rooms: ${response.statusCode}';
          }
        } catch (e) {
          debugPrint('ChatListPage: Error fetching chat rooms: $e');
          error.value = 'Error fetching chat rooms: $e';
        } finally {
          isLoading.value = false;
        }
      }

      fetchChatRooms();
      return null;
    }, [userId, sessionId]);

    Future<void> _fetchOtherUsers() async {
      if (chatRooms.value.isEmpty) return;

      final Set<String> otherUserIds = {};
      for (final chatRoom in chatRooms.value) {
        final otherUserId = chatRoom['user_id_from'] == userId
            ? chatRoom['user_id_to'].toString()
            : chatRoom['user_id_from'].toString();
        otherUserIds.add(otherUserId);
      }

      if (otherUserIds.isEmpty) return;

      isFetchingUsers.value = true;
      try {
        final userIdsQuery = otherUserIds.join(',');
        final url = Uri.parse('$baseUrl/user-profile-list.php?token=$token&user_ids=$userIdsQuery');
        final response = await http.get(
          url,
          headers: {'Cookie': 'PHPSESSID=$sessionId'},
        );

        debugPrint('ChatListPage: Fetching users: $url');
        debugPrint('ChatListPage: User response status: ${response.statusCode}');
        debugPrint('ChatListPage: User response body: ${response.body}');

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          if (jsonResponse['status'] == true && jsonResponse['data'] is List) {
            final List<dynamic> usersList = jsonResponse['data'];
            final Map<String, Map<String, String>> fetchedUsers = {};
            for (final user in usersList) {
              final userIdStr = user['user_id'].toString();
              fetchedUsers[userIdStr] = {
                'name': user['name']?.toString() ?? '',
                'image': user['image']?.toString() ?? '',
              };
            }
            userData.value = fetchedUsers;
          } else {
            debugPrint('ChatListPage: Invalid user data format');
          }
        } else {
          debugPrint('ChatListPage: Failed to fetch users: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('ChatListPage: Error fetching users: $e');
      } finally {
        isFetchingUsers.value = false;
      }
    }

    Widget _buildUserTile(Map<String, dynamic> chatRoom, String otherUserId) {
      Map<String, String> user = userData.value[otherUserId] ?? {'name': '', 'image': ''};
      String displayName = user['name']!.isNotEmpty ? user['name']! : 'Guest User';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            radius: 28,
            child: Icon(
              Icons.person,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
          ),
          title: Text(
            displayName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Last updated: ${chatRoom['updated_on']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
            size: 20,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  listenerId: otherUserId,
                  listenerName: displayName,
                  listenerImage: user['image'] ?? '',
                  userId: userId,
                ),
              ),
            );
          },
        ),
      );
    }

    Widget _buildLoadingTile(Map<String, dynamic> chatRoom) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: Colors.grey[100],
            radius: 28,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          title: Container(
            width: 120,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 180,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      );
    }

    return CustomSafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          title: const Text(
            'Chats',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
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
                      'Loading chats...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : error.value != null
                ? Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red[100]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Oops! Something went wrong',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.value!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : chatRooms.value.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No chats yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start a conversation to see your chats here',
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: chatRooms.value.length,
                        itemBuilder: (context, index) {
                          final chatRoom = chatRooms.value[index];
                          final otherUserId = chatRoom['user_id_from'] == userId
                              ? chatRoom['user_id_to'].toString()
                              : chatRoom['user_id_from'].toString();

                          if (isFetchingUsers.value && !userData.value.containsKey(otherUserId)) {
                            return _buildLoadingTile(chatRoom);
                          }

                          return _buildUserTile(chatRoom, otherUserId);
                        },
                      ),
      ),
    );
  }
}