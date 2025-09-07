import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/my_bids_widget.dart' hide MyMeetingsWidget;
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/my_meetings_widget.dart';

class BuyingStatusPage extends StatelessWidget {
  const BuyingStatusPage({super.key, String? userId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // must match number of tabs and views
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buying Status'),
          bottom: const TabBar(
            dividerColor: Colors.transparent,
            isScrollable: false, // enables scrolling for many tabs
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 14),
            tabs: [
              Tab(text: 'My Bids'),
              Tab(text: 'My Meetings'),
              Tab(text: 'Expired'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MyBidsWidget(),
            MyMeetingsWidget(),
            Center(child: Text('Expired')),
          ],
        ),
      ),
    );
  }
}
