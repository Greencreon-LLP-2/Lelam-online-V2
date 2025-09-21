import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class AppDrawerWidget extends StatelessWidget {
  const AppDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<LoggedUserProvider>();
    final userData = userProvider.userData;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primaryColor),
            accountName: Text(
              userProvider.isLoggedIn && userData?.name.isNotEmpty == true
                  ? userData!.name
                  : 'Welcome',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              userProvider.isLoggedIn && userData?.mobile.isNotEmpty == true
                  ? userData!.mobile
                  : 'Join our bidding and ads platform!',
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: ClipOval(
                child:
                    (userProvider.isLoggedIn &&
                            userData?.image?.isNotEmpty == true)
                        ? Image.network(
                          "$getImageFromServer${userData!.image}",
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          errorBuilder:
                              (_, __, ___) => Image.asset(
                                'assets/images/avatar.gif',
                                fit: BoxFit.cover,
                                width: 60,
                                height: 60,
                              ),
                        )
                        : Image.asset(
                          'assets/images/avatar.gif',
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                        ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.category,
                  title: 'Categories',
                  onTap: () {
                    Navigator.pop(context);
                    context.pushNamed(RouteNames.categoriespage);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.favorite,
                  title: 'Favourites',
                  onTap: () {
                    Navigator.pop(context);
                    if (userProvider.isLoggedIn) {
                      context.pushNamed(RouteNames.shortlistpage);
                    } else {
                      context.pushNamed(RouteNames.loginPage);
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.post_add,
                  title: 'My Post',
                  onTap: () {
                    Navigator.pop(context);
                    if (userProvider.isLoggedIn) {
                      context.pushNamed(
                        RouteNames.sellingstatuspage,
                        extra: {'userId': userData!.userId},
                      );
                    } else {
                      context.pushNamed(RouteNames.loginPage);
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
                  leading: const Icon(Icons.info_outline),
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
                            leading: const Icon(Icons.privacy_tip_outlined),
                            title: Text(title),
                            onTap: () => Navigator.pop(context),
                          ),
                        )
                        ,
                  ],
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.contact_phone,
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
                  icon: userProvider.isLoggedIn ? Icons.logout : Icons.login,
                  title: userProvider.isLoggedIn ? 'Logout' : 'Login',
                  onTap: () async {
                    Navigator.pop(context);
                    if (userProvider.isLoggedIn) {
                      await userProvider.clearUser();
                    } else {
                      context.pushNamed(RouteNames.loginPage);
                    }
                  },
                  isLogOut: userProvider.isLoggedIn,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogOut = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isLogOut ? Colors.red : Colors.black),
      title: Text(
        title,
        style: TextStyle(color: isLogOut ? Colors.red : Colors.black),
      ),
      onTap: onTap,
    );
  }
}
