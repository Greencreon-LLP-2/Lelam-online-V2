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
    final userData = useState<Map<String, Map<String, String>>>({}); // Now dynamic
    final isFetchingUsers = useState(false); // For user data loading

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
              // After chat rooms load, fetch unique other users
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

      // Collect unique other user IDs
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
        // Assuming a batched API endpoint like 'user-profile-list.php?user_ids=1,2,3'
        // Adjust URL/query params based on your backend (e.g., POST with JSON body if needed)
        final userIdsQuery = otherUserIds.join(',');
        final url = Uri.parse('$baseUrl/user-profile-list.php?token=$token&user_ids=$userIdsQuery'); // Replace with your actual endpoint
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
                'name': user['name']?.toString() ?? '', // Assume 'name' field; adjust as needed
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
      String displayName = user['name']!.isNotEmpty ? user['name']! : 'Guest User'; // Fallback to "Guest User" if no name

      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          // leading: CircleAvatar(
          //   backgroundImage: user['image']!.isNotEmpty
          //       ? NetworkImage("${ApiConstant.imageurl}${user['image']}")
          //       : const AssetImage('assets/images/avatar.gif') as ImageProvider,
          //   radius: 24,
          // ),
          title: Text(
            displayName, // Always shows name or "Guest User" – no ID
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Last updated: ${chatRoom['updated_on']}',
            style: const TextStyle(color: Colors.grey),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  listenerId: otherUserId,
                  listenerName: displayName, // Pass the display name
                  listenerImage: user['image'] ?? '',
                  userId: userId,
                ),
              ),
            );
          },
        ),
      );
    }

    return CustomSafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
        ),
        body: isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : error.value != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          error.value!,
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ],
                    ),
                  )
                : chatRooms.value.isEmpty
                    ? const Center(
                        child: Text(
                          'No chats available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: chatRooms.value.length,
                        itemBuilder: (context, index) {
                          final chatRoom = chatRooms.value[index];
                          final otherUserId = chatRoom['user_id_from'] == userId
                              ? chatRoom['user_id_to'].toString()
                              : chatRoom['user_id_from'].toString();

                          // Show loading if still fetching users
                          if (isFetchingUsers.value && !userData.value.containsKey(otherUserId)) {
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: const CircularProgressIndicator(strokeWidth: 2),
                                title: const Text('Loading...'),
                                subtitle: Text('Last updated: ${chatRoom['updated_on']}'),
                              ),
                            );
                          }

                          return _buildUserTile(chatRoom, otherUserId);
                        },
                      ),
      ),
    );
  }
}