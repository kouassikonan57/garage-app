import 'package:cloud_firestore/cloud_firestore.dart';

enum PhotoType { problem, part, document, repair, finalResult }

class AppointmentPhoto {
  final String id;
  final String url;
  final PhotoType type;
  final DateTime timestamp;
  final String appointmentId;
  final String? description;
  final String? uploadedBy;
  final int fileSize;
  final String fileName;

  AppointmentPhoto({
    required this.id,
    required this.url,
    required this.type,
    required this.timestamp,
    required this.appointmentId,
    this.description,
    this.uploadedBy,
    this.fileSize = 0,
    this.fileName = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'appointmentId': appointmentId,
      'description': description,
      'uploadedBy': uploadedBy,
      'fileSize': fileSize,
      'fileName': fileName,
    };
  }

  factory AppointmentPhoto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentPhoto(
      id: data['id'] ?? doc.id,
      url: data['url'] ?? '',
      type: _stringToPhotoType(data['type']),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      appointmentId: data['appointmentId'] ?? '',
      description: data['description'],
      uploadedBy: data['uploadedBy'],
      fileSize: data['fileSize'] ?? 0,
      fileName: data['fileName'] ?? '',
    );
  }

  static PhotoType _stringToPhotoType(String type) {
    switch (type) {
      case 'problem':
        return PhotoType.problem;
      case 'part':
        return PhotoType.part;
      case 'document':
        return PhotoType.document;
      case 'repair':
        return PhotoType.repair;
      case 'finalResult':
        return PhotoType.finalResult;
      default:
        return PhotoType.problem;
    }
  }

  AppointmentPhoto copyWith({
    String? id,
    String? url,
    PhotoType? type,
    DateTime? timestamp,
    String? appointmentId,
    String? description,
    String? uploadedBy,
    int? fileSize,
    String? fileName,
  }) {
    return AppointmentPhoto(
      id: id ?? this.id,
      url: url ?? this.url,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      appointmentId: appointmentId ?? this.appointmentId,
      description: description ?? this.description,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      fileSize: fileSize ?? this.fileSize,
      fileName: fileName ?? this.fileName,
    );
  }
}
