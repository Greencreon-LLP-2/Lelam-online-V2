import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/router/app_router.dart';
import 'package:lelamonline_flutter/feature/home/view/provider/product_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ProductProvider()..fetchFeaturedProducts(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}
