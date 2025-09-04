import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/selling_status/my_ads_widget.dart';

class SellingStatusPage extends StatelessWidget {
  final String? userId;
  final Map<String, dynamic>? adData; // Add this parameter
  
  const SellingStatusPage({super.key, this.userId, this.adData});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Selling Status'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            dividerColor: Colors.transparent,
            isScrollable: false,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 14),
            tabs: [Tab(text: 'My Ads'), Tab(text: 'Sold')],
          ),
        ),
        body: TabBarView(
          children: [
            MyAdsWidget(userId: userId, adData: adData), // Pass adData here
            const Center(child: Text('Sold')),
          ],
        ),
      ),
    );
  }
}
