import '../models/enriched_client_model.dart';
import 'appointment_service.dart';
import 'client_service.dart';
import '../models/appointment_model.dart';
import '../models/vehicle_model.dart';

class EnrichedClientService {
  final AppointmentService _appointmentService = AppointmentService();
  final ClientService _clientService = ClientService();

  // Obtenir tous les clients enrichis depuis les données réelles
  Future<List<EnrichedClient>> getAllEnrichedClients() async {
    try {
      // Récupérer les rendez-vous réels
      final appointments = await _appointmentService.getAllAppointments();

      // Récupérer les clients depuis ClientService
      final clientsFromService = await _clientService.getAllClients();

      // Grouper par client
      final clientMap = <String, EnrichedClient>{};

      // D'abord, ajouter tous les clients du ClientService
      for (final client in clientsFromService) {
        clientMap[client.email] = client;
      }

      // Ensuite, calculer les statistiques depuis les rendez-vous
      for (final appointment in appointments) {
        final clientEmail = appointment.clientEmail;

        if (!clientMap.containsKey(clientEmail)) {
          // Créer un client enrichi basique depuis les rendez-vous si pas trouvé dans ClientService
          final vehicle = appointment.vehicle != null
              ? Vehicle(
                  id: 'temp_${appointment.id}',
                  clientId: appointment.clientId,
                  brand: _extractBrandFromVehicle(appointment.vehicle!),
                  model: _extractModelFromVehicle(appointment.vehicle!),
                  year: DateTime.now().year,
                  licensePlate: 'Non spécifié',
                  color: 'Non spécifié',
                  fuelType: 'Essence',
                  transmission: 'Manuelle',
                  mileage: 0,
                  vin: 'Non spécifié',
                  lastServiceDate: DateTime.now(),
                )
              : null;

          clientMap[clientEmail] = EnrichedClient(
            id: appointment.clientId,
            uid: appointment.clientId,
            name: appointment.clientName,
            email: clientEmail,
            phone: appointment.clientPhone,
            address: 'Adresse non renseignée',
            registrationDate: appointment.createdAt,
            totalAppointments: 0,
            vehicles: vehicle != null ? [vehicle] : [],
            lastVisit: null,
            notes: appointment.notes,
          );
        }

        // Mettre à jour les statistiques depuis les rendez-vous
        final client = clientMap[clientEmail]!;
        final appointmentCount = client.totalAppointments + 1;

        // Déterminer le dernier rendez-vous
        final lastVisit = client.lastVisit;
        final newLastVisit =
            lastVisit == null || appointment.dateTime.isAfter(lastVisit)
                ? appointment.dateTime
                : lastVisit;

        // Mettre à jour la liste des véhicules
        final updatedVehicles = _updateVehiclesList(
            client.vehicles, appointment.vehicle, appointment.clientId);

        clientMap[clientEmail] = EnrichedClient(
          id: client.id,
          uid: client.uid,
          name: client.name,
          email: client.email,
          phone: client.phone,
          address: client.address,
          registrationDate: client.registrationDate,
          totalAppointments: appointmentCount,
          notes: client.notes,
          vehicles: updatedVehicles,
          lastVisit: newLastVisit,
        );
      }

      // Trier par nombre de rendez-vous (décroissant)
      final enrichedClients = clientMap.values.toList();
      enrichedClients
          .sort((a, b) => b.totalAppointments.compareTo(a.totalAppointments));

      return enrichedClients;
    } catch (e) {
      print('❌ Erreur lors de la récupération des clients enrichis: $e');
      return [];
    }
  }

  // Extraire la marque du véhicule depuis la chaîne
  String _extractBrandFromVehicle(String vehicleString) {
    final parts = vehicleString.split(' ');
    return parts.isNotEmpty ? parts[0] : 'Inconnu';
  }

  // Extraire le modèle du véhicule depuis la chaîne
  String _extractModelFromVehicle(String vehicleString) {
    final parts = vehicleString.split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : 'Inconnu';
  }

  // Mettre à jour la liste des véhicules
  List<Vehicle> _updateVehiclesList(List<Vehicle> currentVehicles,
      String? newVehicleString, String clientId) {
    if (newVehicleString == null || newVehicleString.isEmpty) {
      return currentVehicles;
    }

    // Vérifier si le véhicule existe déjà
    final vehicleExists = currentVehicles.any((vehicle) =>
        '${vehicle.brand} ${vehicle.model}'.toLowerCase() ==
        newVehicleString.toLowerCase());

    if (!vehicleExists) {
      final newVehicle = Vehicle(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        clientId: clientId,
        brand: _extractBrandFromVehicle(newVehicleString),
        model: _extractModelFromVehicle(newVehicleString),
        year: DateTime.now().year,
        licensePlate: 'Non spécifié',
        color: 'Non spécifié',
        fuelType: 'Essence',
        transmission: 'Manuelle',
        mileage: 0,
        vin: 'Non spécifié',
        lastServiceDate: DateTime.now(),
      );
      return [...currentVehicles, newVehicle];
    }

    return currentVehicles;
  }

  // Obtenir les statistiques réelles des clients
  Map<String, dynamic> getClientStats(List<EnrichedClient> clients) {
    if (clients.isEmpty) {
      return {
        'totalClients': 0,
        'totalVehicles': 0,
        'totalAppointments': 0,
        'averageAppointments': '0.0',
        'clientsWithMultipleVehicles': 0,
        'recentClients': 0,
        'clientsWithNoAppointments': 0,
        'newClients': 0,
        'regularClients': 0,
        'loyalClients': 0,
      };
    }

    final totalClients = clients.length;
    final totalVehicles =
        clients.fold(0, (sum, client) => sum + client.vehicles.length);
    final totalAppointments =
        clients.fold(0, (sum, client) => sum + client.totalAppointments);
    final clientsWithMultipleVehicles =
        clients.where((c) => c.vehicles.length > 1).length;

    // Clients avec un rendez-vous dans les 30 derniers jours
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentClients = clients
        .where((client) =>
            client.lastVisit != null &&
            client.lastVisit!.isAfter(thirtyDaysAgo))
        .length;

    final averageAppointments =
        totalClients > 0 ? totalAppointments / totalClients : 0.0;

    // Statistiques par niveau d'activité
    final newClients = clients.where((c) => c.totalAppointments <= 1).length;
    final regularClients = clients
        .where((c) => c.totalAppointments >= 2 && c.totalAppointments <= 5)
        .length;
    final loyalClients = clients.where((c) => c.totalAppointments >= 6).length;

    return {
      'totalClients': totalClients,
      'totalVehicles': totalVehicles,
      'totalAppointments': totalAppointments,
      'averageAppointments': averageAppointments.toStringAsFixed(1),
      'clientsWithMultipleVehicles': clientsWithMultipleVehicles,
      'recentClients': recentClients,
      'clientsWithNoAppointments':
          clients.where((c) => c.totalAppointments == 0).length,
      'newClients': newClients,
      'regularClients': regularClients,
      'loyalClients': loyalClients,
    };
  }

  // Rechercher des clients avec des critères étendus
  Future<List<EnrichedClient>> searchClients(
      List<EnrichedClient> clients, String query) async {
    if (query.isEmpty) return clients;

    final lowercaseQuery = query.toLowerCase();

    return clients.where((client) {
      return client.name.toLowerCase().contains(lowercaseQuery) ||
          client.email.toLowerCase().contains(lowercaseQuery) ||
          client.phone.contains(query) ||
          client.vehicles.any((vehicle) => '${vehicle.brand} ${vehicle.model}'
              .toLowerCase()
              .contains(lowercaseQuery));
    }).toList();
  }

  // Filtrer les clients par nombre de rendez-vous
  List<EnrichedClient> filterClientsByAppointmentCount(
      List<EnrichedClient> clients, String filterType) {
    switch (filterType) {
      case 'Tous':
        return clients;
      case 'Nouveaux (0-1 RDV)':
        return clients
            .where((client) => client.totalAppointments <= 1)
            .toList();
      case 'Réguliers (2-5 RDV)':
        return clients
            .where((client) =>
                client.totalAppointments >= 2 && client.totalAppointments <= 5)
            .toList();
      case 'Fidèles (6+ RDV)':
        return clients
            .where((client) => client.totalAppointments >= 6)
            .toList();
      case 'Aucun RDV':
        return clients
            .where((client) => client.totalAppointments == 0)
            .toList();
      default:
        return clients;
    }
  }

  // Obtenir les clients les plus actifs
  List<EnrichedClient> getMostActiveClients(List<EnrichedClient> clients,
      {int limit = 5}) {
    final sortedClients = List<EnrichedClient>.from(clients)
      ..sort((a, b) => b.totalAppointments.compareTo(a.totalAppointments));

    return sortedClients.take(limit).toList();
  }

  // Obtenir les clients récents (dernière visite dans les 30 jours)
  List<EnrichedClient> getRecentClients(List<EnrichedClient> clients) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return clients
        .where((client) =>
            client.lastVisit != null &&
            client.lastVisit!.isAfter(thirtyDaysAgo))
        .toList();
  }

  // Mettre à jour les notes d'un client
  Future<void> updateClientNotes(String clientEmail, String notes) async {
    try {
      print('📝 Mise à jour des notes pour $clientEmail: $notes');
    } catch (e) {
      print('❌ Erreur mise à jour notes client: $e');
      throw e;
    }
  }

  // Obtenir l'historique complet d'un client
  Future<List<Appointment>> getClientAppointmentHistory(
      String clientEmail) async {
    try {
      return await _appointmentService.getClientAppointments(clientEmail);
    } catch (e) {
      print('❌ Erreur récupération historique client: $e');
      return [];
    }
  }

  // Obtenir les clients avec plusieurs véhicules
  List<EnrichedClient> getClientsWithMultipleVehicles(
      List<EnrichedClient> clients) {
    return clients.where((client) => client.vehicles.length > 1).toList();
  }

  // Obtenir les clients sans rendez-vous récents (plus de 90 jours)
  List<EnrichedClient> getInactiveClients(List<EnrichedClient> clients) {
    final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));

    return clients
        .where((client) =>
            client.lastVisit == null ||
            client.lastVisit!.isBefore(ninetyDaysAgo))
        .toList();
  }

  // Obtenir le client par email
  Future<EnrichedClient?> getClientByEmail(String email) async {
    try {
      final clients = await getAllEnrichedClients();
      return clients.firstWhere((client) => client.email == email);
    } catch (e) {
      print('❌ Client non trouvé: $email');
      return null;
    }
  }
}
