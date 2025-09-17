import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lelamonline_flutter/core/router/app_router.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/feature/home/view/provider/product_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

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

  // Initialize user provider
  final loggedUserProvider = LoggedUserProvider();
  await loggedUserProvider.loadUser(); // load from Hive before runApp

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => loggedUserProvider),
        ChangeNotifierProvider(
          create: (_) => ProductProvider()..fetchFeaturedProducts(),
        ),
      ],
      child: const LelamOnlineWidget(),
    ),
  );
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