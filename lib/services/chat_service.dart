import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Envoyer un message
  Future<void> sendMessage(ChatMessage message) async {
    try {
      print('📤 Envoi du message: ${message.content}');

      await _firestore
          .collection('chat_messages')
          .doc(message.id)
          .set(message.toMap());

      print('✅ Message sauvegardé dans Firestore');

      // Mettre à jour la conversation
      await _updateConversation(message);

      print('💬 Message envoyé: ${message.content}');
    } catch (e) {
      print('❌ Erreur envoi message: $e');
      throw e;
    }
  }

  // Récupérer l'historique des messages - VERSION ULTIME
  Future<List<ChatMessage>> getChatMessages(
      String appointmentId, String garageId) async {
    try {
      print(
          '🔍 Chargement messages pour RDV: $appointmentId, Garage: $garageId');

      // ESSAI 1: Méthode optimisée avec les bons filtres
      try {
        final querySnapshot = await _firestore
            .collection('chat_messages')
            .where('appointmentId', isEqualTo: appointmentId)
            .where('garageId', isEqualTo: garageId)
            .orderBy('timestamp', descending: false)
            .limit(50)
            .get();

        final messages = querySnapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .where((message) => !_isMessageDeletedForGarage(
                message, garageId)) // FILTRE SUPPRESSION
            .toList();

        print('✅ Méthode 1 réussie: ${messages.length} messages trouvés');
        return messages;
      } catch (e) {
        print('⚠️ Méthode 1 échouée: $e');
        // Continuer à la méthode de secours
      }

      // ESSAI 2: Méthode de secours sans filtre garageId
      try {
        final querySnapshot = await _firestore
            .collection('chat_messages')
            .where('appointmentId', isEqualTo: appointmentId)
            .orderBy('timestamp', descending: false)
            .limit(50)
            .get();

        final allMessages = querySnapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList();

        // Filtrer localement par garageId et suppression
        final filteredMessages = allMessages.where((message) {
          return message.garageId == garageId &&
              !_isMessageDeletedForGarage(message, garageId);
        }).toList();

        print(
            '✅ Méthode 2 réussie: ${filteredMessages.length} messages filtrés');
        return filteredMessages;
      } catch (e) {
        print('⚠️ Méthode 2 échouée: $e');
        // Continuer à la méthode ultime
      }

      // ESSAI 3: Méthode ultime - tout charger et filtrer
      return await _getAllMessagesAndFilter(appointmentId, garageId);
    } catch (e) {
      print('❌ Erreur récupération messages: $e');
      return [];
    }
  }

  // Vérifier si le message est supprimé pour le garage
  bool _isMessageDeletedForGarage(ChatMessage message, String garageId) {
    // Si le message a un champ deletedForGarages, vérifier si ce garage y est
    // Cette logique sera implémentée dans fromFirestore
    return false; // Temporaire - la vraie logique est dans fromFirestore
  }

  // Méthode ultime de secours
  Future<List<ChatMessage>> _getAllMessagesAndFilter(
      String appointmentId, String garageId) async {
    try {
      print('🔄 Utilisation méthode ultime de secours...');

      final querySnapshot = await _firestore
          .collection('chat_messages')
          .orderBy('timestamp', descending: false)
          .limit(100)
          .get();

      print(
          '📊 Total documents dans chat_messages: ${querySnapshot.docs.length}');

      final allMessages = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print(
            '📄 Document: ${doc.id} - appointmentId: ${data['appointmentId']} - garageId: ${data['garageId']}');
        return ChatMessage.fromFirestore(doc);
      }).toList();

      // Filtrer localement
      final filteredMessages = allMessages.where((message) {
        final matches = message.appointmentId == appointmentId &&
            message.garageId == garageId;
        if (matches) {
          print(
              '🎯 MESSAGE CORRESPOND: "${message.content}" - ${message.timestamp}');
        }
        return matches;
      }).toList();

      print('📨 Messages correspondants: ${filteredMessages.length}');
      return filteredMessages;
    } catch (e) {
      print('❌ Erreur méthode ultime: $e');
      return [];
    }
  }

  // Écouter les messages en temps réel - VERSION INTELLIGENTE
  Stream<List<ChatMessage>> subscribeToChat(
      String appointmentId, String garageId) {
    print(
        '🎧 Démarrage écoute temps réel pour: $appointmentId, Garage: $garageId');

    try {
      // ESSAI: Stream avec les bons filtres
      return _firestore
          .collection('chat_messages')
          .where('appointmentId', isEqualTo: appointmentId)
          .where('garageId', isEqualTo: garageId)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .handleError((error) {
        print('❌ Erreur stream Firestore (rebasculer vers polling): $error');
        // En cas d'erreur, basculer vers un stream vide et laisser le polling gérer
        return Stream<List<ChatMessage>>.empty();
      }).map((snapshot) {
        final messages = snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .where((message) => !_isMessageDeletedForGarage(
                message, garageId)) // FILTRE SUPPRESSION
            .toList();
        print('🔄 Mise à jour temps réel: ${messages.length} messages');
        return messages;
      });
    } catch (e) {
      print('❌ Erreur configuration écoute temps réel: $e');
      return Stream<List<ChatMessage>>.empty();
    }
  }

  // Mettre à jour la conversation
  Future<void> _updateConversation(ChatMessage message) async {
    try {
      final conversationId = '${message.appointmentId}_${message.garageId}';

      print('💾 Mise à jour conversation: $conversationId');

      // CORRECTION: Utiliser FieldValue.serverTimestamp() pour updatedAt
      await _firestore
          .collection('chat_conversations')
          .doc(conversationId)
          .set({
        'id': conversationId,
        'appointmentId': message.appointmentId,
        'garageId': message.garageId,
        'clientEmail': message.clientEmail ?? '',
        'clientName': message.clientName ??
            message.clientEmail?.split('@').first ??
            'Client',
        'lastMessage': _getLastMessagePreview(message), // AMÉLIORATION
        'updatedAt': FieldValue.serverTimestamp(), // CORRECTION ICI
        'lastMessageTimestamp': FieldValue.serverTimestamp(), // AJOUT
        'unreadCount': message.senderType == SenderType.client
            ? FieldValue.increment(1)
            : 0,
      }, SetOptions(merge: true));

      print('✅ Conversation mise à jour');
    } catch (e) {
      print('❌ Erreur mise à jour conversation: $e');
      // Ne pas propager l'erreur pour ne pas bloquer l'envoi du message
    }
  }

  // Obtenir un aperçu du dernier message selon le type
  String _getLastMessagePreview(ChatMessage message) {
    switch (message.type) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.file:
        return '📎 Fichier: ${message.fileName ?? "Document"}';
      case MessageType.system:
        return '⚙️ Message système';
      default:
        return message.content;
    }
  }

  // NOUVELLE MÉTHODE: Forcer le rechargement des messages
  Future<void> forceRefreshMessages(
      String appointmentId, String garageId) async {
    try {
      print('🔄 Forcer le rechargement des messages...');
      final messages = await getChatMessages(appointmentId, garageId);
      print('✅ Rechargement forcé: ${messages.length} messages');
    } catch (e) {
      print('❌ Erreur rechargement forcé: $e');
    }
  }

  Future<void> markMessagesAsRead(String appointmentId, String garageId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chat_messages')
          .where('appointmentId', isEqualTo: appointmentId)
          .where('garageId', isEqualTo: garageId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      final conversationId = '${appointmentId}_${garageId}';
      await _firestore
          .collection('chat_conversations')
          .doc(conversationId)
          .update({'unreadCount': 0});
    } catch (e) {
      print('❌ Erreur marquage messages lus: $e');
    }
  }

  Future<List<ChatConversation>> getGarageConversations(String garageId) async {
    try {
      print('🔍 Chargement conversations pour garage: $garageId');

      final querySnapshot = await _firestore
          .collection('chat_conversations')
          .where('garageId', isEqualTo: garageId)
          .orderBy('updatedAt', descending: true)
          .get();

      final conversations = querySnapshot.docs
          .map((doc) => ChatConversation.fromFirestore(doc))
          .toList();

      print('✅ ${conversations.length} conversations chargées pour le garage');
      return conversations;
    } catch (e) {
      print('❌ Erreur récupération conversations garage: $e');

      // MÉTHODE DE SECOURS AMÉLIORÉE
      return await _getGarageConversationsFallback(garageId);
    }
  }

  // NOUVELLE MÉTHODE DE SECOURS
  Future<List<ChatConversation>> _getGarageConversationsFallback(
      String garageId) async {
    try {
      print('🔄 Utilisation méthode de secours pour conversations...');

      final allConversations =
          await _firestore.collection('chat_conversations').get();

      final filteredConversations = allConversations.docs
          .where((doc) {
            final data = doc.data();
            final docGarageId = data['garageId'];
            return docGarageId == garageId;
          })
          .map((doc) => ChatConversation.fromFirestore(doc))
          .toList();

      // Trier manuellement par updatedAt
      filteredConversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      print(
          '✅ ${filteredConversations.length} conversations filtrées chargées');
      return filteredConversations;
    } catch (fallbackError) {
      print('❌ Erreur méthode de secours: $fallbackError');
      return [];
    }
  }

  Future<void> debugConversations(String garageId) async {
    try {
      print('🐛 DEBUG: Analyse des conversations...');

      final allDocs = await _firestore.collection('chat_conversations').get();

      print(
          '📊 Total documents dans chat_conversations: ${allDocs.docs.length}');

      for (var doc in allDocs.docs) {
        final data = doc.data();
        print('📄 Document ${doc.id}:');
        print('   - garageId: ${data['garageId']}');
        print('   - clientEmail: ${data['clientEmail']}');
        print('   - updatedAt: ${data['updatedAt']}');
        print('   - lastMessage: ${data['lastMessage']}');
        print('   ---');
      }

      // Vérifier les conversations pour ce garage
      final garageConversations = allDocs.docs
          .where((doc) => doc.data()['garageId'] == garageId)
          .toList();

      print(
          '🎯 Conversations pour garage_principal: ${garageConversations.length}');
    } catch (e) {
      print('❌ Erreur debug: $e');
    }
  }

  // SUPPRESSION POUR TOUS LES TYPES DE MESSAGES
  Future<void> deleteMessageForEveryone(String messageId) async {
    try {
      await _firestore.collection('chat_messages').doc(messageId).delete();
      print('✅ Message supprimé pour tout le monde: $messageId');
    } catch (e) {
      print('❌ Erreur suppression message pour tous: $e');
      throw e;
    }
  }

  Future<void> deleteMessageForGarage(String messageId, String garageId) async {
    try {
      // Marquer le message comme supprimé pour ce garage
      await _firestore.collection('chat_messages').doc(messageId).update({
        'deletedForGarages': FieldValue.arrayUnion([garageId])
      });
      print('✅ Message supprimé pour le garage: $messageId');
    } catch (e) {
      print('❌ Erreur suppression message pour garage: $e');
      throw e;
    }
  }

  Future<void> deleteMessageForClient(
      String messageId, String clientEmail) async {
    try {
      // Marquer le message comme supprimé pour ce client
      await _firestore.collection('chat_messages').doc(messageId).update({
        'deletedForClients': FieldValue.arrayUnion([clientEmail])
      });
      print('✅ Message supprimé pour le client: $messageId');
    } catch (e) {
      print('❌ Erreur suppression message pour client: $e');
      throw e;
    }
  }

  Future<void> debugGarageConversations(String garageId) async {
    try {
      print('🐛 DEBUG: Analyse des conversations garage...');

      final allDocs = await _firestore.collection('chat_conversations').get();

      print(
          '📊 Total documents dans chat_conversations: ${allDocs.docs.length}');

      for (var doc in allDocs.docs) {
        final data = doc.data();
        print('📄 Document ${doc.id}:');
        print('   - garageId: ${data['garageId']}');
        print('   - clientEmail: ${data['clientEmail']}');
        print('   - updatedAt: ${data['updatedAt']}');
        print('   - lastMessage: ${data['lastMessage']}');
        print('   - unreadCount: ${data['unreadCount']}');
        print('   ---');
      }

      // Vérifier les conversations pour ce garage
      final garageConversations = allDocs.docs
          .where((doc) => doc.data()['garageId'] == garageId)
          .toList();

      print('🎯 Conversations pour $garageId: ${garageConversations.length}');
    } catch (e) {
      print('❌ Erreur debug garage: $e');
    }
  }

  Future<List<ChatConversation>> getClientConversations(
      String clientEmail) async {
    try {
      final querySnapshot = await _firestore
          .collection('chat_conversations')
          .where('clientEmail', isEqualTo: clientEmail)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChatConversation.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération conversations client: $e');
      return [];
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _firestore
          .collection('chat_conversations')
          .doc(conversationId)
          .delete();
    } catch (e) {
      print('❌ Erreur suppression conversation: $e');
      throw e;
    }
  }

  Future<bool> conversationExists(String appointmentId, String garageId) async {
    try {
      final conversationId = '${appointmentId}_${garageId}';
      final doc = await _firestore
          .collection('chat_conversations')
          .doc(conversationId)
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ Erreur vérification conversation: $e');
      return false;
    }
  }

  Future<void> createEmptyConversation(String appointmentId, String garageId,
      String clientEmail, String clientName) async {
    try {
      final conversationId = '${appointmentId}_${garageId}';

      await _firestore
          .collection('chat_conversations')
          .doc(conversationId)
          .set({
        'id': conversationId,
        'appointmentId': appointmentId,
        'garageId': garageId,
        'clientEmail': clientEmail,
        'clientName': clientName,
        'lastMessage': 'Conversation démarrée',
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      });

      print('✅ Conversation vide créée: $conversationId');
    } catch (e) {
      print('❌ Erreur création conversation: $e');
      throw e;
    }
  }

  Future<void> updateMessage(String messageId, String newContent) async {
    try {
      await _firestore.collection('chat_messages').doc(messageId).update({
        'content': newContent,
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Message modifié: $messageId');
    } catch (e) {
      print('❌ Erreur modification message: $e');
      throw e;
    }
  }

  void dispose() {
    // Nettoyage si nécessaire
  }
}
