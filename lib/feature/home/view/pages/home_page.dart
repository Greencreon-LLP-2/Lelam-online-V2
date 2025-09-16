import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/utils/districts.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/banner_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/category_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/product_section_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/search_button_widget.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedDistrict;
  String? userId;
  late final LoggedUserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
    if (kDebugMode) {
      print('HomePage initialized, userId: ${_userProvider.userData?.userId}');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Handle pull-to-refresh
  Future<void> _onRefresh() async {
    if (kDebugMode) {
      print(
        'Pull-to-refresh triggered, searchQuery: $_searchQuery, selectedDistrict: $_selectedDistrict',
      );
    }
    try {
      // Optionally reset search query and district for a full refresh
      // setState(() {
      //   _searchQuery = '';
      //   _selectedDistrict = null;
      //   _searchController.clear();
      // });

      // Trigger data reload for widgets
      // Assuming ProductSectionWidget, BannerWidget, and CategoryWidget
      // use providers or internal state to fetch data, rebuild them
      setState(() {
        // Force rebuild of stateful widgets
        _searchQuery = _searchQuery; // Trigger ProductSectionWidget refresh
      });

      // Simulate API call or data refresh (replace with actual logic)
      await Future.delayed(const Duration(seconds: 1)); // Mock delay
      if (kDebugMode) {
        print('Refresh completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during refresh: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh: $e'),
          backgroundColor: Colors.red.withOpacity(0.8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: Theme.of(context).primaryColor,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(), // Ensure scrollable for refresh
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _selectedDistrict,
                              hint: const Text('All Kerala'),
                              items:
                                  districts.map((district) {
                                    return DropdownMenuItem<String>(
                                      value: district,
                                      child: Text(district),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                if (mounted) {
                                  setState(() {
                                    _selectedDistrict = newValue;
                                  });
                                  if (kDebugMode) {
                                    print(
                                      'Selected district: $_selectedDistrict',
                                    );
                                  }
                                }
                              },
                              underline: const SizedBox(),
                              icon: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            context.pushNamed(RouteNames.notificationPage);
                            if (kDebugMode) {
                              print('Navigating to notification page');
                            }
                          },
                          icon: const Icon(Icons.notifications),
                        ),
                      ],
                    ),
                  ),
                  if (_userProvider.isLoggedIn) const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SearchButtonWidget(
                      controller: _searchController,
                      onSearch: (query) {
                        if (mounted) {
                          setState(() {
                            _searchQuery = query;
                          });
                          if (kDebugMode) {
                            print('Search query updated: $_searchQuery');
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 5),
                  const BannerWidget(),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: CategoryWidget(),
                  ),
                  SizedBox(
                    child: Row(
                      children: [
                        SizedBox(width: 10,),
                        Text(
                          'Handpicked Deals',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  ProductSectionWidget(searchQuery: _searchQuery),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
