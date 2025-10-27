import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String? id;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String service;
  final DateTime dateTime;
  final String status;
  final String? notes;
  final String? vehicle;
  final DateTime createdAt;
  // NOUVEAUX CHAMPS POUR LE TECHNICIEN
  final String? assignedTechnicianId;
  final String? assignedTechnicianName;
  final String? assignedTechnicianSpecialty;
  // NOUVEAUX CHAMPS POUR LE SYSTÈME DE CHAT ET GARAGE
  final String garageId; // AJOUT OBLIGATOIRE
  final String? garageName; // AJOUT OPTIONNEL

  Appointment({
    this.id,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.service,
    required this.dateTime,
    this.status = 'pending',
    this.notes,
    this.vehicle,
    required this.createdAt,
    // NOUVEAUX PARAMÈTRES
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    this.assignedTechnicianSpecialty,
    // AJOUT DES NOUVEAUX PARAMÈTRES
    required this.garageId, // OBLIGATOIRE
    this.garageName, // OPTIONNEL
  });

  String get formattedDate {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String get formattedTime {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDateTime {
    return '${formattedDate} à ${formattedTime}';
  }

  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  bool get isUpcoming {
    return dateTime.isAfter(DateTime.now());
  }

  Duration get timeUntilAppointment {
    return dateTime.difference(DateTime.now());
  }

  // NOUVELLE MÉTHODE : Vérifier si un technicien est assigné
  bool get hasAssignedTechnician {
    return assignedTechnicianId != null && assignedTechnicianId!.isNotEmpty;
  }

  // MÉTHODE POUR FIRESTORE - Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'service': service,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
      'notes': notes,
      'vehicle': vehicle,
      'createdAt': Timestamp.fromDate(createdAt),
      'assignedTechnicianId': assignedTechnicianId,
      'assignedTechnicianName': assignedTechnicianName,
      'assignedTechnicianSpecialty': assignedTechnicianSpecialty,
      'garageId': garageId, // AJOUT
      'garageName': garageName, // AJOUT
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // MÉTHODE POUR FIRESTORE - Création depuis DocumentSnapshot
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Gestion des Timestamps
    final dateTime = data['dateTime'] is Timestamp
        ? (data['dateTime'] as Timestamp).toDate()
        : DateTime.parse(data['dateTime'] as String);

    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.parse(data['createdAt'] as String);

    return Appointment(
      id: doc.id,
      clientId: data['clientId'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      clientEmail: data['clientEmail'] as String? ?? '',
      clientPhone: data['clientPhone'] as String? ?? '+225 00 00 00 00',
      service: data['service'] as String? ?? '',
      dateTime: dateTime,
      status: data['status'] as String? ?? 'pending',
      notes: data['notes'] as String?,
      vehicle: data['vehicle'] as String?,
      createdAt: createdAt,
      assignedTechnicianId: data['assignedTechnicianId'] as String?,
      assignedTechnicianName: data['assignedTechnicianName'] as String?,
      assignedTechnicianSpecialty:
          data['assignedTechnicianSpecialty'] as String?,
      garageId: data['garageId'] as String? ??
          'garage_principal', // AJOUT avec valeur par défaut
      garageName: data['garageName'] as String?, // AJOUT
    );
  }

  // CONSERVER L'ANCIENNE MÉTHODE fromMap pour la compatibilité
  factory Appointment.fromMap(String id, Map<String, dynamic> map) {
    return Appointment(
      id: id,
      clientId: map['clientId'] as String,
      clientName: map['clientName'] as String,
      clientEmail: map['clientEmail'] as String,
      clientPhone: map['clientPhone'] as String? ?? '+225 00 00 00 00',
      service: map['service'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      vehicle: map['vehicle'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      assignedTechnicianId: map['assignedTechnicianId'] as String?,
      assignedTechnicianName: map['assignedTechnicianName'] as String?,
      assignedTechnicianSpecialty:
          map['assignedTechnicianSpecialty'] as String?,
      garageId: map['garageId'] as String? ??
          'garage_principal', // AJOUT avec valeur par défaut
      garageName: map['garageName'] as String?, // AJOUT
    );
  }

  // Méthode pour créer une copie avec des valeurs mises à jour
  Appointment copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? service,
    DateTime? dateTime,
    String? status,
    String? notes,
    String? vehicle,
    DateTime? createdAt,
    String? assignedTechnicianId,
    String? assignedTechnicianName,
    String? assignedTechnicianSpecialty,
    String? garageId, // AJOUT
    String? garageName, // AJOUT
  }) {
    return Appointment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      service: service ?? this.service,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      vehicle: vehicle ?? this.vehicle,
      createdAt: createdAt ?? this.createdAt,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      assignedTechnicianName:
          assignedTechnicianName ?? this.assignedTechnicianName,
      assignedTechnicianSpecialty:
          assignedTechnicianSpecialty ?? this.assignedTechnicianSpecialty,
      garageId: garageId ?? this.garageId, // AJOUT
      garageName: garageName ?? this.garageName, // AJOUT
    );
  }
}
