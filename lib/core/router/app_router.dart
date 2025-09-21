import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/utils/splash_page.dart';
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
  initialLocation: '/', // Set SplashScreen as the initial route
  routes: [
    // Splash Screen Route
    GoRoute(
      path: RouteNames.splashPage,
      name: RouteNames.splashPage,
      builder: (context, state) => const SplashScreen(),
    ),

    /// PUBLIC ROUTES
    GoRoute(
      path: RouteNames.loginPage,
      name: RouteNames.loginPage,
      builder: (context, state) => LoginPage(
        extra: state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null,
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
  builder: (context, state) {
    final loggedUser = context.watch<LoggedUserProvider>();
    // Extract query parameters using queryParameters
    final initialTab = int.tryParse(state.uri.queryParameters['initialTab'] ?? '0') ?? 0;
    final initialStatus = state.uri.queryParameters['initialStatus'];
    final postId = state.uri.queryParameters['postId'];
    final bidId = state.uri.queryParameters['bidId'];
    final userId = loggedUser.isLoggedIn ? loggedUser.userData?.userId : null;

    if (loggedUser.isLoggedIn) {
      return BuyingStatusPage(
        userId: userId,
        initialTab: initialTab,
        initialStatus: initialStatus,
        postId: postId,
        bidId: bidId,
      );
    }
    return LoginPage();
  },
),
    GoRoute(
      path: RouteNames.sellpage,
      name: RouteNames.sellpage,
      builder: (context, state) => const SellPage(),
    ),
    GoRoute(
      path: RouteNames.productDetailsPage,
      name: RouteNames.productDetailsPage,
      builder: (context, state) => ProductDetailsPage(product: state.extra),
    ),
    GoRoute(
      path: RouteNames.faqPage,
      name: RouteNames.faqPage,
      builder: (context, state) => const FAQPage(),
    ),
    GoRoute(
      path: RouteNames.settingsPage,
      name: RouteNames.settingsPage,
      builder: (context, state) {
        final loggedUser = context.watch<LoggedUserProvider>();
        if (loggedUser.isLoggedIn) {
          return SettingsPage();
        }
        return LoginPage();
      },
    ),
    GoRoute(
      path: RouteNames.editProfilePage,
      name: RouteNames.editProfilePage,
      builder: (context, state) {
        final loggedUser = context.watch<LoggedUserProvider>();
        if (loggedUser.isLoggedIn) {
          return EditProfilePage();
        }
        return LoginPage();
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
      builder: (context, state) => AdPostPage(extra: state.extra as Map<String, dynamic>?),
    ),
    GoRoute(
      path: RouteNames.usedCarsPage,
      name: RouteNames.usedCarsPage,
      builder: (context, state) => const UsedCarsPage(),
    ),
    GoRoute(
      path: RouteNames.marketPlaceProductDetailsPage,
      name: RouteNames.marketPlaceProductDetailsPage,
      builder: (context, state) => const MarketPlaceProductDetailsPage(product: null),
    ),

    /// MAIN SCAFFOLD (always load)
    GoRoute(
      path: RouteNames.mainscaffold,
      name: RouteNames.mainscaffold,
      builder: (context, state) {
        final loggedUser = context.watch<LoggedUserProvider>();
        return MainScaffold();
      },
    ),

    /// SHORTLIST PAGE (optional login)
    GoRoute(
      path: RouteNames.shortlistpage,
      name: RouteNames.shortlistpage,
      builder: (context, state) {
        final loggedUser = context.watch<LoggedUserProvider>();
        if (loggedUser.isLoggedIn) {
          return ShortListPage(userId: loggedUser.userData?.userId);
        }
        return LoginPage();
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

        if (loggedUser.isLoggedIn) {
          return SellingStatusPage(
            userId: loggedUser.userData?.userId ?? '',
            adData: adData,
          );
        }
        return LoginPage();
      },
    ),
  ],

  /// Error fallback
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Something went wrong in navigation')),
  ),
);