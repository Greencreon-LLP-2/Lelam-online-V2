import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart' as ApiConstant;
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
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

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin, RouteAware {
  final FocusNode _searchFocusNode = FocusNode();
  String? _selectedDistrict;
  List<String> _districts = ['All Kerala'];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    SearchState().resetOnNavigation();
    _searchFocusNode.unfocus();
    if (kDebugMode) {
      developer.log('Navigating away from HomePage, cleared search state');
    }
  }

  Future<void> _fetchDistricts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConstant.baseUrl}/list-location.php?token=${ApiConstant.token}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'true' && responseData['data'] is List) {
          final List<dynamic> data = responseData['data'];
          setState(() {
            _districts = ['All Kerala'] +
                data
                    .where((item) => item['status'] == '1')
                    .map((item) => item['name'].toString())
                    .toList();
            _isLoading = false;
          });
          if (kDebugMode) {
            developer.log('Districts fetched: $_districts');
          }
        } else {
          throw Exception('Invalid response: ${responseData['status']}');
        }
      } else {
        throw Exception('Failed to load districts: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load districts: $e';
      });
      if (kDebugMode) {
        developer.log('Error fetching districts: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Failed to load districts'),
          backgroundColor: Colors.red.withOpacity(0.8),
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    if (kDebugMode) {
      developer.log('Pull-to-refresh triggered, selectedDistrict: $_selectedDistrict');
    }
    try {
      await _fetchDistricts();
      await Future.delayed(const Duration(seconds: 1));
      if (kDebugMode) {
        developer.log('Refresh completed');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error during refresh: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh: $e'),
          backgroundColor: Colors.red.withOpacity(0.8),
        ),
      );
    }
  }

  void _onSearch(String query) {
    if (query.isNotEmpty) {
      SearchState().resetOnNavigation();
      _searchFocusNode.unfocus();
      context.pushNamed('searchResults', queryParameters: {'query': query});
      if (kDebugMode) {
        developer.log('Navigating to search results with query: $query, search state cleared');
      }
    }
  }

  void _handleTapOutside() {
    if (_searchFocusNode.hasFocus) {
      SearchState().resetOnNavigation();
      _searchFocusNode.unfocus();
      if (kDebugMode) {
        developer.log('Tapped outside search bar (general), cleared search state and unfocused');
      }
    }
  }

  void _handleInteractiveTap(String source) {
    if (_searchFocusNode.hasFocus) {
      SearchState().resetOnNavigation();
      _searchFocusNode.unfocus();
      if (kDebugMode) {
        developer.log('Tapped on $source, cleared search state and unfocused');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userProvider = context.watch<LoggedUserProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: _handleTapOutside,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: Theme.of(context).primaryColor,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on),
                              const SizedBox(width: 8),
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : _errorMessage != null
                                      ? const Text('Error loading locations')
                                      : DropdownButton<String>(
                                          value: _selectedDistrict,
                                          hint: const Text('All Kerala'),
                                          items: _districts.map((district) {
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
                                              _handleInteractiveTap('location dropdown');
                                              if (kDebugMode) {
                                                developer.log('Selected district: $_selectedDistrict');
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
                              SearchState().resetOnNavigation();
                              _searchFocusNode.unfocus();
                              context.pushNamed(RouteNames.notificationPage);
                              if (kDebugMode) {
                                developer.log('Navigating to notification page, search state cleared');
                              }
                            },
                            icon: const Icon(Icons.notifications),
                          ),
                        ],
                      ),
                    ),
                    if (userProvider.isLoggedIn) const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SearchButtonWidget(
                        focusNode: _searchFocusNode,
                        onSearch: _onSearch,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const BannerWidget(),
                      const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 0),
                      child: TapRegion(
                        onTapInside: (_) => _handleInteractiveTap('category widget'),
                        child: CategoryWidget(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TapRegion(
                      onTapInside: (_) => _handleInteractiveTap('product section'),
                      child: ProductSectionWidget(searchQuery: ''),
                    ),
                    
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();