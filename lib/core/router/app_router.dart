import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/feature/authentication/views/pages/login_page.dart';
import 'package:lelamonline_flutter/feature/authentication/views/pages/otp_verification_page.dart';
import 'package:lelamonline_flutter/feature/authentication/views/pages/signup_page.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/market_used_cars_page.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/used_cars_categorie.dart';
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
import 'package:lelamonline_flutter/utils/please_login_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.mainscaffold,
  routes: [
    GoRoute(
      path: RouteNames.mainscaffold,
      name: RouteNames.mainscaffold,
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>?;
        return MainScaffold(userId: params?['userId'] as String?);
      },
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
      name: RouteNames.sellingstatuspage,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SellingStatusPage(
          userId: extra?['userId'],
          adData: extra?['adData'],
        );
      },
    ),
    GoRoute(
      path: RouteNames.sellpage,
      builder: (context, state) => const SellPage(),
      name: RouteNames.sellpage,
    ),
    GoRoute(
      path: RouteNames.productDetailsPage,
      builder: (context, state) {
        final dynamic product = state.extra;
        return ProductDetailsPage(product: product);
      },
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
      path: '/ad-post',
      name: RouteNames.adPostPage,
      builder:
          (context, state) => AdPostPage(
            extra: state.extra as Map<String, dynamic>?, // Pass extra correctly
          ),
    ),
    GoRoute(
      path: '/login',
      name: RouteNames.loginPage,
      builder:
          (context, state) => LoginPage(
            extra:
                state.extra is Map<String, dynamic>
                    ? state.extra as Map<String, dynamic>
                    : null,
          ),
    ),
    GoRoute(
      path: RouteNames.signupPage,
      builder: (context, state) => const SignUpPage(),
      name: RouteNames.signupPage,
    ),
    GoRoute(
      path: '/otp-verification',
      name: RouteNames.otpVerificationPage,
      builder:
          (context, state) => OtpVerificationPage(
            extra:
                state.extra is Map<String, dynamic>
                    ? state.extra as Map<String, dynamic>
                    : {},
          ),
    ),
    GoRoute(
      path: RouteNames.usedCarsPage,
      builder: (context, state) => const UsedCarsPage(),
      name: RouteNames.usedCarsPage,
    ),
    GoRoute(
      path: RouteNames.marketPlaceProductDetailsPage,
      builder:
          (context, state) =>
              const MarketPlaceProductDetailsPage(product: null),
      name: RouteNames.marketPlaceProductDetailsPage,
    ),
    GoRoute(
      path: RouteNames.pleaseLoginPage,
      builder: (context, state) => const PleaseLoginPage(),
      name: RouteNames.pleaseLoginPage,
    ),
  ],
  errorBuilder:
      (context, state) => Scaffold(
        body: Center(child: Text('Something went wrong in navigation')),
      ),
);
