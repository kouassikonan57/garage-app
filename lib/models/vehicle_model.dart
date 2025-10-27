class Vehicle {
  final String id;
  final String clientId;
  final String brand;
  final String model;
  final int year;
  final String licensePlate;
  final String color;
  final String fuelType;
  final String transmission;
  final int mileage;
  final String vin;
  final DateTime? lastServiceDate;
  final String? notes;

  Vehicle({
    required this.id,
    required this.clientId,
    required this.brand,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.color,
    required this.fuelType,
    required this.transmission,
    required this.mileage,
    required this.vin,
    this.lastServiceDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'brand': brand,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'color': color,
      'fuelType': fuelType,
      'transmission': transmission,
      'mileage': mileage,
      'vin': vin,
      'lastServiceDate': lastServiceDate?.toIso8601String(),
      'notes': notes,
    };
  }

  // AJOUTEZ CETTE MÉTHODE MANQUANTE
  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'],
      clientId: map['clientId'],
      brand: map['brand'],
      model: map['model'],
      year: map['year'],
      licensePlate: map['licensePlate'],
      color: map['color'],
      fuelType: map['fuelType'],
      transmission: map['transmission'],
      mileage: map['mileage'],
      vin: map['vin'],
      lastServiceDate: map['lastServiceDate'] != null
          ? DateTime.parse(map['lastServiceDate'])
          : null,
      notes: map['notes'],
    );
  }

  String get fullName => '$brand $model ($year)';
  String get formattedMileage => '$mileage km';

  @override
  String toString() {
    return 'Vehicle{$brand $model - $licensePlate}';
  }
}
