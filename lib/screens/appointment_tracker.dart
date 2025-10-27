import 'package:flutter/material.dart';
import 'dart:async';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';
import 'in_app_chat.dart';

class AppointmentTracker extends StatefulWidget {
  final String appointmentId;
  final String clientEmail;

  const AppointmentTracker({
    super.key,
    required this.appointmentId,
    required this.clientEmail,
  });

  @override
  _AppointmentTrackerState createState() => _AppointmentTrackerState();
}

class _AppointmentTrackerState extends State<AppointmentTracker> {
  int _currentStep = 0;
  Timer? _updateTimer;
  final AppointmentService _appointmentService = AppointmentService();
  Appointment? _currentAppointment;
  bool _isAppointmentValid = false;
  bool _isLoading = true;
  bool _appointmentNotFound = false;

  List<AppointmentStep> get _steps {
    if (_currentAppointment?.status == 'rejected') {
      return [
        AppointmentStep(
            'Demande envoyée',
            'Votre demande de rendez-vous a été envoyée au garage',
            Icons.send,
            Colors.blue),
        AppointmentStep(
            'Rendez-vous rejeté',
            'Le garage a refusé votre rendez-vous. Contactez-les pour plus d\'informations.',
            Icons.cancel,
            Colors.red),
      ];
    }

    if (_currentAppointment?.status == 'cancelled') {
      return [
        AppointmentStep(
            'Demande envoyée',
            'Votre demande de rendez-vous a été envoyée au garage',
            Icons.send,
            Colors.blue),
        AppointmentStep('Rendez-vous annulé', 'Le rendez-vous a été annulé',
            Icons.cancel, Colors.red),
      ];
    }

    return [
      AppointmentStep(
          'En attente de confirmation',
          'Votre demande de rendez-vous est en attente de confirmation par le garage',
          Icons.access_time,
          Colors.orange),
      AppointmentStep(
          'Confirmé',
          'Votre rendez-vous a été confirmé par le garage',
          Icons.check_circle,
          Colors.green),
      AppointmentStep('En cours de préparation',
          'Le garage prépare votre véhicule', Icons.build_circle, Colors.blue),
      AppointmentStep('Diagnostic', 'Diagnostic du véhicule en cours',
          Icons.search, Colors.blue),
      AppointmentStep('En réparation', 'Réparation du véhicule en cours',
          Icons.build, Colors.blue),
      AppointmentStep('Contrôle qualité', 'Contrôle final et vérifications',
          Icons.verified, Colors.purple),
      AppointmentStep('Terminé', 'Véhicule prêt à être récupéré',
          Icons.done_all, Colors.green),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializeAppointment();
  }

  void _initializeAppointment() async {
    print('🔍 Initialisation du suivi de rendez-vous:');
    print('   ID: ${widget.appointmentId}');
    print('   Client: ${widget.clientEmail}');

    try {
      _currentAppointment =
          await _appointmentService.getAppointment(widget.appointmentId);

      if (_currentAppointment == null) {
        print('❌ Rendez-vous non trouvé en base de données');
        setState(() {
          _isLoading = false;
          _appointmentNotFound = true;
          _isAppointmentValid = false;
        });
        return;
      }

      final belongsToClient =
          _currentAppointment!.clientEmail == widget.clientEmail;

      if (!belongsToClient) {
        print('🚫 Accès interdit: le rendez-vous ne correspond pas au client');
        setState(() {
          _isLoading = false;
          _isAppointmentValid = false;
        });
        return;
      }

      _validateAppointment();
      _determineCurrentStep();

      if (_isAppointmentValid) {
        _startRealTimeUpdates();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation: $e');
      setState(() {
        _isLoading = false;
        _isAppointmentValid = false;
      });
    }
  }

  void _validateAppointment() {
    final appointment = _currentAppointment!;

    final hasValidId = appointment.id != null && appointment.id!.isNotEmpty;
    final hasValidClient = appointment.clientName.isNotEmpty;
    final hasValidService = appointment.service.isNotEmpty;
    final hasValidDate = appointment.dateTime.isAfter(DateTime(2020));
    final hasValidEmail = appointment.clientEmail.isNotEmpty &&
        appointment.clientEmail.contains('@');
    final hasValidGarage = appointment.garageId.isNotEmpty;

    _isAppointmentValid = hasValidId &&
        hasValidClient &&
        hasValidService &&
        hasValidDate &&
        hasValidEmail &&
        hasValidGarage;

    if (!_isAppointmentValid) {
      print('''
⚠️ RENDEZ-VOUS INVALIDE:
  ID: ${appointment.id}
  Client: ${appointment.clientName}
  Email: ${appointment.clientEmail}
  Service: ${appointment.service}
  Date: ${appointment.dateTime}
  Statut: ${appointment.status}
  Garage: ${appointment.garageId}
''');
    } else {
      print(
          '✅ Rendez-vous valide: ${appointment.id} - Statut: ${appointment.status}');
    }
  }

  void _determineCurrentStep() {
    if (!_isAppointmentValid) {
      _currentStep = 0;
      return;
    }

    switch (_currentAppointment!.status) {
      case 'pending':
        _currentStep = 0;
        break;
      case 'rejected':
        _currentStep = 1;
        break;
      case 'cancelled':
        _currentStep = 1;
        break;
      case 'confirmed':
        _currentStep = 1;
        break;
      case 'in_progress':
        _currentStep = 2;
        break;
      case 'diagnostic':
        _currentStep = 3;
        break;
      case 'repair':
        _currentStep = 4;
        break;
      case 'quality_check':
        _currentStep = 5;
        break;
      case 'completed':
        _currentStep = 6;
        break;
      default:
        _currentStep = 0;
    }

    print(
        '📊 Étape déterminée: $_currentStep - Statut: ${_currentAppointment!.status}');
  }

  void _startRealTimeUpdates() {
    if (!_isAppointmentValid) return;

    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (mounted) {
        await _refreshAppointmentData();
      }
    });
  }

  Future<void> _refreshAppointmentData() async {
    try {
      final updatedAppointment =
          await _appointmentService.getAppointment(widget.appointmentId);
      if (updatedAppointment != null && mounted) {
        setState(() {
          _currentAppointment = updatedAppointment;
          _determineCurrentStep();
        });
      } else if (mounted) {
        setState(() {
          _isAppointmentValid = false;
          _appointmentNotFound = true;
        });
        _updateTimer?.cancel();
      }
    } catch (e) {
      print('❌ Erreur rafraîchissement données: $e');
    }
  }

  String _getFormattedDate() {
    if (!_isAppointmentValid) {
      return 'Date non définie';
    }
    final date = _currentAppointment!.dateTime;
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi du Rendez-vous'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _appointmentNotFound
              ? _buildNotFoundState()
              : _isAppointmentValid
                  ? _buildAppointmentContent()
                  : _buildInvalidState(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement du rendez-vous...'),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Rendez-vous non trouvé',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Le rendez-vous a été supprimé ou n\'existe pas dans notre base de données',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retour à la liste'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Rendez-vous invalide',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Impossible d\'afficher les détails de ce rendez-vous',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retour à la liste'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentContent() {
    if (_currentAppointment!.status == 'rejected' ||
        _currentAppointment!.status == 'cancelled') {
      return _buildRejectedState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppointmentHeader(),
          const SizedBox(height: 20),
          _buildTimeline(),
          const SizedBox(height: 20),
          _buildAppointmentDetails(),
          const SizedBox(height: 16),
          _buildQuickContact(),
        ],
      ),
    );
  }

  Widget _buildRejectedState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppointmentHeader(),
          const SizedBox(height: 20),
          _buildTimeline(),
          const SizedBox(height: 20),
          _buildAppointmentDetails(),
          const SizedBox(height: 20),
          _buildRejectedMessage(),
          const SizedBox(height: 16),
          _buildQuickContact(),
        ],
      ),
    );
  }

  Widget _buildRejectedMessage() {
    return Card(
      elevation: 2,
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  _currentAppointment!.status == 'rejected'
                      ? 'Rendez-vous rejeté'
                      : 'Rendez-vous annulé',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _currentAppointment!.status == 'rejected'
                  ? 'Le garage a refusé votre demande de rendez-vous. Cela peut être dû à :'
                  : 'Le rendez-vous a été annulé. Raisons possibles :',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentAppointment!.status == 'rejected') ...[
                    _buildReasonItem('• Indisponibilité à la date demandée'),
                    _buildReasonItem('• Capacité d\'accueil dépassée'),
                    _buildReasonItem('• Service non disponible temporairement'),
                    _buildReasonItem('• Problème de planning'),
                  ] else ...[
                    _buildReasonItem('• Annulation par le client'),
                    _buildReasonItem('• Annulation par le garage'),
                    _buildReasonItem('• Problème de disponibilité'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Contactez le garage pour plus d\'informations ou pour prendre un nouveau rendez-vous.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildAppointmentHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Rendez-vous #${_currentAppointment!.id!.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Service: ${_currentAppointment!.service}',
              style: const TextStyle(fontSize: 14),
            ),
            if (_currentAppointment!.vehicle != null) ...[
              const SizedBox(height: 4),
              Text(
                'Véhicule: ${_currentAppointment!.vehicle}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getStatusText().toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progression du rendez-vous',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCompleted = index <= _currentStep;
              final isCurrent = index == _currentStep;

              return _buildTimelineStep(step, isCompleted, isCurrent, index);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
      AppointmentStep step, bool isCompleted, bool isCurrent, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? step.color : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? step.icon : Icons.access_time,
                  color: isCompleted ? Colors.white : Colors.grey,
                  size: 16,
                ),
              ),
              if (index < _steps.length - 1) ...[
                Container(
                  width: 2,
                  height: 40,
                  color: isCompleted ? step.color : Colors.grey[300],
                ),
              ],
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent ? step.color : null,
                        ),
                      ),
                    ),
                    if (isCurrent &&
                        _currentAppointment!.status != 'rejected' &&
                        _currentAppointment!.status != 'cancelled') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: step.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'En cours',
                          style: TextStyle(
                            fontSize: 10,
                            color: step.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (isCurrent &&
                    _currentAppointment!.status != 'rejected' &&
                    _currentAppointment!.status != 'cancelled') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Temps estimé: ${_getEstimatedTime(index)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetails() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails du rendez-vous',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.person,
              'Client',
              _currentAppointment!.clientName,
            ),
            _buildDetailRow(
              Icons.phone,
              'Téléphone',
              _currentAppointment!.clientPhone,
            ),
            _buildDetailRow(
              Icons.email,
              'Email',
              _currentAppointment!.clientEmail,
            ),
            _buildDetailRow(
              Icons.build,
              'Service',
              _currentAppointment!.service,
            ),
            if (_currentAppointment!.vehicle != null)
              _buildDetailRow(
                Icons.directions_car,
                'Véhicule',
                _currentAppointment!.vehicle!,
              ),
            if (_currentAppointment!.assignedTechnicianName != null)
              _buildDetailRow(
                Icons.engineering,
                'Technicien',
                _currentAppointment!.assignedTechnicianName!,
              ),
            _buildDetailRow(
              Icons.calendar_today,
              'Date et heure',
              _getFormattedDate(),
            ),
            if (_currentAppointment!.notes != null &&
                _currentAppointment!.notes!.isNotEmpty)
              _buildDetailRow(
                Icons.note,
                'Notes',
                _currentAppointment!.notes!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickContact() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.support_agent, size: 24, color: Colors.green[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Besoin d\'aide ?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentAppointment!.status == 'rejected' ||
                            _currentAppointment!.status == 'cancelled'
                        ? 'Contactez le garage pour comprendre la situation'
                        : 'Contactez directement le garage',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat, size: 18),
              label: const Text('Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat() {
    if (!_isAppointmentValid) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InAppChat(
          garageId: _currentAppointment!.garageId,
          appointmentId: _currentAppointment!.id!,
          clientEmail: _currentAppointment!.clientEmail,
          clientName: _currentAppointment!.clientName,
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_currentAppointment!.status) {
      case 'confirmed':
        return 'confirmé';
      case 'in_progress':
        return 'en cours';
      case 'completed':
        return 'terminé';
      case 'cancelled':
        return 'annulé';
      case 'rejected':
        return 'rejeté';
      case 'pending':
        return 'en attente';
      default:
        return _currentAppointment!.status;
    }
  }

  Color _getStatusColor() {
    switch (_currentAppointment!.status) {
      case 'confirmed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getEstimatedTime(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return 'En attente de confirmation';
      case 1:
        return 'Immédiat';
      case 2:
        return '15-30 minutes';
      case 3:
        return '30-45 minutes';
      case 4:
        return '1-3 heures';
      case 5:
        return '20-30 minutes';
      case 6:
        return 'Terminé';
      default:
        return 'Variable';
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

class AppointmentStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  AppointmentStep(this.title, this.description, this.icon, this.color);
}
