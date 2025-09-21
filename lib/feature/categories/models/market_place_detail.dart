import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/feature/categories/models/model_variation_model.dart';
import 'package:lelamonline_flutter/feature/categories/models/used_cars_model.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/market_used_cars_page.dart';


class MarketplaceService2 {
  static const String baseUrl = 'https://lelamonline.com/admin/api/v1';
  static const String token = '5cb2c9b569416b5db1604e0e12478ded';

  static final Map<String, List<MarketplacePost>> _postsCache = {};
  // Add cache for model variations
  static final Map<String, ModelVariation> _modelVariationsCache = {};

  Future<List<MarketplacePost>> fetchPosts({
    required String categoryId,
    required String userZoneId,
    required String listingType,
    required String userId,
  }) async {
    final cacheKey = '$categoryId-$userZoneId-$listingType-$userId';
    final endpoint =
        listingType == 'auction'
            ? '$baseUrl/list-category-post-auction.php'
            : '$baseUrl/list-category-post-marketplace.php';
    final url =
        listingType == 'auction'
            ? '$endpoint?token=$token&category_id=$categoryId&user_id=$userId&user_zone_id=$userZoneId'
            : '$endpoint?token=$token&category_id=$categoryId&user_zone_id=$userZoneId';

    try {
      print('Fetching posts from: $url');
      final response = await http.get(Uri.parse(url));
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is List) {
          final posts =
              decodedBody
                  .map((json) => MarketplacePost.fromJson(json))
                  .toList();
          _postsCache[cacheKey] = posts;
          return posts;
        } else if (decodedBody is Map && decodedBody.containsKey('data')) {
          if (decodedBody['data'] is List) {
            final data = decodedBody['data'] as List;
            final posts =
                data.map((json) => MarketplacePost.fromJson(json)).toList();
            _postsCache[cacheKey] = posts;
            return posts;
          } else if (decodedBody['data'] ==
              'Please accept live auction terms') {
            throw Exception('Please accept live auction terms');
          } else if (decodedBody['data'] == 'Data not found') {
            print('No posts found for $listingType');
            _postsCache[cacheKey] = [];
            return [];
          } else {
            throw Exception('Unexpected data format: ${decodedBody['data']}');
          }
        } else {
          throw Exception('Unexpected API response format');
        }
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchPosts ($listingType): $e');
      throw Exception('Error fetching posts: $e');
    }
  }

  Future<String> fetchAuctionTerms() async {
    final url = '$baseUrl/live-auction-terms.php?token=$token';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map &&
            decodedBody.containsKey('data') &&
            decodedBody['data'] is List &&
            decodedBody['data'].isNotEmpty) {
          final details = decodedBody['data'][0]['details']?.toString() ?? '';
          if (details.isEmpty) {
            throw Exception('No terms details found in response');
          }
          return details;
        } else {
          throw Exception('Unexpected terms response format');
        }
      } else {
        throw Exception('Failed to load terms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching auction terms: $e');
      throw Exception('Error fetching terms: $e');
    }
  }

  Future<bool> acceptAuctionTerms(String userId) async {
    final url =
        '$baseUrl/live-auction-terms-accept.php?token=$token&user_id=$userId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody['status'] == 'true') {
          return true;
        } else {
          throw Exception('Failed to accept terms: ${decodedBody['data']}');
        }
      } else {
        throw Exception('Failed to accept terms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error accepting auction terms: $e');
      return false;
    }
  }

  Future<Map<String, String>> fetchPostAttributeValues(String postId) async {
    final url =
        '$baseUrl/post-attribute-values.php?token=$token&post_id=$postId';
    try {
      print('Fetching post attribute values from: $url');
      final response = await http.get(Uri.parse(url));
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody['status'] == 'true' && decodedBody['data'] is List) {
          final Map<String, String> uniqueAttributes = {};
          for (var item in decodedBody['data']) {
            if (item['attribute_name']?.isNotEmpty == true &&
                item['attribute_value']?.isNotEmpty == true) {
              uniqueAttributes[item['attribute_name']] =
                  item['attribute_value'];
            }
          }
          return uniqueAttributes;
        } else {
          print('Invalid response: ${decodedBody['data']}');
          return {};
        }
      } else {
        throw Exception('Failed to fetch attributes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching attributes for post $postId: $e');
      return {};
    }
  }

  Future<Map<String, String>> fetchPostDetailsWithIcons(String postId) async {
    final url =
        '$baseUrl/post-details-with-icons.php?token=$token&post_id=$postId';
    try {
      print('Fetching post details with icons from: $url');
      final response = await http.get(Uri.parse(url));
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody['status'] == 'true' && decodedBody['data'] is List) {
          final Map<String, String> uniqueAttributes = {};
          for (var item in decodedBody['data']) {
            final icon = item['icon']?.toString() ?? '';
            final value = item['value']?.toString() ?? '';
            if (value.isNotEmpty) {
              // Map the icon to the corresponding attribute name
              switch (icon) {
                case 'bi-calendar-minus-fill':
                  uniqueAttributes['Year'] = value;
                  break;
                case 'bi-person-fill':
                  uniqueAttributes['No of owners'] = value;
                  break;
                case 'bi-speedometer':
                  uniqueAttributes['KM Range'] = value;
                  break;
                case 'bi-fuel-pump-fill':
                  uniqueAttributes['Fuel Type'] = value;
                  break;
                case 'bi-gear-fill':
                  uniqueAttributes['Transmission'] = value;
                  break;
              }
            }
          }
          return uniqueAttributes;
        } else {
          print('Invalid response: ${decodedBody['data']}');
          return {};
        }
      } else {
        throw Exception('Failed to fetch post details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching post details for post $postId: $e');
      return {};
    }
  }

  // Add this method to your MarketplaceService2 class
  static Future<ContainerInfoResponse> fetchContainerInfo(String postId) async {
    try {
      final url =
          '$baseUrl/post-details-with-icons.php?token=$token&post_id=$postId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ContainerInfoResponse.fromJson(responseData);
      } else {
        throw Exception(
          'Failed to load container info: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw e;
    }
  }

  Future<ModelVariation?> fetchModelVariation(String postId) async {
    if (_modelVariationsCache.containsKey(postId)) {
      print('Returning cached model variation for postId: $postId');
      return _modelVariationsCache[postId];
    }

    final url =
        '$baseUrl/post-brand-model-variation.php?token=$token&post_id=$postId';
    try {
      print('Fetching model variation from: $url');
      final response = await http.get(Uri.parse(url));
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody['status'] == 'true' &&
            decodedBody['data'] is List &&
            decodedBody['data'].isNotEmpty) {
          final variation = ModelVariation.fromJson(decodedBody['data'][0]);
          _modelVariationsCache[postId] = variation;
          return variation;
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        throw Exception(
          'Failed to load model variation: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching model variation for postId $postId: $e');
      return null;
    }
  }

  static void clearCache() {
    _postsCache.clear();
    _modelVariationsCache.clear();
  }
}
