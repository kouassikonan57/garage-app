import 'appointment_service.dart';
import 'loyalty_service.dart';
import 'client_service.dart';
import 'enriched_client_service.dart';
import 'notification_service.dart';

class ServiceProvider {
  static final ServiceProvider _instance = ServiceProvider._internal();
  factory ServiceProvider() => _instance;
  ServiceProvider._internal();

  late ClientService _clientService;
  late EnrichedClientService _enrichedClientService;
  late LoyaltyService _loyaltyService;
  late AppointmentService _appointmentService;
  late NotificationService _notificationService;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;

    print('🔄 Initialisation des services...');

    try {
      _clientService = ClientService();
      print('✅ ClientService initialisé');

      _notificationService = NotificationService(
        emailJSServiceId: 'service_zp8xyar',
        emailJSTemplateId: 'template_dt4gd95',
        emailJSPublicKey: 'uYoCHtHqOkOvUfm5l',
      );
      print('✅ NotificationService initialisé');

      final tempLoyaltyService = LoyaltyService(
        clientService: _clientService,
        appointmentService: null,
      );

      final tempAppointmentService = AppointmentService(
        loyaltyService: tempLoyaltyService,
        notificationService: _notificationService,
      );

      _enrichedClientService = EnrichedClientService(
        appointmentService: tempAppointmentService,
        clientService: _clientService,
      );
      print('✅ EnrichedClientService initialisé');

      _loyaltyService = LoyaltyService(
        clientService: _clientService,
        appointmentService: tempAppointmentService,
      );

      _appointmentService = AppointmentService(
        loyaltyService: _loyaltyService,
        notificationService: _notificationService,
      );
      print('✅ Services principaux initialisés');

      _resolveCircularDependencies();
      print('✅ Dépendances circulaires résolues');

      _recreateEnrichedClientService();
      print('✅ EnrichedClientService mis à jour');

      _isInitialized = true;
      print('🎯 Tous les services initialisés avec succès!');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation: $e');
      _initializeEmergencyFallback();
    }
  }

  void _resolveCircularDependencies() {
    try {
      _loyaltyService.updateAppointmentService(_appointmentService);
      _appointmentService.updateLoyaltyService(_loyaltyService);
    } catch (e) {
      print('❌ Erreur résolution dépendances circulaires: $e');
    }
  }

  void _recreateEnrichedClientService() {
    try {
      _enrichedClientService = EnrichedClientService(
        appointmentService: _appointmentService,
        clientService: _clientService,
      );
    } catch (e) {
      print('❌ Erreur recréation EnrichedClientService: $e');
    }
  }

  void _initializeEmergencyFallback() {
    print('🔄 Initialisation d\'urgence...');

    try {
      _clientService = ClientService();
      _notificationService = NotificationService();

      final fallbackLoyaltyService = LoyaltyService(
        clientService: _clientService,
        appointmentService: null,
      );

      final fallbackAppointmentService = AppointmentService(
        loyaltyService: fallbackLoyaltyService,
        notificationService: _notificationService,
      );

      _enrichedClientService = EnrichedClientService(
        appointmentService: fallbackAppointmentService,
        clientService: _clientService,
      );

      _loyaltyService = fallbackLoyaltyService;
      _appointmentService = fallbackAppointmentService;

      _isInitialized = true;
      print('✅ Initialisation d\'urgence réussie');
    } catch (e) {
      print('❌ Échec de l\'initialisation: $e');
      throw Exception('Impossible de démarrer l\'application: $e');
    }
  }

  AppointmentService get appointmentService {
    if (!_isInitialized) initialize();
    return _appointmentService;
  }

  LoyaltyService get loyaltyService {
    if (!_isInitialized) initialize();
    return _loyaltyService;
  }

  ClientService get clientService {
    if (!_isInitialized) initialize();
    return _clientService;
  }

  EnrichedClientService get enrichedClientService {
    if (!_isInitialized) initialize();
    return _enrichedClientService;
  }

  NotificationService get notificationService {
    if (!_isInitialized) initialize();
    return _notificationService;
  }

  void reset() {
    _isInitialized = false;
    print('🔄 Réinitialisation des services...');
    initialize();
  }

  bool get isInitialized => _isInitialized;
}
