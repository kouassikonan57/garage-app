import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/appointment_service.dart';
import '../services/simple_auth_service.dart';
import '../services/service_provider.dart'; // AJOUT
import '../models/user_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key}); // SUPPRIMER le paramètre requis

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late AppointmentService _appointmentService; // MODIFIÉ: late
  Map<String, int> _stats = {};
  Map<String, int> _serviceStats = {};
  List<Map<String, dynamic>> _recentAppointments = [];
  bool _isLoading = true;
  bool _checkingAccess = true;
  bool _isGarage = false;
  String _selectedPeriod = 'month';

  // Liste des périodes disponibles
  final List<String> _periods = ['today', 'week', 'month', 'year', 'all'];

  final Map<String, String> _periodLabels = {
    'today': 'Aujourd\'hui',
    'week': 'Cette semaine',
    'month': 'Ce mois',
    'year': 'Cette année',
    'all': 'Tout le temps',
  };

  @override
  void initState() {
    super.initState();
    _appointmentService = ServiceProvider().appointmentService; // MODIFIÉ
    _checkGarageAccess();
  }

  Future<void> _checkGarageAccess() async {
    try {
      print('🔐 Vérification des accès garage pour rapports...');

      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);
      final currentUser = await authService.getCurrentAppUser();

      if (currentUser != null && currentUser.userType == UserType.garage) {
        print('✅ Accès garage autorisé pour les rapports');
        setState(() {
          _isGarage = true;
          _checkingAccess = false;
        });
        _loadReports();
      } else {
        print('❌ Accès garage refusé pour les rapports');
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
      print('❌ Erreur vérification accès rapports: $e');
      setState(() {
        _checkingAccess = false;
        _isGarage = false;
      });
    }
  }

  void _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appointments = await _appointmentService.getAllAppointments();

      // Filtrer les rendez-vous selon la période sélectionnée
      final filteredAppointments = _filterAppointmentsByPeriod(appointments);

      // Statistiques générales basées sur les rendez-vous filtrés
      final stats = _calculateStats(filteredAppointments);

      // Statistiques par service basées sur les rendez-vous filtrés
      final serviceStats = <String, int>{};
      for (final appointment in filteredAppointments) {
        serviceStats[appointment.service] =
            (serviceStats[appointment.service] ?? 0) + 1;
      }

      // Rendez-vous récents (5 derniers) parmi les filtrés
      final recentAppointments =
          filteredAppointments.take(5).map((appointment) {
        return {
          'client': appointment.clientName,
          'service': appointment.service,
          'date': appointment.formattedDateTime,
          'status': appointment.status,
          'amount': _estimateServiceAmount(appointment.service),
        };
      }).toList();

      setState(() {
        _stats = stats;
        _serviceStats = serviceStats;
        _recentAppointments = recentAppointments;
        _isLoading = false;
      });

      print(
          '📊 Rapports chargés pour $_selectedPeriod: ${_stats['total']} RDV, ${_serviceStats.length} services');
    } catch (e) {
      print('❌ Erreur chargement rapports: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthode pour filtrer les rendez-vous par période
  List<dynamic> _filterAppointmentsByPeriod(List<dynamic> appointments) {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 'today':
        final today = DateTime(now.year, now.month, now.day);
        return appointments.where((appointment) {
          final appointmentDate = appointment.dateTime;
          return appointmentDate
              .isAfter(today.subtract(const Duration(seconds: 1)));
        }).toList();

      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return appointments.where((appointment) {
          final appointmentDate = appointment.dateTime;
          return appointmentDate.isAfter(weekAgo);
        }).toList();

      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return appointments.where((appointment) {
          final appointmentDate = appointment.dateTime;
          return appointmentDate.isAfter(monthAgo);
        }).toList();

      case 'year':
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        return appointments.where((appointment) {
          final appointmentDate = appointment.dateTime;
          return appointmentDate.isAfter(yearAgo);
        }).toList();

      case 'all':
      default:
        return appointments;
    }
  }

  // Méthode pour calculer les stats depuis la liste filtrée
  Map<String, int> _calculateStats(List<dynamic> appointments) {
    final now = DateTime.now();

    return {
      'total': appointments.length,
      'upcoming': appointments
          .where((a) => a.status != 'cancelled' && a.dateTime.isAfter(now))
          .length,
      'pending': appointments.where((a) => a.status == 'pending').length,
      'confirmed': appointments.where((a) => a.status == 'confirmed').length,
      'cancelled': appointments.where((a) => a.status == 'cancelled').length,
    };
  }

  // Méthode pour changer la période
  void _changePeriod(String newPeriod) {
    setState(() {
      _selectedPeriod = newPeriod;
    });
    _loadReports();
  }

  // Estimation du montant basée sur le service (à remplacer par vos prix réels)
  double _estimateServiceAmount(String service) {
    final prices = {
      'Vidange': 25000.0,
      'Révision complète': 75000.0,
      'Changement pneus': 50000.0,
      'Freinage': 60000.0,
      'Diagnostic': 15000.0,
      'Climatisation': 45000.0,
      'Carrosserie': 120000.0,
      'Mécanique générale': 80000.0,
    };
    return prices[service] ?? 30000.0;
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} FCFA';
  }

  // Calcul du revenu total basé sur les services réels
  double get _totalRevenue {
    double total = 0;
    for (final entry in _serviceStats.entries) {
      total += _estimateServiceAmount(entry.key) * entry.value;
    }
    return total;
  }

  // Taux de conversion (RDV confirmés / total)
  double get _conversionRate {
    final total = _stats['total'] ?? 1;
    final confirmed = _stats['confirmed'] ?? 0;
    return total > 0 ? (confirmed / total) * 100 : 0;
  }

  // Revenu moyen par RDV
  double get _averageRevenue {
    final total = _stats['total'] ?? 1;
    return total > 0 ? _totalRevenue / total : 0;
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
        title: const Text('Rapports et Statistiques'),
        backgroundColor: Colors.orange,
        actions: [
          // Sélecteur de période dans l'AppBar
          PopupMenuButton<String>(
            onSelected: _changePeriod,
            itemBuilder: (BuildContext context) {
              return _periods.map((String period) {
                return PopupMenuItem<String>(
                  value: period,
                  child: Row(
                    children: [
                      Icon(
                        _getPeriodIcon(period),
                        color: _selectedPeriod == period
                            ? Colors.orange
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _periodLabels[period] ?? period,
                          style: TextStyle(
                            fontWeight: _selectedPeriod == period
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _selectedPeriod == period
                                ? Colors.orange
                                : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
            icon: const Icon(Icons.date_range),
            tooltip: 'Changer la période',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Actualiser les données',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des rapports...'),
                ],
              ),
            )
          : _buildReportsContent(),
    );
  }

  Widget _buildReportsContent() {
    final totalAppointments = _stats['total'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec indicateur de période
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tableau de Bord Garage',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  _periodLabels[_selectedPeriod] ?? _selectedPeriod,
                  overflow: TextOverflow.ellipsis,
                ),
                backgroundColor: Colors.orange.withOpacity(0.1),
                labelStyle: const TextStyle(color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Basé sur ${totalAppointments} rendez-vous (${_periodLabels[_selectedPeriod]?.toLowerCase() ?? _selectedPeriod})',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 24),

          // Cartes de statistiques principales
          if (totalAppointments > 0) ...[
            _buildMainStatsSection(),
            const SizedBox(height: 24),
          ],

          // Services les plus demandés
          if (_serviceStats.isNotEmpty) ...[
            _buildServicesSection(),
            const SizedBox(height: 24),
          ],

          // Activité récente
          if (_recentAppointments.isNotEmpty) ...[
            _buildRecentActivitySection(),
            const SizedBox(height: 24),
          ],

          // Performance globale
          if (totalAppointments > 0) ...[
            _buildPerformanceSection(),
            const SizedBox(height: 24),
          ],

          // État vide si pas de données
          if (totalAppointments == 0) ...[
            _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildMainStatsSection() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Total RDV',
          _stats['total']?.toString() ?? '0',
          Icons.calendar_today,
          Colors.blue,
          _periodLabels[_selectedPeriod] ?? '',
        ),
        _buildStatCard(
          'À venir',
          _stats['upcoming']?.toString() ?? '0',
          Icons.upcoming,
          Colors.green,
          'Prochains RDV',
        ),
        _buildStatCard(
          'En attente',
          _stats['pending']?.toString() ?? '0',
          Icons.pending_actions,
          Colors.orange,
          'En attente',
        ),
        _buildStatCard(
          'Confirmés',
          _stats['confirmed']?.toString() ?? '0',
          Icons.check_circle,
          Colors.green,
          'RDV confirmés',
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    final totalAppointments = _stats['total'] ?? 1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.build_circle, color: Colors.blue),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Services les plus Demandés',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._serviceStats.entries.map((entry) {
              final percentage = (entry.value / totalAppointments * 100);
              final revenue = _estimateServiceAmount(entry.key) * entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: LinearProgressIndicator(
                            value: entry.value / totalAppointments,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _getServiceColor(entry.key)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${entry.value} RDV',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _formatCurrency(revenue),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.access_time, color: Colors.purple),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Activité Récente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._recentAppointments.map((appointment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointment['status'])
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: _getStatusColor(appointment['status']),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment['client'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            appointment['service'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            appointment['date'],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(appointment['status'])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(appointment['status']),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusColor(appointment['status']),
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(appointment['amount']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assessment, color: Colors.orange),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Performance Globale',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildPerformanceCard(
                  'Taux de Conversion',
                  '${_conversionRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  _conversionRate >= 70 ? Colors.green : Colors.orange,
                ),
                _buildPerformanceCard(
                  'Revenu Total',
                  _formatCurrency(_totalRevenue),
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildPerformanceCard(
                  'Revenu Moyen',
                  _formatCurrency(_averageRevenue),
                  Icons.bar_chart,
                  Colors.blue,
                ),
                _buildPerformanceCard(
                  'RDV Actifs',
                  '${_stats['upcoming'] ?? 0}',
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Aucune donnée disponible pour cette période',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Les rapports apparaîtront ici après la création de rendez-vous',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getServiceColor(String service) {
    final colors = {
      'Vidange': Colors.blue,
      'Révision complète': Colors.green,
      'Changement pneus': Colors.orange,
      'Freinage': Colors.red,
      'Diagnostic': Colors.purple,
      'Climatisation': Colors.cyan,
      'Carrosserie': Colors.brown,
      'Mécanique générale': Colors.indigo,
    };
    return colors[service] ?? Colors.grey;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmé';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  IconData _getPeriodIcon(String period) {
    switch (period) {
      case 'today':
        return Icons.today;
      case 'week':
        return Icons.calendar_view_week;
      case 'month':
        return Icons.calendar_view_month;
      case 'year':
        return Icons.calendar_today;
      case 'all':
        return Icons.all_inclusive;
      default:
        return Icons.date_range;
    }
  }
}
