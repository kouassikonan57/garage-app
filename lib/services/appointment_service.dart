import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import 'notification_service.dart';
import 'loyalty_service.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService;
  LoyaltyService? _loyaltyService;

  // MODIFIER le constructeur pour injecter NotificationService
  AppointmentService({
    LoyaltyService? loyaltyService,
    required NotificationService notificationService,
  })  : _loyaltyService = loyaltyService,
        _notificationService = notificationService;

  void updateLoyaltyService(LoyaltyService loyaltyService) {
    _loyaltyService = loyaltyService;
    print('✅ AppointmentService: LoyaltyService mis à jour');
  }

  // Mettre à jour un rendez-vous complet
  Future<void> updateAppointment(Appointment updatedAppointment) async {
    try {
      if (updatedAppointment.id == null) {
        throw Exception('Appointment ID is required for update');
      }

      await _firestore
          .collection('appointments')
          .doc(updatedAppointment.id)
          .update(updatedAppointment.toMap());

      print('🔄 RDV MIS À JOUR: ${updatedAppointment.clientName}');
    } catch (e) {
      print('❌ Erreur mise à jour RDV: $e');
      throw e;
    }
  }

  // NOUVELLE MÉTHODE : Vérifier si un changement de statut est autorisé
  bool isStatusChangeAllowed(String currentStatus, String newStatus) {
    // Définir l'ordre du workflow (unidirectionnel)
    final workflowOrder = [
      'pending',
      'confirmed',
      'in_progress',
      'diagnostic',
      'repair',
      'quality_check',
      'completed'
    ];

    final currentIndex = workflowOrder.indexOf(currentStatus);
    final newIndex = workflowOrder.indexOf(newStatus);

    // Autoriser seulement la progression vers l'avant
    if (currentIndex != -1 && newIndex != -1) {
      return newIndex > currentIndex;
    }

    // Autoriser les statuts spéciaux (annulé, rejeté) à tout moment
    return newStatus == 'cancelled' || newStatus == 'rejected';
  }

  // METTRE À JOUR : Mettre à jour le statut avec validation
  Future<void> updateAppointmentStatus(
      String appointmentId, String newStatus) async {
    try {
      // Récupérer le RDV actuel pour vérifier le statut
      final currentAppointment = await getAppointment(appointmentId);
      if (currentAppointment == null) {
        throw Exception('Rendez-vous non trouvé');
      }

      // Valider le changement de statut
      if (!isStatusChangeAllowed(currentAppointment.status, newStatus)) {
        throw Exception(
            'Changement de statut non autorisé: ${currentAppointment.status} -> $newStatus');
      }

      final updates = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Ajouter un timestamp spécifique pour certains statuts
      if (newStatus == 'in_progress') {
        updates['startedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'completed') {
        updates['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update(updates);

      // Envoyer les notifications
      await _sendStatusNotifications(currentAppointment, newStatus);

      print('🔄 STATUT MODIFIÉ: $appointmentId -> $newStatus');
    } catch (e) {
      print('❌ Erreur mise à jour statut: $e');
      throw e;
    }
  }

  // NOUVELLE MÉTHODE : Envoyer les notifications de statut
  Future<void> _sendStatusNotifications(
      Appointment appointment, String newStatus) async {
    // NOTIFICATION AVEC EMAIL
    await _notificationService.sendStatusUpdate(
      appointment.clientName,
      appointment.service,
      newStatus,
      clientEmail: appointment.clientEmail, // AJOUTER l'email
    );

    // Système de fidélité pour les RDV complétés
    if (newStatus == 'completed' && _loyaltyService != null) {
      print('🎯 DÉCLENCHEMENT FIDÉLITÉ AUTO pour: ${appointment.clientName}');
      await _loyaltyService!.awardPointsForAppointment(appointment);
    }

    if (newStatus == 'confirmed') {
      await _scheduleReminder(appointment);
    }

    // PROGRAMMER LES RAPPELS DE SUIVI APRÈS RDV
    if (newStatus == 'completed') {
      await _scheduleFollowUpReminders(appointment);
    }
  }

  // Progresser au statut suivant
  Future<void> progressToNextStatus(
      String appointmentId, String currentStatus) async {
    try {
      String nextStatus = _getNextStatus(currentStatus);

      if (nextStatus != currentStatus) {
        await updateAppointmentStatus(appointmentId, nextStatus);
      }
    } catch (e) {
      print('❌ Erreur progression statut: $e');
      throw e;
    }
  }

  // Obtenir le statut suivant dans le workflow
  String _getNextStatus(String currentStatus) {
    switch (currentStatus) {
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
        return currentStatus;
    }
  }

  // Vérifier si un statut peut progresser
  bool canProgressStatus(String currentStatus) {
    return ['confirmed', 'in_progress', 'diagnostic', 'repair', 'quality_check']
        .contains(currentStatus);
  }

  // Obtenir le texte du statut pour l'affichage
  String getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmé';
      case 'in_progress':
        return 'En cours de préparation';
      case 'diagnostic':
        return 'Diagnostic';
      case 'repair':
        return 'En réparation';
      case 'quality_check':
        return 'Contrôle qualité';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      case 'rejected':
        return 'Rejeté';
      default:
        return status;
    }
  }

  Future<String?> bookAppointment(Appointment appointment) async {
    try {
      // Vérifier la disponibilité du créneau
      final startOfHour = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
        appointment.dateTime.hour,
      );
      final endOfHour = startOfHour.add(const Duration(hours: 1));

      final conflictingAppointments = await _firestore
          .collection('appointments')
          .where('dateTime', isGreaterThanOrEqualTo: startOfHour)
          .where('dateTime', isLessThan: endOfHour)
          .where('status', whereIn: ['pending', 'confirmed']).get();

      if (conflictingAppointments.docs.isNotEmpty) {
        return 'Ce créneau horaire est déjà réservé';
      }

      final docRef = _firestore.collection('appointments').doc();

      final appointmentWithId = appointment.copyWith(id: docRef.id);

      await docRef.set(appointmentWithId.toMap());

      // PROGRAMMER LES RAPPELS AVANCÉS
      await _scheduleAdvancedReminders(appointmentWithId);

      // METTRE À JOUR : Ajouter l'email dans la notification
      await _notificationService.sendAppointmentConfirmation(
        appointment.clientName,
        appointment.service,
        appointment.dateTime,
        clientEmail: appointment.clientEmail, // AJOUTER
      );

      print(
          '✅ RENDEZ-VOUS AJOUTÉ: ${appointment.clientName} - ${appointment.service}');
      return null;
    } catch (e) {
      print('❌ Erreur prise de RDV: $e');
      return 'Erreur lors de la prise de rendez-vous';
    }
  }

  // METTRE À JOUR : Système de rappels avancés avec emails
  Future<void> _scheduleAdvancedReminders(Appointment appointment) async {
    try {
      final now = DateTime.now();
      final appointmentDate = appointment.dateTime;

      // Rappel 24h avant
      final reminder24h = appointmentDate.subtract(const Duration(hours: 24));
      if (reminder24h.isAfter(now)) {
        await _notificationService.scheduleNotification(
          title: '📅 Rappel RDV Demain',
          body:
              'Votre rendez-vous pour ${appointment.service} est demain à ${_formatTime(appointment.dateTime)}',
          scheduledTime: reminder24h,
          payload: {
            'type': 'appointment_reminder_24h',
            'appointmentId': appointment.id!,
          },
          clientEmail: appointment.clientEmail, // AJOUTER
          clientName: appointment.clientName, // AJOUTER
        );
        print('⏰ Rappel 24h programmé pour: ${appointment.clientName}');
      }

      // Rappel 2h avant
      final reminder2h = appointmentDate.subtract(const Duration(hours: 2));
      if (reminder2h.isAfter(now)) {
        await _notificationService.scheduleNotification(
          title: '⏰ RDV dans 2 heures',
          body:
              'Préparez-vous pour votre rendez-vous ${appointment.service} chez le garage',
          scheduledTime: reminder2h,
          payload: {
            'type': 'appointment_reminder_2h',
            'appointmentId': appointment.id!,
          },
          clientEmail: appointment.clientEmail, // AJOUTER
          clientName: appointment.clientName, // AJOUTER
        );
        print('⏰ Rappel 2h programmé pour: ${appointment.clientName}');
      }

      // Alerte trafic 1h avant
      final trafficAlert = appointmentDate.subtract(const Duration(hours: 1));
      if (trafficAlert.isAfter(now)) {
        await _notificationService.scheduleNotification(
          title: '🚗 Pensez au trafic',
          body:
              'Votre RDV est dans 1h. Vérifiez le trafic pour arriver à l\'heure',
          scheduledTime: trafficAlert,
          payload: {
            'type': 'traffic_alert',
            'appointmentId': appointment.id!,
          },
          clientEmail: appointment.clientEmail, // AJOUTER
          clientName: appointment.clientName, // AJOUTER
        );
        print('🚗 Alerte trafic programmée pour: ${appointment.clientName}');
      }

      // Rappel la veille pour les préparatifs
      final preparationReminder =
          appointmentDate.subtract(const Duration(hours: 12));
      if (preparationReminder.isAfter(now)) {
        await _notificationService.scheduleNotification(
          title: '🔧 Préparatifs RDV',
          body: 'Pensez à apporter votre carte grise et les clés du véhicule',
          scheduledTime: preparationReminder,
          payload: {
            'type': 'preparation_reminder',
            'appointmentId': appointment.id!,
          },
          clientEmail: appointment.clientEmail, // AJOUTER
          clientName: appointment.clientName, // AJOUTER
        );
      }
    } catch (e) {
      print('❌ Erreur programmation rappels: $e');
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
  }

  Future<List<Appointment>> getClientAppointments(String clientEmail) async {
    try {
      print('📅 Recherche des RDV pour: $clientEmail');

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('clientEmail', isEqualTo: clientEmail)
          .get();

      print('📊 RDV trouvés: ${querySnapshot.docs.length}');

      final appointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();

      // Trier localement par date (plus récent en premier)
      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      return appointments;
    } catch (e) {
      print('❌ Erreur récupération RDV client: $e');
      return [];
    }
  }

  Future<List<Appointment>> getAllAppointments() async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .orderBy('dateTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération tous les RDV: $e');
      throw e;
    }
  }

  Future<Appointment?> getAppointment(String appointmentId) async {
    try {
      final doc =
          await _firestore.collection('appointments').doc(appointmentId).get();
      if (doc.exists) {
        return Appointment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération rendez-vous: $e');
      return null;
    }
  }

  Future<List<Appointment>> getGarageAppointments(String garageId) async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('garageId', isEqualTo: garageId)
          .orderBy('dateTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération rendez-vous garage: $e');
      return [];
    }
  }

  // RAPPELS DE SUIVI APRÈS RDV
  Future<void> _scheduleFollowUpReminders(Appointment appointment) async {
    try {
      final now = DateTime.now();

      // Rappel 3 jours après pour feedback
      final feedbackReminder =
          appointment.dateTime.add(const Duration(days: 3));
      if (feedbackReminder.isAfter(now)) {
        await _notificationService.scheduleNotification(
          title: '💬 Comment s\'est passé votre RDV ?',
          body: 'Donnez votre avis sur la réparation de ${appointment.service}',
          scheduledTime: feedbackReminder,
          payload: {
            'type': 'feedback_reminder',
            'appointmentId': appointment.id!,
          },
          clientEmail: appointment.clientEmail, // AJOUTER
          clientName: appointment.clientName, // AJOUTER
        );
      }

      // Rappel entretien suivant (selon le type de service)
      final nextMaintenance = _calculateNextMaintenance(appointment);
      if (nextMaintenance.isAfter(now)) {
        await _notificationService.scheduleNotification(
          title: '🔧 Rappel entretien',
          body:
              'Il est temps de programmer votre prochain ${appointment.service}',
          scheduledTime: nextMaintenance.subtract(const Duration(days: 7)),
          payload: {
            'type': 'maintenance_reminder',
            'appointmentId': appointment.id!,
          },
          clientEmail: appointment.clientEmail, // AJOUTER
          clientName: appointment.clientName, // AJOUTER
        );
      }
    } catch (e) {
      print('❌ Erreur programmation rappels suivi: $e');
    }
  }

  DateTime _calculateNextMaintenance(Appointment appointment) {
    final baseDate = appointment.dateTime;

    switch (appointment.service.toLowerCase()) {
      case 'vidange':
        return baseDate.add(const Duration(days: 90));
      case 'révision complète':
        return baseDate.add(const Duration(days: 365));
      case 'freinage':
        return baseDate.add(const Duration(days: 180));
      case 'pneus':
        return baseDate.add(const Duration(days: 365));
      default:
        return baseDate.add(const Duration(days: 180));
    }
  }

  Future<void> _scheduleReminder(Appointment appointment) async {
    final reminderDate = appointment.dateTime.subtract(const Duration(days: 1));
    if (reminderDate.isAfter(DateTime.now())) {
      print('⏰ RAPPEL PROGRAMMÉ pour: ${appointment.clientName}');
      // METTRE À JOUR : Ajouter l'email dans le rappel
      await _notificationService.sendReminder(
        appointment.clientName,
        appointment.service,
        appointment.dateTime,
        clientEmail: appointment.clientEmail, // AJOUTER
      );
    }
  }

  List<String> getAvailableServices() {
    return [
      'Vidange',
      'Révision complète',
      'Changement pneus',
      'Freinage',
      'Diagnostic',
      'Climatisation',
      'Carrosserie',
      'Mécanique générale'
    ];
  }

  Future<List<DateTime>> getAvailableTimeSlots(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
          .where('dateTime', isLessThanOrEqualTo: endOfDay)
          .where('status', whereIn: ['pending', 'confirmed']).get();

      final bookedSlots = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final dt = data['dateTime'] as Timestamp;
        return dt.toDate();
      }).toList();

      final availableSlots = <DateTime>[];
      final now = DateTime.now();

      for (int hour = 8; hour <= 17; hour++) {
        final slot = DateTime(date.year, date.month, date.day, hour);

        if (slot.isAfter(now)) {
          bool isReserved = bookedSlots.any((bookedSlot) =>
              bookedSlot.year == slot.year &&
              bookedSlot.month == slot.month &&
              bookedSlot.day == slot.day &&
              bookedSlot.hour == slot.hour);

          if (!isReserved) {
            availableSlots.add(slot);
          }
        }
      }

      return availableSlots;
    } catch (e) {
      print('❌ Erreur récupération créneaux: $e');
      return [];
    }
  }

  Future<List<Appointment>> getUpcomingAppointments() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('dateTime', isGreaterThan: now)
          .orderBy('dateTime')
          .get();

      return querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération RDV à venir: $e');
      throw e;
    }
  }

  Future<List<Appointment>> getPastAppointments() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('dateTime', isLessThan: now)
          .orderBy('dateTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération RDV passés: $e');
      throw e;
    }
  }

  // Récupérer les RDV assignés à un technicien
  Future<List<Appointment>> getTechnicianAppointments(
      String technicianId) async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('assignedTechnicianId', isEqualTo: technicianId)
          .get();

      return querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération RDV technicien: $e');
      throw e;
    }
  }

  Future<Map<String, int>> getAppointmentStats() async {
    try {
      final allAppointments = await getAllAppointments();
      final now = DateTime.now();

      final upcoming =
          allAppointments.where((a) => a.dateTime.isAfter(now)).length;
      final past =
          allAppointments.where((a) => a.dateTime.isBefore(now)).length;
      final pending =
          allAppointments.where((a) => a.status == 'pending').length;
      final confirmed =
          allAppointments.where((a) => a.status == 'confirmed').length;
      final inProgress =
          allAppointments.where((a) => a.status == 'in_progress').length;
      final diagnostic =
          allAppointments.where((a) => a.status == 'diagnostic').length;
      final repair = allAppointments.where((a) => a.status == 'repair').length;
      final qualityCheck =
          allAppointments.where((a) => a.status == 'quality_check').length;
      final completed =
          allAppointments.where((a) => a.status == 'completed').length;
      final cancelled =
          allAppointments.where((a) => a.status == 'cancelled').length;

      return {
        'total': allAppointments.length,
        'upcoming': upcoming,
        'past': past,
        'pending': pending,
        'confirmed': confirmed,
        'in_progress': inProgress,
        'diagnostic': diagnostic,
        'repair': repair,
        'quality_check': qualityCheck,
        'completed': completed,
        'cancelled': cancelled,
      };
    } catch (e) {
      print('❌ Erreur statistiques RDV: $e');
      return {
        'total': 0,
        'upcoming': 0,
        'past': 0,
        'pending': 0,
        'confirmed': 0,
        'in_progress': 0,
        'diagnostic': 0,
        'repair': 0,
        'quality_check': 0,
        'completed': 0,
        'cancelled': 0,
      };
    }
  }

  // Écouter les changements en temps réel pour un client
  Stream<List<Appointment>> streamClientAppointments(String clientEmail) {
    return _firestore
        .collection('appointments')
        .where('clientEmail', isEqualTo: clientEmail)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .toList());
  }

  // Écouter tous les RDV en temps réel (pour les garages)
  Stream<List<Appointment>> streamAllAppointments() {
    return _firestore
        .collection('appointments')
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .toList());
  }

  // Écouter les RDV d'un technicien en temps réel
  Stream<List<Appointment>> streamTechnicianAppointments(String technicianId) {
    return _firestore
        .collection('appointments')
        .where('assignedTechnicianId', isEqualTo: technicianId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .toList());
  }

  // Annuler tous les rappels d'un RDV
  Future<void> cancelAppointmentReminders(String appointmentId) async {
    try {
      await _notificationService.cancelScheduledNotifications(
        filter: {'appointmentId': appointmentId},
      );
      print('🗑️ Rappels annulés pour RDV: $appointmentId');
    } catch (e) {
      print('❌ Erreur annulation rappels: $e');
    }
  }
}
