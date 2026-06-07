class ItemModel {
  final int id;
  final String name;
  final double price;
  final String description;

  ItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      description: json['description'] ?? '',
    );
  }
}