// product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/feature/home/view/models/feature_list_model.dart';

class ProductService {
  static Future<List<FeatureListModel>> fetchFeaturedProducts() async {
    final headers = {
      'token': '5cb2c9b569416b5db1604e0e12478ded', 
      'Cookie': 'PHPSESSID=koib3m1uifk1b4ucclf5dsegpe',
    };

    final response = await http.get(
      Uri.parse('https://lelamonline.com/admin/api/v1/list-feature-post.php'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) =>FeatureListModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }
}
