import 'package:flutter/foundation.dart';
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
  final String? userId;

  const MainScaffold({super.key, this.userId});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int currentIndex = 0;
  bool isStatus = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _pages => [
        HomePage(userId: widget.userId),
        isStatus
            ? BuyingStatusPage(userId: widget.userId)
            : const Center(child: Text('Support')),
        isStatus
            ? SellingStatusPage(userId: widget.userId)
            : SellPage(userId: widget.userId),
        isStatus
            ? ShortListPage(userId: widget.userId)
            : StatusPage(userId: widget.userId),
        Center(
          child: Text(
            'Profile: User ID ${widget.userId ?? 'Unknown'}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawerWidget(userId: widget.userId),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: _pages[currentIndex],
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        top: false,
        left: false,
        right: false,
        child: SizedBox(
          height: 60 + (bottomPadding > 0 ? bottomPadding : 0),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            onTap: (index) {
              if (kDebugMode) print(index);
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
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 8,
            ),
            selectedFontSize: 8,
            unselectedFontSize: 8,
            iconSize: 18,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(isStatus ? Icons.shopping_cart : Icons.support_agent, size: 18),
                label: isStatus ? 'Buying' : 'Support',
              ),
              BottomNavigationBarItem(
                icon: isStatus
                    ? const Icon(Icons.sell, size: 18)
                    : Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 12,
                          color: Color.fromARGB(255, 12, 9, 233),
                        ),
                      ),
                label: isStatus ? 'Selling' : 'Sell',
              ),
              BottomNavigationBarItem(
                icon: Icon(isStatus ? Icons.star_border_outlined : Icons.stream_outlined, size: 18),
                label: isStatus ? 'Shortlist' : 'Status',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.more_vert), label: 'More'),
            ],
          ),
        ),
      ),
    );
  }
}