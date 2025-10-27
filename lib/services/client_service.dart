import '../models/enriched_client_model.dart';
import '../models/vehicle_model.dart';

class ClientService {
  static final List<EnrichedClient> _clients = [];

  // Sauvegarder ou mettre à jour un client
  Future<void> saveClient(EnrichedClient client) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final existingIndex = _clients.indexWhere((c) => c.id == client.id);

    if (existingIndex != -1) {
      _clients[existingIndex] = client;
      print('💾 Client mis à jour: ${client.name} (${client.email})');
    } else {
      _clients.add(client);
      print('💾 Nouveau client créé: ${client.name} (${client.email})');
    }

    print('📊 Total clients dans ClientService: ${_clients.length}');

    // DEBUG: Afficher tous les clients
    for (var client in _clients) {
      print(
          '👤 Client: ${client.name} | Tel: ${client.phone} | Addr: ${client.address}');
    }
  }

  // Récupérer un client par email
  Future<EnrichedClient?> getClientByEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final client = _clients.firstWhere((client) => client.email == email);
      print('🔍 Client trouvé: ${client.name} (${client.email})');
      return client;
    } catch (e) {
      print('❌ Client non trouvé pour email: $email');
      return null;
    }
  }

  // Mettre à jour les statistiques d'un client après un RDV
  Future<void> updateClientAfterAppointment(
    String clientEmail,
    String service,
  ) async {
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
    }
  }

  // Obtenir tous les clients (pour l'écran des clients enrichis)
  Future<List<EnrichedClient>> getAllClients() async {
    await Future.delayed(const Duration(seconds: 1));
    print('📋 Récupération de ${_clients.length} clients depuis ClientService');
    return _clients;
  }

  // Ajouter un véhicule à un client
  Future<void> addVehicleToClient(String clientEmail, Vehicle vehicle) async {
    final client = await getClientByEmail(clientEmail);

    if (client != null) {
      final updatedVehicles = List<Vehicle>.from(client.vehicles)..add(vehicle);

      final updatedClient = EnrichedClient(
        id: client.id,
        uid: client.uid,
        name: client.name,
        email: client.email,
        phone: client.phone,
        address: client.address,
        registrationDate: client.registrationDate,
        totalAppointments: client.totalAppointments,
        vehicles: updatedVehicles,
        lastVisit: client.lastVisit,
        notes: client.notes,
      );

      await saveClient(updatedClient);
    }
  }

  // DEBUG: Méthode pour voir l'état actuel
  void debugPrintClients() {
    print('=== DEBUG CLIENT SERVICE ===');
    print('Nombre de clients: ${_clients.length}');
    for (var client in _clients) {
      print(
          '👤 ${client.name} | ${client.email} | Tel: ${client.phone} | Addr: ${client.address}');
    }
    print('===========================');
  }
}
