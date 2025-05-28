import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/feature/categories/view/categories_page.dart';
import 'package:lelamonline_flutter/feature/home/view/pages/main_scaffold.dart';
import 'package:lelamonline_flutter/feature/sell/view/pages/sell_page.dart';
import 'package:lelamonline_flutter/feature/shortlist/views/short_list_page.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/buying_status_page.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/selling_status_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.mainscaffold,
  routes: [
    GoRoute(
      path: RouteNames.mainscaffold,
      builder: (context, state) => const MainScaffold(),
      name: RouteNames.mainscaffold,
    ),
    GoRoute(
      path: RouteNames.categoriespage,
      builder: (context, state) => const CategoriesPage(),
      name: RouteNames.categoriespage,
    ),
    GoRoute(
      path: RouteNames.shortlistpage,
      builder: (context, state) => const ShortListPage(),
      name: RouteNames.shortlistpage,
    ),
    GoRoute(
      path: RouteNames.buyingStatusPage,
      builder: (context, state) => const BuyingStatusPage(),
      name: RouteNames.buyingStatusPage,
    ),
    GoRoute(
      path: RouteNames.sellingstatuspage,
      builder: (context, state) => const SellingStatusPage(),
      name: RouteNames.sellingstatuspage,
    ),
    GoRoute(
      path: RouteNames.sellpage,
      builder: (context, state) => const SellPage(),
      name: RouteNames.sellpage,
    ),
  ],
  errorBuilder:
      (context, state) => Scaffold(
        body: Center(child: Text('Something went wrong in navigation')),
      ),
);
