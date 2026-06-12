import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminPanelScreen extends StatefulWidget {
  final String token;

  const AdminPanelScreen({super.key, required this.token});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _estNameController = TextEditingController();
  final _estAddressController = TextEditingController();
  String _selectedEstType = 'Ресторан';
  bool _isEstLoading = false;

  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _itemDescController = TextEditingController();
  
  List<dynamic> _establishmentsDropdownList = [];
  String? _selectedEstablishmentId;
  bool _isItemLoading = false;

  
  List<dynamic> _allGlobalOrders = [];
  bool _isOrdersLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchEstablishmentsLookup();
    _fetchGlobalOrders(); 
  }

  @override
  void dispose() {
    _estNameController.dispose();
    _estAddressController.dispose();
    _itemNameController.dispose();
    _itemPriceController.dispose();
    _itemDescController.dispose();
    super.dispose();
  }

  Future<void> _fetchEstablishmentsLookup() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/items/admin/lookup'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        setState(() {
          if (decodedData is List) {
            _establishmentsDropdownList = decodedData;
          } else {
            _establishmentsDropdownList = [];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading lookup list: $e');
      setState(() {
        _establishmentsDropdownList = [];
      });
    }
  }

  
  Future<void> _fetchGlobalOrders() async {
    setState(() { _isOrdersLoading = true; });
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/orders/admin'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        setState(() {
          _allGlobalOrders = decodedData is List ? decodedData : [];
        });
      }
    } catch (e) {
      debugPrint('Error getting administrative system orders: $e');
    } finally {
      setState(() { _isOrdersLoading = false; });
    }
  }

  
  Future<void> _updateOrderStatus(dynamic orderId, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('http://localhost:3000/api/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Статус замовлення змінено!"), backgroundColor: Colors.green),
        );
        _fetchGlobalOrders(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Помилка оновлення статусу"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Помилка з'єднання з сервером")),
      );
    }
  }

  void _createEstablishment() async {
    final name = _estNameController.text.trim();
    final address = _estAddressController.text.trim();

    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Заповніть усі поля")),
      );
      return;
    }

    setState(() { _isEstLoading = true; });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/establishments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'name': name,
          'type': _selectedEstType,
          'address': address,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Заклад успішно додано!"), backgroundColor: Colors.green),
        );
        _estNameController.clear();
        _estAddressController.clear();
        _fetchEstablishmentsLookup();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Помилка створення закладу"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Помилка з'єднання з сервером")),
      );
    } finally {
      setState(() { _isEstLoading = false; });
    }
  }

  void _createMenuItem() async {
    final name = _itemNameController.text.trim();
    final priceStr = _itemPriceController.text.trim();
    final description = _itemDescController.text.trim();

    if (_selectedEstablishmentId == null || name.isEmpty || priceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Будь ласка, заповніть обов'язкові поля")),
      );
      return;
    }

    setState(() { _isItemLoading = true; });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'establishment_id': _selectedEstablishmentId,
          'name': name,
          'price': priceStr,
          'description': description,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Страву успішно додано до меню!"), backgroundColor: Colors.green),
        );
        _itemNameController.clear();
        _itemPriceController.clear();
        _itemDescController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Помилка додавання страви"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Помилка з'єднання з сервером")),
      );
    } finally {
      setState(() { _isItemLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Панель адміністратора"),
          backgroundColor: Colors.redAccent,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.storefront, color: Colors.white), child: Text("Заклади", style: TextStyle(color: Colors.white))),
              Tab(icon: Icon(Icons.restaurant_menu, color: Colors.white), child: Text("Страви/Товари", style: TextStyle(color: Colors.white))),
              Tab(icon: Icon(Icons.assignment_turned_in, color: Colors.white), child: Text("Замовлення", style: TextStyle(color: Colors.white))), 
            ],
          ),
        ),
        body: TabBarView(
          children: [
            
            Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Додати новий заклад",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _estNameController,
                            decoration: const InputDecoration(
                              labelText: "Коротка назва закладу",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedEstType,
                            decoration: const InputDecoration(
                              labelText: "Тип закладу",
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Ресторан', child: Text('Ресторан')),
                              DropdownMenuItem(value: 'Маркет', child: Text('Супермаркет')),
                            ],
                            onChanged: (value) {
                              setState(() { _selectedEstType = value!; });
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _estAddressController,
                            decoration: const InputDecoration(
                              labelText: "Фізична адреса",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isEstLoading ? null : _createEstablishment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isEstLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Створити заклад", style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            
            Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Додати позицію в меню",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          (_establishmentsDropdownList.isEmpty)
                              ? DropdownButtonFormField<String>(
                                  onChanged: null,
                                  decoration: const InputDecoration(
                                    labelText: "Цільовий заклад",
                                    border: OutlineInputBorder(),
                                    hintText: "Завантаження закладів...",
                                  ),
                                  items: const [],
                                )
                              : DropdownButtonFormField<String>(
                                  initialValue: _selectedEstablishmentId,
                                  hint: const Text('Оберіть заклад'),
                                  decoration: const InputDecoration(
                                    labelText: "Цільовий заклад",
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _establishmentsDropdownList.map<DropdownMenuItem<String>>((dynamic est) {
                                    return DropdownMenuItem<String>(
                                      value: est['id']?.toString(),
                                      child: Text(est['name'] ?? 'Без назви'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedEstablishmentId = value;
                                    });
                                  },
                                ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _itemNameController,
                            decoration: const InputDecoration(
                              labelText: "Назва страви / товару",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _itemPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "Ціна (UAH)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _itemDescController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: "Опис або складники (необов'язково)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isItemLoading ? null : _createMenuItem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isItemLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Додати до каталогу", style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            
            _isOrdersLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                : RefreshIndicator(
                    color: Colors.redAccent,
                    onRefresh: _fetchGlobalOrders,
                    child: _allGlobalOrders.isEmpty
                        ? const Center(
                            child: Text(
                              "Активних замовлень у системі немає.",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _allGlobalOrders.length,
                            itemBuilder: (context, index) {
                              final order = _allGlobalOrders[index];
                              final orderItemsList = order['order_items'] ?? order['items'] ?? [];
                              final currentStatus = order['status'] ?? 'Опрацьовується';

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 3,
                                child: ExpansionTile(
                                  iconColor: Colors.redAccent,
                                  title: Text(
                                    "Замовлення #${order['id']} — Користувач ID: ${order['user_id']}",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text("Поточний статус: $currentStatus"),
                                  children: [
                                    const Divider(height: 1),
                                    if (orderItemsList is List)
                                      ...orderItemsList.map<Widget>((dynamic orderItem) {
                                        final itemDetails = orderItem['item'] ?? {};
                                        final price = double.tryParse(itemDetails['price']?.toString() ?? '0') ?? 0;
                                        final qty = orderItem['quantity'] ?? 0;
                                        return ListTile(
                                          title: Text(itemDetails['name'] ?? 'Страва'),
                                          subtitle: Text("Кількість: x$qty"),
                                          trailing: Text("${(qty * price).toStringAsFixed(2)} грн"),
                                        );
                                      }),
                                    const Divider(),
                                    
                                    
                                    ListTile(
                                      title: const Text(
                                        "Загальна сума:", 
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)
                                      ),
                                      trailing: Text(
                                        "${order['total_price'] ?? order['total']} грн", 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)
                                      ),
                                    ),
                                    
                                    
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Змінити стан:", style: TextStyle(fontWeight: FontWeight.w500)),
                                          DropdownButton<String>(
                                            value: ['Опрацьовується', 'Готується', 'Доставляється', 'Доставлено'].contains(currentStatus) 
                                                ? currentStatus 
                                                : 'Опрацьовується',
                                            items: const [
                                              DropdownMenuItem(value: 'Опрацьовується', child: Text('Опрацьовується')),
                                              DropdownMenuItem(value: 'Готується', child: Text('Готується')),
                                              DropdownMenuItem(value: 'Доставляється', child: Text('Доставляється')),
                                              DropdownMenuItem(value: 'Доставлено', child: Text('Доставлено')),
                                            ],
                                            onChanged: (newStatus) {
                                              if (newStatus != null && newStatus != currentStatus) {
                                                _updateOrderStatus(order['id'], newStatus);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}