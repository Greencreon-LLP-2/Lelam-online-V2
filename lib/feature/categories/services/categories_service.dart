import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/feature/categories/models/categories_model.dart';

class CategoryService {
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse(categories));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle actual API response structure
        if (data is List) {  // Directly a list of categories
          return data.map((item) => CategoryModel.fromJson(item)).toList();
        } 
        else if (data is Map<String, dynamic> && data['data'] is List) {
          return (data['data'] as List)
              .map((item) => CategoryModel.fromJson(item))
              .toList();
        } 
        else {
          throw Exception('Invalid response format: ${response.body}');
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}