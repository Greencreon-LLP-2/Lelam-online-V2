import 'dart:developer';
import 'dart:developer' as developer;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: CustomSafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileSection(context),
            const SizedBox(height: 24),
            _buildSettingsSection(context),
            const SizedBox(height: 24),
            _buildDangerSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final userProvider = Provider.of<LoggedUserProvider>(context);
    final userData = userProvider.userData;

    // Build the image URL if user has image
    final originalImageUrl =
        (userData?.image?.isNotEmpty ?? false)
            ? "$getImageFromServer${userData!.image}"
            : null;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child:
                    originalImageUrl != null
                        ? CachedNetworkImage(
                          imageUrl: originalImageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorWidget:
                              (context, error, stackTrace) => Image.asset(
                                'assets/images/avatar.gif',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                        )
                        : Image.asset(
                          'assets/images/avatar.gif',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
              ),
            ),
            const SizedBox(height: 16),

            // Show name only if not empty
            if ((userData?.name?.isNotEmpty ?? false))
              Text(
                userData!.name!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

            if ((userData?.username?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 4),
              Text(
                userData!.username!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.pushNamed(RouteNames.editProfilePage);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Account Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.post_add,
            title: 'My Ads',
            onTap: () => context.pushNamed(RouteNames.sellingstatuspage),
          ),
          _buildSettingsTile(
            icon: Icons.favorite,
            title: 'Favourites',
            onTap: () => context.pushNamed(RouteNames.shortlistpage),
            isFavorite: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection(BuildContext context) {
    final userProvider = context.watch<LoggedUserProvider>();
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            textColor: Colors.red,
            onTap: () {
              final userProvider = context.read<LoggedUserProvider>();
              final outerContext = context;
              showDialog(
                context: outerContext,
                builder:
                    (dialogContext) => Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.logout,
                                size: 36,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Are you sure you want to logout? You will need to login again to access your account.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed:
                                        () => Navigator.of(dialogContext).pop(),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.black87),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      Navigator.of(dialogContext).pop();
                                      await userProvider
                                          .clearUser(); // clear tokens/hive
                                      outerContext.goNamed(
                                        RouteNames.loginPage,
                                      ); // navigate to login
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade700,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            textColor: Colors.red,
            onTap: () {
              final userProvider = context.read<LoggedUserProvider>();
              final userData = userProvider.userData;
              final outerContext = context;
              log(userData!.userId);

              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Delete Account'),
                      content: const Text(
                        'Are you sure you want to delete your account? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Handle account deletion
                            // Navigator.pop(context);
                            _deleteAccount(outerContext, userProvider);
                            // Navigator.pop(context);
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
    );
  }

  final dio = Dio();

  Future<void> _deleteAccount(
    BuildContext context,
    LoggedUserProvider userProvider,
  ) async {
    log('Deleting account...');
    final userId = userProvider.userData?.userId;

    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User ID not found.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final userIdInt = int.tryParse(userId.toString());
    if (userIdInt == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Invalid User ID format.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final response = await ApiService().get(
        url: deleteuser,
        queryParams: {"user_id": userIdInt, 'delete': 'user'},
      );
      log('Response: $response');

      if (!context.mounted) return;

      // Response is Map<String, dynamic> from ApiService.get
      final jsonResponse = response as Map<String, dynamic>;
      final status = jsonResponse['status'] as String?;
      final message = jsonResponse['data'] as String?;
      final code = jsonResponse['code'] as int?;

      if (status == 'true' && code == 0) {
        await userProvider.clearUser();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account ${userProvider.userData?.username ?? 'unknown'} deleted successfully: $message',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.goNamed(RouteNames.loginPage);
      } else if (code == 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid or missing parameters: $message'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      if (!context.mounted) return;
      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage =
            'Connection timed out. Please check your internet or try again later.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'Server took too long to respond. Please try again later.';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMessage = 'Server error: ${e.response?.statusCode ?? 'unknown'}';
      } else {
        errorMessage = 'Network error: ${e.message ?? 'unknown'}';
      }
      log('DioException: $errorMessage');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          action:
              e.type == DioExceptionType.connectionTimeout ||
                      e.type == DioExceptionType.receiveTimeout
                  ? SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () => _deleteAccount(context, userProvider),
                  )
                  : null,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      log('Unexpected error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    bool isFavorite = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isFavorite ? Colors.red : textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
