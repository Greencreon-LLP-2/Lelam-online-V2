import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/my_bids_widget.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/buying_status/my_meetings_widget.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/selling_status/junk_widget.dart';

class TabBarWidget extends StatelessWidget {
  const TabBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            dividerColor: Colors.transparent,
            isScrollable: false,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 14),
            tabs: [
              Tab(text: 'My Bids'),
              Tab(text: 'My Meetings'),
              Tab(text: 'Junk'),
            ],
          ),
          SizedBox(
            height: 200, // Fixed height for the TabBarView
            child: TabBarView(
              children: [MyBidsWidget(), MyMeetingsWidget(), JunkWidget()],
            ),
          ),
        ],
      ),
    );
  }
}
