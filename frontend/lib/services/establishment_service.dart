import 'dart:convert';
import 'package:http/http.dart' as http;

class EstablishmentService {
  final String baseUrl = 'http://localhost:3000/api';

  Future<bool> createEstablishment({
    required String name,
    required String type,
    required String address,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/establishments');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'type': type,
          'address': address,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}