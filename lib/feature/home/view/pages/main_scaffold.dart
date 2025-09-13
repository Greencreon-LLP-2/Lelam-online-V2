import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/Support/views/support_page.dart';
import 'package:lelamonline_flutter/feature/chat/views/chat_list_page.dart';
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
  String? sessionId;
  Map<String, dynamic>? adData;
  bool isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    adData = widget.adData;
    _loadUserId();
  }

  @override
  void didUpdateWidget(MainScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      setState(() {
        userId = widget.userId;
        isLoading = false;
      });
      _loadUserId(); // Reload from SharedPreferences to ensure consistency
    }
  }

  Future<void> _loadUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? widget.userId;
      sessionId = prefs.getString('sessionId');
      isLoading = false;
    });
    if (kDebugMode) {
      print('Loaded userId: $userId');
      print('Loaded sessionId: $sessionId');
    }
  }

  bool get _isUserIdValid => userId != null;

  List<Widget> get _pages => [
        HomePage(userId: userId),
        isStatus
            ? (_isUserIdValid
                ? BuyingStatusPage(userId: userId!)
                : const Center(child: Text('Please log in to view Buying Status')))
            : (_isUserIdValid
                ? SupportTicketPage(userId: userId!)
                : const Center(child: Text('Please log in to access Support'))),
        isStatus
            ? (_isUserIdValid
                ? SellingStatusPage(userId: userId!, adData: adData)
                : const Center(child: Text('Please log in to view Selling Status')))
            : (_isUserIdValid
                ? SellPage(userId: userId!)
                : const Center(child: Text('Please log in to access Sell'))),
        isStatus
            ? (_isUserIdValid
                ? ChatListPage(userId: userId!, sessionId: sessionId ?? '')
                : const Center(child: Text('Please log in to access Chats')))
            : (_isUserIdValid
                ? StatusPage(userId: userId!)
                : const Center(child: Text('Please log in to view Status'))),
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
      builder: (context) => AlertDialog(
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

  void _navigateToLogin() {
    GoRouter.of(context).pushNamed(RouteNames.loginPage).then((value) {
      if (value != null && value is String) {
        setState(() {
          userId = value; // Update userId with the returned value
          isLoading = false;
        });
      }
      _loadUserId(); // Reload from SharedPreferences to ensure consistency
    });
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to access this feature'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToLogin();
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawerWidget(userId: userId),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pages[currentIndex],
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

                  if (index != 0 && userId == null) {
                    _showLoginDialog();
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
                    icon: isStatus
                        ? const Icon(Icons.sell)
                        : Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 2,
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
        ),
      ),
    );
  }
}