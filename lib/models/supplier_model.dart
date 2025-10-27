class Supplier {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final List<String> suppliedParts;
  final double rating;
  final String paymentTerms;
  final DateTime lastOrderDate;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.suppliedParts,
    this.rating = 0.0,
    required this.paymentTerms,
    required this.lastOrderDate,
    required this.createdAt,
  });

  Supplier copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    List<String>? suppliedParts,
    double? rating,
    String? paymentTerms,
    DateTime? lastOrderDate,
    DateTime? createdAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      suppliedParts: suppliedParts ?? this.suppliedParts,
      rating: rating ?? this.rating,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'suppliedParts': suppliedParts,
      'rating': rating,
      'paymentTerms': paymentTerms,
      'lastOrderDate': lastOrderDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      contactPerson: map['contactPerson'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      suppliedParts: List<String>.from(map['suppliedParts']),
      rating: map['rating']?.toDouble() ?? 0.0,
      paymentTerms: map['paymentTerms'],
      lastOrderDate: DateTime.parse(map['lastOrderDate']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
