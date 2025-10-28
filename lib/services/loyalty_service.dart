import '../models/loyalty_model.dart';
import '../models/appointment_model.dart';
import 'appointment_service.dart';
import 'client_service.dart';

class LoyaltyService {
  // Liste statique pour la démonstration (remplacera par Firebase plus tard)
  static final List<LoyaltyProgram> _loyaltyPrograms = [];
  static final List<LoyaltyTransaction> _transactions = [];

  // Services pour accéder aux données réelles - MODIFIÉ : rendus optionnels
  AppointmentService? _appointmentService;
  final ClientService _clientService;

  // CONSTRUCTEUR MODIFIÉ : clientService requis, appointmentService optionnel
  LoyaltyService({
    required ClientService clientService,
    AppointmentService? appointmentService,
  })  : _appointmentService = appointmentService,
        _clientService = clientService;

  // Méthode pour mettre à jour l'AppointmentService après l'initialisation
  void updateAppointmentService(AppointmentService appointmentService) {
    _appointmentService = appointmentService;
    print('✅ LoyaltyService: AppointmentService mis à jour');
  }

  // Attribuer automatiquement les points après un RDV
  Future<void> awardPointsForAppointment(Appointment appointment) async {
    // AJOUT: Vérifier si _appointmentService est disponible
    if (_appointmentService == null) {
      print('⚠️ AppointmentService non disponible pour attribution des points');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final points = _calculatePointsForService(appointment.service);

    print(
        '🎯 Attribution auto de $points points pour ${appointment.clientName}');

    // Récupérer ou créer le programme du client
    var program = await _getLoyaltyProgram(appointment.clientEmail);

    if (program == null) {
      program = await _enrollClientAuto(
          appointment.clientEmail, appointment.clientName);
    }

    // Ajouter les points
    await _addPointsAuto(appointment.clientEmail, points,
        '${appointment.service} - RDV #${appointment.id}', appointment.id);

    // Vérifier et mettre à jour le niveau
    await _checkAndUpdateTierAuto(appointment.clientEmail);
  }

  // Calcul automatique des points selon le service
  int _calculatePointsForService(String service) {
    final pointsMap = {
      'Vidange': 50,
      'Révision complète': 75,
      'Changement pneus': 60,
      'Freinage': 70,
      'Diagnostic': 30,
      'Climatisation': 40,
      'Carrosserie': 100,
      'Mécanique générale': 80,
    };

    return pointsMap[service] ?? 50;
  }

  // Création automatique du programme fidélité
  Future<LoyaltyProgram> _enrollClientAuto(
      String clientEmail, String clientName) async {
    final newProgram = LoyaltyProgram(
      id: 'lp_${DateTime.now().millisecondsSinceEpoch}',
      clientId: 'client_$clientEmail',
      clientEmail: clientEmail,
      points: 0,
      currentTier: 'Nouveau',
      totalSpent: 0,
      totalVisits: 0,
      joinDate: DateTime.now(),
      lastActivity: DateTime.now(),
      transactions: [],
    );

    _loyaltyPrograms.add(newProgram);

    print('📝 Programme fidélité créé auto pour: $clientEmail');

    return newProgram;
  }

  // Ajout automatique des points
  Future<void> _addPointsAuto(
    String clientEmail,
    int points,
    String description,
    String? appointmentId,
  ) async {
    final programIndex =
        _loyaltyPrograms.indexWhere((p) => p.clientEmail == clientEmail);

    if (programIndex != -1) {
      final oldProgram = _loyaltyPrograms[programIndex];

      // Créer la transaction
      final transaction = LoyaltyTransaction(
        id: 'lt_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        type: 'earn',
        points: points,
        description: description,
        appointmentId: appointmentId,
      );

      _transactions.add(transaction);

      // Mettre à jour le programme
      final newTransactions =
          List<LoyaltyTransaction>.from(oldProgram.transactions)
            ..add(transaction);

      _loyaltyPrograms[programIndex] = LoyaltyProgram(
        id: oldProgram.id,
        clientId: oldProgram.clientId,
        clientEmail: oldProgram.clientEmail,
        points: oldProgram.points + points,
        currentTier: oldProgram.currentTier,
        totalSpent: oldProgram.totalSpent,
        totalVisits: oldProgram.totalVisits + 1,
        joinDate: oldProgram.joinDate,
        lastActivity: DateTime.now(),
        transactions: newTransactions,
      );

      print('⭐ $points points ajoutés auto à $clientEmail');

      // Envoyer notification des points gagnés (version simplifiée sans NotificationService)
      _sendPointsNotification(clientEmail, oldProgram.clientId, points,
          oldProgram.points + points, description);
    }
  }

  // Vérification et mise à jour automatique du niveau
  Future<void> _checkAndUpdateTierAuto(String clientEmail) async {
    final programIndex =
        _loyaltyPrograms.indexWhere((p) => p.clientEmail == clientEmail);

    if (programIndex != -1) {
      final oldProgram = _loyaltyPrograms[programIndex];
      final newTier = _calculateTier(oldProgram.points);

      if (newTier != oldProgram.currentTier) {
        _loyaltyPrograms[programIndex] = LoyaltyProgram(
          id: oldProgram.id,
          clientId: oldProgram.clientId,
          clientEmail: oldProgram.clientEmail,
          points: oldProgram.points,
          currentTier: newTier,
          totalSpent: oldProgram.totalSpent,
          totalVisits: oldProgram.totalVisits,
          joinDate: oldProgram.joinDate,
          lastActivity: DateTime.now(),
          transactions: oldProgram.transactions,
        );

        print('🏆 Promotion auto: $clientEmail -> $newTier');

        // Envoyer notification de promotion
        _sendTierUpgradeNotification(
            clientEmail, oldProgram.currentTier, newTier);
      }
    }
  }

  String _calculateTier(int points) {
    if (points >= 600) return 'Or';
    if (points >= 300) return 'Argent';
    if (points >= 100) return 'Bronze';
    return 'Nouveau';
  }

  // Récupérer le programme d'un client
  Future<LoyaltyProgram?> _getLoyaltyProgram(String clientEmail) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _loyaltyPrograms.firstWhere((p) => p.clientEmail == clientEmail);
    } catch (e) {
      return null;
    }
  }

  // Obtenir tous les programmes de fidélité (pour l'écran gestion) avec données réelles
  Future<List<LoyaltyProgram>> getAllLoyaltyPrograms() async {
    await Future.delayed(const Duration(seconds: 1));

    // Synchroniser avec les clients réels
    await _syncWithRealClients();

    return _loyaltyPrograms;
  }

  // Obtenir le programme d'un client spécifique
  Future<LoyaltyProgram?> getClientLoyaltyProgram(String clientEmail) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _loyaltyPrograms.firstWhere((p) => p.clientEmail == clientEmail);
    } catch (e) {
      return null;
    }
  }

  // Ajouter des points manuellement (optionnel - pour bonus)
  Future<void> addManualPoints(
    String clientEmail,
    int points,
    String reason,
  ) async {
    await _addPointsAuto(clientEmail, points, 'Bonus: $reason', null);
    await _checkAndUpdateTierAuto(clientEmail);
  }

  // Échanger des points contre une récompense
  Future<void> redeemPoints(
    String clientEmail,
    int points,
    String rewardName,
  ) async {
    final programIndex =
        _loyaltyPrograms.indexWhere((p) => p.clientEmail == clientEmail);

    if (programIndex != -1) {
      final oldProgram = _loyaltyPrograms[programIndex];

      if (oldProgram.points >= points) {
        // Créer transaction de retrait
        final transaction = LoyaltyTransaction(
          id: 'lt_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          type: 'redeem',
          points: -points,
          description: 'Échange: $rewardName',
          appointmentId: null,
        );

        _transactions.add(transaction);

        // Mettre à jour le programme
        final newTransactions =
            List<LoyaltyTransaction>.from(oldProgram.transactions)
              ..add(transaction);

        _loyaltyPrograms[programIndex] = LoyaltyProgram(
          id: oldProgram.id,
          clientId: oldProgram.clientId,
          clientEmail: oldProgram.clientEmail,
          points: oldProgram.points - points,
          currentTier: oldProgram.currentTier,
          totalSpent: oldProgram.totalSpent,
          totalVisits: oldProgram.totalVisits,
          joinDate: oldProgram.joinDate,
          lastActivity: DateTime.now(),
          transactions: newTransactions,
        );

        print('🎁 $clientEmail a échangé $points points pour: $rewardName');

        // Envoyer notification de récompense
        _sendRewardNotification(clientEmail, rewardName, points);
      }
    }
  }

  // NOTIFICATION : Points gagnés (version simplifiée sans NotificationService)
  void _sendPointsNotification(
    String clientEmail,
    String clientId,
    int points,
    int totalPoints,
    String service,
  ) async {
    final clientName = clientId.replaceFirst('client_', '');

    print('🎯 NOTIFICATION POINTS FIDÉLITÉ:');
    print('👤 À: $clientName ($clientEmail)');
    print('⭐ Points gagnés: $points');
    print('💰 Total points: $totalPoints');
    print('🔧 Service: $service');
    print('---');
  }

  // NOTIFICATION : Promotion de niveau (version simplifiée)
  void _sendTierUpgradeNotification(
    String clientEmail,
    String oldTier,
    String newTier,
  ) async {
    final clientName = clientEmail.split('@').first;

    print('🏆 NOTIFICATION PROMOTION:');
    print('👤 À: $clientName ($clientEmail)');
    print('🔄 Promotion: $oldTier → $newTier');
    print('🎁 Avantages: ${_getTierBenefits(newTier)}');
    print('---');
  }

  // NOTIFICATION : Récompense échangée (version simplifiée)
  void _sendRewardNotification(
    String clientEmail,
    String rewardName,
    int points,
  ) async {
    final clientName = clientEmail.split('@').first;

    print('🎁 NOTIFICATION RÉCOMPENSE:');
    print('👤 À: $clientName ($clientEmail)');
    print('🎯 Récompense: $rewardName');
    print('⭐ Points utilisés: $points');
    print('---');
  }

  String _getTierBenefits(String tier) {
    switch (tier) {
      case 'Bronze':
        return 'Réduction 5% • Priorité RDV • Newsletters';
      case 'Argent':
        return 'Réduction 10% • Lavage offert • Diagnostic gratuit';
      case 'Or':
        return 'Réduction 15% • Service VIP • Conseiller dédié';
      default:
        return 'Accès au programme de fidélité';
    }
  }

  // Obtenir les statistiques de fidélité avec données réelles
  Future<Map<String, dynamic>> getLoyaltyStats() async {
    // Synchroniser avec les clients réels pour avoir des données à jour
    await _syncWithRealClients();

    final totalClients = _loyaltyPrograms.length;
    final bronzeClients =
        _loyaltyPrograms.where((p) => p.currentTier == 'Bronze').length;
    final silverClients =
        _loyaltyPrograms.where((p) => p.currentTier == 'Argent').length;
    final goldClients =
        _loyaltyPrograms.where((p) => p.currentTier == 'Or').length;
    final totalPoints =
        _loyaltyPrograms.fold(0, (sum, program) => sum + program.points);
    final totalVisits =
        _loyaltyPrograms.fold(0, (sum, program) => sum + program.totalVisits);

    // Calculer les points moyens par client
    final averagePoints = totalClients > 0 ? totalPoints / totalClients : 0;

    // Clients actifs (au moins une visite dans les 90 derniers jours)
    final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
    final activeClients = _loyaltyPrograms
        .where((p) => p.lastActivity.isAfter(ninetyDaysAgo))
        .length;

    return {
      'totalClients': totalClients,
      'bronzeClients': bronzeClients,
      'silverClients': silverClients,
      'goldClients': goldClients,
      'totalPoints': totalPoints,
      'totalVisits': totalVisits,
      'averagePoints': averagePoints.round(),
      'activeClients': activeClients,
      'inactiveClients': totalClients - activeClients,
    };
  }

  // NOUVELLE MÉTHODE : Synchroniser avec les clients réels
  Future<void> _syncWithRealClients() async {
    // AJOUT: Vérifier si _appointmentService est disponible
    if (_appointmentService == null) {
      print('⚠️ AppointmentService non disponible pour synchronisation');
      return;
    }

    try {
      // Récupérer les rendez-vous réels
      final appointments = await _appointmentService!.getAllAppointments();

      // Récupérer les clients depuis ClientService
      final clientsFromService = await _clientService.getAllClients();

      // Pour chaque client du service, s'assurer qu'il a un programme fidélité
      for (final client in clientsFromService) {
        final existingProgram = await _getLoyaltyProgram(client.email);

        if (existingProgram == null) {
          // Créer un programme fidélité pour ce client
          await _enrollClientAuto(client.email, client.name);
        }
      }

      // Mettre à jour les statistiques des programmes basées sur les rendez-vous réels
      for (final appointment in appointments) {
        final program = await _getLoyaltyProgram(appointment.clientEmail);

        if (program != null) {
          // Vérifier si ce rendez-vous a déjà été comptabilisé
          final transactionExists = _transactions.any(
              (t) => t.appointmentId == appointment.id && t.type == 'earn');

          if (!transactionExists) {
            // Attribuer les points pour ce rendez-vous non comptabilisé
            await awardPointsForAppointment(appointment);
          }
        }
      }

      print('🔄 Synchronisation fidélité avec données réelles terminée');
    } catch (e) {
      print('❌ Erreur synchronisation fidélité avec données réelles: $e');
    }
  }

  // NOUVELLE MÉTHODE : Obtenir les clients éligibles pour la fidélité
  Future<List<Map<String, dynamic>>> getEligibleClients() async {
    try {
      // Récupérer tous les clients depuis ClientService
      final allClients = await _clientService.getAllClients();

      // Filtrer les clients qui n'ont pas encore de programme fidélité
      final eligibleClients = <Map<String, dynamic>>[];

      for (final client in allClients) {
        final program = await _getLoyaltyProgram(client.email);
        if (program == null) {
          eligibleClients.add({
            'email': client.email,
            'name': client.name,
            'phone': client.phone,
            'registrationDate': client.registrationDate,
          });
        }
      }

      return eligibleClients;
    } catch (e) {
      print('❌ Erreur récupération clients éligibles: $e');
      return [];
    }
  }

  // NOUVELLE MÉTHODE : Inscrire un client manuellement au programme
  Future<void> enrollClientManually(
      String clientEmail, String clientName) async {
    try {
      final existingProgram = await _getLoyaltyProgram(clientEmail);

      if (existingProgram != null) {
        throw Exception('Ce client est déjà inscrit au programme fidélité');
      }

      await _enrollClientAuto(clientEmail, clientName);
      print(
          '✅ Client $clientName ($clientEmail) inscrit manuellement au programme fidélité');
    } catch (e) {
      print('❌ Erreur inscription manuelle: $e');
      throw e;
    }
  }

  // NOUVELLE MÉTHODE : Obtenir le classement des clients par points
  Future<List<Map<String, dynamic>>> getClientRanking() async {
    await _syncWithRealClients();

    final rankedClients = _loyaltyPrograms.map((program) {
      return {
        'clientEmail': program.clientEmail,
        'clientName': program.clientId.replaceFirst('client_', ''),
        'points': program.points,
        'tier': program.currentTier,
        'totalVisits': program.totalVisits,
        'lastActivity': program.lastActivity,
      };
    }).toList();

    // Trier par points (décroissant) avec gestion des null
    rankedClients.sort((a, b) {
      final pointsA = a['points'] as int;
      final pointsB = b['points'] as int;
      return pointsB.compareTo(pointsA);
    });

    return rankedClients;
  }

  // NOUVELLE MÉTHODE : Obtenir l'historique des transactions d'un client
  Future<List<LoyaltyTransaction>> getClientTransactionHistory(
      String clientEmail) async {
    try {
      final program = await _getLoyaltyProgram(clientEmail);

      if (program != null) {
        // Trier les transactions par date (plus récent en premier)
        final sortedTransactions =
            List<LoyaltyTransaction>.from(program.transactions)
              ..sort((a, b) => b.date.compareTo(a.date));

        return sortedTransactions;
      }

      return [];
    } catch (e) {
      print('❌ Erreur récupération historique transactions: $e');
      return [];
    }
  }

  // NOUVELLE MÉTHODE : Réinitialiser les points (pour tests/admin)
  Future<void> resetClientPoints(String clientEmail) async {
    final programIndex =
        _loyaltyPrograms.indexWhere((p) => p.clientEmail == clientEmail);

    if (programIndex != -1) {
      final oldProgram = _loyaltyPrograms[programIndex];

      // Créer une transaction de réinitialisation
      final transaction = LoyaltyTransaction(
        id: 'lt_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        type: 'reset',
        points: -oldProgram.points,
        description: 'Réinitialisation des points',
        appointmentId: null,
      );

      _transactions.add(transaction);

      // Mettre à jour le programme
      final newTransactions =
          List<LoyaltyTransaction>.from(oldProgram.transactions)
            ..add(transaction);

      _loyaltyPrograms[programIndex] = LoyaltyProgram(
        id: oldProgram.id,
        clientId: oldProgram.clientId,
        clientEmail: oldProgram.clientEmail,
        points: 0,
        currentTier: 'Nouveau',
        totalSpent: oldProgram.totalSpent,
        totalVisits: oldProgram.totalVisits,
        joinDate: oldProgram.joinDate,
        lastActivity: DateTime.now(),
        transactions: newTransactions,
      );

      print('🔄 Points réinitialisés pour $clientEmail');
    }
  }

  // NOUVELLE MÉTHODE : Obtenir les récompenses disponibles
  Map<String, int> getAvailableRewards() {
    return {
      'Réduction 10%': 100,
      'Lavage offert': 50,
      'Diagnostic gratuit': 75,
      'Vidange gratuite': 200,
      'Révision offerte': 300,
      'Accessoire auto': 150,
    };
  }

  // NOUVELLE MÉTHODE : Vérifier l'éligibilité pour une récompense
  Future<bool> checkRewardEligibility(
      String clientEmail, String rewardName) async {
    try {
      final program = await _getLoyaltyProgram(clientEmail);
      final rewards = getAvailableRewards();
      final requiredPoints = rewards[rewardName];

      if (program != null && requiredPoints != null) {
        return program.points >= requiredPoints;
      }

      return false;
    } catch (e) {
      print('❌ Erreur vérification éligibilité récompense: $e');
      return false;
    }
  }

  // NOUVELLE MÉTHODE : Obtenir les programmes fidélité expirant bientôt
  Future<List<LoyaltyProgram>> getExpiringPrograms() async {
    await _syncWithRealClients();

    final oneYearAgo =
        DateTime.now().subtract(const Duration(days: 330)); // 11 mois
    final expiringPrograms = _loyaltyPrograms.where((program) {
      return program.lastActivity.isBefore(oneYearAgo) && program.points > 0;
    }).toList();

    return expiringPrograms;
  }

  // NOUVELLE MÉTHODE : Obtenir les transactions récentes
  Future<List<LoyaltyTransaction>> getRecentTransactions(
      {int limit = 10}) async {
    // Trier toutes les transactions par date (plus récent en premier)
    final sortedTransactions = List<LoyaltyTransaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return sortedTransactions.take(limit).toList();
  }

  // NOUVELLE MÉTHODE : Rechercher des programmes fidélité
  Future<List<LoyaltyProgram>> searchLoyaltyPrograms(String query) async {
    await _syncWithRealClients();

    if (query.isEmpty) {
      return _loyaltyPrograms;
    }

    final lowercaseQuery = query.toLowerCase();

    return _loyaltyPrograms.where((program) {
      return program.clientEmail.toLowerCase().contains(lowercaseQuery) ||
          program.clientId.toLowerCase().contains(lowercaseQuery) ||
          program.currentTier.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}
