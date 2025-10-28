import 'package:flutter/material.dart';
import '../services/appointment_service.dart';

class ClientListScreen extends StatefulWidget {
  final AppointmentService appointmentService;

  const ClientListScreen({
    super.key,
    required this.appointmentService,
  });

  @override
  _ClientListScreenState createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  late final AppointmentService _appointmentService;
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _appointmentService = widget.appointmentService;
    _loadClients();
  }

  void _loadClients() async {
    final appointments = await _appointmentService.getAllAppointments();

    // Grouper les rendez-vous par client
    final clientMap = <String, Map<String, dynamic>>{};

    for (final appointment in appointments) {
      final clientEmail = appointment.clientEmail;
      if (!clientMap.containsKey(clientEmail)) {
        clientMap[clientEmail] = {
          'name': appointment.clientName,
          'email': appointment.clientEmail,
          'appointmentCount': 0,
          'lastAppointment': appointment.dateTime,
          'totalSpent': 0.0,
        };
      }

      clientMap[clientEmail]!['appointmentCount']++;
      if (appointment.dateTime
          .isAfter(clientMap[clientEmail]!['lastAppointment'])) {
        clientMap[clientEmail]!['lastAppointment'] = appointment.dateTime;
      }
    }

    setState(() {
      _clients = clientMap.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Clients'),
        backgroundColor: Colors.purple,
      ),
      body: _clients.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun client pour le moment',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Statistiques
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.purple[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                          _clients.length.toString(), 'Clients total'),
                      _buildStatItem(
                          _clients
                              .where((c) => c['appointmentCount'] > 1)
                              .length
                              .toString(),
                          'Clients fidèles'),
                    ],
                  ),
                ),

                // Liste des clients
                Expanded(
                  child: ListView.builder(
                    itemCount: _clients.length,
                    itemBuilder: (context, index) {
                      final client = _clients[index];
                      final lastAppointment =
                          client['lastAppointment'] as DateTime;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple[100],
                            child: Text(
                              client['name'][0].toUpperCase(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            client['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(client['email']),
                              Text('${client['appointmentCount']} rendez-vous'),
                              Text(
                                'Dernier: ${lastAppointment.day}/${lastAppointment.month}/${lastAppointment.year}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: client['appointmentCount'] > 1
                              ? const Icon(Icons.star, color: Colors.amber)
                              : null,
                          onTap: () {
                            _showClientDetails(client);
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

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  void _showClientDetails(Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${client['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${client['email']}'),
            Text('Nombre de RDV: ${client['appointmentCount']}'),
            Text(
              'Client ${client['appointmentCount'] > 1 ? 'fidèle' : 'nouveau'}',
              style: TextStyle(
                color: client['appointmentCount'] > 1
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
}
