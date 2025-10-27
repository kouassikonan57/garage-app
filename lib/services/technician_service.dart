import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/technician_model.dart';

class TechnicianService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer tous les techniciens du garage connecté
  Future<List<Technician>> getTechnicians(String garageId) async {
    try {
      final querySnapshot = await _firestore
          .collection('technicians') // ⬅️ CORRIGÉ : 'technicians'
          .where('garageId', isEqualTo: garageId)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => Technician.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération techniciens: $e');
      throw e;
    }
  }

  // Récupérer un technicien par son ID
  Future<Technician?> getTechnicianById(String technicianId) async {
    try {
      final doc = await _firestore
          .collection('technicians')
          .doc(technicianId)
          .get(); // ⬅️ CORRIGÉ
      if (doc.exists) {
        return Technician.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération technicien $technicianId: $e');
      return null;
    }
  }

  // Ajouter un nouveau technicien
  Future<void> addTechnician(Technician technician) async {
    try {
      final docRef = _firestore.collection('technicians').doc(); // ⬅️ CORRIGÉ

      // Créer le technicien avec l'ID du document Firestore
      final technicianWithId = technician.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(technicianWithId.toMap());

      print('✅ Technicien ajouté: ${technician.name}');
    } catch (e) {
      print('❌ Erreur ajout technicien: $e');
      throw e;
    }
  }

  // Récupérer tous les techniciens (tous garages)
  Future<List<Technician>> getAllTechnicians() async {
    try {
      final querySnapshot = await _firestore
          .collection('technicians')
          .orderBy('name')
          .get(); // ⬅️ CORRIGÉ

      return querySnapshot.docs
          .map((doc) => Technician.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération tous les techniciens: $e');
      throw e;
    }
  }

  // Mettre à jour un technicien existant
  Future<void> updateTechnician(Technician technician) async {
    try {
      await _firestore
          .collection('technicians') // ⬅️ CORRIGÉ
          .doc(technician.id)
          .update(technician.toMap()
            ..addAll({
              'updatedAt': FieldValue.serverTimestamp(),
            }));

      print('✅ Technicien mis à jour: ${technician.name}');
    } catch (e) {
      print('❌ Erreur mise à jour technicien: $e');
      throw e;
    }
  }

  // Supprimer un technicien
  Future<void> deleteTechnician(String technicianId) async {
    try {
      await _firestore
          .collection('technicians')
          .doc(technicianId)
          .delete(); // ⬅️ CORRIGÉ
      print('✅ Technicien supprimé: $technicianId');
    } catch (e) {
      print('❌ Erreur suppression technicien: $e');
      throw e;
    }
  }

  // Changer la disponibilité d'un technicien
  Future<void> toggleTechnicianAvailability(
      String technicianId, bool isAvailable) async {
    try {
      await _firestore.collection('technicians').doc(technicianId).update({
        // ⬅️ CORRIGÉ
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Disponibilité technicien $technicianId: $isAvailable');
    } catch (e) {
      print('❌ Erreur changement disponibilité: $e');
      throw e;
    }
  }

  // Écouter les changements en temps réel
  Stream<List<Technician>> streamTechnicians(String garageId) {
    return _firestore
        .collection('technicians') // ⬅️ CORRIGÉ
        .where('garageId', isEqualTo: garageId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Technician.fromFirestore(doc)).toList());
  }

  // Rechercher des techniciens
  Future<List<Technician>> searchTechnicians(
      String garageId, String query) async {
    try {
      if (query.isEmpty) {
        return getTechnicians(garageId);
      }

      final querySnapshot = await _firestore
          .collection('technicians') // ⬅️ CORRIGÉ
          .where('garageId', isEqualTo: garageId)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      return querySnapshot.docs
          .map((doc) => Technician.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur recherche techniciens: $e');
      return [];
    }
  }

  // 🔥 MÉTHODE SIMPLIFIÉE : Gérer l'image avec URL seulement
  Future<String?> handleTechnicianImage(
      String? imageUrl, List<int>? imageBytes) async {
    // Pour l'instant, on utilise uniquement l'URL fournie
    // Vous pourrez implémenter un service d'upload d'images gratuit plus tard
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return imageUrl;
    }

    // Si pas d'URL, on peut utiliser une image par défaut
    return 'https://via.placeholder.com/150/FFA500/FFFFFF?text=T';
  }

  // 🔥 MÉTHODE : Ajouter un technicien avec gestion d'image simplifiée
  Future<void> addTechnicianWithImage(
      Technician technician, String? imageUrl, List<int>? imageBytes) async {
    try {
      // Gérer l'image (URL seulement pour l'instant)
      final String? finalImageUrl =
          await handleTechnicianImage(imageUrl, imageBytes);

      final docRef = _firestore.collection('techniciens').doc();

      // Créer le technicien avec l'URL de l'image et l'ID
      final technicianWithId = technician.copyWith(
        id: docRef.id,
        profileImage: finalImageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(technicianWithId.toMap());

      print('✅ Technicien ajouté avec image: ${technician.name}');
    } catch (e) {
      print('❌ Erreur ajout technicien avec image: $e');
      throw e;
    }
  }

  // 🔥 MÉTHODE : Mettre à jour un technicien avec gestion d'image simplifiée
  Future<void> updateTechnicianWithImage(
      Technician technician, String? imageUrl, List<int>? imageBytes) async {
    try {
      String? finalImageUrl;

      // Si une nouvelle image est fournie, on l'utilise
      if (imageUrl != null && imageUrl.isNotEmpty) {
        finalImageUrl = imageUrl;
      } else if (imageBytes != null) {
        // Si bytes mais pas d'URL, on garde l'ancienne image
        finalImageUrl = technician.profileImage;
      } else {
        // Sinon on garde l'image existante
        finalImageUrl = technician.profileImage;
      }

      // Mettre à jour le technicien avec la nouvelle URL d'image
      final updatedTechnician = technician.copyWith(
        profileImage: finalImageUrl,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('techniciens')
          .doc(technician.id)
          .update(updatedTechnician.toMap()
            ..addAll({
              'updatedAt': FieldValue.serverTimestamp(),
            }));

      print('✅ Technicien mis à jour avec image: ${technician.name}');
    } catch (e) {
      print('❌ Erreur mise à jour technicien avec image: $e');
      throw e;
    }
  }

  // 🔥 NOUVELLE MÉTHODE : Recherche avancée avec plusieurs critères
  Future<List<Technician>> advancedSearch({
    required String garageId,
    String? name,
    String? specialty,
    int? minExperience,
    int? maxExperience,
    bool? isAvailable,
    List<String>? skills,
  }) async {
    try {
      Query query = _firestore
          .collection('techniciens')
          .where('garageId', isEqualTo: garageId);

      // Appliquer les filtres
      if (name != null && name.isNotEmpty) {
        query = query
            .where('name', isGreaterThanOrEqualTo: name)
            .where('name', isLessThan: name + 'z');
      }

      if (specialty != null && specialty.isNotEmpty) {
        query = query.where('specialty', isEqualTo: specialty);
      }

      if (minExperience != null) {
        query =
            query.where('experience', isGreaterThanOrEqualTo: minExperience);
      }

      if (maxExperience != null) {
        query = query.where('experience', isLessThanOrEqualTo: maxExperience);
      }

      if (isAvailable != null) {
        query = query.where('isAvailable', isEqualTo: isAvailable);
      }

      final querySnapshot = await query.orderBy('name').get();

      // Filtrer par compétences si spécifié
      List<Technician> technicians = querySnapshot.docs
          .map((doc) => Technician.fromFirestore(doc))
          .toList();

      if (skills != null && skills.isNotEmpty) {
        technicians = technicians.where((technician) {
          return skills.any((skill) => technician.skills.any(
              (tSkill) => tSkill.toLowerCase().contains(skill.toLowerCase())));
        }).toList();
      }

      return technicians;
    } catch (e) {
      print('❌ Erreur recherche avancée: $e');
      return [];
    }
  }

  // 🔥 NOUVELLE MÉTHODE : Mettre à jour la note d'un technicien
  Future<void> updateTechnicianRating(
      String technicianId, double newRating, int totalRatings) async {
    try {
      await _firestore.collection('techniciens').doc(technicianId).update({
        'rating': newRating,
        'totalRatings': totalRatings,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Note mise à jour pour technicien $technicianId: $newRating');
    } catch (e) {
      print('❌ Erreur mise à jour note: $e');
      throw e;
    }
  }

  // 🔥 NOUVELLE MÉTHODE : Incrémenter le compteur de travaux complétés
  Future<void> incrementCompletedJobs(String technicianId) async {
    try {
      await _firestore.collection('techniciens').doc(technicianId).update({
        'completedJobs': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Travail complété ajouté pour technicien: $technicianId');
    } catch (e) {
      print('❌ Erreur incrémentation travaux: $e');
      throw e;
    }
  }

  // 🔥 NOUVELLE MÉTHODE : Récupérer les statistiques des techniciens
  Future<Map<String, dynamic>> getTechniciansStats(String garageId) async {
    try {
      final technicians = await getTechnicians(garageId);

      if (technicians.isEmpty) {
        return {
          'total': 0,
          'available': 0,
          'busy': 0,
          'averageRating': 0.0,
          'totalExperience': 0,
          'totalJobs': 0,
          'certifiedCount': 0,
        };
      }

      final total = technicians.length;
      final available = technicians.where((t) => t.isAvailable).length;
      final busy = total - available;
      final averageRating = technicians.isEmpty
          ? 0.0
          : technicians.map((t) => t.rating).reduce((a, b) => a + b) / total;
      final totalExperience =
          technicians.fold(0, (sum, t) => sum + t.experience);
      final totalJobs = technicians.fold(0, (sum, t) => sum + t.completedJobs);
      final certifiedCount =
          technicians.where((t) => t.hasCertifications).length;

      return {
        'total': total,
        'available': available,
        'busy': busy,
        'averageRating': double.parse(averageRating.toStringAsFixed(1)),
        'totalExperience': totalExperience,
        'totalJobs': totalJobs,
        'certifiedCount': certifiedCount,
        'averageExperience':
            double.parse((totalExperience / total).toStringAsFixed(1)),
      };
    } catch (e) {
      print('❌ Erreur récupération statistiques: $e');
      return {
        'total': 0,
        'available': 0,
        'busy': 0,
        'averageRating': 0.0,
        'totalExperience': 0,
        'totalJobs': 0,
        'certifiedCount': 0,
        'averageExperience': 0.0,
      };
    }
  }

  // 🔥 NOUVELLE MÉTHODE : Vérifier si un email existe déjà
  Future<bool> checkEmailExists(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('techniciens')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erreur vérification email: $e');
      return false;
    }
  }

  // 🔥 NOUVELLE MÉTHODE : Récupérer les techniciens par spécialité
  Future<List<Technician>> getTechniciansBySpecialty(
      String garageId, String specialty) async {
    try {
      final querySnapshot = await _firestore
          .collection('techniciens')
          .where('garageId', isEqualTo: garageId)
          .where('specialty', isEqualTo: specialty)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => Technician.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération par spécialité: $e');
      return [];
    }
  }

  // 🔥 NOUVELLE MÉTHODE : Récupérer les spécialités disponibles
  Future<Set<String>> getAvailableSpecialties(String garageId) async {
    try {
      final technicians = await getTechnicians(garageId);
      return technicians.map((t) => t.specialty).toSet();
    } catch (e) {
      print('❌ Erreur récupération spécialités: $e');
      return {};
    }
  }
}
