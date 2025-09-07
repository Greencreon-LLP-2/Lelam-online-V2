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
import 'package:shared_preferences/shared_preferences.dart';

class MainScaffold extends StatefulWidget {
  final String? userId;
  final Map<String, dynamic>? adData;

  const MainScaffold({super.key, this.userId, this.adData});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int currentIndex = 0;
  bool isStatus = false;
  String? userId;
  Map<String, dynamic>? adData;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserId();
    adData = widget.adData;
  }

  Future<void> _loadUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? widget.userId ?? 'Unknown';
    });
    if (kDebugMode) {
      print('Loaded userId: $userId');
    }
  }

  List<Widget> get _pages => [
        HomePage(userId: userId),
        isStatus
            ? BuyingStatusPage(userId: userId)
            : const Center(child: Text('Support')),
        isStatus
            ? SellingStatusPage(userId: userId, adData: adData)
            : SellPage(userId: userId),
        isStatus ? ShortListPage(userId: userId) : StatusPage(userId: userId),
        Center(
          child: Text(
            'Profile: User ID ${userId ?? 'Unknown'}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawerWidget(userId: userId),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: _pages[currentIndex], // Main page content inside SafeArea
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        top: false,
        left: false,
        right: false,
        child: SizedBox(
          height: 37,
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: currentIndex,
              onTap: (index) {
                if (kDebugMode) print('Selected index: $index');
                if (index == 4) {
                  _scaffoldKey.currentState?.openDrawer();
                  return;
                }

                setState(() {
                  currentIndex = index;
                  if (index == 0) {
                    isStatus = false;
                  } else if (index == 3) {
                    isStatus = true;
                  }
                });
              },
              selectedItemColor:
                  isStatus ? Colors.redAccent : Colors.black,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              showSelectedLabels: true,
              selectedLabelStyle: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 8),
              selectedFontSize: 8,
              unselectedFontSize: 8,
              iconSize: 14,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    isStatus ? Icons.shopping_cart : Icons.support_agent,
                  ),
                  label: isStatus ? 'Buying' : 'Support',
                ),
                BottomNavigationBarItem(
                  icon: isStatus
                      ? const Icon(Icons.sell)
                      : Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.black, width: 2),
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
                  icon: Icon(
                    isStatus
                        ? Icons.star_border_outlined
                        : Icons.stream_outlined,
                  ),
                  label: isStatus ? 'Shortlist' : 'Status',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.more_vert),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
