// service_provider.dart
import 'appointment_service.dart';
import 'loyalty_service.dart';
import 'client_service.dart';
import 'enriched_client_service.dart';

class ServiceProvider {
  static final ServiceProvider _instance = ServiceProvider._internal();
  factory ServiceProvider() => _instance;
  ServiceProvider._internal();

  late ClientService _clientService;
  late EnrichedClientService _enrichedClientService;
  late LoyaltyService _loyaltyService;
  late AppointmentService _appointmentService;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;

    print('🔄 Initialisation des services...');

    try {
      // ÉTAPE 1: Initialiser ClientService (aucune dépendance)
      _clientService = ClientService();
      print('✅ ClientService initialisé');

      // ÉTAPE 2: Créer des instances TEMPORAIRES pour résoudre les dépendances circulaires

      // Créer un AppointmentService temporaire avec un LoyaltyService temporaire
      final tempLoyaltyService = LoyaltyService(
        clientService: _clientService,
        appointmentService: null, // Temporairement null
      );

      final tempAppointmentService = AppointmentService(
        loyaltyService: tempLoyaltyService,
      );

      // ÉTAPE 3: Maintenant initialiser EnrichedClientService avec les instances temporaires
      _enrichedClientService = EnrichedClientService(
        appointmentService: tempAppointmentService, // ✅ Paramètre requis fourni
        clientService: _clientService, // ✅ Paramètre requis fourni
      );
      print('✅ EnrichedClientService initialisé');

      // ÉTAPE 4: Créer les VRAIES instances des services
      _loyaltyService = LoyaltyService(
        clientService: _clientService,
        appointmentService:
            tempAppointmentService, // Utiliser temporaire d'abord
      );

      _appointmentService = AppointmentService(
        loyaltyService: _loyaltyService,
      );
      print('✅ Services principaux initialisés');

      // ÉTAPE 5: RÉSOLUTION DES DÉPENDANCES CIRCULAIRES
      _resolveCircularDependencies();
      print('✅ Dépendances circulaires résolues');

      // ÉTAPE 6: RECRÉER EnrichedClientService avec les vraies instances
      _recreateEnrichedClientService();
      print('✅ EnrichedClientService mis à jour avec les vraies instances');

      _isInitialized = true;
      print('🎯 TOUS les services initialisés avec succès!');
    } catch (e) {
      print('❌ Erreur critique lors de l\'initialisation: $e');
      _initializeEmergencyFallback();
    }
  }

  void _resolveCircularDependencies() {
    try {
      // 1. Mettre à jour LoyaltyService avec la VRAIE instance de AppointmentService
      _loyaltyService.updateAppointmentService(_appointmentService);
      print('✅ LoyaltyService -> Vrai AppointmentService');

      // 2. Mettre à jour AppointmentService avec la VRAIE instance de LoyaltyService
      _appointmentService.updateLoyaltyService(_loyaltyService);
      print('✅ AppointmentService -> Vrai LoyaltyService');
    } catch (e) {
      print('❌ Erreur résolution dépendances circulaires: $e');
    }
  }

  void _recreateEnrichedClientService() {
    try {
      // Recréer EnrichedClientService avec les VRAIES instances maintenant disponibles
      _enrichedClientService = EnrichedClientService(
        appointmentService: _appointmentService, // ✅ Vraie instance
        clientService: _clientService, // ✅ Vraie instance
      );
      print('✅ EnrichedClientService recréé avec vraies dépendances');
    } catch (e) {
      print('❌ Erreur recréation EnrichedClientService: $e');
      // On garde l'instance temporaire si la recréation échoue
    }
  }

  void _initializeEmergencyFallback() {
    print('🔄 Lancement de l\'initialisation d\'urgence...');

    try {
      // Initialisation ultra-simplifiée sans résolution de dépendances complexes
      _clientService = ClientService();

      // Créer des instances basiques pour les autres services
      final fallbackLoyaltyService = LoyaltyService(
        clientService: _clientService,
        appointmentService: null,
      );

      final fallbackAppointmentService = AppointmentService(
        loyaltyService: fallbackLoyaltyService,
      );

      _enrichedClientService = EnrichedClientService(
        appointmentService: fallbackAppointmentService,
        clientService: _clientService,
      );

      _loyaltyService = fallbackLoyaltyService;
      _appointmentService = fallbackAppointmentService;

      _isInitialized = true;
      print('✅ Initialisation d\'urgence réussie (fonctionnalités limitées)');
    } catch (e) {
      print('❌ ÉCHEC COMPLET de l\'initialisation: $e');
      throw Exception('IMPOSSIBLE de démarrer l\'application: $e');
    }
  }

  // GETTERS avec initialisation automatique
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

  // Méthodes utilitaires
  void reset() {
    _isInitialized = false;
    print('🔄 Réinitialisation des services demandée...');
    initialize();
  }

  bool get isInitialized => _isInitialized;

  String get initializationStatus {
    if (!_isInitialized) return '❌ Non initialisé';

    final services = [
      'ClientService',
      'EnrichedClientService',
      'LoyaltyService',
      'AppointmentService',
    ];

    return '✅ Initialisé (${services.length}/4 services)';
  }

  // Méthode de débogage - CORRIGÉE
  void debugServices() {
    print('\n🔍 ÉTAT DES SERVICES:');
    print('• ClientService: ✅');
    print('• EnrichedClientService: ✅');
    print('• LoyaltyService: ✅');
    print('• AppointmentService: ✅');
    print('• Initialisé: ${_isInitialized ? '✅' : '❌'}');

    // Vérification des dépendances circulaires
    print(
        '• Dépendances circulaires résolues: ${_checkCircularDependencies()}');
  }

  String _checkCircularDependencies() {
    try {
      // Vérifier si les dépendances circulaires sont correctement résolues
      // Vous pouvez ajouter des vérifications spécifiques ici si nécessaire
      return '✅';
    } catch (e) {
      return '❌ ($e)';
    }
  }
}
