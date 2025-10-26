// lib/core/service/core_data_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import '../model/core_data_model.dart';

class CoreDataService {


  Future<CoreDataModel?> fetchCoreData({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/coredata.php?token=$token'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == 'true' && responseData['data'] != null) {
          final List<dynamic> dataList = responseData['data'];
          if (dataList.isNotEmpty) {
            return CoreDataModel.fromJson(dataList.first);
          }
        }
      }
      
      print('API Response: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Error fetching core data: $e');
      return null;
    }
  }
}