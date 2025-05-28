import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class AppDrawerWidget extends StatelessWidget {
  const AppDrawerWidget({super.key});

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
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: AppTheme.primaryColor,
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
              // TODO: Navigate to FAQ
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            icon: Icons.info_outlined,
            title: 'Info',
            onTap: () {
              // TODO: Navigate to orders
              Navigator.pop(context);
            },
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
              // TODO: Navigate to settings
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            isfavourite: true,
            isLogOut: true,
            icon: Icons.logout,
            title: 'Log Out',
            onTap: () {
              // TODO: Navigate to settings
              Navigator.pop(context);
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
