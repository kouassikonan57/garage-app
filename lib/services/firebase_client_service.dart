import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enriched_client_model.dart';

class FirebaseClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialiser le service
  Future<void> init() async {
    print('✅ FirebaseClientService initialisé');
  }

  // Récupérer un client par UID
  Future<EnrichedClient?> getClientByUid(String uid) async {
    try {
      print('🔍 FirebaseClientService - Recherche client par UID: $uid');

      final doc = await _firestore.collection('clients').doc(uid).get();

      if (doc.exists) {
        final clientData = doc.data()!;
        print('✅ Client trouvé par UID: ${clientData['email']}');
        print('📋 Données client: $clientData');

        final client = EnrichedClient.fromMap(clientData);
        return client;
      } else {
        print('❌ Client non trouvé pour UID: $uid');
        return null;
      }
    } catch (e) {
      print('❌ Erreur récupération client par UID: $e');
      return null;
    }
  }

  // Récupérer un client par email
  Future<EnrichedClient?> getClientByEmail(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      print(
          '🔍 FirebaseClientService - Recherche client par email: $cleanEmail');

      final query = await _firestore
          .collection('clients')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      print(
          '📊 Résultats de recherche Firestore: ${query.docs.length} documents');

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final clientData = doc.data();

        print('✅ Client trouvé dans Firestore: ${clientData['name']}');
        print('📧 Email stocké: ${clientData['email']}');
        print('🔑 UID stocké: ${clientData['uid']}');
        print('📞 Téléphone stocké: ${clientData['phone']}');
        print('🏠 Adresse stockée: ${clientData['address']}');
        print('📋 ID document: ${doc.id}');

        final client = EnrichedClient.fromMap(clientData);
        return client;
      } else {
        print('❌ Aucun client trouvé dans Firestore pour email: $cleanEmail');

        // Debug: Vérifier tous les clients
        await debugClientCollection();

        return null;
      }
    } catch (e) {
      print('❌ Erreur récupération client par email dans Firestore: $e');
      return null;
    }
  }

  // Sauvegarder ou mettre à jour un client
  Future<void> saveClient(EnrichedClient client) async {
    try {
      print('💾 Début sauvegarde client: ${client.email}');

      // Vérifier que les données sont valides
      if (client.uid.isEmpty) {
        throw Exception('UID client vide');
      }

      // Préparer les données avec email en minuscules pour la cohérence
      final clientData = client.toMap();
      clientData['email'] = client.email.toLowerCase().trim();

      print('📦 Données à sauvegarder: $clientData');
      print('🔑 Document ID (UID): ${client.uid}');

      // Sauvegarder dans Firestore
      await _firestore
          .collection('clients')
          .doc(client.uid)
          .set(clientData, SetOptions(merge: true));

      print('✅ Client sauvegardé avec succès dans Firestore: ${client.email}');

      // Vérifier que la sauvegarde a fonctionné
      await _verifyClientSaved(client.uid);
    } catch (e, stackTrace) {
      print('❌ ERREUR CRITIQUE sauvegarde client: $e');
      print('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Vérifier que le client a bien été sauvegardé
  Future<void> _verifyClientSaved(String uid) async {
    try {
      print('🔍 Vérification sauvegarde pour UID: $uid');
      final doc = await _firestore.collection('clients').doc(uid).get();

      if (doc.exists) {
        print('✅ Vérification réussie - Client présent dans Firestore');
        print('📋 Données vérifiées: ${doc.data()}');
      } else {
        print('❌ Vérification échouée - Client absent de Firestore');
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification: $e');
    }
  }

  // Créer un nouveau client à partir d'un utilisateur
  Future<void> createClientFromUser({
    required String uid,
    required String email,
    required String name,
    String phone = '+225 00 00 00 00',
    String address = 'Adresse non spécifiée',
  }) async {
    try {
      // Vérifier si le client existe déjà
      final existingClient = await getClientByEmail(email);
      if (existingClient != null) {
        print('⚠️ Client existe déjà: $email');
        return;
      }

      // Créer le nouveau client
      final newClient = EnrichedClient(
        id: uid,
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        address: address,
        registrationDate: DateTime.now(),
        totalAppointments: 0,
        vehicles: [],
        lastVisit: null,
      );

      await saveClient(newClient);
      print('✅ Nouveau client créé: $email');
    } catch (e) {
      print('❌ Erreur création client: $e');
      rethrow;
    }
  }

  // Récupérer tous les clients
  Future<List<EnrichedClient>> getAllClients() async {
    try {
      print('📊 Récupération de tous les clients depuis Firestore...');

      final query = await _firestore.collection('clients').get();
      final clients =
          query.docs.map((doc) => EnrichedClient.fromMap(doc.data())).toList();

      print('✅ Récupération de ${clients.length} clients depuis Firestore');
      return clients;
    } catch (e) {
      print('❌ Erreur récupération tous les clients: $e');
      return [];
    }
  }

  // Mettre à jour les statistiques d'un client après un RDV
  Future<void> updateClientAfterAppointment(
    String clientEmail,
    String service,
  ) async {
    try {
      final client = await getClientByEmail(clientEmail);

      if (client != null) {
        final updatedClient = EnrichedClient(
          id: client.id,
          uid: client.uid,
          name: client.name,
          email: client.email,
          phone: client.phone,
          address: client.address,
          registrationDate: client.registrationDate,
          totalAppointments: client.totalAppointments + 1,
          vehicles: client.vehicles,
          lastVisit: DateTime.now(),
          notes: client.notes,
        );

        await saveClient(updatedClient);
        print('📈 Statistiques mises à jour pour: $clientEmail');
      } else {
        print('❌ Client non trouvé pour mise à jour: $clientEmail');
      }
    } catch (e) {
      print('❌ Erreur mise à jour statistiques client: $e');
    }
  }

  // Méthode de débogage pour analyser la collection clients
  Future<void> debugClientCollection() async {
    try {
      print('🔍 === DEBUG COLLECTION CLIENTS ===');
      final allClients = await _firestore.collection('clients').get();

      print('📊 Total clients dans Firestore: ${allClients.docs.length}');

      if (allClients.docs.isEmpty) {
        print('ℹ️ Aucun client dans la collection Firestore');
      } else {
        for (final doc in allClients.docs) {
          final data = doc.data();
          print('   📄 Document ID: ${doc.id}');
          print('   👤 Nom: ${data['name']}');
          print('   📧 Email: ${data['email']}');
          print('   🔑 UID: ${data['uid']}');
          print('   📞 Téléphone: ${data['phone']}');
          print('   🏠 Adresse: ${data['address']}');
          print('   📅 Date inscription: ${data['registrationDate']}');
          print('   ---');
        }
      }
      print('🔍 ================================');
    } catch (e) {
      print('❌ Erreur debug collection: $e');
    }
  }

  // Rechercher des clients par nom ou email
  Future<List<EnrichedClient>> searchClients(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllClients();
      }

      final searchTerm = query.toLowerCase();

      // Recherche par nom
      final nameQuery = await _firestore
          .collection('clients')
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThan: searchTerm + 'z')
          .get();

      // Recherche par email
      final emailQuery = await _firestore
          .collection('clients')
          .where('email', isGreaterThanOrEqualTo: searchTerm)
          .where('email', isLessThan: searchTerm + 'z')
          .get();

      // Fusionner les résultats et supprimer les doublons
      final allDocs = {...nameQuery.docs, ...emailQuery.docs};
      final clients =
          allDocs.map((doc) => EnrichedClient.fromMap(doc.data())).toList();

      print('🔍 Recherche "$query": ${clients.length} résultats');
      return clients;
    } catch (e) {
      print('❌ Erreur recherche clients: $e');
      return [];
    }
  }

  // Supprimer un client (pour la gestion admin)
  Future<void> deleteClient(String uid) async {
    try {
      await _firestore.collection('clients').doc(uid).delete();
      print('🗑️ Client supprimé: $uid');
    } catch (e) {
      print('❌ Erreur suppression client: $e');
      rethrow;
    }
  }
}
