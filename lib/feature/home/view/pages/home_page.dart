import 'package:flutter/material.dart';
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
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
    super.initState();
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
        child: Padding(
          padding: const EdgeInsets.only(
            top: 16,
          ), // Adds padding to avoid system UI
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
                ProductSectionWidget(searchQuery: _searchQuery),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
//