import 'package:flutter/material.dart';

class ShortListPage extends StatelessWidget {
  const ShortListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("Short list")),
      body: Center(child: Text("Short list page")),
    );
  }
}
