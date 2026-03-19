import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projectprm/configuration/appsetting.dart';
import 'package:projectprm/viewmodels/request/paymentRequest.dart';
import 'package:projectprm/viewmodels/response/paymentResponse.dart';
import 'package:projectprm/service/auth_helper.dart';

class PaymentApiService {
  final String baseUrl;

  PaymentApiService({String? baseUrl})
      : baseUrl = baseUrl ?? AppSetting.apiUrl;

  String _getUrl(String endpoint) {
    final url = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$url/api/Payment$endpoint';
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthHelper.instance.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. Tạo giao dịch thanh toán mới
  Future<PaymentResponse> createPayment(CreatePaymentRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(_getUrl('')),
        headers: await _getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return PaymentResponse.fromJson(jsonDecode(response.body));
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Lỗi tạo thanh toán');
      }
    } catch (e) {
      throw Exception('Lỗi mạng: $e');
    }
  }

  // 2. Cập nhật trạng thái thanh toán
  Future<PaymentResponse> updatePaymentStatus(int paymentId, UpdatePaymentStatusRequest request) async {
    try {
      final response = await http.put(
        Uri.parse(_getUrl('/$paymentId/status')),
        headers: await _getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return PaymentResponse.fromJson(jsonDecode(response.body));
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Lỗi cập nhật thanh toán');
      }
    } catch (e) {
      throw Exception('Lỗi mạng: $e');
    }
  }

  // 3. Lấy lịch sử thanh toán của 1 booking
  Future<List<PaymentResponse>> getPaymentsByBooking(int bookingId) async {
    try {
      final response = await http.get(
        Uri.parse(_getUrl('/booking/$bookingId')),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PaymentResponse.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải dữ liệu thanh toán');
      }
    } catch (e) {
      throw Exception('Lỗi mạng: $e');
    }
  }
}