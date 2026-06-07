import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/item_model.dart';

class OrderService {
  List<ItemModel> getMockMenu() {
    return [
      ItemModel(id: 1, name: "Бургер Класичний", price: 150.0, description: "Соковита котлета, сир чеддер, фірмовий соус"),
      ItemModel(id: 2, name: "Піца Пепероні", price: 280.0, description: "Гостра ковбаска, моцарела, томатний соус"),
      ItemModel(id: 3, name: "Картопля фрі", price: 65.0, description: "Хрустка картопля з сіллю"),
      ItemModel(id: 4, name: "Кока-кола", price: 40.0, description: "Охолоджена, 0.5л"),
    ];
  }

  Future<Map<String, dynamic>> sendOrder({
    required List<Map<String, dynamic>> items, 
    required String token
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.orders),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'establishment_id': 1,
          'delivery_address': 'вул. Студентська, 10',
          'items': items,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'order_id': responseData['id']};
      } else {
        return {'success': false, 'error': responseData['error'] ?? 'Помилка створення замовлення'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Не вдалося зв`язатися з сервером замовлень'};
    }
  }
}