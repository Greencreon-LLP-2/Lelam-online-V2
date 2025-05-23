import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/feature/home/view/pages/main_scaffold.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: MainScaffold());
  }
}
