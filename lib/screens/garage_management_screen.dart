import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/appointment_service.dart';
import '../services/technician_service.dart';
import '../services/simple_auth_service.dart';
import '../services/service_provider.dart';
import '../models/appointment_model.dart';
import '../models/technician_model.dart';
import '../models/user_model.dart';

class GarageManagementScreen extends StatefulWidget {
  const GarageManagementScreen({super.key});

  @override
  _GarageManagementScreenState createState() => _GarageManagementScreenState();
}

class _GarageManagementScreenState extends State<GarageManagementScreen> {
  late AppointmentService _appointmentService;
  final TechnicianService _technicianService = TechnicianService();
  List<Appointment> _appointments = [];
  List<Technician> _technicians = [];
  bool _isLoading = true;
  bool _checkingAccess = true;
  bool _isGarage = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _appointmentService = ServiceProvider().appointmentService;
    _checkGarageAccess();
  }

  Future<void> _checkGarageAccess() async {
    try {
      print('🔐 Vérification des accès garage pour gestion...');

      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);
      final currentUser = await authService.getCurrentAppUser();

      if (currentUser != null && currentUser.userType == UserType.garage) {
        print('✅ Accès garage autorisé pour la gestion');
        setState(() {
          _isGarage = true;
          _checkingAccess = false;
        });
        await _loadTechnicians();
        _loadAppointments();
      } else {
        print('❌ Accès garage refusé pour la gestion');
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
      print('❌ Erreur vérification accès gestion: $e');
      setState(() {
        _checkingAccess = false;
        _isGarage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de vérification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadTechnicians() async {
    try {
      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);
      final currentUser = await authService.getCurrentAppUser();

      if (currentUser != null) {
        final technicians =
            await _technicianService.getTechnicians(currentUser.uid);
        setState(() {
          _technicians = technicians;
        });
        print('👨‍🔧 ${_technicians.length} techniciens chargés');
      }
    } catch (e) {
      print('❌ Erreur chargement techniciens: $e');
    }
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appointments = await _appointmentService.getAllAppointments();
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
      print('📊 ${_appointments.length} rendez-vous chargés');
    } catch (e) {
      print('❌ Erreur chargement des rendez-vous: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _assignTechnician(Appointment appointment) async {
    if (_technicians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun technicien disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Technician? selectedTechnician;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assigner un technicien'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _technicians.length,
            itemBuilder: (context, index) {
              final technician = _technicians[index];
              return MouseRegion(
                cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange[100],
                      child: Text(
                        technician.name.characters.first,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    title: Text(
                      technician.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          technician.specialty,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text('${technician.rating}'),
                            const Spacer(),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: technician.isAvailable
                                      ? Colors.green[50]
                                      : Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
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
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: appointment.assignedTechnicianId == technician.id
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      selectedTechnician = technician;
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selectedTechnician != null) {
      try {
        // UTILISER LA NOUVELLE MÉTHODE D'ASSIGNATION QUI ENVOIE LA NOTIFICATION
        await _appointmentService.assignTechnicianToAppointment(
          appointment.id!,
          selectedTechnician!.id,
        );

        await _technicianService.toggleTechnicianAvailability(
            selectedTechnician!.id, false);

        await _loadTechnicians();
        await _loadAppointments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${selectedTechnician!.name} assigné au RDV - Notification envoyée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Erreur assignation technicien: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'assignation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _releaseTechnician(Appointment appointment) async {
    if (appointment.assignedTechnicianId == null) return;

    try {
      await _technicianService.toggleTechnicianAvailability(
          appointment.assignedTechnicianId!, true);

      final updatedAppointment = appointment.copyWith(
        assignedTechnicianId: null,
        assignedTechnicianName: null,
        assignedTechnicianSpecialty: null,
      );

      await _appointmentService.updateAppointment(updatedAppointment);

      await _loadTechnicians();
      await _loadAppointments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Technicien libéré du RDV'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur libération technicien: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la libération'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NOUVELLE MÉTHODE: Vérifier si un statut est autorisé
  bool _isStatusAllowed(String currentStatus, String newStatus) {
    // Définir l'ordre du workflow (unidirectionnel)
    final workflowOrder = [
      'pending',
      'confirmed',
      'in_progress',
      'diagnostic',
      'repair',
      'quality_check',
      'completed'
    ];

    final currentIndex = workflowOrder.indexOf(currentStatus);
    final newIndex = workflowOrder.indexOf(newStatus);

    // Autoriser seulement la progression vers l'avant
    if (currentIndex != -1 && newIndex != -1) {
      return newIndex > currentIndex;
    }

    // Toujours autoriser l'annulation et le rejet
    return newStatus == 'cancelled' || newStatus == 'rejected';
  }

  // MÉTHODE: Faire progresser le statut du RDV
  Future<void> _progressAppointmentStatus(Appointment appointment) async {
    try {
      await _appointmentService.progressToNextStatus(
          appointment.id!, appointment.status);
      await _loadAppointments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Statut mis à jour: ${_getStatusText(appointment.nextStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur progression statut: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // MÉTHODE: Mettre à jour un statut spécifique
  Future<void> _updateAppointmentStatus(
      Appointment appointment, String newStatus) async {
    try {
      if (appointment.id != null) {
        await _appointmentService.updateAppointmentStatus(
            appointment.id!, newStatus);
        await _loadAppointments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Statut mis à jour: ${_getStatusText(newStatus)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur mise à jour statut: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Appointment> get _filteredAppointments {
    if (_selectedFilter == 'all') {
      return _appointments;
    } else if (_selectedFilter == 'with_technician') {
      return _appointments
          .where((appointment) => appointment.hasAssignedTechnician)
          .toList();
    } else if (_selectedFilter == 'in_progress') {
      return _appointments
          .where((appointment) => appointment.canProgress)
          .toList();
    }
    return _appointments
        .where((appointment) => appointment.status == _selectedFilter)
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'diagnostic':
        return Colors.blue;
      case 'repair':
        return Colors.blue;
      case 'quality_check':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // CORRECTION: Utiliser la méthode du service pour l'affichage cohérent
  String _getStatusText(String status) {
    return _appointmentService.getStatusDisplayText(status);
  }

  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du rendez-vous'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Client:', appointment.clientName),
              _buildDetailRow('Email:', appointment.clientEmail),
              _buildDetailRow('Téléphone:', appointment.clientPhone),
              _buildDetailRow('Service:', appointment.service),
              _buildDetailRow('Date:', appointment.formattedDateTime),
              _buildDetailRow('Statut:', _getStatusText(appointment.status)),
              if (appointment.vehicle != null &&
                  appointment.vehicle!.isNotEmpty)
                _buildDetailRow('Véhicule:', appointment.vehicle!),
              if (appointment.hasAssignedTechnician) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Technicien assigné:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '👨‍🔧 ${appointment.assignedTechnicianName!}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '🔧 ${appointment.assignedTechnicianSpecialty!}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              if (appointment.notes != null && appointment.notes!.isNotEmpty)
                _buildDetailRow('Notes:', appointment.notes!),

              // Affichage de la progression
              if (appointment.canProgress) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prochaine étape:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStatusText(appointment.nextStatus),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _progressAppointmentStatus(appointment);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: Text(_getNextStatusText(appointment.status)),
                        ),
                      ),
                    ],
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
          if (!appointment.hasAssignedTechnician &&
              appointment.status == 'confirmed')
            MouseRegion(
              cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _assignTechnician(appointment);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Assigner Technicien'),
              ),
            )
          else if (appointment.hasAssignedTechnician)
            MouseRegion(
              cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _releaseTechnician(appointment);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Libérer Technicien'),
              ),
            ),
        ],
      ),
    );
  }

  // NOUVELLE MÉTHODE: Obtenir le texte du prochain statut
  String _getNextStatusText(String currentStatus) {
    switch (currentStatus) {
      case 'confirmed':
        return 'Commencer la préparation';
      case 'in_progress':
        return 'Démarrer le diagnostic';
      case 'diagnostic':
        return 'Commencer la réparation';
      case 'repair':
        return 'Contrôle qualité';
      case 'quality_check':
        return 'Marquer comme terminé';
      default:
        return 'Terminer';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des rendez-vous - Garage'),
        backgroundColor: Colors.blue,
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _loadTechnicians();
                _loadAppointments();
              },
              tooltip: 'Actualiser',
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec stats techniciens
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.build_circle,
                        color: Colors.blue, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Espace Garage - Gestion des RDV',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      backgroundColor: Colors.blue[100],
                      label: Text(
                        '${_appointments.length} RDV',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Statistiques techniciens
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Chip(
                      backgroundColor: Colors.green[100],
                      label: Text(
                        '${_technicians.where((t) => t.isAvailable).length} Tech. dispo',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                    Chip(
                      backgroundColor: Colors.orange[100],
                      label: Text(
                        '${_technicians.where((t) => !t.isAvailable).length} Tech. occupés',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                    Chip(
                      backgroundColor: Colors.blue[100],
                      label: Text(
                        '${_appointments.where((a) => a.canProgress).length} RDV en cours',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filtres
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tous', 'all'),
                  _buildFilterChip('En attente', 'pending'),
                  _buildFilterChip('Confirmés', 'confirmed'),
                  _buildFilterChip('En cours', 'in_progress'),
                  _buildFilterChip('Terminés', 'completed'),
                  _buildFilterChip('Avec Technicien', 'with_technician'),
                ],
              ),
            ),
          ),

          // Liste des rendez-vous
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAppointments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aucun rendez-vous trouvé',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Les rendez-vous apparaîtront ici',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadTechnicians();
                          await _loadAppointments();
                        },
                        child: ListView.builder(
                          itemCount: _filteredAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = _filteredAppointments[index];
                            return _buildAppointmentCard(appointment);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
        child: FilterChip(
          label: Text(label),
          selected: _selectedFilter == value,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = value;
            });
          },
          selectedColor: Colors.blue[100],
          checkmarkColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 2,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(appointment.status).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(appointment.status),
              color: _getStatusColor(appointment.status),
            ),
          ),
          title: Text(
            appointment.clientName,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.service,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                appointment.formattedDateTime,
                overflow: TextOverflow.ellipsis,
              ),
              if (appointment.vehicle != null &&
                  appointment.vehicle!.isNotEmpty)
                Text(
                  'Véhicule: ${appointment.vehicle!}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              // Affichage du technicien assigné
              if (appointment.hasAssignedTechnician)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.engineering,
                          size: 12, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          appointment.assignedTechnicianName!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(appointment.status),
                  style: TextStyle(
                    color: _getStatusColor(appointment.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Bouton de progression rapide
              if (appointment.canProgress) ...[
                const SizedBox(height: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
                  child: SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => _progressAppointmentStatus(appointment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 0),
                      ),
                      child: Text(
                        _getNextStatusText(appointment.status),
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'assign_technician') {
                _assignTechnician(appointment);
              } else if (value == 'release_technician') {
                _releaseTechnician(appointment);
              } else if (value == 'progress_status' &&
                  appointment.canProgress) {
                _progressAppointmentStatus(appointment);
              } else {
                _updateAppointmentStatus(appointment, value);
              }
            },
            itemBuilder: (context) {
              // FILTRER les options selon le statut actuel
              final menuItems = <PopupMenuEntry<String>>[];

              // Options de statut de base (uniquement autorisées)
              if (_isStatusAllowed(appointment.status, 'confirmed')) {
                menuItems.add(
                  PopupMenuItem(
                    value: 'confirmed',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: _getStatusColor('confirmed')),
                        const SizedBox(width: 8),
                        const Text('Confirmer'),
                      ],
                    ),
                  ),
                );
              }

              // Toujours autoriser l'annulation
              menuItems.add(
                PopupMenuItem(
                  value: 'cancelled',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: _getStatusColor('cancelled')),
                      const SizedBox(width: 8),
                      const Text('Annuler'),
                    ],
                  ),
                ),
              );

              // Option de progression (uniquement si autorisée)
              if (appointment.canProgress) {
                menuItems.add(
                  PopupMenuItem(
                    value: 'progress_status',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_forward,
                            color: _getStatusColor(appointment.nextStatus)),
                        const SizedBox(width: 8),
                        Text('${_getNextStatusText(appointment.status)} →'),
                      ],
                    ),
                  ),
                );
              }

              // Gestion des techniciens
              if (!appointment.hasAssignedTechnician &&
                  appointment.status == 'confirmed') {
                menuItems.add(const PopupMenuDivider());
                menuItems.add(
                  const PopupMenuItem(
                    value: 'assign_technician',
                    child: Row(
                      children: [
                        Icon(Icons.person_add, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Assigner Technicien'),
                      ],
                    ),
                  ),
                );
              } else if (appointment.hasAssignedTechnician) {
                menuItems.add(const PopupMenuDivider());
                menuItems.add(
                  const PopupMenuItem(
                    value: 'release_technician',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Libérer Technicien'),
                      ],
                    ),
                  ),
                );
              }

              return menuItems;
            },
          ),
          onTap: () => _showAppointmentDetails(appointment),
        ),
      ),
    );
  }

  // MÉTHODE: Obtenir l'icône selon le statut
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.build_circle;
      case 'diagnostic':
        return Icons.search;
      case 'repair':
        return Icons.build;
      case 'quality_check':
        return Icons.verified;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      case 'rejected':
        return Icons.block;
      default:
        return Icons.calendar_today;
    }
  }

  Future<void> _logout() async {
    try {
      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);
      await authService.logout();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Déconnexion réussie'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la déconnexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
