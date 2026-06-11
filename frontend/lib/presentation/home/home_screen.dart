import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/order_service.dart';
import '../../models/item_model.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;

  const HomeScreen({super.key, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OrderService _orderService = OrderService();
  
  
  int _currentTab = 0; 
  List<dynamic> _establishments = [];
  List<ItemModel> _liveMenu = [];
  List<dynamic> _userOrders = [];
  final Map<int, int> _cart = {}; 
  
  String? _selectedEstablishmentId;
  String _selectedEstablishmentName = "Завантаження...";
  
  bool _isLoadingEst = true;
  bool _isLoadingMenu = false;
  bool _isLoadingOrders = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialEstablishments();
  }

  
  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      ),
    );

    int statusCode = 0;
    String errorMessage = '';

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          
          'Authorization': 'Bearer ${widget.token}', 
        },
      );

      statusCode = response.statusCode;
      errorMessage = response.body;

    } catch (e) {
      debugPrint('[Auth Error] Network failed: $e');
    }

    
    if (mounted) Navigator.pop(context);

    if (statusCode == 200) {
      
      debugPrint('[Auth] Session invalidated successfully on server.');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false, 
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ви успішно вийшли з акаунту"), 
            backgroundColor: Colors.blueGrey
          ),
        );
      }
    } else {
      
      debugPrint('[Auth Error] Server returned code: $statusCode, Body: $errorMessage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Помилка сервера ($statusCode): $errorMessage"), 
            backgroundColor: Colors.redAccent
          ),
        );
      }
    }
  }

  
  Future<void> _loadInitialEstablishments() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/establishments'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          setState(() {
            _establishments = decoded;
            _isLoadingEst = false;
            _selectedEstablishmentId = decoded[0]['id'].toString();
            _selectedEstablishmentName = decoded[0]['name'] ?? 'Без назви';
          });
          _fetchMenuForEstablishment(_selectedEstablishmentId!);
          return;
        }
      }
      setState(() => _isLoadingEst = false);
    } catch (e) {
      debugPrint('Помилка завантаження локацій: $e');
      setState(() => _isLoadingEst = false);
    }
  }

  
  Future<void> _fetchMenuForEstablishment(String establishmentId) async {
    setState(() {
      _isLoadingMenu = true;
      _cart.clear(); 
    });
    
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/items?establishment_id=$establishmentId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          setState(() {
            _liveMenu = decoded.map((json) => ItemModel(
              id: json['id'] ?? 0,
              name: json['name'] ?? 'Без назви',
              price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
              description: json['description'] ?? '',
            )).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Помилка завантаження каталогу: $e');
    } finally {
      setState(() => _isLoadingMenu = false);
    }
  }

  
  Future<void> _fetchUserOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/orders'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _userOrders = decoded is List ? decoded : [];
        });
      }
    } catch (e) {
      debugPrint('Помилка завантаження замовлень: $e');
    } finally {
      setState(() => _isLoadingOrders = false);
    }
  }

  void _addToCart(int itemId) {
    setState(() { _cart[itemId] = (_cart[itemId] ?? 0) + 1; });
  }

  void _clearCart() {
    setState(() { _cart.clear(); });
  }

  double _calculateTotal(List<ItemModel> menu) {
    double total = 0;
    _cart.forEach((itemId, quantity) {
      final item = menu.firstWhere((element) => element.id == itemId, 
        orElse: () => ItemModel(id: 0, name: '', price: 0.0, description: '')
      );
      total += item.price * quantity;
    });
    return total;
  }

  void _submitOrder() async {
    if (_cart.isEmpty) return;

    setState(() { _isSubmitting = true; });

    List<Map<String, dynamic>> orderItems = [];
    _cart.forEach((itemId, quantity) {
      orderItems.add({'item_id': itemId, 'quantity': quantity});
    });

    final result = await _orderService.sendOrder(items: orderItems, token: widget.token);

    if (!mounted) return;
    setState(() { _isSubmitting = false; });

    if (result['success']) {
      _clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Замовлення #${result['order_id']} успішно створено на сервері."),
          backgroundColor: Colors.green,
        ),
      );
      
      _fetchUserOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
      );
    }
  }

  void _showLocationSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Оберіть заклад партнерської мережі",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _establishments.isEmpty
                  ? const Padding(padding: EdgeInsets.all(16.0), child: Text("Немає доступних закладів"))
                  : Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _establishments.length,
                        itemBuilder: (context, index) {
                          final est = _establishments[index];
                          final idStr = est['id'].toString();
                          final isCurrent = idStr == _selectedEstablishmentId;

                          return ListTile(
                            leading: Icon(
                              est['type'] == 'Ресторан' ? Icons.restaurant : Icons.store,
                              color: Colors.orange,
                            ),
                            title: Text(est['name'] ?? 'Без назви', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(est['address'] ?? ''),
                            trailing: isCurrent ? const Icon(Icons.check_circle, color: Colors.green) : null,
                            onTap: () {
                              setState(() {
                                _selectedEstablishmentId = idStr;
                                _selectedEstablishmentName = est['name'] ?? 'Без назви';
                              });
                              Navigator.pop(context);
                              _fetchMenuForEstablishment(idStr);
                            },
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _calculateTotal(_liveMenu);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        
        title: _currentTab == 0
            ? InkWell(
                onTap: _isLoadingEst ? null : _showLocationSelector,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _selectedEstablishmentName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white),
                  ],
                ),
              )
            : const Text("Мої замовлення", style: TextStyle(color: Colors.white)),
        actions: [
          if (_currentTab == 0 && _cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: _clearCart,
            ),
          
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Вийти з додатку',
            onPressed: _handleLogout,
          ),
        ],
      ),
      
      
      body: _isLoadingEst
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _currentTab == 0
              ? RefreshIndicator(
                  color: Colors.orange,
                  onRefresh: () => _fetchMenuForEstablishment(_selectedEstablishmentId!),
                  child: _isLoadingMenu
                      ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                      : _liveMenu.isEmpty
                          ? const ListViewPlaceholder(message: "У цьому закладі немає товарів.")
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _liveMenu.length,
                              itemBuilder: (context, index) {
                                final item = _liveMenu[index];
                                final cartQuantity = _cart[item.id] ?? 0;

                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: ListTile(
                                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text("${item.description}\nЦіна: ${item.price} грн"),
                                    isThreeLine: true,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (cartQuantity > 0)
                                          Chip(
                                            label: Text("x$cartQuantity"),
                                            backgroundColor: Colors.orange.shade100,
                                          ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.add_shopping_cart, color: Colors.orange),
                                          onPressed: () => _addToCart(item.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                )
              
              : RefreshIndicator(
                  color: Colors.orange,
                  onRefresh: _fetchUserOrders,
                  child: _isLoadingOrders
                      ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                      : _userOrders.isEmpty
                          ? const ListViewPlaceholder(message: "У вас немає активних замовлень.")
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _userOrders.length,
                              itemBuilder: (context, index) {
                                final order = _userOrders[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: ExpansionTile(
                                    leading: const Icon(Icons.receipt_long, color: Colors.orange),
                                    title: Text("Замовлення #${order['id']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text("Статус: ${order['status'] ?? 'Обробка'}"),
                                    trailing: Text(
                                      "${order['total_price'] ?? '0'} грн",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                    children: [
                                      
                                      if (order['items'] != null)
                                        ...(order['items'] as List).map((orderItem) {
                                          final itemDetails = orderItem['item'] ?? {};
                                          return ListTile(
                                            dense: true,
                                            title: Text(itemDetails['name'] ?? 'Страва'),
                                            subtitle: Text("Кількість: ${orderItem['quantity']}"),
                                            trailing: Text("${(double.tryParse(itemDetails['price']?.toString() ?? '0') ?? 0) * (orderItem['quantity'] ?? 1)} грн"),
                                          );
                                        }),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),

      
      bottomNavigationBar: _currentTab == 0
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Разом:", style: TextStyle(fontSize: 16)),
                      Text("$totalPrice грн", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: (_cart.isEmpty || _isSubmitting) ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Оформити замовлення", style: TextStyle(fontSize: 16, color: Colors.white)),
                  )
                ],
              ),
            )
          : null,

      
      bottomSheet: BottomNavigationBar(
        currentIndex: _currentTab,
        selectedItemColor: Colors.orange,
        onTap: (index) {
          setState(() { _currentTab = index; });
          if (index == 1) { _fetchUserOrders(); } 
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Меню'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Замовлення'),
        ],
      ),
    );
  }
}

class ListViewPlaceholder extends StatelessWidget {
  final String message;
  const ListViewPlaceholder({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(child: Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 16))),
      ],
    );
  }
}