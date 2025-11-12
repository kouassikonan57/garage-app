import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enriched_client_model.dart';
import '../models/vehicle_model.dart';
import '../services/simple_auth_service.dart';
import '../services/firebase_client_service.dart';

class ClientProfileScreen extends StatefulWidget {
  final String clientEmail;

  const ClientProfileScreen({super.key, required this.clientEmail});

  @override
  _ClientProfileScreenState createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  EnrichedClient? _client;
  bool _isLoading = true;
  bool _isNewClient = false;
  bool _isSaving = false;
  bool _isFixingEmail = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _vehicleBrandController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleFuelController = TextEditingController();
  final _vehicleTransmissionController = TextEditingController();
  final _vehicleMileageController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _vehicleVinController = TextEditingController();
  final _vehicleNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('🔄 ClientProfileScreen init pour: ${widget.clientEmail}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _loadClientData();
    }
  }

  void _loadClientData() async {
    try {
      print('🔄 Chargement des données client...');
      final clientService =
          Provider.of<FirebaseClientService>(context, listen: false);

      final client = await clientService.getClientByEmail(widget.clientEmail);

      if (mounted) {
        setState(() {
          if (client == null) {
            _isNewClient = true;
            _nameController.text = _extractNameFromEmail(widget.clientEmail);
            _phoneController.text = '+225 00 00 00 00';
            _addressController.text = 'Adresse non spécifiée';
            print('✅ Nouveau client détecté');
          } else {
            _client = client;
            _nameController.text = client.name;
            _phoneController.text = client.phone;
            _addressController.text = client.address;

            // Vérifier et corriger l'email si nécessaire
            if (client.email != widget.clientEmail) {
              print(
                  '⚠️ Email incorrect détecté: ${client.email} → ${widget.clientEmail}');
              _checkAndFixEmail();
              return; // Ne pas continuer le chargement, attendre la correction
            }

            if (client.vehicles.isNotEmpty) {
              final vehicle = client.vehicles.first;
              _vehicleBrandController.text = vehicle.brand;
              _vehicleModelController.text = vehicle.model;
              _vehicleYearController.text = vehicle.year.toString();
              _vehicleColorController.text = vehicle.color;
              _vehicleFuelController.text = vehicle.fuelType;
              _vehicleTransmissionController.text = vehicle.transmission;
              _vehicleMileageController.text = vehicle.mileage.toString();
              _licensePlateController.text = vehicle.licensePlate;
              _vehicleVinController.text = vehicle.vin;
              _vehicleNotesController.text = vehicle.notes ?? '';
              print('✅ Véhicule chargé: ${vehicle.brand} ${vehicle.model}');
            }
            print('✅ Client existant chargé: ${client.name}');
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des données: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isNewClient = true;
          _nameController.text = _extractNameFromEmail(widget.clientEmail);
          _phoneController.text = '+225 00 00 00 00';
          _addressController.text = 'Adresse non spécifiée';
        });
      }
    }
  }

  // Méthode pour corriger l'email automatiquement
  void _checkAndFixEmail() async {
    if (_client == null) return;

    setState(() {
      _isFixingEmail = true;
    });

    try {
      print('🔄 Correction automatique de l\'email...');
      final clientService =
          Provider.of<FirebaseClientService>(context, listen: false);

      // Créer une copie corrigée du client
      final correctedClient = EnrichedClient(
        id: _client!.id,
        uid: _client!.uid,
        name: _client!.name,
        email: widget.clientEmail, // Email corrigé
        phone: _client!.phone,
        address: _client!.address,
        registrationDate: _client!.registrationDate,
        totalAppointments: _client!.totalAppointments,
        vehicles: _client!.vehicles,
        lastVisit: _client!.lastVisit,
        notes: _client!.notes,
      );

      await clientService.saveClient(correctedClient);
      print('✅ Email corrigé avec succès: ${widget.clientEmail}');

      // Recharger les données après correction
      if (mounted) {
        setState(() {
          _isFixingEmail = false;
        });
        _loadClientData(); // Recharger pour avoir les données corrigées
      }
    } catch (e) {
      print('❌ Erreur lors de la correction de l\'email: $e');
      if (mounted) {
        setState(() {
          _isFixingEmail = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la mise à jour de l\'email'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _extractNameFromEmail(String email) {
    final namePart = email.split('@')[0];
    if (namePart.isNotEmpty) {
      return namePart[0].toUpperCase() + namePart.substring(1);
    }
    return namePart;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewClient ? 'Créer mon profil' : 'Mon Profil'),
        backgroundColor: Colors.orange,
        actions: [
          if (_isSaving || _isFixingEmail)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            MouseRegion(
              cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
              child: IconButton(
                icon: const Icon(Icons.save),
                onPressed: _isSaving ? null : _saveProfile,
                tooltip: 'Sauvegarder',
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // CORRECTION: Méthode séparée pour le body pour éviter l'erreur de compilation
  Widget _buildBody() {
    if (_isLoading || _isFixingEmail) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _isFixingEmail
                  ? 'Correction de l\'email en cours...'
                  : 'Chargement du profil...',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    } else {
      return _buildProfileForm();
    }
  }

  Widget _buildProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isNewClient) ...[
            _buildWelcomeMessage(),
            const SizedBox(height: 20),
          ],
          _buildSectionTitle('Informations personnelles'),
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildSectionTitle('Mon véhicule (optionnel)'),
          _buildVehicleCard(),
          const SizedBox(height: 30),
          _isSaving
              ? const Center(child: CircularProgressIndicator())
              : MouseRegion(
                  cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: _saveProfile,
                      child: Text(
                        _isNewClient
                            ? 'CRÉER MON PROFIL'
                            : 'SAUVEGARDER LES MODIFICATIONS',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.orange[800]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bienvenue ! Complétez votre profil pour une meilleure expérience.',
              style: TextStyle(
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet *',
                hintText: 'Votre nom complet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            _buildReadOnlyField('Email', widget.clientEmail),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone *',
                hintText: '+225 00 00 00 00',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse *',
                hintText: 'Abidjan, Cocody',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Ces informations nous aident à mieux préparer votre rendez-vous',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _vehicleBrandController,
              decoration: const InputDecoration(
                labelText: 'Marque du véhicule',
                hintText: 'Toyota, Peugeot, etc.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _vehicleModelController,
              decoration: const InputDecoration(
                labelText: 'Modèle',
                hintText: 'Corolla, 208, etc.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vehicleYearController,
                    decoration: const InputDecoration(
                      labelText: 'Année',
                      hintText: '2020',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _vehicleColorController,
                    decoration: const InputDecoration(
                      labelText: 'Couleur',
                      hintText: 'Noir, Blanc, etc.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vehicleFuelController,
                    decoration: const InputDecoration(
                      labelText: 'Carburant',
                      hintText: 'Essence, Diesel',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _vehicleTransmissionController,
                    decoration: const InputDecoration(
                      labelText: 'Transmission',
                      hintText: 'Manuelle, Automatique',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _vehicleMileageController,
              decoration: const InputDecoration(
                labelText: 'Kilométrage',
                hintText: '50000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _licensePlateController,
              decoration: const InputDecoration(
                labelText: 'Plaque d\'immatriculation',
                hintText: 'AB 123 CD',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _vehicleVinController,
              decoration: const InputDecoration(
                labelText: 'Numéro VIN',
                hintText: '1HGCM82633A123456',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _vehicleNotesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                hintText: 'Problèmes connus, modifications, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.shade50,
          ),
          child: Text(value),
        ),
      ],
    );
  }

  void _saveProfile() async {
    print('🔄 Début de la sauvegarde du profil...');

    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir les champs obligatoires (*)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      print('🔄 Récupération des services...');
      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);
      final clientService =
          Provider.of<FirebaseClientService>(context, listen: false);

      final currentUser = await authService.getCurrentAppUser();
      print('👤 Utilisateur courant: ${currentUser?.uid}');

      if (currentUser == null) {
        print('❌ Aucun utilisateur connecté');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: utilisateur non connecté'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final List<Vehicle> vehicles = [];

      if (_vehicleBrandController.text.isNotEmpty) {
        vehicles.add(Vehicle(
          id: _client != null && _client!.vehicles.isNotEmpty
              ? _client!.vehicles.first.id
              : 'vehicle_${DateTime.now().millisecondsSinceEpoch}',
          clientId: currentUser.uid,
          brand: _vehicleBrandController.text,
          model: _vehicleModelController.text,
          year: int.tryParse(_vehicleYearController.text) ?? 2020,
          licensePlate: _licensePlateController.text.isNotEmpty
              ? _licensePlateController.text
              : 'Non spécifiée',
          color: _vehicleColorController.text.isNotEmpty
              ? _vehicleColorController.text
              : 'Non spécifiée',
          fuelType: _vehicleFuelController.text.isNotEmpty
              ? _vehicleFuelController.text
              : 'Essence',
          transmission: _vehicleTransmissionController.text.isNotEmpty
              ? _vehicleTransmissionController.text
              : 'Manuelle',
          mileage: int.tryParse(_vehicleMileageController.text) ?? 0,
          vin: _vehicleVinController.text.isNotEmpty
              ? _vehicleVinController.text
              : 'Non spécifié',
          lastServiceDate: _client != null && _client!.vehicles.isNotEmpty
              ? _client!.vehicles.first.lastServiceDate
              : DateTime.now(),
          notes: _vehicleNotesController.text.isNotEmpty
              ? _vehicleNotesController.text
              : null,
        ));
        print(
            '🚗 Véhicule préparé: ${_vehicleBrandController.text} ${_vehicleModelController.text}');
      }

      final client = EnrichedClient(
        id: currentUser.uid,
        uid: currentUser.uid,
        name: _nameController.text,
        email: widget.clientEmail, // ✅ Toujours l'email complet
        phone: _phoneController.text,
        address: _addressController.text,
        registrationDate: _isNewClient
            ? DateTime.now()
            : _client?.registrationDate ?? DateTime.now(),
        totalAppointments: _isNewClient ? 0 : _client?.totalAppointments ?? 0,
        vehicles: vehicles,
        lastVisit: _isNewClient ? null : _client?.lastVisit,
        notes: _isNewClient ? null : _client?.notes,
      );

      print('💾 Tentative de sauvegarde dans Firestore...');
      print('📝 Données client: ${client.toMap()}');

      await clientService.saveClient(client);
      print('✅ Client sauvegardé avec succès!');

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isNewClient = false;
          _client = client;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil sauvegardé avec succès !'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e, stackTrace) {
      print('❌ Erreur critique lors de la sauvegarde: $e');
      print('📋 Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vehicleBrandController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehicleColorController.dispose();
    _vehicleFuelController.dispose();
    _vehicleTransmissionController.dispose();
    _vehicleMileageController.dispose();
    _licensePlateController.dispose();
    _vehicleVinController.dispose();
    _vehicleNotesController.dispose();
    super.dispose();
  }
}