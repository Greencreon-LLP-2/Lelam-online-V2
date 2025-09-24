import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/model/user_model.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/core/service/hive_helper.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/feature/Support/views/support_page.dart';
import 'package:lelamonline_flutter/feature/chat/views/chat_list_page.dart';
import 'package:lelamonline_flutter/feature/home/view/pages/home_page.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/app_drawer.dart';
import 'package:lelamonline_flutter/feature/sell/view/pages/sell_page.dart';
import 'package:lelamonline_flutter/feature/shortlist/views/short_list_page.dart';
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
  Map<String, dynamic>? adData;
  bool isLoading = true;
  bool _hasShownNameDialog = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _nameController = TextEditingController();
  late final LoggedUserProvider _userProvider;
  final HiveHelper _hiveHelper = HiveHelper();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) print('MainScaffold initialized');
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
    adData = widget.adData;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initHasShownFlag().then((_) => _checkAndShowNameDialog());
    });
  }

  Future<void> _initHasShownFlag() async {
    _hasShownNameDialog = await _hiveHelper.getHasShownNameDialog();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _checkAndShowNameDialog() {
    final userProvider = Provider.of<LoggedUserProvider>(
      context,
      listen: false,
    );
    if (kDebugMode) {
      print('Checking dialog conditions:');
      print('userId: ${userProvider.userData?.userId}');
      print('name: ${userProvider.userData?.name}');
      print('hasShownNameDialog: $_hasShownNameDialog');
    }
    if (userProvider.userData?.userId != null &&
        (userProvider.userData?.name == null ||
            userProvider.userData!.name.isEmpty) &&
        !_hasShownNameDialog) {
      _showNameDialog();
    }
  }

  void _showNameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            'Please enter your name to continue',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty &&
                    _nameController.text.length >= 2) {
                  _saveName(context);
                } else {
                  Fluttertoast.showToast(
                    msg: "Please enter a valid name (at least 2 characters)",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red.withOpacity(0.8),
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveName(BuildContext dialogContext) async {
    try {
      final userProvider = Provider.of<LoggedUserProvider>(
        context,
        listen: false,
      );
      final changedFields = <String, String>{
        'user_id': userProvider.userData?.userId ?? '',
        'name': _nameController.text,
      };

      final response = await ApiService().postMultipart(
        url: userProfileUpdate,
        fields: changedFields,
        fileField: "image",
        filePath: null,
      );

      if (response["status"] == true && response["code"] == 200) {
        final updatedResponse = await ApiService().get(
          url: userDetails,
          queryParams: {"user_id": userProvider.userData?.userId ?? ''},
        );

        if (updatedResponse['status'] == true &&
            updatedResponse['code'] == 200) {
          final updatedUserData = UserData.fromJson(
            updatedResponse['data'][0] as Map<String, dynamic>,
          );

          await userProvider.setUser(updatedUserData);
          await _hiveHelper.setHasShownNameDialog(true);
          setState(() {
            _hasShownNameDialog = true;
          });

          Fluttertoast.showToast(
            msg: "Name updated successfully",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            textColor: Colors.white,
            fontSize: 16.0,
          );
          Navigator.of(dialogContext).pop();
        } else {
          throw Exception('Failed to fetch updated user data');
        }
      } else {
        throw Exception(response["data"]?.toString() ?? 'Update failed');
      }
    } catch (e) {
      print('Error in _saveName: $e');
      Fluttertoast.showToast(
        msg: "Error: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  List<Widget> get _pages => [
        HomePage(),
        isStatus ? BuyingStatusPage() : ChatListPage(),
        isStatus ? SellingStatusPage(adData: adData) : SellPage(),
        isStatus ? ShortListPage() : StatusPage(),
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
        if (kDebugMode) print('Back to Home, currentIndex: $currentIndex, isStatus: $isStatus');
      });
      return false;
    }

    bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.exit_to_app,
                  size: 32,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Exit App',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to exit the app?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Exit',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<LoggedUserProvider>(
      context,
      listen: false,
    );
    userId = userProvider.userData?.userId;
    if (kDebugMode) print('Building MainScaffold, currentIndex: $currentIndex, isStatus: $isStatus, page: ${_pages[currentIndex].runtimeType}');
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawerWidget(),
        resizeToAvoidBottomInset: false,
        body: SafeArea(child: _pages[currentIndex]),
        bottomNavigationBar: SafeArea(
          bottom: true,
          child: Container(
            height: 35,
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: currentIndex,
              onTap: (index) {
                if (kDebugMode) print('BottomNavigationBar onTap, index: $index, isStatus: $isStatus');
                if (index == 4) {
                  _scaffoldKey.currentState?.openDrawer();
                  if (kDebugMode) print('Opening drawer');
                  return;
                }
                setState(() {
                  if (index == 3 && !isStatus) {
                    isStatus = true;
                    currentIndex = 1; // Navigate to BuyingStatusPage
                    if (kDebugMode) print('Status clicked, set currentIndex to 1, isStatus: $isStatus, page: ${_pages[currentIndex].runtimeType}');
                  } else {
                    currentIndex = index;
                    if (index == 0) {
                      isStatus = false;
                      if (kDebugMode) print('Home clicked, set currentIndex to 0, isStatus: $isStatus, page: ${_pages[currentIndex].runtimeType}');
                    }
                    if (kDebugMode) print('Set currentIndex to $currentIndex, isStatus: $isStatus, page: ${_pages[currentIndex].runtimeType}');
                  }
                });
              },
              selectedItemColor: isStatus ? Colors.redAccent : Colors.black,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              showSelectedLabels: true,
              selectedLabelStyle: const TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 7,
              ),
              selectedFontSize: 7,
              unselectedFontSize: 7,
              iconSize: 16,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    isStatus
                        ? Icons.add_shopping_cart
                        : Icons.chat_bubble_outline,
                  ),
                  label: isStatus ? 'Buying' : 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: isStatus
                      ? const Icon(Icons.sell)
                      : FittedBox(
                          fit: BoxFit.contain,
                          child: Container(
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
                              size: 10,
                              color: Color.fromARGB(255, 12, 9, 233),
                            ),
                          ),
                        ),
                  label: isStatus ? 'Selling' : 'Sell',
                ),
                BottomNavigationBarItem(
                  icon: Icon(isStatus ? Icons.star : Icons.stream_outlined),
                  label: isStatus ? 'Short List' : 'Status',
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