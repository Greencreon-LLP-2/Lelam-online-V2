// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/home/view/pages/home_page.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/app_drawer.dart';
import 'package:lelamonline_flutter/feature/sell/view/pages/sell_page.dart';
import 'package:lelamonline_flutter/feature/shortlist/views/short_list_page.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/buying_status_page.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/selling_status_page.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/status_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int currentIndex = 0;
  bool isStatus = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _pages => [
    HomePage(),
    isStatus ? BuyingStatusPage() : Center(child: Text('Support')),
    isStatus ? SellingStatusPage() : SellPage(),
    isStatus ? ShortListPage() : StatusPage(),
    Center(child: Text('Profile')),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawerWidget(),
      body: _pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          print(index);
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
            return;
          }
          setState(() {
            currentIndex = index;
          });
          if (index == 0) {
            setState(() {
              isStatus = false;
            });
          }
          if (index == 3) {
            setState(() {
              // currentIndex = isStatus ? 1 : 3;
              isStatus = true;
            });
          }
        },
        selectedItemColor: isStatus ? Colors.redAccent : AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        selectedFontSize: 14,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          isStatus
              ? BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart),
                label: 'Buying',
              )
              : BottomNavigationBarItem(
                icon: Icon(Icons.support_agent),
                label: 'Support',
              ),
          isStatus
              ? BottomNavigationBarItem(
                icon: Icon(Icons.sell),
                label: 'Selling',
              )
              : BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color.fromARGB(255, 12, 9, 233),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Color.fromARGB(255, 12, 9, 233),
                  ),
                ),
                label: 'Sell',
              ),

          isStatus
              ? BottomNavigationBarItem(
                icon: Icon(Icons.star_border_outlined),
                label: 'Shortlist',
              )
              : BottomNavigationBarItem(
                icon: Icon(Icons.stream_outlined),
                label: 'Status',
              ),
          BottomNavigationBarItem(icon: Icon(Icons.more_vert), label: 'More'),
        ],
      ),
    );
  }
}
