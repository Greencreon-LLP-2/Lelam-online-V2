import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/feature/home/view/models/feature_list_model.dart';

class ProductProvider with ChangeNotifier {
  List<FeatureListModel> _products = [];
  bool _isLoading = true;
  String? _error;
  bool _hasFeaturedProducts = false;

  List<FeatureListModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasFeaturedProducts => _hasFeaturedProducts;

  Future<void> fetchFeaturedProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.https(
        'lelamonline.com',
        '/admin/api/v1/list-feature-post.php',
        {'token': '5cb2c9b569416b5db1604e0e12478ded'},
      );
      final cookieJar = <String, String>{
        'Cookie': 'PHPSESSID=koib3m1uifk1b4ucclf5dsegpe',
      };

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...cookieJar,
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        if (decodedResponse is List) {
          _products = decodedResponse
              .map<FeatureListModel>(
                (json) => FeatureListModel.fromJson(json),
              )
              .toList();
          _hasFeaturedProducts = _products.isNotEmpty;
        } else if (decodedResponse is Map) {
          if (decodedResponse['status'] == 'error') {
            throw Exception('API Error: ${decodedResponse['message']}');
          } else if (decodedResponse['data'] is List) {
            _products = (decodedResponse['data'] as List)
                .map<FeatureListModel>(
                  (json) => FeatureListModel.fromJson(json),
                )
                .toList();
            _hasFeaturedProducts = _products.isNotEmpty;
          }
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}\nResponse: ${response.body}',
        );
      }
    } catch (e) {
      _error = 'Failed to load products: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  List<FeatureListModel> getFilteredProducts(String searchQuery) {
    if (searchQuery.trim().isEmpty) {
      return _products;
    }
    final query = searchQuery.toLowerCase();
    return _products.where((product) {
      return product.title.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.price.contains(query) ||
          product.auctionStartingPrice.contains(query);
    }).toList();
  }
}