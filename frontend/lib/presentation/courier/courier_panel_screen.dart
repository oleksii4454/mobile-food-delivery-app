import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CourierPanelScreen extends StatefulWidget {
  final String token;

  const CourierPanelScreen({super.key, required this.token});

  @override
  State<CourierPanelScreen> createState() => _CourierPanelScreenState();
}

class _CourierPanelScreenState extends State<CourierPanelScreen> {
  List<dynamic> _allOrders = [];
  bool _isLoading = true;

  
  final List<String> _courierStatuses = ['Доставляється', 'Доставлено'];

  @override
  void initState() {
    super.initState();
    _fetchCourierOrders();
  }

  Future<void> _fetchCourierOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/orders/courier'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _allOrders = jsonDecode(response.body);
        });
      } else {
        _showSnackBar("Помилка завантаження: ${response.statusCode}", Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar("Мережева помилка: $e", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('http://localhost:3000/api/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Статус замовлення #$orderId змінено на '$newStatus'", Colors.green);
        _fetchCourierOrders(); 
      } else {
        final errBody = jsonDecode(response.body);
        _showSnackBar("Помилка зміни: ${errBody['error'] ?? response.statusCode}", Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar("Не вдалося оновити статус: $e", Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: bgColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Панель кур'єра", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 81, 158, 98),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchCourierOrders,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey))
          : _allOrders.isEmpty
              ? const Center(child: Text("Немає активних замовлень для доставки."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _allOrders.length,
                  itemBuilder: (context, index) {
                    final order = _allOrders[index];
                    final int orderId = order['id'];
                    final String currentStatus = order['status'] ?? 'Опрацьовується';
                    final items = order['order_items'] ?? [];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Замовлення #$orderId",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                
                                Text(
                                  currentStatus,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: currentStatus == 'Доставлено' ? Colors.green : Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            if (items is List)
                              ...items.map<Widget>((itemWrap) {
                                final detail = itemWrap['item'] ?? {};
                                return Text("• ${detail['name']} x${itemWrap['quantity']}");
                              }),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Сума: ${order['total_price']} грн",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: [
                                    const Text("Змінити на: ", style: TextStyle(fontSize: 13)),
                                    const SizedBox(width: 4),
                                    DropdownButton<String>(
                                      hint: const Text("Виберіть дію", style: TextStyle(fontSize: 13)),
                                      style: const TextStyle(color: Colors.black, fontSize: 14),
                                      underline: Container(height: 1, color: Colors.blueGrey),
                                      
                                      items: currentStatus == 'Доставлено'
                                          ? null
                                          : _courierStatuses.map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                      onChanged: (String? selectedValue) {
                                        if (selectedValue != null) {
                                          _updateStatus(orderId, selectedValue);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}