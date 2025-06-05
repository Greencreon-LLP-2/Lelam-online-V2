import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/districts.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/banner_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/category_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/product_section_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/search_button_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedDistrict;

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
            spacing: 16,
            children: [
              //!TOP section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    //!Location section
                    Row(
                      children: [
                        Icon(Icons.location_on),
                        SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _selectedDistrict,
                          hint: Text('Select District'),
                          items:
                              districts.map((district) {
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
                          underline: SizedBox(),
                        ),
                      ],
                    ),
                    Spacer(),
                    //!Notification section
                    IconButton(
                      onPressed: () {
                        context.pushNamed(RouteNames.notificationPage);
                      },
                      icon: Icon(Icons.notifications),
                    ),
                    IconButton(
                      onPressed: () {
                        context.pushNamed(RouteNames.loginPage);
                      },
                      icon: Icon(Icons.person),
                    ),
                  ],
                ),
              ),
              //!Search section
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

              //!Banner section
              BannerWidget(),

              //!Category section
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: CategoryWidget(),
              ),

              //!Product section
              ProductSectionWidget(searchQuery: _searchQuery),
            ],
          ),
        ),
      ),
    );
  }
}
