class InventoryItem {
  final String id;
  final String name;
  final String category;
  final String description;
  final double purchasePrice;
  final double sellingPrice;
  final int quantity;
  final int minStockLevel;
  final String supplierId;
  final String supplierName;
  final String location;
  final DateTime lastRestocked;
  final DateTime createdAt;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    required this.minStockLevel,
    required this.supplierId,
    required this.supplierName,
    required this.location,
    required this.lastRestocked,
    required this.createdAt,
  });

  bool get isLowStock => quantity <= minStockLevel;
  bool get isOutOfStock => quantity == 0;
  double get totalValue => purchasePrice * quantity;
  double get potentialProfit => (sellingPrice - purchasePrice) * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'minStockLevel': minStockLevel,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'location': location,
      'lastRestocked': lastRestocked.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    double? purchasePrice,
    double? sellingPrice,
    int? quantity,
    int? minStockLevel,
    String? supplierId,
    String? supplierName,
    String? location,
    DateTime? lastRestocked,
    DateTime? createdAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      location: location ?? this.location,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
