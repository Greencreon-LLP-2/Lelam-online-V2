import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/selling_status/my_bids_seller_widget.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/selling_status/my_meeting_seller_sidget.dart';

import 'package:lelamonline_flutter/feature/status/view/widgets/selling_status/junk_widget.dart';

class SellerTabBarWidget extends StatefulWidget {
  final String? userId;
  final Map<String, dynamic>? adData;
   final String? postId;
  const SellerTabBarWidget({
    super.key,
    this.userId,
    this.adData, this.postId,
  });

  @override
  State<SellerTabBarWidget> createState() => _SellerTabBarWidget();
}

class _SellerTabBarWidget extends State<SellerTabBarWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasSelectedTab = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _hasSelectedTab = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          isScrollable: false,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: 'My Ads'),
            Tab(text: 'My Meetings (Seller)'),
            Tab(text: 'Junk'),
          ],
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250), // Adjust as needed
            child: _hasSelectedTab
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      MyBidsSellerWidget(
                        userId: widget.userId,
                        postId: widget.postId
                       
                      ),
                     MyMeetingsSellerWidget(
                     
                        postId: widget.postId
                       
                      ),
                      const JunkWidget(),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}