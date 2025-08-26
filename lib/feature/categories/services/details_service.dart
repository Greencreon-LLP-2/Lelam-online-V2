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

  static Future<List<AttributeVariation>> fetchAttributeVariations() async {
    final response = await http.get(Uri.parse(attributeVariations));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((e) => AttributeVariation.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load attribute variations");
    }
  }
}
