import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import '../models/appointment_model.dart';
import '../services/service_provider.dart';

class ClientAppointmentsScreen extends StatefulWidget {
  final String clientEmail;

  const ClientAppointmentsScreen({
    super.key,
    required this.clientEmail,
  });

  @override
  _ClientAppointmentsScreenState createState() =>
      _ClientAppointmentsScreenState();
}

class _ClientAppointmentsScreenState extends State<ClientAppointmentsScreen> {
  late final AppointmentService _appointmentService;
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _appointmentService = ServiceProvider().appointmentService;
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    // Utiliser directement l'email au lieu de créer un ID
    final appointments =
        await _appointmentService.getClientAppointments(widget.clientEmail);
    setState(() {
      _appointments = appointments;
      _isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes rendez-vous'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 20),
                      const Text(
                        'Aucun rendez-vous pour le moment',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Prenez votre premier rendez-vous !',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Retour à l'accueil
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Prendre un rendez-vous'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(appointment.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(
                          appointment.service,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${appointment.formattedDate} à ${appointment.formattedTime}'),
                            Text(
                              _getStatusText(appointment.status),
                              style: TextStyle(
                                color: _getStatusColor(appointment.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (appointment.notes != null &&
                                appointment.notes!.isNotEmpty)
                              Text(
                                'Notes: ${appointment.notes!}',
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic),
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
    );
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
