import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import '../models/location_model.dart';

class LocationService {
  Future<LocationResponse?> fetchLocations() async {
    try {
      final response = await http.get(Uri.parse(locations));

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        return LocationResponse.fromJson(jsonBody);
      } else {
        throw Exception("Failed to load locations");
      }
    } catch (e) {
      rethrow;
    }
  }
}
