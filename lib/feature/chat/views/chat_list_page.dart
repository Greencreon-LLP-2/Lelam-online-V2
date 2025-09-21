import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final userName = userProvider.userData?.name.isNotEmpty == true
        ? userProvider.userData!.name
        : 'Guest User';

 Future<void> openWhatsApp(BuildContext context) async {
  const phoneNumber = '+918089308048';
  const message = 'Hello Support Team';
  const supportEmail = 'support@lelamonline.com'; // Replace with actual support email
  final whatsappAppUrl = 'whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}';
  final whatsappWebUrl = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
  final testBrowserUrl = 'https://www.google.com';

  try {
    // Step 1: Test browser availability
    debugPrint('Testing browser with URL: $testBrowserUrl');
    final browserUri = Uri.parse(testBrowserUrl);
    if (!await canLaunchUrl(browserUri)) {
      debugPrint('No browser available to handle HTTPS URLs');
      throw Exception('No browser available to handle HTTPS URLs');
    }
    debugPrint('Browser URL can be launched');

    // Step 2: Try WhatsApp app URL
    debugPrint('Attempting WhatsApp app with URL: $whatsappAppUrl');
    final appUri = Uri.parse(whatsappAppUrl);
    if (await canLaunchUrl(appUri)) {
      debugPrint('Launching WhatsApp app');
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
      return;
    }
    debugPrint('WhatsApp app URL cannot be launched');

    // Step 3: Try WhatsApp web URL
    debugPrint('Trying WhatsApp web URL: $whatsappWebUrl');
    final webUri = Uri.parse(whatsappWebUrl);
    if (await canLaunchUrl(webUri)) {
      debugPrint('Launching WhatsApp web URL');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    }
    debugPrint('WhatsApp web URL cannot be launched');

    // Step 4: Fallback to SMS
    debugPrint('Attempting SMS fallback');
    final smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(smsUri)) {
      debugPrint('Launching SMS');
      await launchUrl(smsUri);
      return;
    }
    debugPrint('SMS cannot be launched');

    // Step 5: Fallback to email
    debugPrint('Attempting email fallback');
    final emailUri = Uri.parse('mailto:$supportEmail?subject=Support%20Request&body=$message');
    if (await canLaunchUrl(emailUri)) {
      debugPrint('Launching email client');
      await launchUrl(emailUri);
      return;
    }
    debugPrint('Email cannot be launched');

    // Step 6: Show manual instructions with copy option
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not open WhatsApp, browser, SMS, or email. Please contact support manually at $phoneNumber or $supportEmail.',
        ),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Copy Contact',
          textColor: Colors.white,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: '$phoneNumber, $supportEmail'));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Support contact copied to clipboard'),
                backgroundColor: AppTheme.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
        ),
      ),
    );
  } catch (e) {
    debugPrint('Error in _openWhatsApp: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to open WhatsApp or fallbacks: $e'),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Copy Contact',
          textColor: Colors.white,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: '$phoneNumber, $supportEmail'));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Support contact copied to clipboard'),
                backgroundColor: AppTheme.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
        ),
      ),
    );
  }
}

    Future<void> fetchOtherUsers(
      String userId,
      ValueNotifier<List<Map<String, dynamic>>> chatRooms,
      ValueNotifier<Map<String, Map<String, String>>> userData,
    ) async {
      if (chatRooms.value.isEmpty) return;

      // Collect all user IDs (both user_id_from and user_id_to)
      final Set<String> allUserIds = {};
      for (final chatRoom in chatRooms.value) {
        allUserIds.add(chatRoom['user_id_from'].toString());
        allUserIds.add(chatRoom['user_id_to'].toString());
      }

      if (allUserIds.isEmpty) return;

      isFetchingUsers.value = true;
      try {
        final Map<String, Map<String, String>> fetchedUsers = {};
        // Fetch user data for each user ID individually
        for (final userIdStr in allUserIds) {
          final url = Uri.parse(
            '$baseUrl/index.php?token=$token&user_id=$userIdStr',
          );
          final response = await http.get(url);

          debugPrint('ChatListPage: Fetching user: $url');
          debugPrint('ChatListPage: User response status: ${response.statusCode}');
          debugPrint('ChatListPage: User response body: ${response.body}');

          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body);
            if (jsonResponse['status'] == true && jsonResponse['data'] is List && jsonResponse['data'].isNotEmpty) {
              final user = jsonResponse['data'][0];
              final userName = user['name']?.toString();
              fetchedUsers[userIdStr] = {
                'name': userName != null && userName.isNotEmpty
                    ? userName
                    : 'Guest User',
                'image': user['profile']?.toString() ?? '',
              };
            } else {
              debugPrint('ChatListPage: Invalid user data format for user ID: $userIdStr');
              fetchedUsers[userIdStr] = {
                'name': 'Guest User',
                'image': '',
              };
            }
          } else {
            debugPrint('ChatListPage: Failed to fetch user $userIdStr: ${response.statusCode}');
            fetchedUsers[userIdStr] = {
              'name': 'Guest User',
              'image': '',
            };
          }
        }
        userData.value = fetchedUsers;
        debugPrint('ChatListPage: Updated userData: ${userData.value}');
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
              await fetchOtherUsers(userId, chatRooms, userData);
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

    if (!userProvider.isLoggedIn || userId.isEmpty) {
      return CustomSafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.pushNamed(RouteNames.loginPage);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Log In to View Chats',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => openWhatsApp(context),
            backgroundColor: const Color(0xFF25D366),
            tooltip: 'Contact Support on WhatsApp',
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/whatsapp_icon.svg',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Support',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildUserTile(Map<String, dynamic> chatRoom) {
      final userIdFrom = chatRoom['user_id_from'].toString();
      final userIdTo = chatRoom['user_id_to'].toString();
      final otherUserId = userIdFrom == userId ? userIdTo : userIdFrom;

      final displayName = userData.value[otherUserId]?['name'] ?? 'Guest User';
      final displayImage = userData.value[otherUserId]?['image'] ?? '';

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
            child: displayImage.isEmpty
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
                builder: (context) => ChatPage(
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

    Widget buildLoadingTile(Map<String, dynamic> chatRoom) {
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

    return Scaffold(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openWhatsApp(context),
        backgroundColor: const Color(0xFF25D366),
        tooltip: 'Contact Support on WhatsApp',
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/whatsapp_icon.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Support',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
                          style: TextStyle(fontSize: 14, color: Colors.red[600]),
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
                        final userIdFrom = chatRoom['user_id_from'].toString();
                        final userIdTo = chatRoom['user_id_to'].toString();

                        if (isFetchingUsers.value &&
                            (!userData.value.containsKey(userIdFrom) ||
                                !userData.value.containsKey(userIdTo))) {
                          return buildLoadingTile(chatRoom);
                        }

                        return buildUserTile(chatRoom);
                      },
                    ),
    );
  }
}