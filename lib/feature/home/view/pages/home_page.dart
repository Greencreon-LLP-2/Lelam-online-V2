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
import 'package:lelamonline_flutter/feature/home/view/provider/location_provider.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/banner_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/category_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/product_section_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/search_button_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, RouteAware {
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchDistricts(); // Load districts on init
  }

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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (ApiConstant.token.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'API token is missing. Check ApiConstant.token.';
      });
      developer.log('Error: Empty token in ApiConstant');
      return;
    }

    try {
      final url =
          '${ApiConstant.baseUrl}/list-location.php?token=${ApiConstant.token}';
      developer.log('Fetching districts from: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      developer.log('Response Status: ${response.statusCode}');
      developer.log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        developer.log('Parsed Response Data: $responseData');

        if (responseData['status'] == 'true' && responseData['data'] is List) {
          final List<dynamic> data = responseData['data'];
          final filteredData =
              data.where((item) => item['status'] == '1').toList();
          final locations =
              filteredData.map((item) => LocationData.fromJson(item)).toList();

          if (mounted) {
            context.read<LocationProvider>().setLocations(locations);
            setState(() {
              _isLoading = false;
            });
            developer.log(
              'Updated districts: ${context.read<LocationProvider>().districts}',
            );
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Invalid API response format. Check logs.';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'API error: ${response.statusCode} - ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      developer.log('Full error in _fetchDistricts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              '"dear developer if your read this please leave the company"';
        });
      }
      if (_errorMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red.withOpacity(0.8),
            action: SnackBarAction(label: 'Retry', onPressed: _fetchDistricts),
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    if (kDebugMode) {
      developer.log(
        'Pull-to-refresh triggered, selectedLocationName: ${context.read<LocationProvider>().selectedLocationName}',
      );
    }
    try {
      await _fetchDistricts();
      if (kDebugMode) {
        developer.log('Refresh completed');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error during refresh: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "dear developer if your read this please leave the company",
          ),
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
        developer.log(
          'Navigating to search results with query: $query, search state cleared',
        );
      }
    }
  }

  void _handleTapOutside() {
    if (_searchFocusNode.hasFocus) {
      SearchState().resetOnNavigation();
      _searchFocusNode.unfocus();
      if (kDebugMode) {
        developer.log(
          'Tapped outside search bar (general), cleared search state and unfocused',
        );
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
    final locationProvider = context.watch<LocationProvider>();

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
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : _errorMessage != null
                                  ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Error loading locations'),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 16,
                                        ),
                                        onPressed: _fetchDistricts,
                                      ),
                                    ],
                                  )
                                  : DropdownButton<String>(
                                    value:
                                        locationProvider.selectedLocationName ==
                                                'All Kerala'
                                            ? null
                                            : locationProvider
                                                .selectedLocationName,
                                    hint: const Text('All Kerala'),
                                    items:
                                        locationProvider.districts.map((
                                          district,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value:
                                                district == 'All Kerala'
                                                    ? 'all'
                                                    : district,
                                            child: Text(district),
                                          );
                                        }).toList(),
                                    onChanged:
                                        _isLoading
                                            ? null
                                            : (String? newValue) {
                                              if (mounted && newValue != null) {
                                                final id = locationProvider
                                                    .getLocationIdByName(
                                                      newValue,
                                                    );
                                                locationProvider
                                                    .setSelectedLocation(
                                                      newValue == 'all'
                                                          ? 'All Kerala'
                                                          : newValue,
                                                      id: id,
                                                    );
                                                _handleInteractiveTap(
                                                  'location dropdown',
                                                );
                                                if (kDebugMode) {
                                                  developer.log(
                                                    'Selected district: ${locationProvider.selectedLocationName} (ID: ${locationProvider.selectedLocationId})',
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
                              SearchState().resetOnNavigation();
                              _searchFocusNode.unfocus();
                              context.pushNamed(RouteNames.notificationPage);
                              if (kDebugMode) {
                                developer.log(
                                  'Navigating to notification page, search state cleared',
                                );
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
                        onTapInside:
                            (_) => _handleInteractiveTap('category widget'),
                        child: CategoryWidget(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TapRegion(
                      onTapInside:
                          (_) => _handleInteractiveTap('product section'),
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
