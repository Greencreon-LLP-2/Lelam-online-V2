import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/utils/districts.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/banner_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/category_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/product_section_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/search_button_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final String? userId;

  const HomePage({super.key, this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedDistrict;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? widget.userId ?? 'Unknown';
    });
    if (kDebugMode) {
      print('HomePage - Loaded userId: $userId');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                          hint: Text(userId != null && userId != 'Unknown'
                              ? 'User ID: $userId'
                              : 'All Kerala'),
                          items: districts.map((district) {
                            return DropdownMenuItem<String>(
                              value: district,
                              child: Text(district),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDistrict = newValue;
                            });
                          },
                          underline: const SizedBox(),
                          icon: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        context.pushNamed(RouteNames.notificationPage, extra: {'userId': userId});
                      },
                      icon: const Icon(Icons.notifications),
                    ),
                  ],
                ),
              ),
              if (userId != null && userId != 'Unknown')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Logged in as User ID: $userId',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchButtonWidget(
                  controller: _searchController,
                  onSearch: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                ),
              ),
              const BannerWidget(),
              // Pass userId to CategoryWidget
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: CategoryWidget(userId: userId),
              ),
              ProductSectionWidget(searchQuery: _searchQuery, userId: userId),
            ],
          ),
        ),
      ),
    );
  }
}