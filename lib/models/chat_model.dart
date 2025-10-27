import 'package:cloud_firestore/cloud_firestore.dart';

enum SenderType { client, garage, system }

enum MessageType { text, image, file, system }

class ChatMessage {
  final String id;
  final String content;
  final SenderType senderType;
  final MessageType type;
  final DateTime timestamp;
  final String appointmentId;
  final String garageId;
  final String? clientId;
  final String? clientEmail;
  final String? clientName;
  final String? fileName;
  final int? fileSize;
  final bool isRead;
  final String? imageUrl;
  final String? imageBase64; // NOUVEAU: pour stocker l'image en base64
  final bool isEdited;
  final DateTime? editedAt;
  final List<dynamic>? deletedForGarages;
  final List<dynamic>? deletedForClients;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderType,
    required this.type,
    required this.timestamp,
    required this.appointmentId,
    required this.garageId,
    this.clientId,
    this.clientEmail,
    this.clientName,
    this.fileName,
    this.fileSize,
    this.isRead = false,
    this.imageUrl,
    this.imageBase64, // NOUVEAU
    this.isEdited = false,
    this.editedAt,
    this.deletedForGarages,
    this.deletedForClients,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'senderType': senderType.name,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'appointmentId': appointmentId,
      'garageId': garageId,
      'clientId': clientId,
      'clientEmail': clientEmail,
      'clientName': clientName,
      'fileName': fileName,
      'fileSize': fileSize,
      'isRead': isRead,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64, // NOUVEAU
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'deletedForGarages': deletedForGarages,
      'deletedForClients': deletedForClients,
    };
  }

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatMessage(
      id: data['id'] ?? doc.id,
      content: data['content'] ?? '',
      senderType: _stringToSenderType(data['senderType']),
      type: _stringToMessageType(data['type']),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      appointmentId: data['appointmentId'] ?? '',
      garageId: data['garageId'] ?? '',
      clientId: data['clientId'],
      clientEmail: data['clientEmail'],
      clientName: data['clientName'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      isRead: data['isRead'] ?? false,
      imageUrl: data['imageUrl'],
      imageBase64: data['imageBase64'], // NOUVEAU
      isEdited: data['isEdited'] ?? false,
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      deletedForGarages: data['deletedForGarages'] as List<dynamic>?,
      deletedForClients: data['deletedForClients'] as List<dynamic>?,
    );
  }

  // Méthode pour vérifier si le message est supprimé pour un garage
  bool isDeletedForGarage(String garageId) {
    return deletedForGarages?.contains(garageId) == true;
  }

  // Méthode pour vérifier si le message est supprimé pour un client
  bool isDeletedForClient(String clientEmail) {
    return deletedForClients?.contains(clientEmail) == true;
  }

  static SenderType _stringToSenderType(String type) {
    switch (type) {
      case 'client':
        return SenderType.client;
      case 'garage':
        return SenderType.garage;
      case 'system':
        return SenderType.system;
      default:
        return SenderType.client;
    }
  }

  static MessageType _stringToMessageType(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    SenderType? senderType,
    MessageType? type,
    DateTime? timestamp,
    String? appointmentId,
    String? garageId,
    String? clientId,
    String? clientEmail,
    String? clientName,
    String? fileName,
    int? fileSize,
    bool? isRead,
    String? imageUrl,
    String? imageBase64,
    bool? isEdited,
    DateTime? editedAt,
    List<dynamic>? deletedForGarages,
    List<dynamic>? deletedForClients,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      senderType: senderType ?? this.senderType,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      appointmentId: appointmentId ?? this.appointmentId,
      garageId: garageId ?? this.garageId,
      clientId: clientId ?? this.clientId,
      clientEmail: clientEmail ?? this.clientEmail,
      clientName: clientName ?? this.clientName,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      deletedForGarages: deletedForGarages ?? this.deletedForGarages,
      deletedForClients: deletedForClients ?? this.deletedForClients,
    );
  }
}

class ChatConversation {
  final String id;
  final String appointmentId;
  final String garageId;
  final String clientEmail;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final String lastMessage;

  ChatConversation({
    required this.id,
    required this.appointmentId,
    required this.garageId,
    required this.clientEmail,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.lastMessage = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'garageId': garageId,
      'clientEmail': clientEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unreadCount': unreadCount,
      'lastMessage': lastMessage,
    };
  }

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // CORRECTION: Gérer les Timestamp null
    Timestamp? createdAtTimestamp = data['createdAt'];
    Timestamp? updatedAtTimestamp = data['updatedAt'];

    return ChatConversation(
      id: data['id'] ?? doc.id,
      appointmentId: data['appointmentId'] ?? '',
      garageId: data['garageId'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      createdAt: createdAtTimestamp?.toDate() ?? DateTime.now(),
      updatedAt: updatedAtTimestamp?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
      lastMessage: data['lastMessage'] ?? 'Aucun message',
    );
  }
}
