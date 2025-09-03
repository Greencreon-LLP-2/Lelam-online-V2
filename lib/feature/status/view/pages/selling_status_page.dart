import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/selling_status/my_ads_widget.dart';

class SellingStatusPage extends StatelessWidget {
  const SellingStatusPage({super.key, String? userId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Selling Status'),
          bottom: const TabBar(
            dividerColor: Colors.transparent,
            isScrollable: false, // enables scrolling for many tabs
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 14),
            tabs: [Tab(text: 'My Ads'), Tab(text: 'Sold')],
          ),
        ),
        body: TabBarView(
          children: [const MyAdsWidget(), Center(child: Text('Sold'))],
        ),
      ),
    );
  }
}
