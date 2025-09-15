import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/selling_status/my_ads_widget.dart';
import 'package:provider/provider.dart';

class SellingStatusPage extends StatelessWidget {
  final String? userId;
  final Map<String, dynamic>? adData;

  const SellingStatusPage({super.key, this.userId, this.adData});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<LoggedUserProvider>(context, listen: false);

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
              'Log In to View Ads',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Selling Status',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            dividerColor: Colors.transparent,
            isScrollable: false,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontSize: 14),
            tabs: [Tab(text: 'My Ads'), Tab(text: 'Sold')],
          ),
        ),
        backgroundColor: Colors.grey[50],
        body: TabBarView(
          children: [
            MyAdsWidget(adData: adData),
            const Center(child: Text('Sold')),
          ],
        ),
      ),
    );
  }
}