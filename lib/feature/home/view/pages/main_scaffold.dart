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
      bottomNavigationBar: SizedBox(
        height: 55, // Reduced height from 65 to 50
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
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
                currentIndex = isStatus ? 1 : 3;
                isStatus = true;
              });
            }
          },
          selectedItemColor: isStatus ? Colors.redAccent : Colors.black,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          showSelectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontSize: 8, // Reduced font size
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 8,
          ), // Reduced font size
          selectedFontSize: 8, // Ensure consistency
          unselectedFontSize: 8, // Ensure consistency
          iconSize: 18, // Reduced icon size
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            isStatus
                ? BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart, size: 18), // Reduced size
                  label: 'Buying',
                )
                : BottomNavigationBarItem(
                  icon: Icon(Icons.support_agent, size: 18), // Reduced size
                  label: 'Support',
                ),
            isStatus
                ? BottomNavigationBarItem(
                  icon: Icon(Icons.sell, size: 18), // Reduced size
                  label: 'Selling',
                )
                : BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(1), // Reduced padding
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 3,
                      ), // Thinner border
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 12, // Reduced size
                      color: Color.fromARGB(255, 12, 9, 233),
                    ),
                  ),
                  label: 'Sell',
                ),
            isStatus
                ? BottomNavigationBarItem(
                  icon: Icon(
                    Icons.star_border_outlined,
                    size: 18,
                  ), // Reduced size
                  label: 'Shortlist',
                )
                : BottomNavigationBarItem(
                  icon: Icon(Icons.stream_outlined, size: 18), // Reduced size
                  label: 'Status',
                ),
            BottomNavigationBarItem(icon: Icon(Icons.more_vert), label: 'More'),
          ],
        ),
      ),
    );
  }
}
