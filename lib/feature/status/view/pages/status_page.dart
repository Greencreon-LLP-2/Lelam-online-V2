import 'package:flutter/material.dart';

class StatusPage extends StatelessWidget {
  const StatusPage({super.key, String? userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Status')),
      body: Column(
        children: [
          ListView.builder(
            itemBuilder: (context, index) {
              return ListTile(title: Text('Status $index'));
            },
          ),
        ],
      ),
    );
  }
}
