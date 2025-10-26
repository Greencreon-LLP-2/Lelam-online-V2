import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/my_bids_widget.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/my_meetings_widget.dart';
import 'package:provider/provider.dart';

class BuyingStatusPage extends StatefulWidget {
  final String? userId;
  final String? postId;
  final String? bidId;
  final int initialTabIndex;
  final String? initialStatus;
  final bool forceRefresh;

  const BuyingStatusPage({
    super.key,
    this.userId,
    this.postId,
    this.bidId,
    this.initialTabIndex = 0,
    this.initialStatus,
    this.forceRefresh = false,
  });

  @override
  State<BuyingStatusPage> createState() => _BuyingStatusPageState();
}

class _BuyingStatusPageState extends State<BuyingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentStatus;
  String? _currentPostId;
  String? _currentBidId;
  bool _forceRefresh = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: widget.initialTabIndex,
      length: 2,
      vsync: this,
    );
    _currentStatus = widget.initialStatus;
    _currentPostId = widget.postId;
    _currentBidId = widget.bidId;
    _forceRefresh = widget.forceRefresh;

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        debugPrint('Tab index changed to: ${_tabController.index}');
      }
    });
  }

  @override
  void didUpdateWidget(covariant BuyingStatusPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex ||
        widget.initialStatus != oldWidget.initialStatus ||
        widget.postId != oldWidget.postId ||
        widget.bidId != oldWidget.bidId ||
        widget.forceRefresh != oldWidget.forceRefresh) {
      setState(() {
        _tabController.index = widget.initialTabIndex;
        _currentStatus = widget.initialStatus;
        _currentPostId = widget.postId;
        _currentBidId = widget.bidId;
        _forceRefresh = widget.forceRefresh;
      });
      debugPrint(
        'Updated BuyingStatusPage with tab: ${widget.initialTabIndex}, status: ${widget.initialStatus}, forceRefresh: ${widget.forceRefresh}',
      );
    }
  }

  void _navigateToMeetings(
    String status,
    String? postId,
    String? bidId,
    bool forceRefresh,
  ) {
    print('=== _navigateToMeetings CALLED ===');
    print('Status: $status');
    print('PostId: $postId');
    print('BidId: $bidId');
    print('ForceRefresh: $forceRefresh');
    print('Current tab index: ${_tabController.index}');
    print('Mounted: $mounted');

    if (!mounted) {
      print('ERROR: Widget not mounted, cannot navigate');
      return;
    }

    try {
      setState(() {
        _tabController.index = 1; // Switch to "My Meetings" tab
        _currentStatus = status;
        _currentPostId = postId;
        _currentBidId = bidId;
        _forceRefresh = forceRefresh;
      });

      print('=== TAB SWITCHED SUCCESSFULLY ===');
      print('New tab index: ${_tabController.index}');
      print('New status: $_currentStatus');
      print('New forceRefresh: $_forceRefresh');
    } catch (e) {
      print('ERROR in _navigateToMeetings: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<LoggedUserProvider>(
      context,
      listen: false,
    );

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
          controller: _tabController,
          dividerColor: Colors.transparent,
          isScrollable: false,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [Tab(text: 'My Bids'), Tab(text: 'My Meetings')],
        ),
      ),
      backgroundColor: Colors.grey[50],
      body:  TabBarView(
  controller: _tabController,
  physics: const BouncingScrollPhysics(),
  children: [
    MyBidsWidget(
      userId: widget.userId,
      onNavigateToMeetings: _navigateToMeetings,
    ),
    MyMeetingsWidget(
      showAppBar: false,
      postId: _currentPostId,
      bidId: _currentBidId,
      initialStatus: _currentStatus,
      forceRefresh: _forceRefresh,
    ),
  ],
),
    );
  }
}
