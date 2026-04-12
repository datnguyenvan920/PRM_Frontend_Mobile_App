import 'dart:convert';
import 'package:http/http.dart' as http;
import '../configuration/appsetting.dart';
import '../viewmodels/response/category_response.dart';

class CategoryApiService {
  final String _baseUrl = AppSetting.apiUrl.endsWith('/') 
      ? AppSetting.apiUrl.substring(0, AppSetting.apiUrl.length - 1) 
      : AppSetting.apiUrl;

  Future<List<CategoryResponse>> getCategories() async {
    try {
      // Using the endpoint specified in the snippet
      final url = Uri.parse('$_baseUrl/book/Booking/categories');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CategoryResponse.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }
}
