class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  // Stockage simple en mémoire (remplacera par shared_preferences plus tard)
  Map<String, dynamic> _localStorage = {};
  DateTime? _lastSync;

  // Sauvegarder les données localement (version simplifiée)
  Future<void> saveAppointmentsLocally(String appointmentsData) async {
    _localStorage['appointments'] = appointmentsData;
    _lastSync = DateTime.now();
    print('📱 Données sauvegardées localement: ${appointmentsData.length} caractères');
  }

  // Récupérer les données sauvegardées
  Future<String?> getLocalAppointments() async {
    final data = _localStorage['appointments'];
    return data != null ? data.toString() : null;
  }

  // Vérifier si des données sont disponibles hors ligne
  Future<bool> hasOfflineData() async {
    return _localStorage.containsKey('appointments');
  }

  // Obtenir la date de dernière synchronisation
  Future<DateTime?> getLastSyncDate() async {
    return _lastSync;
  }

  // Synchroniser les données (simulation)
  Future<void> syncData() async {
    print('🔄 Synchronisation des données hors ligne...');
    await Future.delayed(const Duration(seconds: 2));
    print('✅ Synchronisation terminée');
  }

  // Effacer les données hors ligne
  Future<void> clearOfflineData() async {
    _localStorage.clear();
    _lastSync = null;
    print('🧹 Données hors ligne effacées');
  }

  // Simuler la sauvegarde de données de test
  Future<void> initializeTestData() async {
    final testData = {
      'appointments': [
        {
          'id': 'offline_1',
          'clientName': 'Client Hors Ligne',
          'service': 'Vidange',
          'date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'status': 'pending'
        }
      ]
    };
    await saveAppointmentsLocally(testData.toString());
  }

  // Obtenir le statut hors ligne
  Map<String, dynamic> getOfflineStatus() {
    return {
      'hasData': _localStorage.isNotEmpty,
      'lastSync': _lastSync?.toIso8601String(),
      'dataSize': _localStorage.length,
    };
  }
}