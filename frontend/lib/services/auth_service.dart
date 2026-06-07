import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': responseData['token'],
          'role': responseData['role'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Невідома помилка сервера',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Помилка підключення до сервера',
      };
    }
  }
}