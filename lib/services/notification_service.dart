import 'advanced_reminder_service.dart'; // AJOUTER CET IMPORT

class NotificationService {
  // Simuler l'envoi de notifications
  Future<void> sendAppointmentConfirmation(
      String clientName, String service, DateTime dateTime) async {
    await Future.delayed(const Duration(seconds: 1));

    print('📲 NOTIFICATION ENVOYÉE:');
    print('👤 À: $clientName');
    print('🔧 Service: $service');
    print('📅 Date: ${_formatDate(dateTime)}');
    print('⏰ Heure: ${_formatTime(dateTime)}');
    print('---');
  }

  Future<void> sendReminder(
      String clientName, String service, DateTime dateTime) async {
    await Future.delayed(const Duration(seconds: 1));

    print('🔔 RAPPEL ENVOYÉE:');
    print('👤 À: $clientName');
    print('🔧 Service: $service');
    print('📅 Demain à ${_formatTime(dateTime)}');
    print('---');
  }

  Future<void> sendStatusUpdate(
      String clientName, String service, String status) async {
    await Future.delayed(const Duration(seconds: 1));

    print('🔄 STATUT MIS À JOUR:');
    print('👤 À: $clientName');
    print('🔧 Service: $service');
    print('📊 Nouveau statut: ${_getStatusText(status)}');
    print('---');
  }

  // Méthodes pour les rappels avancés
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required Map<String, dynamic> payload,
  }) async {
    try {
      // Utiliser notre service simplifié
      await AdvancedReminderService.scheduleNotification(
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        payload: payload,
      );
    } catch (e) {
      print('❌ Erreur scheduleNotification: $e');
    }
  }

  Future<void> cancelScheduledNotifications(
      {Map<String, dynamic>? filter}) async {
    try {
      if (filter != null && filter.containsKey('appointmentId')) {
        await AdvancedReminderService.cancelAppointmentReminders(
          filter['appointmentId']!,
        );
      }
    } catch (e) {
      print('❌ Erreur annulation notifications: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmé';
      case 'cancelled':
        return 'Annulé';
      case 'pending':
        return 'En attente';
      default:
        return status;
    }
  }
}
