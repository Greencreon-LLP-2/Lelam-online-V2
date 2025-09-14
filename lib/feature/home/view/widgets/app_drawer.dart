import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/api/hive_helper.dart';
import 'package:provider/provider.dart';
import 'package:lelamonline_flutter/core/model/user_model.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class AppDrawerWidget extends StatelessWidget {
  const AppDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Get user data from Provider
    final userData = Provider.of<UserData?>(context, listen: false);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child:
                        userData?.profile != null &&
                                userData!.profile!.isNotEmpty
                            ? Image.network(
                              userData!.profile!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback if network image fails
                                return Image.asset(
                                  'assets/images/avatar.gif',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                            : Image.asset(
                              'assets/images/avatar.gif',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  userData?.name.isNotEmpty == true
                      ? 'Hello, ${userData!.name}'
                      : 'Welcome',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (userData?.mobile.isNotEmpty == true)
                  Text(
                    userData!.mobile,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
              ],
            ),
          ),

          _buildDrawerItem(
            icon: Icons.category,
            title: 'Categories',
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(RouteNames.categoriespage);
            },
          ),
          _buildDrawerItem(
            isfavourite: true,
            icon: Icons.favorite_outlined,
            title: 'Favourites',
            onTap: () {
              if (userData?.userId.isNotEmpty == true) {
                Navigator.pop(context);
                context.pushNamed(RouteNames.shortlistpage);
              } else {
                context.goNamed(RouteNames.loginPage);
              }
            },
          ),
          _buildDrawerItem(
            icon: Icons.add_to_photos_rounded,
            title: 'My Post',
            onTap: () {
              if (userData?.userId.isNotEmpty == true) {
                Navigator.pop(context);
                context.pushNamed(
                  RouteNames.sellingstatuspage,
                  extra: {'userId': userData!.userId},
                );
              } else {
                context.goNamed(RouteNames.loginPage);
              }
            },
          ),
          _buildDrawerItem(
            icon: Icons.question_answer,
            title: 'FAQ',
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(RouteNames.faqPage);
            },
          ),
          ExpansionTile(
            leading: const Icon(Icons.info_outlined, color: Colors.black),
            title: const Text('Info'),
            children: [
              ...[
                    'EULA',
                    'Privacy Policy',
                    'Terms of Service',
                    'About Us',
                    'Shipping Policy',
                  ]
                  .map(
                    (title) => ListTile(
                      contentPadding: const EdgeInsets.only(left: 72),
                      title: Text(title),
                      leading: const Icon(
                        Icons.privacy_tip_outlined,
                        color: Colors.black,
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                  )
                  .toList(),
            ],
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.phone,
            title: 'Contact Us',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(RouteNames.settingsPage);
            },
          ),
          _buildDrawerItem(
            isfavourite: true,
            isLogOut: true,
            icon: Icons.logout,
            title: userData != null ? 'Logout' : 'Login',
            onTap: () async {
              Navigator.pop(context);

              if (userData != null) {
                // Clear Hive data
                await HiveHelper().logout();

                // Update Provider
                Provider.of<UserData?>(
                  context,
                  listen: false,
                ); // will be replaced in MultiProvider
                // Optionally, use a ChangeNotifier for UserData and set it to null
              }

              context.goNamed(RouteNames.loginPage);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    bool isfavourite = false,
    bool isLogOut = false,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isfavourite ? Colors.red : Colors.black),
      title: Text(
        title,
        style: TextStyle(color: isLogOut ? Colors.red : Colors.black),
      ),
      onTap: onTap,
    );
  }
}
