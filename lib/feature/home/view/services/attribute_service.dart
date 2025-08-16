import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/feature/home/view/models/attribute_model.dart';

class ApiService {
  static const String baseUrl = "https://lelamonline.com/admin/api/v1";
  static const String token = "token";

  // Endpoints
  static const String listBrands = "$baseUrl/list-brand.php?token=$token";
  static const String listBrandModels = "$baseUrl/list-model.php?token=$token";
  static const String listModelVariations =
      "$baseUrl/list-model-variations.php?token=$token";
  static const String listAttributes =
      "$baseUrl/filter-attribute.php?token=$token";
  static const String listAttributeVariations =
      "$baseUrl/filter-attribute-variations.php?token=$token";

  // Generic fetch
  static Future<List<T>> fetchList<T>(
    String url,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == "true") {
        List<dynamic> list = data['data'];
        return list.map((e) => fromJson(e)).toList();
      } else {
        throw Exception("API returned status false");
      }
    } else {
      throw Exception("Failed to load data");
    }
  }

  // Fetch methods
  static Future<List<Brand>> getBrands() =>
      fetchList(listBrands, (json) => Brand.fromJson(json));

  static Future<List<BrandModel>> getBrandModels() =>
      fetchList(listBrandModels, (json) => BrandModel.fromJson(json));

  static Future<List<ModelVariation>> getModelVariations() =>
      fetchList(listModelVariations, (json) => ModelVariation.fromJson(json));

  static Future<List<FilterAttribute>> getAttributes() =>
      fetchList(listAttributes, (json) => FilterAttribute.fromJson(json));

  static Future<List<FilterAttributeVariation>> getAttributeVariations() =>
      fetchList(
        listAttributeVariations,
        (json) => FilterAttributeVariation.fromJson(json),
      );
}
