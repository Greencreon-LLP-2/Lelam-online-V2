import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                        ? Image.network(
                          originalImageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder:
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
            if ((userData?.name.isNotEmpty ?? false))
              Text(
                userData!.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

            if ((userData?.username.isNotEmpty ?? false)) ...[
              const SizedBox(height: 4),
              Text(
                userData!.username,
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
                builder: (dialogContext) => Dialog(
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
                          child: Icon(Icons.logout, size: 36, color: Colors.red.shade700),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Logout',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(dialogContext).pop();
                                  await userProvider.clearUser(); // clear tokens/hive
                                  outerContext.goNamed(RouteNames.loginPage); // navigate to login
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Logout', style: TextStyle(color: Colors.white)),
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
                            Navigator.pop(context);
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
