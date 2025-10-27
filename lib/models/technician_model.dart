import 'package:cloud_firestore/cloud_firestore.dart';

class Technician {
  final String id;
  final String name;
  final String specialty;
  final String phone;
  final String email;
  final double rating;
  final List<String> skills;
  final bool isAvailable;
  final String garageId;
  final int experience; // NOUVEAU CHAMP
  final String? profileImage; // NOUVEAU CHAMP
  final String? address; // NOUVEAU CHAMP
  final String? bio; // NOUVEAU CHAMP
  final DateTime? createdAt; // NOUVEAU CHAMP
  final DateTime? updatedAt; // NOUVEAU CHAMP
  final int completedJobs; // NOUVEAU CHAMP
  final List<String> certifications; // NOUVEAU CHAMP
  final String? workingHours; // NOUVEAU CHAMP

  Technician({
    required this.id,
    required this.name,
    required this.specialty,
    required this.phone,
    required this.email,
    this.rating = 0.0,
    required this.skills,
    this.isAvailable = true,
    required this.garageId,
    this.experience = 0, // VALEUR PAR DÉFAUT
    this.profileImage,
    this.address,
    this.bio,
    this.createdAt,
    this.updatedAt,
    this.completedJobs = 0,
    this.certifications = const [], // VALEUR PAR DÉFAUT
    this.workingHours,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'phone': phone,
      'email': email,
      'rating': rating,
      'skills': skills,
      'isAvailable': isAvailable,
      'garageId': garageId,
      'experience': experience, // NOUVEAU CHAMP
      'profileImage': profileImage, // NOUVEAU CHAMP
      'address': address, // NOUVEAU CHAMP
      'bio': bio, // NOUVEAU CHAMP
      'completedJobs': completedJobs, // NOUVEAU CHAMP
      'certifications': certifications, // NOUVEAU CHAMP
      'workingHours': workingHours, // NOUVEAU CHAMP
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Technician.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Gestion des Timestamps pour les dates
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      return null;
    }

    return Technician(
      id: doc.id,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      skills: List<String>.from(data['skills'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      garageId: data['garageId'] ?? '',
      experience: (data['experience'] ?? 0).toInt(), // NOUVEAU CHAMP
      profileImage: data['profileImage'], // NOUVEAU CHAMP
      address: data['address'], // NOUVEAU CHAMP
      bio: data['bio'], // NOUVEAU CHAMP
      completedJobs: (data['completedJobs'] ?? 0).toInt(), // NOUVEAU CHAMP
      certifications:
          List<String>.from(data['certifications'] ?? []), // NOUVEAU CHAMP
      workingHours: data['workingHours'], // NOUVEAU CHAMP
      createdAt: parseTimestamp(data['createdAt']), // NOUVEAU CHAMP
      updatedAt: parseTimestamp(data['updatedAt']), // NOUVEAU CHAMP
    );
  }

  Technician copyWith({
    String? id,
    String? name,
    String? specialty,
    String? phone,
    String? email,
    double? rating,
    List<String>? skills,
    bool? isAvailable,
    String? garageId,
    int? experience, // NOUVEAU CHAMP
    String? profileImage, // NOUVEAU CHAMP
    String? address, // NOUVEAU CHAMP
    String? bio, // NOUVEAU CHAMP
    DateTime? createdAt, // NOUVEAU CHAMP
    DateTime? updatedAt, // NOUVEAU CHAMP
    int? completedJobs, // NOUVEAU CHAMP
    List<String>? certifications, // NOUVEAU CHAMP
    String? workingHours, // NOUVEAU CHAMP
  }) {
    return Technician(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      skills: skills ?? this.skills,
      isAvailable: isAvailable ?? this.isAvailable,
      garageId: garageId ?? this.garageId,
      experience: experience ?? this.experience, // NOUVEAU CHAMP
      profileImage: profileImage ?? this.profileImage, // NOUVEAU CHAMP
      address: address ?? this.address, // NOUVEAU CHAMP
      bio: bio ?? this.bio, // NOUVEAU CHAMP
      createdAt: createdAt ?? this.createdAt, // NOUVEAU CHAMP
      updatedAt: updatedAt ?? this.updatedAt, // NOUVEAU CHAMP
      completedJobs: completedJobs ?? this.completedJobs, // NOUVEAU CHAMP
      certifications: certifications ?? this.certifications, // NOUVEAU CHAMP
      workingHours: workingHours ?? this.workingHours, // NOUVEAU CHAMP
    );
  }

  // MÉTHODES UTILES AJOUTÉES

  // Calculer le niveau d'expertise basé sur l'expérience
  String get expertiseLevel {
    if (experience >= 10) return 'Expert';
    if (experience >= 5) return 'Senior';
    if (experience >= 2) return 'Intermédiaire';
    return 'Débutant';
  }

  // Vérifier si le technicien a des certifications
  bool get hasCertifications => certifications.isNotEmpty;

  // Obtenir le nombre d'années d'expérience formaté
  String get formattedExperience {
    if (experience == 0) return 'Pas d\'expérience';
    if (experience == 1) return '1 an d\'expérience';
    return '$experience ans d\'expérience';
  }

  // Obtenir la note formatée
  String get formattedRating {
    return rating.toStringAsFixed(1);
  }

  // Vérifier si le technicien est très bien noté
  bool get isHighlyRated => rating >= 4.5;

  // Obtenir les compétences principales (limitées)
  List<String> get mainSkills {
    return skills.take(3).toList();
  }

  // Vérifier si le technicien a une image de profil
  bool get hasProfileImage => profileImage != null && profileImage!.isNotEmpty;

  // Méthode pour déterminer si c'est une image base64
  bool get isBase64Image =>
      hasProfileImage && profileImage!.startsWith('data:image');

  // Obtenir le nombre de travaux complétés formaté
  String get formattedCompletedJobs {
    if (completedJobs >= 1000) {
      return '${(completedJobs / 1000).toStringAsFixed(1)}k+ travaux';
    }
    return '$completedJobs travaux';
  }
}
