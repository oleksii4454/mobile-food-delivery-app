import 'package:flutter/material.dart';


class CartItem {
  final int itemId;
  final String name;
  final double price;
  final int quantity;

  CartItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  
  CartItem copyWith({final int? quantity}) {
    return CartItem(
      itemId: itemId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }

  
  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'quantity': quantity,
    };
  }
}


class CartManager {
  
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  
  final ValueNotifier<Map<int, CartItem>> itemsNotifier = ValueNotifier({});

  
  Map<int, CartItem> get items => itemsNotifier.value;
  
  double get totalAmount {
    double total = 0.0;
    items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  int get totalItemCount {
    int count = 0;
    items.forEach((key, cartItem) {
      count += cartItem.quantity;
    });
    return count;
  }

  

  void addItem({required final int id, required final String name, required final double price}) {
    final currentMap = Map<int, CartItem>.from(itemsNotifier.value);

    if (currentMap.containsKey(id)) {
      
      currentMap[id] = currentMap[id]!.copyWith(quantity: currentMap[id]!.quantity + 1);
    } else {
      
      currentMap[id] = CartItem(itemId: id, name: name, price: price, quantity: 1);
    }

    itemsNotifier.value = currentMap; 
  }

  void removeItem(final int id) {
    final currentMap = Map<int, CartItem>.from(itemsNotifier.value);
    if (!currentMap.containsKey(id)) return;

    if (currentMap[id]!.quantity > 1) {
      currentMap[id] = currentMap[id]!.copyWith(quantity: currentMap[id]!.quantity - 1);
    } else {
      currentMap.remove(id);
    }
    itemsNotifier.value = currentMap;
  }

  void clearCart() {
    itemsNotifier.value = {};
  }
}