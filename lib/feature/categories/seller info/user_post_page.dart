import 'package:flutter/material.dart';

class UserPostsPage extends StatelessWidget {
  final String userId;

  const UserPostsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Posts'),
      ),
      body: const Center(
        child: Text('User posts will be displayed here'),
      ),
    );
  }
}