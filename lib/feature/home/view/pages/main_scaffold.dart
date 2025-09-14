import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/feature/Support/views/support_page.dart';
import 'package:lelamonline_flutter/feature/chat/views/chat_list_page.dart';
import 'package:lelamonline_flutter/feature/home/view/pages/home_page.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/app_drawer.dart';
import 'package:lelamonline_flutter/feature/sell/view/pages/sell_page.dart';

import 'package:lelamonline_flutter/feature/status/view/pages/buying_status_page.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/selling_status_page.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/status_page.dart';
import 'package:provider/provider.dart';

class MainScaffold extends StatefulWidget {
  final Map<String, dynamic>? adData;

  const MainScaffold({super.key, this.adData});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int currentIndex = 0;
  bool isStatus = false;
  String? userId;
  String? sessionId;
  Map<String, dynamic>? adData;
  bool isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    adData = widget.adData;
  }

  @override
  void didUpdateWidget(MainScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  List<Widget> get _pages => [
    HomePage(),
    isStatus
        ? BuyingStatusPage(userId: userId)
        : SupportTicketPage(userId: userId ?? 'Unknown'),
    isStatus ? SellingStatusPage(userId: userId, adData: adData) : SellPage(),
    isStatus
        ? ChatListPage(userId: userId ?? 'Unknown')
        : StatusPage(userId: userId),
    Center(
      child: Text(
        'Profile: User ID ${userId ?? 'Unknown'}',
        style: const TextStyle(fontSize: 16),
      ),
    ),
  ];

  Future<bool> _onWillPop() async {
    if (currentIndex != 0) {
      setState(() {
        currentIndex = 0;
        isStatus = false;
      });
      return false;
    }

    bool? shouldExit = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawerWidget(),
        resizeToAvoidBottomInset: false,
        body: SafeArea(child: _pages[currentIndex]),
        bottomNavigationBar: SafeArea(
          bottom: true,
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
            selectedItemColor: isStatus ? Colors.redAccent : Colors.black,
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
                icon:
                    isStatus
                        ? const Icon(Icons.sell)
                        : FittedBox(
                          fit: BoxFit.contain,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 12,
                              color: Color.fromARGB(255, 12, 9, 233),
                            ),
                          ),
                        ),
                label: isStatus ? 'Selling' : 'Sell',
              ),
              BottomNavigationBarItem(
                icon: Icon(isStatus ? Icons.chat : Icons.stream_outlined),
                label: isStatus ? 'Chats' : 'Status',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.more_vert),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
