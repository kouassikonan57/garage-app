import '../models/appointment_model.dart';

class AdvancedReminderService {
  static Future<void> initialize() async {
    print('✅ Service de rappels avancés initialisé');
  }

  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required Map<String, dynamic> payload,
  }) async {
    try {
      // Version simplifiée sans notifications locales
      // En production, vous pourrez intégrer un vrai système de notifications

      print('⏰ Notification programmée: "$title" - "$body"');
      print('📅 Pour le: $scheduledTime');
      print('📦 Payload: $payload');

      // Ici vous pouvez intégrer :
      // - Firebase Cloud Messaging (FCM) pour les notifications push
      // - Envoyer des emails/SMS
      // - Stocker en base pour rappels côté serveur
    } catch (e) {
      print('❌ Erreur programmation notification: $e');
    }
  }

  static Future<void> scheduleAppointmentReminders(
      Appointment appointment) async {
    final now = DateTime.now();
    final appointmentDate = appointment.dateTime;

    // Rappel 24h avant
    final reminder24h = appointmentDate.subtract(const Duration(hours: 24));
    if (reminder24h.isAfter(now)) {
      await scheduleNotification(
        title: '📅 Rappel RDV Demain',
        body:
            'Votre rendez-vous pour ${appointment.service} est demain à ${_formatTime(appointment.dateTime)}',
        scheduledTime: reminder24h,
        payload: {
          'type': 'appointment_reminder_24h',
          'appointmentId': appointment.id!,
          'service': appointment.service,
        },
      );
    }

    // Rappel 2h avant
    final reminder2h = appointmentDate.subtract(const Duration(hours: 2));
    if (reminder2h.isAfter(now)) {
      await scheduleNotification(
        title: '⏰ RDV dans 2 heures',
        body: 'Préparez-vous pour votre rendez-vous ${appointment.service}',
        scheduledTime: reminder2h,
        payload: {
          'type': 'appointment_reminder_2h',
          'appointmentId': appointment.id!,
          'service': appointment.service,
        },
      );
    }

    // Alerte trafic 1h avant
    final trafficAlert = appointmentDate.subtract(const Duration(hours: 1));
    if (trafficAlert.isAfter(now)) {
      await scheduleNotification(
        title: '🚗 Pensez au trafic',
        body:
            'Votre RDV est dans 1h. Vérifiez le trafic pour arriver à l\'heure',
        scheduledTime: trafficAlert,
        payload: {
          'type': 'traffic_alert',
          'appointmentId': appointment.id!,
        },
      );
    }
  }

  static Future<void> scheduleFollowUpReminders(Appointment appointment) async {
    final now = DateTime.now();

    // Rappel feedback 3 jours après
    final feedbackReminder = appointment.dateTime.add(const Duration(days: 3));
    if (feedbackReminder.isAfter(now)) {
      await scheduleNotification(
        title: '💬 Comment s\'est passé votre RDV ?',
        body: 'Donnez votre avis sur la réparation de ${appointment.service}',
        scheduledTime: feedbackReminder,
        payload: {
          'type': 'feedback_reminder',
          'appointmentId': appointment.id!,
          'service': appointment.service,
        },
      );
    }

    // Rappel entretien suivant
    final nextMaintenance = _calculateNextMaintenance(appointment);
    if (nextMaintenance.isAfter(now)) {
      await scheduleNotification(
        title: '🔧 Rappel entretien',
        body:
            'Il est temps de programmer votre prochain ${appointment.service}',
        scheduledTime: nextMaintenance.subtract(const Duration(days: 7)),
        payload: {
          'type': 'maintenance_reminder',
          'appointmentId': appointment.id!,
          'service': appointment.service,
        },
      );
    }
  }

  static DateTime _calculateNextMaintenance(Appointment appointment) {
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

  static Future<void> cancelAppointmentReminders(String appointmentId) async {
    try {
      print('🗑️ Rappels annulés pour RDV: $appointmentId');
      // Implémentation d'annulation des rappels
    } catch (e) {
      print('❌ Erreur annulation rappels: $e');
    }
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
  }
}
