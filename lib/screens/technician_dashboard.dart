import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

class TechnicianDashboard extends StatefulWidget {
  final String technicianId;
  final String technicianName;

  const TechnicianDashboard({
    super.key,
    required this.technicianId,
    required this.technicianName,
  });

  @override
  _TechnicianDashboardState createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard> {
  final AppointmentService _appointmentService = AppointmentService();
  List<Appointment> _myAppointments = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadMyAppointments();
  }

  Future<void> _loadMyAppointments() async {
    try {
      final allAppointments = await _appointmentService.getAllAppointments();
      setState(() {
        _myAppointments = allAppointments.where((appointment) {
          return appointment.assignedTechnicianId == widget.technicianId;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement RDV technicien: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Appointment> get _filteredAppointments {
    if (_selectedFilter == 'all') {
      return _myAppointments;
    }
    return _myAppointments
        .where((appointment) => appointment.status == _selectedFilter)
        .toList();
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmé';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      await _appointmentService.updateAppointmentStatus(appointmentId, status);
      await _loadMyAppointments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Statut mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
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
              if (appointment.notes != null && appointment.notes!.isNotEmpty)
                _buildDetailRow('Notes:', appointment.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (appointment.status == 'confirmed')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateAppointmentStatus(appointment.id!, 'completed');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Marquer Terminé'),
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
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
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
            _selectedFilter = value;
          });
        },
        selectedColor: Colors.orange.shade100,
        checkmarkColor: Colors.orange,
      ),
    );
  }

  Widget _buildStatsChip(int count, String label, Color color) {
    return Column(
      children: [
        Chip(
          backgroundColor: color.withOpacity(0.2),
          label: Text(
            count.toString(),
            style: TextStyle(color: color),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final confirmedCount =
        _myAppointments.where((a) => a.status == 'confirmed').length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de Bord - ${widget.technicianName}'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyAppointments,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // En-tête avec statistiques
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange.shade50,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Text(
                          widget.technicianName[0],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.technicianName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_myAppointments.length} RDV assignés',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      _buildStatsChip(
                          confirmedCount, 'Confirmés', Colors.green),
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
                        _buildFilterChip('Terminés', 'completed'),
                        _buildFilterChip('Annulés', 'cancelled'),
                      ],
                    ),
                  ),
                ),

                // Liste des RDV
                Expanded(
                  child: _filteredAppointments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 60, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'Aucun rendez-vous',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _myAppointments.isEmpty
                                    ? 'Aucun RDV assigné pour le moment'
                                    : 'Aucun RDV avec ce filtre',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMyAppointments,
                          child: ListView.builder(
                            itemCount: _filteredAppointments.length,
                            itemBuilder: (context, index) {
                              final appointment = _filteredAppointments[index];
                              final statusColor =
                                  _getStatusColor(appointment.status);

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.car_repair,
                                      color: statusColor,
                                    ),
                                  ),
                                  title: Text(
                                    appointment.clientName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appointment.service,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(appointment.formattedDateTime),
                                      if (appointment.vehicle != null &&
                                          appointment.vehicle!.isNotEmpty)
                                        Text(
                                          'Véhicule: ${appointment.vehicle!}',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusText(appointment.status),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: appointment.status == 'confirmed'
                                      ? IconButton(
                                          icon: const Icon(Icons.check_circle,
                                              color: Colors.green),
                                          onPressed: () =>
                                              _updateAppointmentStatus(
                                                  appointment.id!, 'completed'),
                                          tooltip: 'Marquer comme terminé',
                                        )
                                      : null,
                                  onTap: () =>
                                      _showAppointmentDetails(appointment),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
