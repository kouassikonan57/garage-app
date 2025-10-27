import 'package:flutter/material.dart';
import 'vehicle_model.dart';

class EnrichedClient {
  final String id;
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final DateTime registrationDate;
  final int totalAppointments;
  final String? notes;
  final List<Vehicle> vehicles;
  final DateTime? lastVisit;

  EnrichedClient({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.registrationDate,
    required this.totalAppointments,
    this.notes,
    required this.vehicles,
    this.lastVisit,
  });

  // Convertir vers Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'registrationDate': registrationDate.millisecondsSinceEpoch,
      'totalAppointments': totalAppointments,
      'notes': notes,
      'vehicles': vehicles.map((v) => v.toMap()).toList(),
      'lastVisit': lastVisit?.millisecondsSinceEpoch,
    };
  }

  // Créer depuis Map de Firebase
  factory EnrichedClient.fromMap(Map<String, dynamic> map) {
    List<Vehicle> vehicles = [];
    if (map['vehicles'] != null) {
      final vehiclesList = List<Map<String, dynamic>>.from(map['vehicles']);
      vehicles = vehiclesList.map((v) => Vehicle.fromMap(v)).toList();
    }

    return EnrichedClient(
      id: map['id'],
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      registrationDate:
          DateTime.fromMillisecondsSinceEpoch(map['registrationDate']),
      totalAppointments: map['totalAppointments'],
      notes: map['notes'],
      vehicles: vehicles,
      lastVisit: map['lastVisit'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastVisit'])
          : null,
    );
  }

  // Méthode pour créer une copie avec des valeurs mises à jour
  EnrichedClient copyWith({
    String? id,
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? address,
    DateTime? registrationDate,
    int? totalAppointments,
    String? notes,
    List<Vehicle>? vehicles,
    DateTime? lastVisit,
  }) {
    return EnrichedClient(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      registrationDate: registrationDate ?? this.registrationDate,
      totalAppointments: totalAppointments ?? this.totalAppointments,
      notes: notes ?? this.notes,
      vehicles: vehicles ?? this.vehicles,
      lastVisit: lastVisit ?? this.lastVisit,
    );
  }

  String get formattedRegistrationDate {
    return '${registrationDate.day}/${registrationDate.month}/${registrationDate.year}';
  }

  // Méthode utilitaire pour vérifier si le client est récent
  bool get isRecent {
    if (lastVisit == null) return false;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return lastVisit!.isAfter(thirtyDaysAgo);
  }

  // Méthode utilitaire pour vérifier si le client a plusieurs véhicules
  bool get hasMultipleVehicles {
    return vehicles.length > 1;
  }

  // Méthode utilitaire pour obtenir le niveau d'activité
  String get activityLevel {
    if (totalAppointments == 0) return 'Aucun RDV';
    if (totalAppointments <= 1) return 'Nouveau';
    if (totalAppointments <= 5) return 'Régulier';
    return 'Fidèle';
  }

  // Couleur basée sur le niveau d'activité
  Color get activityColor {
    switch (activityLevel) {
      case 'Fidèle':
        return Colors.green;
      case 'Régulier':
        return Colors.blue;
      case 'Nouveau':
        return Colors.orange;
      case 'Aucun RDV':
      default:
        return Colors.grey;
    }
  }

  @override
  String toString() {
    return 'EnrichedClient{name: $name, email: $email, appointments: $totalAppointments}';
  }
}
