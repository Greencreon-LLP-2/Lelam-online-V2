import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class BuyingStatusPage extends StatelessWidget {
  const BuyingStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // must match number of tabs and views
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buying Status'),
          bottom: const TabBar(
            isScrollable: true, // enables scrolling for many tabs
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
            Center(child: Text('My Bids')),
            Center(child: Text('My Meetings')),
            Center(child: Text('Expired')),
          ],
        ),
      ),
    );
  }
}
