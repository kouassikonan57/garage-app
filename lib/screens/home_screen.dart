import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'book_appointment_screen.dart';
import 'garage_management_screen.dart';
import 'client_appointments_screen.dart';
import 'settings_screen.dart';
import 'garage_dashboard.dart';
import 'reports_screen.dart';
import 'client_history_screen.dart';
import 'suppliers_management.dart';
import 'advanced_calendar.dart';
import 'enriched_clients_screen.dart';
import 'inventory_management.dart';
import 'loyalty_program_screen.dart';
import 'client_profile_screen.dart';
import '../services/firebase_client_service.dart';
import '../services/simple_auth_service.dart';
import '../services/appointment_service.dart';
import 'technicians_management.dart';
// NOUVEAUX IMPORTS
import 'appointment_tracker.dart';
import 'appointment_photos.dart';
import 'in_app_chat.dart';
import '../models/appointment_model.dart';
import 'garage_chat_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    // AJOUT : Vérifier si le profil est complet (uniquement pour les clients)
    if (isClient) {
      _checkProfileCompletion(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isClient ? 'Espace Client' : 'Espace Garage'),
        backgroundColor: isClient ? Colors.orange : Colors.blue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message de bienvenue
              Text(
                'Bonjour, ${userName.toUpperCase()}!',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isClient
                    ? 'Que souhaitez-vous faire aujourd\'hui ?'
                    : 'Gérez votre garage facilement',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // FONCTIONNALITÉS SPÉCIFIQUES GESTION DE RDV
              if (isClient) ...[
                // ========== COTÉ CLIENT ==========
                const Text(
                  '📋 Gestion de vos Rendez-vous',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),

                // 1. SYSTÈME DE RAPPELS AVANCÉ
                _buildServiceCard(
                  'Rappels Avancés',
                  Icons.notifications_active,
                  Colors.orange,
                  'Configurez vos rappels personnalisés',
                  onTap: () {
                    _showAdvancedReminders(context);
                  },
                ),

                // 2. SUIVI EN TEMPS RÉEL
                _buildServiceCard(
                  'Suivi en Temps Réel',
                  Icons.track_changes,
                  Colors.teal,
                  'Suivez l\'avancement de vos RDV',
                  onTap: () {
                    _navigateToAppointmentTracker(context);
                  },
                ),

                // 3. PHOTOS ET PREUVES
                _buildServiceCard(
                  'Photos et Preuves',
                  Icons.photo_library,
                  Colors.pink,
                  'Consultez les photos de vos véhicules',
                  onTap: () {
                    _navigateToAppointmentPhotos(context);
                  },
                ),

                // 4. CHAT AVEC LE GARAGE
                _buildServiceCard(
                  'Chat avec le Garage',
                  Icons.chat,
                  Colors.indigo,
                  'Communiquez en direct avec votre garage',
                  onTap: () {
                    _navigateToInAppChat(context);
                  },
                ),

                const SizedBox(height: 16),

                // SERVICES CLIENT STANDARD
                _buildServiceCard(
                  'Prendre un rendez-vous',
                  Icons.calendar_today,
                  Colors.green,
                  'Réservez votre intervention',
                  onTap: () {
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
                _buildServiceCard(
                  'Mes rendez-vous',
                  Icons.list_alt,
                  Colors.blue,
                  'Consultez vos réservations',
                  onTap: () {
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
                _buildServiceCard(
                  'Historique',
                  Icons.history,
                  Colors.purple,
                  'Vos interventions passées',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ClientHistoryScreen(clientEmail: userEmail),
                      ),
                    );
                  },
                ),
                _buildServiceCard(
                  'Mon Profil',
                  Icons.person,
                  Colors.purple,
                  'Complétez et modifiez vos informations',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ClientProfileScreen(clientEmail: userEmail),
                      ),
                    );
                  },
                ),
              ] else ...[
                // ========== COTÉ GARAGE ==========
                const Text(
                  '🔧 Gestion Garage - RDV',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),

                // SERVICES GARAGE STANDARD
                _buildServiceCard(
                  'Tableau de Bord',
                  Icons.dashboard,
                  Colors.blue,
                  'Vue d\'ensemble de votre activité',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GarageDashboard()),
                    );
                  },
                ),
                _buildServiceCard(
                  'Gérer les rendez-vous',
                  Icons.schedule,
                  Colors.orange,
                  'Visualisez et gérez tous les RDV',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GarageManagementScreen()),
                    );
                  },
                ),
                _buildServiceCard(
                  'Profils Clients',
                  Icons.people,
                  Colors.purple,
                  'Détails complets des clients',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EnrichedClientsScreen()),
                    );
                  },
                ),

                // 1. CALENDRIER AVANCÉ
                _buildServiceCard(
                  'Calendrier Avancé',
                  Icons.calendar_month,
                  Colors.green,
                  'Vue complète des rendez-vous',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AdvancedCalendar()),
                    );
                  },
                ),

                // 2. CHAT INTÉGRÉ CLIENT-GARAGE
                _buildServiceCard(
                  'Messagerie Clients',
                  Icons.chat,
                  Colors.indigo,
                  'Communiquez avec vos clients en direct',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GarageChatScreen(
                          garageId:
                              'garage_principal', // À adapter selon votre logique
                          garageEmail: userEmail,
                        ),
                      ),
                    );
                  },
                ),

                // 3. GESTION DES RAPPELS
                _buildServiceCard(
                  'Gestion des Rappels',
                  Icons.notifications,
                  Colors.orange,
                  'Envoyez des rappels aux clients',
                  onTap: () {
                    _manageClientReminders(context);
                  },
                ),

                const SizedBox(height: 16),

                _buildServiceCard(
                  'Rapports',
                  Icons.analytics,
                  Colors.orange,
                  'Statistiques et analyses',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReportsScreen()),
                    );
                  },
                ),
                _buildServiceCard(
                  'Fournisseurs',
                  Icons.business,
                  Colors.purple,
                  'Gérez vos partenaires',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SuppliersManagement()),
                    );
                  },
                ),
                _buildServiceCard(
                  'Inventaire & Stocks',
                  Icons.inventory_2,
                  Colors.blue,
                  'Gérez vos pièces et stocks',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => InventoryManagement()),
                    );
                  },
                ),
                _buildServiceCard(
                  'Programme Fidélité',
                  Icons.loyalty,
                  Colors.orange,
                  'Fidélisez vos clients',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LoyaltyProgramScreen()),
                    );
                  },
                ),
                _buildServiceCard(
                  'Gestion Techniciens',
                  Icons.engineering,
                  Colors.teal,
                  'Gérez votre équipe technique',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TechniciansManagement(),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 20),

              // Section paramètres et déconnexion
              _buildServiceCard(
                'Paramètres',
                Icons.settings,
                Colors.grey,
                'Personnalisez votre application',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Bouton de déconnexion
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Déconnexion',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ========== MÉTHODES POUR LES FONCTIONNALITÉS RDV ==========

  // COTÉ CLIENT - Rappels Avancés
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

  // Configuration simplifiée des rappels
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

  // COTÉ CLIENT - Suivi en Temps Réel - CORRECTION COMPLÈTE
  void _navigateToAppointmentTracker(BuildContext context) async {
    try {
      // Récupérer les vrais rendez-vous du client depuis Firestore
      final appointmentService = AppointmentService();
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

      // Si un seul rendez-vous, aller directement au suivi
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
        // Si plusieurs rendez-vous, laisser l'utilisateur choisir
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

  // Afficher la sélection de rendez-vous
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
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    _getAppointmentIcon(appointment.status),
                    color: _getStatusColor(appointment.status),
                  ),
                  title: Text(appointment.service),
                  subtitle: Text(
                    '${appointment.formattedDate} à ${appointment.formattedTime}',
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(appointment.status).withOpacity(0.1),
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

  // Méthodes utilitaires pour les statuts
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

  // COTÉ CLIENT - Photos et Preuves
  void _navigateToAppointmentPhotos(BuildContext context) async {
    try {
      // Récupérer les vrais rendez-vous du client
      final appointmentService = AppointmentService();
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

      // Prendre le rendez-vous le plus récent
      final latestAppointment = appointments.first;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppointmentPhotos(
            appointmentId: latestAppointment.id!,
          ),
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

  // COTÉ CLIENT - Chat avec Garage
  void _navigateToInAppChat(BuildContext context) async {
    try {
      // Récupérer les vrais rendez-vous du client
      final appointmentService = AppointmentService();
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

      // Prendre le rendez-vous le plus récent
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

  // COTÉ GARAGE - Gestion des Rappels
  void _manageClientReminders(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📢 Gestion des Rappels'),
        content: const Text(
            'Envoyez des rappels à vos clients pour leurs rendez-vous à venir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rappels envoyés aux clients')),
              );
            },
            child: const Text('Envoyer Rappels'),
          ),
        ],
      ),
    );
  }

  // CORRECTION : Méthode simplifiée sans référence à ClientService
  void _checkProfileCompletion(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        print('🔍 Vérification profil pour: $userEmail');
        final clientService =
            Provider.of<FirebaseClientService>(context, listen: false);
        final client = await clientService.getClientByEmail(userEmail);

        if (client == null) {
          print('❌ Profil non trouvé dans Firestore pour: $userEmail');

          // Attendre un peu pour que l'écran soit complètement chargé
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
          // Vérifier si le profil utilise des valeurs par défaut
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

  Widget _buildServiceCard(
      String title, IconData icon, Color color, String subtitle,
      {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    );
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
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                await authService.logout();

                if (context.mounted) {
                  Navigator.pop(context);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Déconnexion réussie'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }

                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur de déconnexion: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
