import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/feature/categories/view/categories_page.dart';
import 'package:lelamonline_flutter/feature/faq/view/faq_page.dart';
import 'package:lelamonline_flutter/feature/home/view/pages/main_scaffold.dart';
import 'package:lelamonline_flutter/feature/notification/view/pages/notification_page.dart';
import 'package:lelamonline_flutter/feature/product/view/pages/product_details_page.dart';
import 'package:lelamonline_flutter/feature/product/view/pages/seller_profile_page.dart';
import 'package:lelamonline_flutter/feature/sell/view/pages/ad_post_page.dart';
import 'package:lelamonline_flutter/feature/sell/view/pages/sell_page.dart';
import 'package:lelamonline_flutter/feature/settings/view/pages/edit_profile_page.dart';
import 'package:lelamonline_flutter/feature/settings/view/pages/settings_page.dart';
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
    GoRoute(
      path: RouteNames.productDetailsPage,
      builder: (context, state) => const ProductDetailsPage(),
      name: RouteNames.productDetailsPage,
    ),
    GoRoute(
      path: RouteNames.faqPage,
      builder: (context, state) => const FAQPage(),
      name: RouteNames.faqPage,
    ),
    GoRoute(
      path: RouteNames.settingsPage,
      builder: (context, state) => const SettingsPage(),
      name: RouteNames.settingsPage,
    ),
    GoRoute(
      path: RouteNames.editProfilePage,
      builder: (context, state) => const EditProfilePage(),
      name: RouteNames.editProfilePage,
    ),
    GoRoute(
      path: RouteNames.notificationPage,
      builder: (context, state) => const NotificationPage(),
      name: RouteNames.notificationPage,
    ),
    GoRoute(
      path: RouteNames.sellerProfilePage,
      builder: (context, state) => const SellerProfilePage(),
      name: RouteNames.sellerProfilePage,
    ),
    GoRoute(
      path: RouteNames.adPostPage,
      builder:
          (context, state) =>
              AdPostPage(category: state.extra as String? ?? ''),
      name: RouteNames.adPostPage,
    ),
  ],
  errorBuilder:
      (context, state) => Scaffold(
        body: Center(child: Text('Something went wrong in navigation')),
      ),
);
