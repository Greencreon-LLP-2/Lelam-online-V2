// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/home/view/pages/home_page.dart';
import 'package:lelamonline_flutter/feature/sell/view/pages/sell_page.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/status_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int currentIndex = 0;
  bool isStatus = false;
  List<Widget> get _pages => [
    HomePage(),
    isStatus ? Center(child: Text('Buying')) : Center(child: Text('Support')),
    isStatus ? Center(child: Text('Selling')) : SellPage(),
    isStatus ? Center(child: Text('Shortlist')) : StatusPage(),
    Center(child: Text('Profile')),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          print(index);
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
                icon: Icon(Icons.sell_outlined),
                label: 'Selling',
              )
              : BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Sell'),
          isStatus
              ? BottomNavigationBarItem(
                icon: Icon(Icons.star_border_outlined),
                label: 'Shortlist',
              )
              : BottomNavigationBarItem(
                icon: Icon(Icons.stream_sharp),
                label: 'Status',
              ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
