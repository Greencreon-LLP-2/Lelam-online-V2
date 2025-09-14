import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/feature/authentication/views/pages/login_page.dart';
import 'package:lelamonline_flutter/feature/home/view/pages/main_scaffold.dart';
import 'package:lelamonline_flutter/feature/categories/view/categories_page.dart';
import 'package:lelamonline_flutter/feature/shortlist/views/short_list_page.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/selling_status_page.dart';
import 'package:lelamonline_flutter/feature/status/view/pages/buying_status_page.dart';
import 'package:lelamonline_flutter/feature/sell/view/pages/sell_page.dart';
import 'package:lelamonline_flutter/feature/product/view/pages/product_details_page.dart';
import 'package:lelamonline_flutter/feature/faq/view/faq_page.dart';
import 'package:lelamonline_flutter/feature/settings/view/pages/settings_page.dart';
import 'package:lelamonline_flutter/feature/settings/view/pages/edit_profile_page.dart';
import 'package:lelamonline_flutter/feature/notification/view/pages/notification_page.dart';
import 'package:lelamonline_flutter/feature/product/view/pages/seller_profile_page.dart';
import 'package:lelamonline_flutter/feature/sell/view/pages/ad_post_page.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/used_cars_categorie.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/market_used_cars_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.mainscaffold,
  routes: [
    /// PUBLIC ROUTES
    GoRoute(
      path: RouteNames.loginPage,
      name: RouteNames.loginPage,
      builder: (context, state) => LoginPage(
        extra: state.extra is Map<String, dynamic>
            ? state.extra as Map<String, dynamic>
            : null,
      ),
    ),
    GoRoute(
      path: RouteNames.categoriespage,
      name: RouteNames.categoriespage,
      builder: (context, state) => const CategoriesPage(),
    ),
    GoRoute(
      path: RouteNames.buyingStatusPage,
      name: RouteNames.buyingStatusPage,
      builder: (context, state) => const BuyingStatusPage(),
    ),
    GoRoute(
      path: RouteNames.sellpage,
      name: RouteNames.sellpage,
      builder: (context, state) => const SellPage(),
    ),
    GoRoute(
      path: RouteNames.productDetailsPage,
      name: RouteNames.productDetailsPage,
      builder: (context, state) =>
          ProductDetailsPage(product: state.extra),
    ),
    GoRoute(
      path: RouteNames.faqPage,
      name: RouteNames.faqPage,
      builder: (context, state) => const FAQPage(),
    ),
    GoRoute(
      path: RouteNames.settingsPage,
      name: RouteNames.settingsPage,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: RouteNames.editProfilePage,
      name: RouteNames.editProfilePage,
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>?;
        final userId = params?['userId'] as String? ?? '0';
        return EditProfilePage(userId: userId);
      },
    ),
    GoRoute(
      path: RouteNames.notificationPage,
      name: RouteNames.notificationPage,
      builder: (context, state) => const NotificationPage(),
    ),
    GoRoute(
      path: RouteNames.sellerProfilePage,
      name: RouteNames.sellerProfilePage,
      builder: (context, state) => const SellerProfilePage(),
    ),
    GoRoute(
      path: '/ad-post',
      name: RouteNames.adPostPage,
      builder: (context, state) =>
          AdPostPage(extra: state.extra as Map<String, dynamic>?),
    ),
    GoRoute(
      path: RouteNames.usedCarsPage,
      name: RouteNames.usedCarsPage,
      builder: (context, state) => const UsedCarsPage(),
    ),
    GoRoute(
      path: RouteNames.marketPlaceProductDetailsPage,
      name: RouteNames.marketPlaceProductDetailsPage,
      builder: (context, state) =>
          const MarketPlaceProductDetailsPage(product: null),
    ),

    /// MAIN SCAFFOLD (always load)
    GoRoute(
      path: RouteNames.mainscaffold,
      name: RouteNames.mainscaffold,
      builder: (context, state) {
        final loggedUser = context.watch<LoggedUserProvider>();
        return MainScaffold(userId: loggedUser.userData?.userId ?? '');
      },
    ),

    /// SHORTLIST PAGE (optional login)
    GoRoute(
      path: RouteNames.shortlistpage,
      name: RouteNames.shortlistpage,
      builder: (context, state) {
        final loggedUser = context.watch<LoggedUserProvider>();
        return ShortListPage(userId: loggedUser.userData?.userId ?? '');
      },
    ),

    /// SELLING STATUS PAGE (optional login)
    GoRoute(
      path: RouteNames.sellingstatuspage,
      name: RouteNames.sellingstatuspage,
      builder: (context, state) {
        final loggedUser = context.watch<LoggedUserProvider>();
        final extra = state.extra as Map<String, dynamic>?;
        final adData = extra?['adData'];
        return SellingStatusPage(
          userId: loggedUser.userData?.userId ?? '',
          adData: adData,
        );
      },
    ),
  ],

  /// Error fallback
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Something went wrong in navigation')),
  ),
);
