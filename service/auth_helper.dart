import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthHelper {
  static final AuthHelper instance = AuthHelper._init();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthHelper._init();

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> setAccessToken(String? token) async {
    if (token != null) {
      await _storage.write(key: 'access_token', value: token);
    } else {
      await _storage.delete(key: 'access_token');
    }
  }

  Future<int?> getCurrentCustomerId() async {
    final idStr = await _storage.read(key: 'customer_id');
    return idStr != null ? int.tryParse(idStr) : null;
  }

  Future<void> setCurrentCustomerId(int? customerId) async {
    if (customerId != null) {
      await _storage.write(key: 'customer_id', value: customerId.toString());
    } else {
      await _storage.delete(key: 'customer_id');
    }
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'customer_id');
  }
}
