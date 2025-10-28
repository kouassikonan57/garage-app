import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/service_provider.dart';
import '../services/simple_auth_service.dart';
import '../models/user_model.dart';

// AJOUT: Imports pour les écrans de destination
import 'garage_management_screen.dart';
import 'advanced_calendar.dart';
import 'enriched_clients_screen.dart';
import 'reports_screen.dart';

class GarageDashboard extends StatefulWidget {
  const GarageDashboard({super.key});

  @override
  State<GarageDashboard> createState() => _GarageDashboardState();
}

class _GarageDashboardState extends State<GarageDashboard> {
  // AJOUT: Import manquant pour AppointmentService
  late final dynamic _appointmentService;
  Map<String, int> _stats = {};
  bool _checkingAccess = true;
  bool _isGarage = false;
  bool _loadingStats = false;

  @override
  void initState() {
    super.initState();
    // CORRECTION: Initialiser via ServiceProvider
    _appointmentService = ServiceProvider().appointmentService;
    _checkGarageAccess();
  }

  Future<void> _checkGarageAccess() async {
    try {
      print('🔐 Vérification des accès garage...');

      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);
      final currentUser = await authService.getCurrentAppUser();

      if (currentUser != null && currentUser.userType == UserType.garage) {
        print('✅ Accès garage autorisé');
        setState(() {
          _isGarage = true;
          _checkingAccess = false;
        });
        await _loadStats(); // AJOUT: await ici
      } else {
        print(
            '❌ Accès garage refusé - Type utilisateur: ${currentUser?.userType}');
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
      print('❌ Erreur vérification accès: $e');
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

  // CORRECTION: Ajout de async/await
  Future<void> _loadStats() async {
    setState(() {
      _loadingStats = true;
    });

    try {
      final stats =
          await _appointmentService.getAppointmentStats(); // AJOUT: await
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    } catch (e) {
      print('❌ Erreur chargement stats: $e');
      setState(() {
        _loadingStats = false;
      });
    }
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
              SizedBox(height: 10),
              Text(
                'Retour à l\'accueil...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Garage'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // En-tête Garage
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.build, size: 40, color: Colors.blue),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Espace Professionnel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              'Gestion complète de votre garage',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Cartes de statistiques
              _loadingStats
                  ? const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            _buildStatCard('Total', _stats['total'] ?? 0,
                                Colors.blue, Icons.calendar_today),
                            const SizedBox(width: 12),
                            _buildStatCard('À venir', _stats['upcoming'] ?? 0,
                                Colors.green, Icons.upcoming),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatCard('En attente', _stats['pending'] ?? 0,
                                Colors.orange, Icons.pending),
                            const SizedBox(width: 12),
                            _buildStatCard(
                                'Confirmés',
                                _stats['confirmed'] ?? 0,
                                Colors.green,
                                Icons.check_circle),
                          ],
                        ),
                      ],
                    ),

              const SizedBox(height: 24),

              // Actions rapides
              const Text(
                'Actions Rapides',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // CORRECTION: Redirection vers GarageManagementScreen
                  _buildActionButton(
                      'Voir tous les RDV', Icons.list, Colors.blue, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GarageManagementScreen(),
                      ),
                    );
                  }),

                  // CORRECTION: Redirection vers AdvancedCalendar
                  _buildActionButton(
                      'Disponibilités', Icons.schedule, Colors.green, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdvancedCalendar(),
                      ),
                    );
                  }),

                  // CORRECTION: Redirection vers EnrichedClientsScreen
                  _buildActionButton('Clients', Icons.people, Colors.purple,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EnrichedClientsScreen(),
                      ),
                    );
                  }),

                  // CORRECTION: Redirection vers ReportsScreen
                  _buildActionButton('Rapports', Icons.analytics, Colors.orange,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportsScreen(),
                      ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 24),

              // Informations du jour
              Card(
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Aujourd'hui",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<int>(
                        future: _getTodayAppointmentsCount(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            );
                          }

                          final todayCount = snapshot.data ?? 0;

                          if (todayCount > 0) {
                            return Column(
                              children: [
                                Text(
                                  '$todayCount rendez-vous aujourd\'hui',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Consultez la gestion pour voir les détails',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                Text(
                                  '$todayCount rendez-vous aujourd\'hui',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Aucun rendez-vous prévu aujourd\'hui',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 3,
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 110,
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(height: 8),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<int> _getTodayAppointmentsCount() async {
    try {
      final allAppointments = await _appointmentService.getAllAppointments();
      final now = DateTime.now();
      return allAppointments
          .where((appointment) =>
              appointment.dateTime.year == now.year &&
              appointment.dateTime.month == now.month &&
              appointment.dateTime.day == now.day)
          .length;
    } catch (e) {
      print('❌ Erreur comptage RDV aujourd\'hui: $e');
      return 0;
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
