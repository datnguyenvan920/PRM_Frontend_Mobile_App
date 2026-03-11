import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projectprm/configuration/appsetting.dart';
import 'package:projectprm/viewmodels/request/authorizationRequest.dart';
import 'package:projectprm/viewmodels/response/authorizationResponse.dart';

class AuthService {
  Future<LoginResponse> login(LoginRequest request) async {
    // Ensuring there is exactly one slash between the base URL and the path
    final baseUrl = AppSetting.apiUrl.endsWith('/') 
        ? AppSetting.apiUrl.substring(0, AppSetting.apiUrl.length - 1) 
        : AppSetting.apiUrl;
    
    final url = Uri.parse('$baseUrl/auth/Authorization/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Server returned success but empty body.');
        }
        final Map<String, dynamic> data = jsonDecode(response.body);
        return LoginResponse.fromJson(data);
      } else {
        // Handle non-200 responses safely
        String errorMessage = 'Đăng nhập thất bại (Status: ${response.statusCode}, Response : ${response})';
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (_) {
            // Body isn't JSON, keep default message
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }
}
