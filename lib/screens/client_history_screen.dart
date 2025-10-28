import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import '../models/appointment_model.dart';
import '../services/service_provider.dart'; // AJOUT

class ClientHistoryScreen extends StatefulWidget {
  final String clientEmail;

  const ClientHistoryScreen({
    // SUPPRIMER appointmentService
    super.key,
    required this.clientEmail,
  });

  @override
  _ClientHistoryScreenState createState() => _ClientHistoryScreenState();
}

class _ClientHistoryScreenState extends State<ClientHistoryScreen> {
  late final AppointmentService _appointmentService; // MODIFIER
  List<Appointment> _pastAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _appointmentService = ServiceProvider().appointmentService; // MODIFIER
    _loadHistory();
  }

  void _loadHistory() async {
    final clientId = 'client_${widget.clientEmail}';
    final allAppointments =
        await _appointmentService.getClientAppointments(clientId);

    final now = DateTime.now();
    final pastAppointments =
        allAppointments.where((a) => a.dateTime.isBefore(now)).toList();

    // Trier par date (plus récent en premier)
    pastAppointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    setState(() {
      _pastAppointments = pastAppointments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Historique'),
        backgroundColor: Colors.purple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pastAppointments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucun historique',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Vos rendez-vous passés apparaîtront ici',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Résumé
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.purple[50],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHistoryStat(
                              _pastAppointments.length.toString(), 'Total'),
                          _buildHistoryStat(
                              _pastAppointments
                                  .where((a) => a.status == 'confirmed')
                                  .length
                                  .toString(),
                              'Terminés'),
                          _buildHistoryStat(
                              _pastAppointments
                                  .where((a) => a.status == 'cancelled')
                                  .length
                                  .toString(),
                              'Annulés'),
                        ],
                      ),
                    ),

                    // Liste historique
                    Expanded(
                      child: ListView.builder(
                        itemCount: _pastAppointments.length,
                        itemBuilder: (context, index) {
                          final appointment = _pastAppointments[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: _getStatusIcon(appointment.status),
                              title: Text(
                                appointment.service,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${appointment.formattedDate} à ${appointment.formattedTime}'),
                                  Text(
                                    _getStatusText(appointment.status),
                                    style: TextStyle(
                                      color:
                                          _getStatusColor(appointment.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (appointment.notes != null &&
                                      appointment.notes!.isNotEmpty)
                                    Text(
                                      'Notes: ${appointment.notes!}',
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward),
                              onTap: () {
                                _showAppointmentDetails(appointment);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHistoryStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return const Icon(Icons.check_circle, color: Colors.green, size: 30);
      case 'cancelled':
        return const Icon(Icons.cancel, color: Colors.red, size: 30);
      default:
        return const Icon(Icons.pending, color: Colors.orange, size: 30);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'En attente';
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
              _buildDetailRow('Service:', appointment.service),
              _buildDetailRow('Date:', appointment.formattedDate),
              _buildDetailRow('Heure:', appointment.formattedTime),
              _buildDetailRow('Statut:', _getStatusText(appointment.status)),
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
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
