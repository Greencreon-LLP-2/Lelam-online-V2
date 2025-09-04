import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/authentication/views/pages/login_page.dart';

class AppDrawerWidget extends StatelessWidget {
  const AppDrawerWidget({super.key, String? userId});

  @override
  Widget build(BuildContext context) {
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
                  child: Image.asset(
                    'assets/images/avatar.gif',
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Welcome',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Sign in to access all features',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
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
              Navigator.pop(context);
              context.pushNamed(RouteNames.shortlistpage);
            },
          ),
          _buildDrawerItem(
            icon: Icons.add_to_photos_rounded,
            title: 'My Post',
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(RouteNames.sellingstatuspage);
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
              ListTile(
                contentPadding: const EdgeInsets.only(left: 72),
                title: const Text('EULA'),
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Colors.black,
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 72),
                title: const Text('Privacy Policy'),
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Colors.black,
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 72),
                title: const Text('Terms of Service'),
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Colors.black,
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 72),
                title: const Text('About Us'),
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Colors.black,
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 72),
                title: const Text('Shipping Policy'),
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Colors.black,
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.phone,
            title: 'Contact Us',
            onTap: () {
              // TODO: Navigate to settings
              Navigator.pop(context);
            },
          ),

          _buildDrawerItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              // TODO: Navigate to help
              Navigator.pop(context);
            },
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
            title: 'Login',
            onTap: () {
              Navigator.pop(context); // Close the drawer first

              // Navigate to LoginPage and remove all previous routes

              // Navigate to login page and clear stack
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
