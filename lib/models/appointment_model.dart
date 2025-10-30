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
  final String? assignedTechnicianId;
  final String? assignedTechnicianName;
  final String? assignedTechnicianSpecialty;
  final String garageId;
  final String? garageName;
  final DateTime? startedAt;
  final DateTime? completedAt;

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
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    this.assignedTechnicianSpecialty,
    required this.garageId,
    this.garageName,
    this.startedAt,
    this.completedAt,
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

  bool get hasAssignedTechnician {
    return assignedTechnicianId != null && assignedTechnicianId!.isNotEmpty;
  }

  // NOUVELLES MÉTHODES POUR LE WORKFLOW
  bool get canProgress {
    return ['confirmed', 'in_progress', 'diagnostic', 'repair', 'quality_check']
        .contains(status);
  }

  String get nextStatus {
    switch (status) {
      case 'confirmed':
        return 'in_progress';
      case 'in_progress':
        return 'diagnostic';
      case 'diagnostic':
        return 'repair';
      case 'repair':
        return 'quality_check';
      case 'quality_check':
        return 'completed';
      default:
        return status;
    }
  }

  String get nextStatusText {
    switch (nextStatus) {
      case 'in_progress':
        return 'Commencer la préparation';
      case 'diagnostic':
        return 'Démarrer le diagnostic';
      case 'repair':
        return 'Commencer la réparation';
      case 'quality_check':
        return 'Contrôle qualité';
      case 'completed':
        return 'Marquer comme terminé';
      default:
        return 'Terminer';
    }
  }

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
      'garageId': garageId,
      'garageName': garageName,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Gestion des Timestamps
    final dateTime = data['dateTime'] is Timestamp
        ? (data['dateTime'] as Timestamp).toDate()
        : DateTime.parse(data['dateTime'] as String);

    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.parse(data['createdAt'] as String);

    final startedAt = data['startedAt'] is Timestamp
        ? (data['startedAt'] as Timestamp).toDate()
        : null;

    final completedAt = data['completedAt'] is Timestamp
        ? (data['completedAt'] as Timestamp).toDate()
        : null;

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
      garageId: data['garageId'] as String? ?? 'garage_principal',
      garageName: data['garageName'] as String?,
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }

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
      garageId: map['garageId'] as String? ?? 'garage_principal',
      garageName: map['garageName'] as String?,
      startedAt: map['startedAt'] != null
          ? DateTime.parse(map['startedAt'] as String)
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
    );
  }

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
    String? garageId,
    String? garageName,
    DateTime? startedAt,
    DateTime? completedAt,
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
      garageId: garageId ?? this.garageId,
      garageName: garageName ?? this.garageName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
