import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../models/technician_model.dart';
import '../services/appointment_service.dart';
import '../services/technician_service.dart';
import '../services/service_provider.dart'; // AJOUT

class BookAppointmentScreen extends StatefulWidget {
  final String clientName;
  final String clientEmail;

  const BookAppointmentScreen({
    // SUPPRIMER appointmentService
    super.key,
    required this.clientName,
    required this.clientEmail,
  });

  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  late final AppointmentService _appointmentService; // MODIFIER
  final TechnicianService _technicianService = TechnicianService();
  final _formKey = GlobalKey<FormState>();

  String _selectedService = 'Vidange';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final _notesController = TextEditingController();
  final _vehicleController = TextEditingController();

  List<Technician> _availableTechnicians = [];
  Technician? _selectedTechnician;
  bool _loadingTechnicians = false;

  final String _garageId = 'garage_principal';
  final String _garageName = 'Garage Principal';

  @override
  void initState() {
    super.initState();
    _appointmentService = ServiceProvider().appointmentService; // MODIFIER
    _loadAvailableTechnicians();
  }

  Future<void> _loadAvailableTechnicians() async {
    setState(() {
      _loadingTechnicians = true;
    });

    try {
      print('🔧 Chargement de tous les techniciens disponibles...');

      // Récupérer tous les techniciens (sans filtre par garage)
      final allTechnicians = await _technicianService.getAllTechnicians();

      // Filtrer seulement les techniciens disponibles
      final availableTechnicians =
          allTechnicians.where((t) => t.isAvailable).toList();

      print(
          '👨‍🔧 Techniciens disponibles récupérés: ${availableTechnicians.length}');

      setState(() {
        _availableTechnicians = availableTechnicians;
        _loadingTechnicians = false;
      });

      // DEBUG: Afficher les techniciens dans la console
      for (var tech in _availableTechnicians) {
        print(
            '✅ Technicien disponible: ${tech.name} - ${tech.specialty} - Expérience: ${tech.experience} ans - Travaux: ${tech.completedJobs}');
      }
    } catch (e) {
      print('❌ Erreur chargement techniciens: $e');
      setState(() {
        _loadingTechnicians = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement des techniciens: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prendre un rendez-vous'),
        backgroundColor: Colors.orange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Information garage
                _buildGarageInfo(),

                const SizedBox(height: 20),

                // Sélection du service
                const Text(
                  'Service demandé',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  items:
                      _appointmentService.getAvailableServices().map((service) {
                    return DropdownMenuItem(
                      value: service,
                      child: Text(service),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedService = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),

                const SizedBox(height: 20),

                // Information véhicule
                const Text(
                  'Véhicule (optionnel)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ex: Toyota Corolla 2020, Peugeot 208...',
                  ),
                ),

                const SizedBox(height: 20),

                // Sélection du technicien
                _buildTechnicianSelector(),

                const SizedBox(height: 20),

                // Sélection de la date
                const Text(
                  'Date du rendez-vous',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _selectDate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(_getFormattedDate(_selectedDate)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Sélection de l'heure
                const Text(
                  'Heure du rendez-vous',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _selectTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[50],
                    foregroundColor: Colors.green,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 8),
                      Text(_selectedTime.format(context)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Notes
                const Text(
                  'Notes supplémentaires (optionnel)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText:
                        'Décrivez votre problème ou demande particulière...',
                  ),
                ),

                const SizedBox(height: 30),

                // Bouton de confirmation
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: _bookAppointment,
                    child: const Text(
                      'CONFIRMER LE RENDEZ-VOUS',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // AJOUT : Widget pour afficher les informations du garage
  Widget _buildGarageInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.build_circle, color: Colors.blue[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _garageName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre rendez-vous sera traité par notre équipe de professionnels',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Technicien préféré (optionnel)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Choisissez un technicien spécialisé pour votre intervention',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        if (_loadingTechnicians)
          const Center(child: CircularProgressIndicator())
        else if (_availableTechnicians.isEmpty)
          _buildInfoMessage('Aucun technicien disponible pour le moment')
        else
          _buildTechnicianDropdown(),
      ],
    );
  }

  Widget _buildTechnicianDropdown() {
    return DropdownButtonFormField<Technician>(
      value: _selectedTechnician,
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Choisir un technicien...',
        prefixIcon: Icon(Icons.engineering),
      ),
      selectedItemBuilder: (context) {
        return [
          const Text('Choisir un technicien...'),
          ..._availableTechnicians.map((technician) {
            return Text(technician.name);
          }),
        ];
      },
      items: [
        const DropdownMenuItem<Technician>(
          value: null,
          child: Text('Aucun technicien spécifique - Assigné automatiquement'),
        ),
        ..._availableTechnicians.map((Technician technician) {
          return DropdownMenuItem<Technician>(
            value: technician,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 70,
                maxHeight: 70, // Hauteur fixe pour chaque item
              ),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo de profil ou avatar
                  _buildTechnicianAvatar(technician),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Ligne 1: Nom et note
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                technician.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (technician.rating > 0) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                technician.formattedRating,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Ligne 2: Spécialité et statut
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                technician.specialty,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: technician.isAvailable
                                    ? Colors.green[50]
                                    : Colors.red[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                technician.isAvailable
                                    ? 'Disponible'
                                    : 'Occupé',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: technician.isAvailable
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Ligne 3: Expérience et travaux
                        if (technician.experience > 0 ||
                            technician.completedJobs > 0)
                          Row(
                            children: [
                              if (technician.experience > 0)
                                Expanded(
                                  child: Text(
                                    '${technician.formattedExperience} • ${technician.expertiseLevel}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (technician.completedJobs > 0)
                                Text(
                                  '• ${technician.formattedCompletedJobs}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                  ),
                                ),
                            ],
                          ),

                        // Ligne 4: Compétences principales (optionnel)
                        if (technician.skills.isNotEmpty)
                          Text(
                            'Compétences: ${technician.mainSkills.join(', ')}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Badge "Très bien noté" si applicable
                  if (technician.isHighlyRated)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        '⭐',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
      onChanged: (Technician? newValue) {
        setState(() {
          _selectedTechnician = newValue;
        });

        if (newValue != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Technicien ${newValue.name} sélectionné - ${newValue.expertiseLevel}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  Widget _buildTechnicianAvatar(Technician technician) {
    // Si le technicien a une image de profil, l'utiliser
    if (technician.hasProfileImage) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(technician.profileImage!),
      );
    }

    // Sinon, utiliser un avatar avec la première lettre du nom
    return CircleAvatar(
      radius: 20,
      backgroundColor: _getAvatarColor(technician.name),
      child: Text(
        technician.name[0].toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
    ];
    final index = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  Widget _buildInfoMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[100]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue[400], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _bookAppointment() async {
    if (_formKey.currentState!.validate()) {
      // Combiner date et heure
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // CORRECTION : Utiliser un appointmentId FIXE basé sur l'email
      final appointmentId = 'appt_${widget.clientEmail.split('@')[0]}_main';

      // Créer le rendez-vous
      final appointment = Appointment(
        id: appointmentId, // MAINTENANT FIXE
        clientId: 'client_${widget.clientEmail}',
        clientName: widget.clientName,
        clientEmail: widget.clientEmail,
        clientPhone: '+225 00 00 00 00',
        service: _selectedService,
        dateTime: appointmentDateTime,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        vehicle:
            _vehicleController.text.isEmpty ? null : _vehicleController.text,
        createdAt: DateTime.now(),
        assignedTechnicianId: _selectedTechnician?.id,
        assignedTechnicianName: _selectedTechnician?.name,
        assignedTechnicianSpecialty: _selectedTechnician?.specialty,
        garageId: _garageId,
        garageName: _garageName,
      );

      // Réserver le rendez-vous
      final String? error =
          await _appointmentService.bookAppointment(appointment);

      if (error != null) {
        _showMessage(error, isSuccess: false);
      } else {
        String successMessage =
            'Rendez-vous confirmé pour le ${_getFormattedDate(appointmentDateTime)} à ${_selectedTime.format(context)}!';

        // Ajouter une mention spéciale si un technicien est sélectionné
        if (_selectedTechnician != null) {
          successMessage +=
              '\nTechnicien assigné : ${_selectedTechnician!.name} (${_selectedTechnician!.expertiseLevel})';
        }

        // Ajouter la mention du garage
        successMessage += '\nGarage : $_garageName';

        _showMessage(successMessage, isSuccess: true);

        // Retour à l'écran précédent après délai
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    }
  }

  String _getFormattedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }
}
