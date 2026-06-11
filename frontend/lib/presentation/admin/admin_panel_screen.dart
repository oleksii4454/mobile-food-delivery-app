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

  @override
  void initState() {
    super.initState();
    _fetchEstablishmentsLookup();
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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Панель адміністратора"),
          backgroundColor: Colors.redAccent,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.storefront, color: Colors.white), child: Text("Заклади", style: TextStyle(color: Colors.white))),
              Tab(icon: Icon(Icons.restaurant_menu, color: Colors.white), child: Text("Страви/Товари", style: TextStyle(color: Colors.white))),
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
                            value: _selectedEstType,
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
          ],
        ),
      ),
    );
  }
}