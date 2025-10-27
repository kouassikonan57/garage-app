import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enriched_client_model.dart';
import '../services/enriched_client_service.dart';
import '../services/simple_auth_service.dart';
import '../models/user_model.dart';
// import 'dart:convert' show utf8;
import 'dart:math'; // Pour Random
import 'package:share_plus/share_plus.dart';
import 'package:clipboard/clipboard.dart';

class EnrichedClientsScreen extends StatefulWidget {
  const EnrichedClientsScreen({super.key});

  @override
  State<EnrichedClientsScreen> createState() => _EnrichedClientsScreenState();
}

class _EnrichedClientsScreenState extends State<EnrichedClientsScreen> {
  final EnrichedClientService _clientService = EnrichedClientService();
  List<EnrichedClient> _clients = [];
  List<EnrichedClient> _filteredClients = [];
  bool _isLoading = true;
  bool _checkingAccess = true;
  bool _isGarage = false;
  String _searchQuery = '';
  String _selectedFilter =
      'all'; // 'all', 'new', 'regular', 'loyal', 'with_vehicles'

  // Contrôleurs pour le formulaire d'ajout
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkGarageAccess();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkGarageAccess() async {
    try {
      print('🔐 Vérification des accès garage pour clients...');

      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);
      final currentUser = await authService.getCurrentAppUser();

      if (currentUser != null && currentUser.userType == UserType.garage) {
        print('✅ Accès garage autorisé pour la gestion clients');
        setState(() {
          _isGarage = true;
          _checkingAccess = false;
        });
        _loadClients();
      } else {
        print('❌ Accès garage refusé pour la gestion clients');
        setState(() {
          _isGarage = false;
          _checkingAccess = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Accès réservé aux garages'),
              backgroundColor: Colors.red,
            ),
          );

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      }
    } catch (e) {
      print('❌ Erreur vérification accès clients: $e');
      setState(() {
        _checkingAccess = false;
        _isGarage = false;
      });
    }
  }

  void _loadClients() async {
    setState(() {
      _isLoading = true;
    });

    final clients = await _clientService.getAllEnrichedClients();

    // Trier les clients par nombre de RDV (les plus fidèles en premier)
    clients.sort((a, b) => b.totalAppointments.compareTo(a.totalAppointments));

    setState(() {
      _clients = clients;
      _filteredClients = clients;
      _isLoading = false;
    });
  }

  void _searchClients(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<EnrichedClient> filtered = _clients;

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((client) {
        return client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            client.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            client.phone.contains(_searchQuery) ||
            client.vehicles.any((vehicle) =>
                vehicle.brand
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                vehicle.model
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                vehicle.licensePlate
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()));
      }).toList();
    }

    // Appliquer le filtre sélectionné
    switch (_selectedFilter) {
      case 'loyal':
        filtered = filtered
            .where((client) => client.activityLevel == 'Fidèle')
            .toList();
        break;
      case 'new':
        filtered = filtered
            .where((client) => client.activityLevel == 'Nouveau')
            .toList();
        break;
      case 'regular':
        filtered = filtered
            .where((client) => client.activityLevel == 'Régulier')
            .toList();
        break;
      case 'with_vehicles':
        filtered =
            filtered.where((client) => client.vehicles.isNotEmpty).toList();
        break;
      case 'all':
      default:
        // Pas de filtre supplémentaire
        break;
    }

    setState(() {
      _filteredClients = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAccess) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Vérification des accès...'),
            ],
          ),
        ),
      );
    }

    if (!_isGarage) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Accès Refusé'),
          backgroundColor: Colors.red,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 20),
              Text(
                'Accès réservé aux garages',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _clientService.getClientStats(_clients);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Clients'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClients,
            tooltip: 'Actualiser',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                _exportClientsData();
              } else if (value == 'stats') {
                _showDetailedStats();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Statistiques détaillées'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Exporter données'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un client, véhicule, plaque...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchClients('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: _searchClients,
                ),
                const SizedBox(height: 12),

                // Filtres rapides
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tous', 'all'),
                      _buildFilterChip('Fidèles', 'loyal'),
                      _buildFilterChip('Réguliers', 'regular'),
                      _buildFilterChip('Nouveaux', 'new'),
                      _buildFilterChip('Avec Véhicules', 'with_vehicles'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Statistiques
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(stats['totalClients'].toString(), 'Clients',
                    Icons.people, Colors.purple),
                _buildStatCard(stats['loyalClients'].toString(), 'Fidèles',
                    Icons.loyalty, Colors.amber),
                _buildStatCard(stats['totalVehicles'].toString(), 'Véhicules',
                    Icons.directions_car, Colors.blue),
                _buildStatCard(stats['totalAppointments'].toString(), 'RDV',
                    Icons.calendar_today, Colors.green),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // En-tête résultats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredClients.length} client(s) trouvé(s)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                if (_searchQuery.isNotEmpty || _selectedFilter != 'all')
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedFilter = 'all';
                      });
                      _applyFilters();
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Réinitialiser'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Liste des clients
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Chargement des clients...'),
                      ],
                    ),
                  )
                : _filteredClients.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredClients.length,
                        itemBuilder: (context, index) {
                          final client = _filteredClients[index];
                          return _buildClientCard(client);
                        },
                      ),
          ),
        ],
      ),

      // Bouton d'action flottant pour créer un nouveau client
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClientForm,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        tooltip: 'Ajouter un nouveau client',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: _selectedFilter == value,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? value : 'all';
          });
          _applyFilters();
        },
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.purple.withOpacity(0.2),
        checkmarkColor: Colors.purple,
        labelStyle: TextStyle(
          color: _selectedFilter == value ? Colors.purple : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun client trouvé pour "$_searchQuery"'
                : 'Aucun client disponible',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Essayez avec d\'autres termes de recherche'
                : 'Les clients apparaîtront ici après leur inscription',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_searchQuery.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'all';
                });
                _applyFilters();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Voir tous les clients'),
            ),
          if (_clients.isEmpty && _searchQuery.isEmpty)
            ElevatedButton.icon(
              onPressed: _showAddClientForm,
              icon: const Icon(Icons.person_add),
              label: const Text('Ajouter le premier client'),
            ),
        ],
      ),
    );
  }

  Widget _buildClientCard(EnrichedClient client) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showClientDetails(client),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: client.activityColor.withOpacity(0.2),
                radius: 20,
                child: Text(
                  client.name[0],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: client.activityColor,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Informations principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      client.email,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          client.phone,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.calendar_today,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${client.totalAppointments} RDV',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Badge d'activité
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: client.activityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  client.activityLevel,
                  style: TextStyle(
                    color: client.activityColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientDetails(EnrichedClient client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: client.activityColor.withOpacity(0.2),
              child: Text(
                client.name[0],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: client.activityColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Profil - ${client.name}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email:', client.email),
              _buildDetailRow('Téléphone:', client.phone),
              _buildDetailRow('Adresse:', client.address),
              _buildDetailRow(
                  'Date d\'inscription:', client.formattedRegistrationDate),
              _buildDetailRow('Niveau d\'activité:',
                  '${client.activityLevel} (${client.totalAppointments} RDV)'),
              if (client.vehicles.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Véhicules:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ...client.vehicles
                    .map((vehicle) => Card(
                          margin: const EdgeInsets.only(top: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${vehicle.brand} ${vehicle.model} (${vehicle.year})',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text('Plaque: ${vehicle.licensePlate}'),
                                Text(
                                    'Kilométrage: ${vehicle.formattedMileage}'),
                                Text(
                                    'Carburant: ${vehicle.fuelType} • ${vehicle.transmission}'),
                                if (vehicle.lastServiceDate != null)
                                  Text(
                                    'Dernier entretien: ${_formatDate(vehicle.lastServiceDate!)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                if (vehicle.notes != null &&
                                    vehicle.notes!.isNotEmpty)
                                  Text(
                                    'Notes: ${vehicle.notes!}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ],
              if (client.notes != null && client.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Card(
                  color: Colors.grey[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(client.notes!),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () => _contactClient(client),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Contacter'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _contactClient(EnrichedClient client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacter le client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${client.name}'),
            Text('Téléphone: ${client.phone}'),
            Text('Email: ${client.email}'),
            const SizedBox(height: 16),
            const Text(
              'Choisissez le mode de contact:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Appel vers ${client.phone}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.phone),
            label: const Text('Appeler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Email à ${client.email}'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            icon: const Icon(Icons.email),
            label: const Text('Email'),
          ),
        ],
      ),
    );
  }

  // FONCTIONNALITÉ D'AJOUT DE CLIENT
  void _showAddClientForm() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Colors.purple),
              SizedBox(width: 8),
              Text('Nouveau Client'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone *',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearForm();
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: _validateForm() ? _addNewClient : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Ajouter le client'),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateForm() {
    return _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty;
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _notesController.clear();
  }

  void _addNewClient() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final temporaryPassword = _generateTemporaryPassword();

      final newClient = EnrichedClient(
        id: timestamp,
        uid: timestamp, // Temporaire
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? 'Adresse non renseignée'
            : _addressController.text.trim(),
        registrationDate: DateTime.now(),
        totalAppointments: 0,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        vehicles: [],
        lastVisit: null,
      );

      // 🔥 CRÉATION DU COMPTE UTILISATEUR FIREBASE
      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);
      final result = await authService.createClientAccount(
        email: newClient.email,
        password: temporaryPassword,
        name: newClient.name,
        phone: newClient.phone,
      );

      if (result['success'] == true) {
        final appUser = result['user'] as AppUser;

        // Mettre à jour le client avec le vrai UID Firebase
        final clientWithUid = newClient.copyWith(
          uid: appUser.uid,
          id: appUser.uid,
        );

        // Ici vous devriez appeler votre service pour sauvegarder le client enrichi
        // await _clientService.addClient(clientWithUid);

        // Pour l'instant, on l'ajoute localement
        setState(() {
          _clients.insert(0, clientWithUid);
          _applyFilters();
        });

        _clearForm();
        Navigator.pop(context);

        // 🔥 AFFICHER LES IDENTIFIANTS
        _showClientInvitation(clientWithUid, temporaryPassword);
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateTemporaryPassword() {
    final random = Random.secure();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#';
    return String.fromCharCodes(Iterable.generate(
        10, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  void _showClientInvitation(EnrichedClient client, String temporaryPassword) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Colors.green),
            SizedBox(width: 8),
            Text('Client Ajouté avec Succès'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Un compte a été créé pour ${client.name}'),
            const SizedBox(height: 16),
            const Text(
              '📧 Identifiants de connexion:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${client.email}'),
                  const SizedBox(height: 4),
                  Text('Mot de passe temporaire: $temporaryPassword'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '💡 Le client peut maintenant:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.login, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(child: Text('Se connecter sur l\'appli client')),
              ],
            ),
            const Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text('Prendre des rendez-vous')),
              ],
            ),
            const Row(
              children: [
                Icon(Icons.chat, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text('Communiquer avec le garage')),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '⚠️ Le client devra changer son mot de passe à la première connexion',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _copyCredentialsToClipboard(client.email, temporaryPassword);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Copier les identifiants'),
          ),
        ],
      ),
    );
  }

  void _copyCredentialsToClipboard(String email, String password) {
    final credentials = 'Email: $email\nMot de passe temporaire: $password';

    // Utilisation du package clipboard pour une vraie copie
    FlutterClipboard.copy(credentials).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identifiants copiés dans le presse-papier'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  // FONCTIONNALITÉ D'EXPORT DES DONNÉES AVEC SHARE_PLUS
  void _exportClientsData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(value: null, strokeWidth: 2),
              SizedBox(width: 12),
              Text('Préparation de l\'export...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      // Créer le contenu CSV
      final StringBuffer csvContent = StringBuffer();

      // En-tête CSV
      csvContent.writeln(
          'Nom,Email,Téléphone,Adresse,Date d\'inscription,Nombre de RDV,Niveau d\'activité,Nombre de véhicules,Dernière visite,Notes');

      // Données des clients
      for (final client in _clients) {
        final escapedNotes = (client.notes ?? '')
            .replaceAll('"', '""')
            .replaceAll(',', ';')
            .replaceAll('\n', ' ');

        final escapedAddress = client.address
            .replaceAll('"', '""')
            .replaceAll(',', ';')
            .replaceAll('\n', ' ');

        csvContent.writeln(
            '"${client.name}","${client.email}","${client.phone}","$escapedAddress","${client.formattedRegistrationDate}",${client.totalAppointments},"${client.activityLevel}",${client.vehicles.length},"${client.lastVisit != null ? _formatDate(client.lastVisit!) : 'Jamais'}","$escapedNotes"');
      }

      // Utilisation de share_plus pour partager/exporter
      await Share.share(
        csvContent.toString(),
        subject: 'Export clients ${DateTime.now().toString()}',
        sharePositionOrigin: Rect.largest,
      );
    } catch (e) {
      print('❌ Erreur export: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDetailedStats() {
    final stats = _clientService.getClientStats(_clients);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques Détaillées'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatDetail(
                  'Total Clients', stats['totalClients'].toString()),
              _buildStatDetail(
                  'Clients Fidèles', stats['loyalClients'].toString()),
              _buildStatDetail(
                  'Clients Réguliers', stats['regularClients'].toString()),
              _buildStatDetail(
                  'Clients Nouveaux', stats['newClients'].toString()),
              _buildStatDetail(
                  'Total Véhicules', stats['totalVehicles'].toString()),
              _buildStatDetail(
                  'RDV Total', stats['totalAppointments'].toString()),
              _buildStatDetail(
                  'Moyenne RDV/Client', stats['averageAppointments']),
              _buildStatDetail('Clients Multi-Véhicules',
                  stats['clientsWithMultipleVehicles'].toString()),
              _buildStatDetail(
                  'Clients Récents', stats['recentClients'].toString()),
              _buildStatDetail('Clients Sans RDV',
                  stats['clientsWithNoAppointments'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: _exportClientsData,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Exporter'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
