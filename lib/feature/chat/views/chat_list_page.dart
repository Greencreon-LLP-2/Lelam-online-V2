import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:lelamonline_flutter/feature/chat/views/chat_page.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatListPage extends HookWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chatRooms = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(true);
    final error = useState<String?>(null);
    final userData = useState<Map<String, Map<String, String>>>({});
    final isFetchingUsers = useState(false);
    final userProvider = Provider.of<LoggedUserProvider>(
      context,
      listen: false,
    );
    final userId = userProvider.userId ?? '';
    final userName = userProvider.userData?.name ?? 'Guest User';

    Future<void> _openWhatsApp() async {
      const phoneNumber = '+918089308048';
      final whatsappUrl =
          'https://wa.me/$phoneNumber?text=Hello%20Support%20Team';
      final uri = Uri.parse(whatsappUrl);

      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open WhatsApp: $e')));
      }
    }

    Future<void> _fetchOtherUsers(
      String userId,
      ValueNotifier<List<Map<String, dynamic>>> chatRooms,
      ValueNotifier<Map<String, Map<String, String>>> userData,
    ) async {
      if (chatRooms.value.isEmpty) return;

      final Set<String> otherUserIds = {};
      for (final chatRoom in chatRooms.value) {
        final otherUserId =
            chatRoom['user_id_from'] == userId
                ? chatRoom['user_id_to'].toString()
                : chatRoom['user_id_from'].toString();
        if (otherUserId != userId) {
          otherUserIds.add(otherUserId);
        }
      }

      if (otherUserIds.isEmpty) return;

      isFetchingUsers.value = true;
      try {
        final userIdsQuery = otherUserIds.join(',');
        final url = Uri.parse(
          '$baseUrl/user-profile-list.php?token=$token&user_ids=$userIdsQuery',
        );
        final response = await http.get(url);

        debugPrint('ChatListPage: Fetching users: $url');
        debugPrint(
          'ChatListPage: User response status: ${response.statusCode}',
        );
        debugPrint('ChatListPage: User response body: ${response.body}');

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          if (jsonResponse['status'] == true && jsonResponse['data'] is List) {
            final List<dynamic> usersList = jsonResponse['data'];
            final Map<String, Map<String, String>> fetchedUsers = {};
            for (final user in usersList) {
              final userIdStr = user['user_id'].toString();
              fetchedUsers[userIdStr] = {
                'name': user['name']?.toString() ?? 'Guest User',
                'image': user['image']?.toString() ?? '',
              };
            }
            userData.value = fetchedUsers;
          } else {
            debugPrint('ChatListPage: Invalid user data format');
          }
        } else {
          debugPrint(
            'ChatListPage: Failed to fetch users: ${response.statusCode}',
          );
        }
      } catch (e) {
        debugPrint('ChatListPage: Error fetching users: $e');
      } finally {
        isFetchingUsers.value = false;
      }
    }

    useEffect(() {
      Future<void> fetchChatRooms() async {
        if (userId.isEmpty) {
          error.value = 'User ID is not available';
          isLoading.value = false;
          return;
        }

        final url = Uri.parse(
          '$baseUrl/chat-room-list.php?token=$token&user_id=$userId',
        );
        try {
          final response = await http.get(url);
          debugPrint('ChatListPage: Fetching chat rooms: $url');
          debugPrint('ChatListPage: Response status: ${response.statusCode}');
          debugPrint('ChatListPage: Response body: ${response.body}');

          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body);
            if (jsonResponse['status'] == true &&
                jsonResponse['data'] is List) {
              chatRooms.value = List<Map<String, dynamic>>.from(
                jsonResponse['data'],
              );
              await _fetchOtherUsers(userId, chatRooms, userData);
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

      if (userProvider.isLoggedIn) {
        fetchChatRooms();
      }
      return null;
    }, [userId]);

    if (!userProvider.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              context.pushNamed(RouteNames.loginPage);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Log In to View Chats',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    Widget _buildUserTile(Map<String, dynamic> chatRoom, String otherUserId) {
      final displayName =
          otherUserId == userId
              ? userName
              : userData.value[otherUserId]?['name']?.isNotEmpty == true
              ? userData.value[otherUserId]!['name']!
              : 'Guest User';
      final displayImage =
          otherUserId == userId
              ? userProvider.userData?.image ?? ''
              : userData.value[otherUserId]?['image'] ?? '';

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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            radius: 28,
            backgroundImage:
                displayImage.isNotEmpty ? NetworkImage(displayImage) : null,
            child:
                displayImage.isEmpty
                    ? Icon(Icons.person, color: AppTheme.primaryColor, size: 28)
                    : null,
          ),
          title: Text(
            displayName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Last updated: ${chatRoom['updated_on']}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
                builder:
                    (context) => ChatPage(
                      listenerId: otherUserId,
                      listenerName: displayName,
                      listenerImage: displayImage,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.grey[100],
            radius: 28,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
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
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          title: const Text(
            'Chats',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Support',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              onPressed: _openWhatsApp,
              backgroundColor: const Color(0xFF25D366),
              child: SvgPicture.asset(
                'assets/icons/whatsapp_icon.svg',
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
        body:
            isLoading.value
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading chats...',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
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
                      border: Border.all(color: Colors.red[100]!, width: 1),
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                    final otherUserId =
                        chatRoom['user_id_from'] == userId
                            ? chatRoom['user_id_to'].toString()
                            : chatRoom['user_id_from'].toString();

                    if (isFetchingUsers.value &&
                        !userData.value.containsKey(otherUserId) &&
                        otherUserId != userId) {
                      return _buildLoadingTile(chatRoom);
                    }

                    return _buildUserTile(chatRoom, otherUserId);
                  },
                ),
      ),
    );
  }
}
