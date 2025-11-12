import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'book_appointment_screen.dart';
import 'garage_management_screen.dart';
import 'client_appointments_screen.dart';
import 'garage_dashboard.dart';
import 'reports_screen.dart';
import 'client_history_screen.dart';
import 'suppliers_management.dart';
import 'advanced_calendar.dart';
import 'enriched_clients_screen.dart';
import 'inventory_management.dart';
import 'client_profile_screen.dart';
import '../services/firebase_client_service.dart';
import '../services/simple_auth_service.dart';
import '../services/appointment_service.dart';
import '../services/service_provider.dart';
import 'technicians_management.dart';
import 'appointment_tracker.dart';
import 'appointment_photos.dart';
import 'in_app_chat.dart';
import '../models/appointment_model.dart';
import 'garage_chat_screen.dart';
import 'dart:async'; // Pour Timer

class HomeScreen extends StatelessWidget {
  final bool isClient;
  final String userName;
  final String userEmail;

  const HomeScreen({
    super.key,
    required this.isClient,
    required this.userName,
    required this.userEmail,
  });

  AppointmentService _getAppointmentService() {
    return ServiceProvider().appointmentService;
  }

  @override
  Widget build(BuildContext context) {
    if (isClient) {
      _checkProfileCompletion(context);
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isClient ? 'Espace Client' : 'Espace Garage'),
        backgroundColor: isClient ? Colors.orange : Colors.blue,
        elevation: 0,
        actions: [
          // Bouton de déconnexion dans l'AppBar
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Déconnexion', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        // AJOUT: Centrer
        child: Container(
          // AJOUT: Container avec largeur max
          constraints: const BoxConstraints(maxWidth: 1200.0),
          child: isClient
              ? _buildClientInterface(context)
              : _buildGarageInterface(context),
        ),
      ),
    );
  }

  // ========== INTERFACE CLIENT ==========
  Widget _buildClientInterface(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // En-tête personnalisé
          _buildCustomHeader(context),

          // Fil d'actualités avec images - MAINTENANT CONDITIONNEL
          _buildConditionalNewsFeed(),

          // Services principaux
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Services Rapides'),
                  const SizedBox(height: 16),

                  // Grille de services
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _buildServiceGridCard(
                        'Prendre RDV',
                        Icons.calendar_today,
                        Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookAppointmentScreen(
                                clientName: userName,
                                clientEmail: userEmail,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildServiceGridCard(
                        'Mes RDV',
                        Icons.list_alt,
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClientAppointmentsScreen(
                                clientEmail: userEmail,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildServiceGridCard(
                        'Suivi',
                        Icons.track_changes,
                        Colors.teal,
                        () {
                          _navigateToAppointmentTracker(context);
                        },
                      ),
                      _buildServiceGridCard(
                        'Chat',
                        Icons.chat,
                        Colors.indigo,
                        () {
                          _navigateToInAppChat(context);
                        },
                      ),
                      _buildServiceGridCard(
                        'Historique',
                        Icons.history,
                        Colors.purple,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClientHistoryScreen(
                                clientEmail: userEmail,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildServiceGridCard(
                        'Mon Profil',
                        Icons.person,
                        Colors.orange,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClientProfileScreen(
                                clientEmail: userEmail,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Outils'),

                  _buildToolCard(
                    'Photos des travaux',
                    Icons.photo_library,
                    'Consultez les photos de vos véhicules',
                    Colors.pink,
                    () {
                      _navigateToAppointmentPhotos(context);
                    },
                  ),

                  _buildToolCard(
                    'Rappels',
                    Icons.notifications_active,
                    'Configurez vos préférences',
                    Colors.amber,
                    () {
                      _showAdvancedReminders(context);
                    },
                  ),

                  // Bouton de déconnexion en bas
                  const SizedBox(height: 24),
                  _buildLogoutButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== INTERFACE GARAGE ==========
  Widget _buildGarageInterface(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // En-tête personnalisé
          _buildCustomHeader(context),

          // Fil d'actualités avec images - MAINTENANT CONDITIONNEL
          _buildConditionalNewsFeed(),

          // Statistiques réelles
          _buildRealStats(context),

          // Services principaux
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Gestion Garage'),
                  const SizedBox(height: 16),

                  // Première ligne
                  Row(
                    children: [
                      Expanded(
                        child: _buildServiceGridCard(
                          'Calendrier',
                          Icons.calendar_month,
                          Colors.green,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdvancedCalendar(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildServiceGridCard(
                          'RDV',
                          Icons.schedule,
                          Colors.orange,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GarageManagementScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Deuxième ligne
                  Row(
                    children: [
                      Expanded(
                        child: _buildServiceGridCard(
                          'Clients',
                          Icons.people,
                          Colors.purple,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const EnrichedClientsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildServiceGridCard(
                          'Messagerie',
                          Icons.chat,
                          Colors.indigo,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GarageChatScreen(
                                  garageId: 'garage_principal',
                                  garageEmail: userEmail,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Atelier & Stocks'),

                  _buildToolCard(
                    'Inventaire',
                    Icons.inventory_2,
                    'Gérez vos pièces et stocks',
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InventoryManagement(),
                        ),
                      );
                    },
                  ),

                  _buildToolCard(
                    'Techniciens',
                    Icons.engineering,
                    'Gérez votre équipe',
                    Colors.teal,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TechniciansManagement(),
                        ),
                      );
                    },
                  ),

                  _buildToolCard(
                    'Fournisseurs',
                    Icons.business,
                    'Gérez vos partenaires',
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SuppliersManagement(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Analyses'),

                  _buildToolCard(
                    'Tableau de bord',
                    Icons.dashboard,
                    'Vue d\'ensemble de votre activité',
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GarageDashboard(),
                        ),
                      );
                    },
                  ),

                  _buildToolCard(
                    'Rapports',
                    Icons.analytics,
                    'Statistiques et analyses',
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportsScreen(),
                        ),
                      );
                    },
                  ),

                  // Bouton de déconnexion en bas
                  const SizedBox(height: 24),
                  _buildLogoutButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== COMPOSANTS COMMUNS ==========
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isClient
              ? [Colors.orange.shade500, Colors.orange.shade700]
              : [Colors.blue.shade500, Colors.blue.shade700],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour,',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userName.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isClient
                ? 'Bienvenue dans votre espace auto'
                : 'Gérez votre garage en toute simplicité',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // NOUVELLE MÉTHODE : Fil d'actualités conditionnel
  Widget _buildConditionalNewsFeed() {
    // Pour tester sans actualités, remplacez par une liste vide :
    // final newsItems = [];

    final newsItems = <Map<String,
        String>>[]; // S'il doit avoir des actualité supprime ou commente cette ligne et active la ligne suivante
    // final newsItems = [
    //   {
    //     'title': '🔧 Nouveau Service Express',
    //     'subtitle': 'Révision complète en 45 minutes seulement !',
    //     'image':
    //         'https://images.unsplash.com/photo-1507136566006-cfc505b114fc?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
    //   },
    //   {
    //     'title': '🎉 Promotion Spéciale Été',
    //     'subtitle': '20% de réduction sur la vidange jusqu\'au 30 décembre',
    //     'image':
    //         'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
    //   },
    //   {
    //     'title': '🚗 Maintenance Programmé',
    //     'subtitle': 'Fermeture exceptionnelle le 25 décembre',
    //     'image':
    //         'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
    //   },
    //   {
    //     'title': '📱 Mise à Jour Application',
    //     'subtitle': 'Nouvelle fonctionnalité : Suivi en temps réel',
    //     'image':
    //         'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
    //   },
    //   {
    //     'title': '🏆 Garage de l\'Année',
    //     'subtitle': 'Nous sommes nominés pour le prix d\'excellence 2024',
    //     'image':
    //         'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?ixlib=rb-4.0.3&w=600&h=300&fit=crop',
    //   },
    // ];

    // SI PAS D'ACTUALITÉS, RETOURNE UN WIDGET VIDE
    if (newsItems.isEmpty) {
      return const SizedBox.shrink(); // Disparaît complètement
    }

    // SINON, AFFICHE LE FIL D'ACTUALITÉS NORMAL
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
            child: Text(
              'Actualités',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: NewsCarousel(newsItems: newsItems),
          ),
        ],
      ),
    );
  }

  // Statistiques RÉELLES pour le garage - CORRIGÉ
  Widget _buildRealStats(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _getRealStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final stats =
            snapshot.data ?? {'today': 0, 'pending': 0, 'in_progress': 0};

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  stats['today'].toString(), 'RDV Aujourd\'hui', Colors.blue),
              _buildStatItem(
                  stats['pending'].toString(), 'En attente', Colors.orange),
              _buildStatItem(
                  stats['in_progress'].toString(), 'En cours', Colors.green),
            ],
          ),
        );
      },
    );
  }

  // Récupérer les statistiques RÉELLES - CORRIGÉ
  Future<Map<String, int>> _getRealStats() async {
    try {
      final appointmentService = _getAppointmentService();
      final allAppointments = await appointmentService.getAllAppointments();

      final today = DateTime.now();
      final todayAppointments = allAppointments.where((appointment) {
        // CORRECTION : Utiliser dateTime comme dans votre modèle
        final appointmentDate = DateTime(
          appointment.dateTime.year,
          appointment.dateTime.month,
          appointment.dateTime.day,
        );
        final todayDate = DateTime(today.year, today.month, today.day);
        return appointmentDate == todayDate;
      }).length;

      final pendingAppointments = allAppointments
          .where((appointment) => appointment.status == 'pending')
          .length;

      final inProgressAppointments = allAppointments
          .where((appointment) => appointment.status == 'in_progress')
          .length;

      return {
        'today': todayAppointments,
        'pending': pendingAppointments,
        'in_progress': inProgressAppointments,
      };
    } catch (e) {
      print('❌ Erreur récupération statistiques: $e');
      return {'today': 0, 'pending': 0, 'in_progress': 0};
    }
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildServiceGridCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(String title, IconData icon, String subtitle,
      Color color, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_forward, color: color, size: 16),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
        child: ElevatedButton.icon(
          onPressed: () => _showLogoutDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Déconnexion'),
        ),
      ),
    );
  }

  // ========== MÉTHODES EXISTANTES (conservées) ==========
  void _showAdvancedReminders(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔔 Rappels Avancés'),
        content: const Text(
            'Configurez vos préférences de rappel pour ne rien oublier.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showReminderConfiguration(context);
            },
            child: const Text('Configurer'),
          ),
        ],
      ),
    );
  }

  void _showReminderConfiguration(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuration des Rappels'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choisissez vos préférences de rappel :'),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Rappel 24h avant'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Rappel 1h avant'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Notifications push'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Préférences de rappel sauvegardées')),
              );
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _navigateToAppointmentTracker(BuildContext context) async {
    try {
      final appointmentService = _getAppointmentService();
      final appointments =
          await appointmentService.getClientAppointments(userEmail);

      if (appointments.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Aucun rendez-vous'),
            content: const Text(
                'Vous n\'avez pas encore de rendez-vous à suivre. Prenez un rendez-vous d\'abord.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookAppointmentScreen(
                        clientName: userName,
                        clientEmail: userEmail,
                      ),
                    ),
                  );
                },
                child: const Text('Prendre RDV'),
              ),
            ],
          ),
        );
        return;
      }

      if (appointments.length == 1) {
        final appointment = appointments.first;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentTracker(
              appointmentId: appointment.id!,
              clientEmail: userEmail,
            ),
          ),
        );
      } else {
        _showAppointmentSelection(context, appointments);
      }
    } catch (e) {
      print('❌ Erreur récupération rendez-vous: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur lors du chargement des rendez-vous')),
      );
    }
  }

  void _showAppointmentSelection(
      BuildContext context, List<Appointment> appointments) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir un rendez-vous'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return MouseRegion(
                cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      _getAppointmentIcon(appointment.status),
                      color: _getStatusColor(appointment.status),
                    ),
                    title: Text(appointment.service),
                    subtitle: Text(
                        '${appointment.formattedDate} à ${appointment.formattedTime}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointment.status)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(appointment.status),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(appointment.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentTracker(
                            appointmentId: appointment.id!,
                            clientEmail: userEmail,
                          ),
                        ),
                      );
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
  }

  IconData _getAppointmentIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      case 'rejected':
        return Icons.block;
      case 'pending':
      default:
        return Icons.access_time;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
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
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
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
      default:
        return 'en attente';
    }
  }

  void _navigateToAppointmentPhotos(BuildContext context) async {
    try {
      final appointmentService = _getAppointmentService();
      final appointments =
          await appointmentService.getClientAppointments(userEmail);

      if (appointments.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Aucun rendez-vous'),
            content: const Text(
                'Vous n\'avez pas encore de rendez-vous avec des photos.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final latestAppointment = appointments.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AppointmentPhotos(appointmentId: latestAppointment.id!),
        ),
      );
    } catch (e) {
      print('❌ Erreur récupération rendez-vous pour photos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur lors du chargement des rendez-vous')),
      );
    }
  }

  void _navigateToInAppChat(BuildContext context) async {
    try {
      final appointmentService = _getAppointmentService();
      final appointments =
          await appointmentService.getClientAppointments(userEmail);

      if (appointments.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Aucun rendez-vous'),
            content: const Text(
                'Vous devez avoir un rendez-vous pour chatter avec le garage.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookAppointmentScreen(
                        clientName: userName,
                        clientEmail: userEmail,
                      ),
                    ),
                  );
                },
                child: const Text('Prendre RDV'),
              ),
            ],
          ),
        );
        return;
      }

      final latestAppointment = appointments.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InAppChat(
            garageId: latestAppointment.garageId,
            appointmentId: latestAppointment.id!,
            clientEmail: userEmail,
            clientName: userName,
          ),
        ),
      );
    } catch (e) {
      print('❌ Erreur récupération rendez-vous pour chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur lors du chargement des rendez-vous')),
      );
    }
  }

  void _checkProfileCompletion(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        print('🔍 Vérification profil pour: $userEmail');
        final clientService =
            Provider.of<FirebaseClientService>(context, listen: false);
        final client = await clientService.getClientByEmail(userEmail);

        if (client == null) {
          print('❌ Profil non trouvé dans Firestore pour: $userEmail');
          await Future.delayed(const Duration(seconds: 1));

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.person, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Complétez votre profil pour une meilleure expérience !',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 6),
                action: SnackBarAction(
                  label: 'Compléter',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ClientProfileScreen(clientEmail: userEmail),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        } else {
          print('✅ Profil trouvé dans Firestore: ${client.name}');
          if (client.phone == '+225 00 00 00 00' ||
              client.address == 'Adresse non spécifiée' ||
              client.vehicles.isEmpty) {
            print('⚠️ Profil incomplet détecté');
            await Future.delayed(const Duration(seconds: 1));

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.person, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Complétez votre profil pour une meilleure expérience !',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 6),
                  action: SnackBarAction(
                    label: 'Compléter',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ClientProfileScreen(clientEmail: userEmail),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          }
        }
      } catch (e) {
        print('❌ Erreur lors de la vérification du profil: $e');
      }
    });
  }

  void _showLogoutDialog(BuildContext context) {
    final authService = Provider.of<SimpleAuthService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );
                await authService.logout();
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Déconnexion réussie'),
                        backgroundColor: Colors.green),
                  );
                }
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false);
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Erreur de déconnexion: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Classe séparée pour le carousel d'actualités
class NewsCarousel extends StatefulWidget {
  final List<Map<String, String>> newsItems;

  const NewsCarousel({super.key, required this.newsItems});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        if (_currentPage < widget.newsItems.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onDotTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Carousel d'images
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            onPageChanged: _onPageChanged,
            itemCount: widget.newsItems.length,
            itemBuilder: (context, index) {
              final news = widget.newsItems[index];
              return MouseRegion(
                cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Image de fond
                        Image.network(
                          news['image']!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Image non disponible',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Overlay gradient pour meilleure lisibilité
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),

                        // Contenu texte
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                news['title']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                news['subtitle']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Points de pagination
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.newsItems.length, (index) {
            return MouseRegion(
              cursor: SystemMouseCursors.click, // CURSEUR MAIN AJOUTÉ
              child: GestureDetector(
                onTap: () => _onDotTapped(index),
                child: Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.orange.shade600
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}