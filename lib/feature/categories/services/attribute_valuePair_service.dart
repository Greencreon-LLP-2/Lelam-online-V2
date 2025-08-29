import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';

class AttributeValuePair {
  final String attributeName;
  final String attributeValue;

  AttributeValuePair({
    required this.attributeName,
    required this.attributeValue,
  });

  factory AttributeValuePair.fromJson(Map<String, dynamic> json) {
    return AttributeValuePair(
      attributeName: json['attribute_name'] ?? '',
      attributeValue: json['attribute_value'] ?? '',
    );
  }
}

class AttributeValueService {
  static Future<List<AttributeValuePair>> fetchAttributeValuePairs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/post-attribute-values.php?token=$token'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Attribute Value Pairs Response: ${data['data']}'); // Debug
        if (data['status'] == 'true' && data['data'] is List) {
          return (data['data'] as List)
              .map((e) => AttributeValuePair.fromJson(e))
              .toList();
        } else {
          print('Invalid response format: ${data['status']}');
          return [];
        }
      } else {
        print('Failed to load attribute value pairs: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching attribute value pairs: $e');
      return [];
    }
  }
}