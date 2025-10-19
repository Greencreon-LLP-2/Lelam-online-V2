import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/expired_widget.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/my_bids_widget.dart' hide MyMeetingsWidget;
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/my_meetings_widget.dart' hide MyBidsWidget;
import 'package:provider/provider.dart';

class BuyingStatusPage extends StatefulWidget {
  final String? userId;
  final String? postId;
  final String? bidId;
  final int initialTabIndex; // Add this parameter

  const BuyingStatusPage({
    super.key,
    this.userId,
    this.postId,
    this.bidId,
    this.initialTabIndex = 0, // Default to first tab
  });

  @override
  State<BuyingStatusPage> createState() => _BuyingStatusPageState();
}

class _BuyingStatusPageState extends State<BuyingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: widget.initialTabIndex,
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
              'Log In to View Buying Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buying Status',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController, // Use custom TabController
          dividerColor: Colors.transparent,
          isScrollable: false,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: 'My Bids'),
            Tab(text: 'My Meetings'),
            //Tab(text: 'Expired'),
          ],
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: TabBarView(
        controller: _tabController, // Use custom TabController
        children: [
          MyBidsWidget(userId: widget.userId),
          MyMeetingsWidget(
            showAppBar: false,
            postId: widget.postId,
            bidId: widget.bidId,
          ),
          const ExpiredMeetingsPage(),
        ],
      ),
    );
  }
}