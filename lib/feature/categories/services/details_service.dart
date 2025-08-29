import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/feature/categories/models/details_model.dart';
//import 'package:lelamonline_flutter/feature/home/view/models/attribute_model.dart' hide ModelVariation, BrandModel, Brand;

class ApiService {
  static Future<List<Brand>> fetchBrands() async {
    final response = await http.get(Uri.parse(brand));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List).map((e) => Brand.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load brands");
    }
  }

  static Future<List<BrandModel>> fetchBrandModels() async {
    final response = await http.get(Uri.parse(brandModel));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List).map((e) => BrandModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load brand models");
    }
  }

  static Future<List<ModelVariation>> fetchModelVariations() async {
    final response = await http.get(Uri.parse(modelVariations));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((e) => ModelVariation.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load model variations");
    }
  }

  static Future<List<Attribute>> fetchAttributes() async {
    final response = await http.get(Uri.parse(attribute));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List).map((e) => Attribute.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load attributes");
    }
  }

  static Future<List<AttributeVariation>> fetchAttributeVariations(
    Map<String, dynamic> filters,
  ) async {
    List<AttributeVariation> allVariations = [];
    for (String attributeId in filters.keys) {
      try {
        final response = await http.get(
          Uri.parse(
            '$baseUrl/filter-attribute-variations.php?token=$token&attribute_id=$attributeId',
          ),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print(
            'Attribute Variations for ID $attributeId: ${data['data']}',
          ); // Debug
          if (data['data'] is List) {
            allVariations.addAll(
              (data['data'] as List)
                  .map((e) => AttributeVariation.fromJson(e))
                  .toList(),
            );
          } else {
            print(
              'Skipping attribute_id=$attributeId: data is not a list (${data['data']})',
            );
          }
        } else {
          print(
            'Failed to load variations for attribute_id=$attributeId: ${response.statusCode}',
          );
        }
      } catch (e) {
        print('Error fetching variations for attribute_id=$attributeId: $e');
      }
    }
    return allVariations;
  }

  
}



