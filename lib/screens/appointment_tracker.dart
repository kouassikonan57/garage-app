import 'package:flutter/material.dart';
import 'dart:async';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';
import '../services/service_provider.dart';
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
  late final AppointmentService _appointmentService;
  Appointment? _currentAppointment;
  bool _isAppointmentValid = false;
  bool _isLoading = true;
  bool _appointmentNotFound = false;

  @override
  void initState() {
    super.initState();
    _appointmentService = ServiceProvider().appointmentService;
    _initializeAppointment();
  }

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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

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
                  ? _buildAppointmentContent(isSmallScreen)
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
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Rendez-vous non trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
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
                minimumSize: const Size(200, 50),
              ),
              child: const Text('Retour à la liste'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvalidState() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Rendez-vous invalide',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
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
                minimumSize: const Size(200, 50),
              ),
              child: const Text('Retour à la liste'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentContent(bool isSmallScreen) {
    if (_currentAppointment!.status == 'rejected' ||
        _currentAppointment!.status == 'cancelled') {
      return _buildRejectedState(isSmallScreen);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppointmentHeader(isSmallScreen),
          const SizedBox(height: 20),
          _buildTimeline(isSmallScreen),
          const SizedBox(height: 20),
          _buildAppointmentDetails(isSmallScreen),
          const SizedBox(height: 16),
          _buildQuickContact(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildRejectedState(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppointmentHeader(isSmallScreen),
          const SizedBox(height: 20),
          _buildTimeline(isSmallScreen),
          const SizedBox(height: 20),
          _buildAppointmentDetails(isSmallScreen),
          const SizedBox(height: 20),
          _buildRejectedMessage(isSmallScreen),
          const SizedBox(height: 16),
          _buildQuickContact(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildRejectedMessage(bool isSmallScreen) {
    return Card(
      elevation: 2,
      color: Colors.red[50],
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 0),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning,
                    color: Colors.red[700], size: isSmallScreen ? 20 : 24),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Text(
                    _currentAppointment!.status == 'rejected'
                        ? 'Rendez-vous rejeté'
                        : 'Rendez-vous annulé',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _currentAppointment!.status == 'rejected'
                  ? 'Le garage a refusé votre demande de rendez-vous. Cela peut être dû à :'
                  : 'Le rendez-vous a été annulé. Raisons possibles :',
              style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: isSmallScreen ? 8 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentAppointment!.status == 'rejected') ...[
                    _buildReasonItem(
                        '• Indisponibilité à la date demandée', isSmallScreen),
                    _buildReasonItem(
                        '• Capacité d\'accueil dépassée', isSmallScreen),
                    _buildReasonItem('• Service non disponible temporairement',
                        isSmallScreen),
                    _buildReasonItem('• Problème de planning', isSmallScreen),
                  ] else ...[
                    _buildReasonItem(
                        '• Annulation par le client', isSmallScreen),
                    _buildReasonItem(
                        '• Annulation par le garage', isSmallScreen),
                    _buildReasonItem(
                        '• Problème de disponibilité', isSmallScreen),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Contactez le garage pour plus d\'informations ou pour prendre un nouveau rendez-vous.',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonItem(String text, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
      ),
    );
  }

  Widget _buildAppointmentHeader(bool isSmallScreen) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 0),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today,
                    color: Colors.blue[700], size: isSmallScreen ? 18 : 20),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    'Rendez-vous #${_currentAppointment!.id!.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Service: ${_currentAppointment!.service}',
              style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
            ),
            if (_currentAppointment!.vehicle != null) ...[
              const SizedBox(height: 4),
              Text(
                'Véhicule: ${_currentAppointment!.vehicle}',
                style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 12,
                vertical: isSmallScreen ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getStatusText().toUpperCase(),
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
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

  Widget _buildTimeline(bool isSmallScreen) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 0),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progression du rendez-vous',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCompleted = index <= _currentStep;
              final isCurrent = index == _currentStep;

              return _buildTimelineStep(
                  step, isCompleted, isCurrent, index, isSmallScreen);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(AppointmentStep step, bool isCompleted,
      bool isCurrent, int index, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: isSmallScreen ? 28 : 32,
                height: isSmallScreen ? 28 : 32,
                decoration: BoxDecoration(
                  color: isCompleted ? step.color : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? step.icon : Icons.access_time,
                  color: isCompleted ? Colors.white : Colors.grey,
                  size: isSmallScreen ? 14 : 16,
                ),
              ),
              if (index < _steps.length - 1) ...[
                Container(
                  width: 2,
                  height: isSmallScreen ? 35 : 40,
                  color: isCompleted ? step.color : Colors.grey[300],
                ),
              ],
            ],
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
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
                          fontSize: isSmallScreen ? 14 : 16,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: step.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'En cours',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 9 : 10,
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
                    fontSize: isSmallScreen ? 12 : 14,
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
                      fontSize: isSmallScreen ? 11 : 12,
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

  Widget _buildAppointmentDetails(bool isSmallScreen) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 0),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails du rendez-vous',
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.person, 'Client',
                _currentAppointment!.clientName, isSmallScreen),
            _buildDetailRow(Icons.phone, 'Téléphone',
                _currentAppointment!.clientPhone, isSmallScreen),
            _buildDetailRow(Icons.email, 'Email',
                _currentAppointment!.clientEmail, isSmallScreen),
            _buildDetailRow(Icons.build, 'Service',
                _currentAppointment!.service, isSmallScreen),
            if (_currentAppointment!.vehicle != null)
              _buildDetailRow(Icons.directions_car, 'Véhicule',
                  _currentAppointment!.vehicle!, isSmallScreen),
            if (_currentAppointment!.assignedTechnicianName != null)
              _buildDetailRow(Icons.engineering, 'Technicien',
                  _currentAppointment!.assignedTechnicianName!, isSmallScreen),
            _buildDetailRow(Icons.calendar_today, 'Date et heure',
                _getFormattedDate(), isSmallScreen),
            if (_currentAppointment!.notes != null &&
                _currentAppointment!.notes!.isNotEmpty)
              _buildDetailRow(Icons.note, 'Notes', _currentAppointment!.notes!,
                  isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isSmallScreen ? 16 : 18, color: Colors.blue[700]),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
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

  Widget _buildQuickContact(bool isSmallScreen) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 0),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Row(
          children: [
            Icon(Icons.support_agent,
                size: isSmallScreen ? 20 : 24, color: Colors.green[700]),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Besoin d\'aide ?',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
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
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            ElevatedButton.icon(
              onPressed: _openChat,
              icon: Icon(Icons.chat, size: isSmallScreen ? 16 : 18),
              label: Text('Chat',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 12,
                ),
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
        return '1-24 heures';
      case 1:
        return 'Immédiat';
      case 2:
        return '30-60 minutes';
      case 3:
        return '1-2 heures';
      case 4:
        return '2-8 heures';
      case 5:
        return '30-60 minutes';
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
