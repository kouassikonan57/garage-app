import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enriched_client_model.dart';
import '../models/vehicle_model.dart';
import '../services/simple_auth_service.dart';
import '../services/firebase_client_service.dart';
import 'home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String clientEmail;
  final String clientName;

  const CompleteProfileScreen({
    super.key,
    required this.clientEmail,
    required this.clientName,
  });

  @override
  _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
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

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compléter votre profil'),
        backgroundColor: Colors.orange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quelques informations supplémentaires',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Informations de contact
              _buildSectionTitle('Informations de contact'),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: '+225 00 00 00 00',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  hintText: 'Abidjan, Cocody',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 25),

              // Informations du véhicule (optionnel)
              _buildSectionTitle('Véhicule principal (optionnel)'),
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
              const SizedBox(height: 30),

              // Bouton de soumission
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: _saveProfile,
                    child: const Text(
                      'TERMINER L\'INSCRIPTION',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),

              const SizedBox(height: 15),
              TextButton(
                onPressed: _skipForNow,
                child: const Text(
                  'Remplir plus tard',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  void _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    // Récupérer l'utilisateur courant pour avoir le UID
    final authService = Provider.of<SimpleAuthService>(context, listen: false);
    final clientService =
        Provider.of<FirebaseClientService>(context, listen: false);

    final currentUser = await authService.getCurrentAppUser();

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: utilisateur non connecté'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Préparer la liste des véhicules
    final List<Vehicle> vehicles = [];

    if (_vehicleBrandController.text.isNotEmpty) {
      vehicles.add(Vehicle(
        id: 'vehicle_${DateTime.now().millisecondsSinceEpoch}',
        clientId: currentUser.uid, // Utiliser le UID Firebase
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
        lastServiceDate: DateTime.now(),
        notes: _vehicleNotesController.text.isNotEmpty
            ? _vehicleNotesController.text
            : null,
      ));
    }

    // Créer le client enrichi
    final client = EnrichedClient(
      id: currentUser.uid, // Utiliser le UID Firebase
      uid: currentUser.uid, // Champ obligatoire
      name: widget.clientName,
      email: widget.clientEmail,
      phone: _phoneController.text.isNotEmpty
          ? _phoneController.text
          : '+225 00 00 00 00',
      address: _addressController.text.isNotEmpty
          ? _addressController.text
          : 'Adresse non spécifiée',
      registrationDate: DateTime.now(),
      totalAppointments: 0,
      vehicles: vehicles,
      lastVisit: null,
    );

    // Sauvegarder le client
    await clientService.saveClient(client);

    setState(() {
      _isLoading = false;
    });

    // Rediriger vers l'accueil
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          isClient: true,
          userName: widget.clientName,
          userEmail: widget.clientEmail,
        ),
      ),
    );
  }

  void _skipForNow() async {
    // Récupérer l'utilisateur courant pour avoir le UID
    final authService = Provider.of<SimpleAuthService>(context, listen: false);
    final clientService =
        Provider.of<FirebaseClientService>(context, listen: false);

    final currentUser = await authService.getCurrentAppUser();

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: utilisateur non connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Créer un client avec des valeurs par défaut
    final client = EnrichedClient(
      id: currentUser.uid, // Utiliser le UID Firebase
      uid: currentUser.uid, // Champ obligatoire
      name: widget.clientName,
      email: widget.clientEmail,
      phone: '+225 00 00 00 00',
      address: 'Adresse non spécifiée',
      registrationDate: DateTime.now(),
      totalAppointments: 0,
      vehicles: [],
      lastVisit: null,
    );

    // Sauvegarder le client
    await clientService.saveClient(client);

    // Rediriger vers l'accueil
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          isClient: true,
          userName: widget.clientName,
          userEmail: widget.clientEmail,
        ),
      ),
    );
  }
}
