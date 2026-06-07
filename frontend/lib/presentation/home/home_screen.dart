import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../models/item_model.dart';

class HomeScreen extends StatefulWidget {
  final String token;

  const HomeScreen({super.key, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OrderService _orderService = OrderService();
  
  final Map<int, int> _cart = {}; 
  bool _isSubmitting = false;

  void _addToCart(int itemId) {
    setState(() {
      _cart[itemId] = (_cart[itemId] ?? 0) + 1;
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  double _calculateTotal(List<ItemModel> menu) {
    double total = 0;
    _cart.forEach((itemId, quantity) {
      final item = menu.firstWhere((element) => element.id == itemId);
      total += item.price * quantity;
    });
    return total;
  }

  void _submitOrder() async {
    if (_cart.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    List<Map<String, dynamic>> orderItems = [];
    _cart.forEach((itemId, quantity) {
      orderItems.add({'item_id': itemId, 'quantity': quantity});
    });

    final result = await _orderService.sendOrder(items: orderItems, token: widget.token);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result['success']) {
      _clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Замовлення #${result['order_id']} успішно створено на сервері."),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = _orderService.getMockMenu();
    final totalPrice = _calculateTotal(menu);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Меню ресторану"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _cart.isEmpty ? null : _clearCart,
          )
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: menu.length,
                  itemBuilder: (context, index) {
                    final item = menu[index];
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
              ),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
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
            ],
          ),
        ),
      ),
    );
  }
}