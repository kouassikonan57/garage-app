import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simple_auth_service.dart';
import '../models/user_model.dart';

class AdvancedCalendar extends StatefulWidget {
  const AdvancedCalendar({super.key});

  @override
  _AdvancedCalendarState createState() => _AdvancedCalendarState();
}

class _AdvancedCalendarState extends State<AdvancedCalendar> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<CalendarEvent>> _events = {};
  bool _checkingAccess = true;
  bool _isGarage = false;

  @override
  void initState() {
    super.initState();
    _checkGarageAccess();
  }

  Future<void> _checkGarageAccess() async {
    try {
      print('🔐 Vérification des accès garage pour calendrier...');

      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);
      final currentUser = await authService.getCurrentAppUser();

      if (currentUser != null && currentUser.userType == UserType.garage) {
        print('✅ Accès garage autorisé pour le calendrier');
        setState(() {
          _isGarage = true;
          _checkingAccess = false;
        });
        _loadAppointments();
      } else {
        print('❌ Accès garage refusé pour le calendrier');
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
      print('❌ Erreur vérification accès calendrier: $e');
      setState(() {
        _checkingAccess = false;
        _isGarage = false;
      });
    }
  }

  // Méthode pour charger les rendez-vous réels (à connecter avec votre service)
  void _loadAppointments() {
    // Pour l'instant, on initialise avec un calendrier vide
    // Vous pourrez connecter cette méthode à votre AppointmentService plus tard
    setState(() {
      _events = {};
    });
    print('📅 Calendrier initialisé - Aucun rendez-vous de démonstration');
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
        title: const Text('Calendrier des Disponibilités'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _focusedDay = DateTime.now();
              });
            },
            tooltip: 'Aujourd\'hui',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
            tooltip: 'Actualiser',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add_availability') {
                _showAddAvailabilityDialog();
              } else if (value == 'view_appointments') {
                _showAppointmentsList();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_availability',
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Ajouter disponibilité'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'view_appointments',
                child: Row(
                  children: [
                    Icon(Icons.list, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Voir tous les RDV'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête du mois
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDay =
                          DateTime(_focusedDay.year, _focusedDay.month - 1);
                    });
                  },
                  tooltip: 'Mois précédent',
                ),
                Column(
                  children: [
                    Text(
                      '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _getFormattedDate(_selectedDate),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedDay =
                          DateTime(_focusedDay.year, _focusedDay.month + 1);
                    });
                  },
                  tooltip: 'Mois suivant',
                ),
              ],
            ),
          ),

          // Jours de la semaine
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.grey[100],
            child: const Row(
              children: [
                Expanded(
                    child: Text('Lun',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text('Mar',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text('Mer',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text('Jeu',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text('Ven',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text('Sam',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text('Dim',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          // Grille du calendrier
          Expanded(
            child: _buildCalendarGrid(),
          ),

          // Section informations
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jour sélectionné:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_events[_selectedDate] != null &&
                    _events[_selectedDate]!.isNotEmpty) ...[
                  Text(
                    '${_events[_selectedDate]!.length} rendez-vous programmé(s)',
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      itemCount: _events[_selectedDate]!.length,
                      itemBuilder: (context, index) {
                        final event = _events[_selectedDate]![index];
                        return ListTile(
                          leading: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: event.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(event.title),
                          subtitle: Text('${event.time.format(context)}'),
                          trailing: const Icon(Icons.arrow_forward, size: 16),
                          onTap: () {
                            _showEventDetails(event);
                          },
                          dense: true,
                        );
                      },
                    ),
                  ),
                ] else ...[
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aucun rendez-vous programmé pour cette date',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddAvailabilityDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajouter une disponibilité'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),

      // Bouton d'action flottant pour ajouter rapidement une disponibilité
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAvailabilityDialog,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        tooltip: 'Ajouter une disponibilité',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: 42, // 6 semaines maximum
      itemBuilder: (context, index) {
        final dayOffset = index - (firstWeekday - 1);
        final currentDay =
            DateTime(_focusedDay.year, _focusedDay.month, 1 + dayOffset);

        final isCurrentMonth = currentDay.month == _focusedDay.month;
        final isToday = _isSameDay(currentDay, DateTime.now());
        final isSelected = _isSameDay(currentDay, _selectedDate);
        final hasEvents =
            _events[currentDay] != null && _events[currentDay]!.isNotEmpty;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = currentDay;
            });
          },
          onLongPress: () {
            _showDateOptions(currentDay);
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green
                  : (isToday ? Colors.green[50] : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isToday ? Colors.green : Colors.transparent,
                width: isToday ? 2 : 0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currentDay.day.toString(),
                  style: TextStyle(
                    color: isCurrentMonth
                        ? (isSelected ? Colors.white : Colors.black)
                        : Colors.grey,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: isToday ? 16 : 14,
                  ),
                ),
                if (hasEvents) ...[
                  const SizedBox(height: 2),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return months[month - 1];
  }

  String _getFormattedDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  void _showEventDetails(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du RDV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${event.title}'),
            Text('Heure: ${event.time.format(context)}'),
            Text('Date: ${_getFormattedDate(_selectedDate)}'),
            const SizedBox(height: 16),
            const Text(
              'Fonctionnalité à connecter avec votre service de rendez-vous',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Ici vous pourrez ajouter la logique pour modifier le RDV
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showAddAvailabilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une disponibilité'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Date: ${_getFormattedDate(_selectedDate)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cette fonctionnalité vous permettra de définir vos créneaux disponibles pour les rendez-vous clients.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'À connecter avec votre système de gestion des disponibilités',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
                  content: Text('Fonctionnalité à implémenter'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Configurer'),
          ),
        ],
      ),
    );
  }

  void _showAppointmentsList() {
    try {
      print('🔄 Tentative de redirection vers la gestion des RDV...');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirection vers la gestion des rendez-vous...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Vérification d'accès avant redirection
      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);

      authService.getCurrentAppUser().then((currentUser) {
        if (currentUser == null || currentUser.userType != UserType.garage) {
          throw Exception('Accès garage non autorisé');
        }

        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pushNamed(context, '/garage-management');
        });
      }).catchError((error) {
        print('❌ Erreur redirection: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    } catch (e) {
      print('❌ Erreur dans _showAppointmentsList: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fonctionnalité en cours de développement'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showDateOptions(DateTime date) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Options pour le ${_getFormattedDate(date)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.green),
              title: const Text('Ajouter une disponibilité'),
              onTap: () {
                Navigator.pop(context);
                _showAddAvailabilityDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('Voir les RDV du jour'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Bloquer cette date'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité de blocage à implémenter'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarEvent {
  final String title;
  final TimeOfDay time;
  final Color color;

  CalendarEvent(this.title, this.time, this.color);
}
