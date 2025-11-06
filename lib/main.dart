import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_meta_sdk/flutter_meta_sdk.dart'; // Added for Meta SDK integration
import 'package:lelamonline_flutter/core/router/app_router.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/service/core_data_notifier.dart';

import 'package:lelamonline_flutter/core/service/push_notification_service.dart';
import 'package:lelamonline_flutter/feature/home/view/provider/location_provider.dart';
import 'package:lelamonline_flutter/feature/home/view/provider/product_provider.dart';
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart'; // Added for OneSignal integration

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Initialize Meta SDK and log app activation
  final metaSdk = FlutterMetaSdk();
  metaSdk.logEvent(name: 'fb_mobile_activate_app');

  // Initialize OneSignal for push notifications
  OneSignal.initialize("c-a9d3-4987-beff-64dc671f75d5");

  // Enable verbose logging for debugging (remove in production)
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

  // Request permission (silent prompt)
  OneSignal.Notifications.requestPermission(false);

  // Handle notification received (display it)
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    event.notification.display();
  });

  // Handle notification opened (e.g., navigate)
  OneSignal.Notifications.addClickListener((event) {
    print('Notification clicked: ${event.notification.title}');
    // Add navigation logic here, e.g., using appRouter
  });

  // Handle permission changes (corrected to addPermissionObserver)
  OneSignal.Notifications.addPermissionObserver((state) {
  });

  // Note: The OneSignal REST API key ("YjYzOGJjN2UtMTk5Zi00YjMwLTlhZTAtOGZlZWJiZmIwYzMw") is typically used server-side for sending notifications.
  // If needed in your PushNotificationService, pass it there (e.g., for backend integration).

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge display
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize AwesomeNotifications (kept for local notifications; can coexist with OneSignal for push)
  await AwesomeNotificationService().initialize();

  // Initialize user provider
  final loggedUserProvider = LoggedUserProvider();
  await loggedUserProvider.loadUser();

  // Initialize core data provider
  final coreDataNotifier = CoreDataNotifier();

  // Set token (you might get this from shared preferences or your auth system)
  final String token = await _getAuthToken();
  coreDataNotifier.setToken(token);

  // Load core data
  await coreDataNotifier.loadCoreData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => loggedUserProvider),
        ChangeNotifierProvider(create: (_) => coreDataNotifier),
        ChangeNotifierProvider(
          create: (_) => ProductProvider()..fetchFeaturedProducts(),
        ),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const LelamOnlineWidget(),
    ),
  );
}

Future<String> _getAuthToken() async {
  // Implement your token retrieval logic here
  // This could be from SharedPreferences, secure storage, etc.
  return 'your_auth_token_here';
}

class LelamOnlineWidget extends StatelessWidget {
  const LelamOnlineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}