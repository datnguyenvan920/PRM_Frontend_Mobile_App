import 'dart:convert';
import 'package:http/http.dart' as http;
import '../configuration/appsetting.dart';
import '../viewmodels/request/bookingRequest.dart';
import '../viewmodels/response/bookingResponse.dart';

class BookingApiService {
  final String baseUrl;

  BookingApiService({String? baseUrl})
      : baseUrl = baseUrl ?? AppSetting.apiUrl;

  String _getUrl(String endpoint) {
    final url = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$url/api/booking/$endpoint';
  }

  Map<String, String> _getHeaders({String? accessToken}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  // Get all bookings for a customer
  Future<List<BookingResponse>> getBookingsByCustomerId(int customerId, {String? accessToken}) async {
    try {
      final url = Uri.parse(_getUrl('customer/$customerId'));
      final response = await http.get(
        url,
        headers: _getHeaders(accessToken: accessToken),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => BookingResponse.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load bookings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  // Get booking by ID
  Future<BookingResponse> getBookingById(int bookingId, {String? accessToken}) async {
    try {
      final url = Uri.parse(_getUrl('$bookingId'));
      final response = await http.get(
        url,
        headers: _getHeaders(accessToken: accessToken),
      );

      if (response.statusCode == 200) {
        return BookingResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load booking: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching booking: $e');
    }
  }

  // Create a new booking
  Future<BookingResponse> createBooking(CreateBookingRequest request, {String? accessToken}) async {
    try {
      final url = Uri.parse(_getUrl(''));
      final response = await http.post(
        url,
        headers: _getHeaders(accessToken: accessToken),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return BookingResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        final errorMessage = errorBody?['message'] ?? 'Failed to create booking: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error creating booking: $e');
    }
  }

  // Update a booking
  Future<BookingResponse> updateBooking(int bookingId, UpdateBookingRequest request, {String? accessToken}) async {
    try {
      final url = Uri.parse(_getUrl('$bookingId'));
      final response = await http.put(
        url,
        headers: _getHeaders(accessToken: accessToken),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return BookingResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        final errorMessage = errorBody?['message'] ?? 'Failed to update booking: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error updating booking: $e');
    }
  }

  // Delete a booking
  Future<bool> deleteBooking(int bookingId, {String? accessToken}) async {
    try {
      final url = Uri.parse(_getUrl('$bookingId'));
      final response = await http.delete(
        url,
        headers: _getHeaders(accessToken: accessToken),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Failed to delete booking: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting booking: $e');
    }
  }

  // Update booking status
  Future<BookingResponse> updateBookingStatus(int bookingId, String status, {String? accessToken}) async {
    final request = UpdateBookingRequest(status: status);
    return await updateBooking(bookingId, request, accessToken: accessToken);
  }
}
