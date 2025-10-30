import 'package:http/http.dart' as http;
import 'dart:convert';
import 'advanced_reminder_service.dart';

class NotificationService {
  final String? _emailJSServiceId;
  final String? _emailJSTemplateId;
  final String? _emailJSPublicKey;

  NotificationService({
    String? emailJSServiceId,
    String? emailJSTemplateId,
    String? emailJSPublicKey,
  })  : _emailJSServiceId = emailJSServiceId,
        _emailJSTemplateId = emailJSTemplateId,
        _emailJSPublicKey = emailJSPublicKey;

  Future<void> sendEmailNotification({
    required String toEmail,
    required String subject,
    required String body,
    required String clientName,
  }) async {
    try {
      if (_emailJSServiceId != null &&
          _emailJSTemplateId != null &&
          _emailJSPublicKey != null) {
        await _sendViaEmailJS(
          toEmail: toEmail,
          subject: subject,
          body: body,
          clientName: clientName,
        );
        return;
      }

      _fallbackToSimulation(toEmail, subject, body);
    } catch (e) {
      print('❌ Erreur envoi email: $e');
      _fallbackToSimulation(toEmail, subject, body);
    }
  }

  Future<void> _sendViaEmailJS({
    required String toEmail,
    required String subject,
    required String body,
    required String clientName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': _emailJSServiceId!,
          'template_id': _emailJSTemplateId!,
          'user_id': _emailJSPublicKey!,
          'template_params': {
            'to_email': toEmail,
            'subject': subject,
            'message': body,
            'client_name': clientName,
            'from_name': 'Votre Garage',
            'reply_to': 'noreply@votregarage.com',
          }
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email envoyé à: $toEmail');
      } else {
        print('❌ Erreur EmailJS: ${response.statusCode}');
        _fallbackToSimulation(toEmail, subject, body);
      }
    } catch (e) {
      print('❌ Erreur EmailJS: $e');
      _fallbackToSimulation(toEmail, subject, body);
    }
  }

  void _fallbackToSimulation(String toEmail, String subject, String body) {
    print('📧 [SIMULATION] Email à: $toEmail');
    print('📧 Sujet: $subject');
    print('📧 Corps: $body');
  }

  Future<void> sendAppointmentConfirmation(
      String clientName, String service, DateTime dateTime,
      {String? clientEmail}) async {
    final subject = '✅ Confirmation de votre rendez-vous';
    final body = '''
Bonjour $clientName,

Votre rendez-vous pour "$service" a été confirmé.
Date: ${_formatDate(dateTime)}
Heure: ${_formatTime(dateTime)}

Merci de votre confiance !

L'équipe Garage
''';

    if (clientEmail != null && clientEmail.contains('@')) {
      await sendEmailNotification(
        toEmail: clientEmail,
        subject: subject,
        body: body,
        clientName: clientName,
      );
    }

    print('📲 Notification confirmation envoyée');
  }

  Future<void> sendStatusUpdate(
      String clientName, String service, String status,
      {String? clientEmail}) async {
    final statusText = _getStatusText(status);
    final subject = '🔄 Mise à jour de votre rendez-vous - $statusText';
    final body = '''
Bonjour $clientName,

Le statut de votre rendez-vous pour "$service" a été mis à jour.

Nouveau statut: $statusText

${_getStatusMessage(status)}

L'équipe Garage
''';

    if (clientEmail != null && clientEmail.contains('@')) {
      await sendEmailNotification(
        toEmail: clientEmail,
        subject: subject,
        body: body,
        clientName: clientName,
      );
    }

    print('🔄 Notification statut envoyée');
  }

  Future<void> sendReminder(
      String clientName, String service, DateTime dateTime,
      {String? clientEmail}) async {
    final subject = '🔔 Rappel - Rendez-vous demain';
    final body = '''
Bonjour $clientName,

Rappel: Vous avez un rendez-vous demain pour "$service".
Heure: ${_formatTime(dateTime)}

Pensez à apporter votre carte grise et les clés du véhicule.

L'équipe Garage
''';

    if (clientEmail != null && clientEmail.contains('@')) {
      await sendEmailNotification(
        toEmail: clientEmail,
        subject: subject,
        body: body,
        clientName: clientName,
      );
    }

    print('🔔 Notification rappel envoyée');
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required Map<String, dynamic> payload,
    String? clientEmail,
    String? clientName,
  }) async {
    try {
      await AdvancedReminderService.scheduleNotification(
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        payload: payload,
      );

      if (clientEmail != null &&
          clientEmail.contains('@') &&
          clientName != null) {
        await sendEmailNotification(
          toEmail: clientEmail,
          subject: title,
          body: body,
          clientName: clientName,
        );
      }
    } catch (e) {
      print('❌ Erreur programmation notification: $e');
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
    return '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(String status) {
    switch (status) {
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
      case 'pending':
        return 'En attente';
      default:
        return status;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'confirmed':
        return 'Votre rendez-vous a été confirmé par le garage.';
      case 'in_progress':
        return 'Votre véhicule est en cours de préparation.';
      case 'diagnostic':
        return 'Le diagnostic de votre véhicule est en cours.';
      case 'repair':
        return 'La réparation de votre véhicule est en cours.';
      case 'quality_check':
        return 'Votre véhicule est en contrôle qualité final.';
      case 'completed':
        return 'Votre véhicule est prêt à être récupéré !';
      case 'cancelled':
        return 'Votre rendez-vous a été annulé. Contactez-nous pour plus d\'informations.';
      case 'rejected':
        return 'Votre demande de rendez-vous a été refusée. Contactez-nous pour plus d\'informations.';
      default:
        return 'Statut mis à jour.';
    }
  }
}
