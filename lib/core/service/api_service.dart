import 'package:dio/dio.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // GET request
  Future<dynamic> get({
    required String url,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final Map<String, dynamic> finalQueryParams = {'token': token};
      if (queryParams != null) {
        finalQueryParams.addAll(queryParams);
      }

      final response = await _dio.get(
        url,
        queryParameters: finalQueryParams,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('Dio error: ${e.message}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST multipart/form-data request
  Future<dynamic> postMultipart({
    required String url,
    required Map<String, dynamic> fields,
    String? fileField,
    String? filePath,
  }) async {
    try {
      final Map<String, dynamic> finalQueryParams = {'token': token};

      FormData formData = FormData.fromMap(fields);

      if (fileField != null && filePath != null && filePath.isNotEmpty) {
        formData.files.add(
          MapEntry(
            fileField,
            await MultipartFile.fromFile(filePath),
          ),
        );
      }

      final response = await _dio.post(
        url,
        queryParameters: finalQueryParams,
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('Dio error: ${e.message}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
