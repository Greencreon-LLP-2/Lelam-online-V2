import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

class SoldPage extends StatelessWidget {
  final String? userId;
  final Map<String, dynamic>? adData;

  const SoldPage({super.key, this.userId, this.adData});

  Future<List<dynamic>> _fetchSoldItems(String userId, String token) async {
    try {
      final response = await ApiService().get(
        url: '$baseUrl/sold.php',
        queryParams: {'token': token, 'user_id': userId},
      );
      if (kDebugMode) print('Sold items response: $response');

      if (response['status'] == true && response['code'] == 200) {
        return response['data'] as List<dynamic>;
      } else {
        throw Exception(response['message']?.toString() ?? 'No sold items');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching sold items: $e');
      throw Exception('Error fetching sold items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<LoggedUserProvider>(
      context,
      listen: false,
    );

    if (!userProvider.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              context.pushNamed(RouteNames.loginPage);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Log In to View Sold Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    final effectiveUserId = userId ?? userProvider.userData?.userId ?? '';
    // Retrieve from LoggedUserProvider or HiveHelper

    if (effectiveUserId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: Text(
            'User ID is missing',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<dynamic>>(
        future: _fetchSoldItems(effectiveUserId, token),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sell, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No sold items found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have no sold items at this time',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sell, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No sold items found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have no sold items at this time',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final soldItems = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: soldItems.length,
            itemBuilder: (context, index) {
              final item = soldItems[index] as Map<String, dynamic>;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    item['title']?.toString() ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Price: ${item['price']?.toString() ?? 'N/A'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.sell, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
