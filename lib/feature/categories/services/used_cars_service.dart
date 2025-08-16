import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/feature/categories/models/used_cars_model.dart';

class MarketplaceService {
  static const String baseUrl = 'https://lelamonline.com/admin/api/v1';
  static const String token = '5cb2c9b569416b5db1604e0e12478ded';

  Future<List<MarketplacePost>> fetchPosts({
    required String categoryId,
    required String userZoneId,
  }) async {
    final url =
        '$baseUrl/list-category-post-marketplace.php?token=$token&category_id=$categoryId&user_zone_id=$userZoneId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MarketplacePost.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }
}
