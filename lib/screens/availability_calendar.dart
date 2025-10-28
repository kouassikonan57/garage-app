import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/appointment_service.dart';
import '../services/simple_auth_service.dart';
import '../models/user_model.dart';

class AvailabilityCalendar extends StatefulWidget {
  final AppointmentService appointmentService;

  const AvailabilityCalendar({
    super.key,
    required this.appointmentService,
  });

  @override
  _AvailabilityCalendarState createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  late final AppointmentService _appointmentService;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<DateTime>> _availability = {};
  Map<DateTime, List<DateTime>> _bookedSlots = {};
  bool _checkingAccess = true;
  bool _isGarage = false;
  bool _isLoading = true;
  String _selectedView = 'day'; // 'day', 'week', 'month'

  @override
  void initState() {
    super.initState();
    _appointmentService = widget.appointmentService;
    _checkGarageAccess();
  }

  Future<void> _checkGarageAccess() async {
    try {
      print('🔐 Vérification des accès garage pour disponibilités...');

      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);
      final currentUser = await authService.getCurrentAppUser();

      if (currentUser != null && currentUser.userType == UserType.garage) {
        print('✅ Accès garage autorisé pour les disponibilités');
        setState(() {
          _isGarage = true;
          _checkingAccess = false;
        });
        await _loadAvailability();
      } else {
        print('❌ Accès garage refusé pour les disponibilités');
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
      print('❌ Erreur vérification accès disponibilités: $e');
      setState(() {
        _checkingAccess = false;
        _isGarage = false;
      });
    }
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les disponibilités pour les 30 prochains jours
      final now = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final date = DateTime(now.year, now.month, now.day + i);
        final availableSlots =
            await _appointmentService.getAvailableTimeSlots(date);
        _availability[date] = availableSlots;
      }

      // Simuler des créneaux réservés (à remplacer par vos vraies données)
      for (int i = 0; i < 10; i++) {
        final date = DateTime(now.year, now.month, now.day + i);
        _bookedSlots[date] = [
          DateTime(date.year, date.month, date.day, 9, 0),
          DateTime(date.year, date.month, date.day, 14, 0),
          DateTime(date.year, date.month, date.day, 16, 0),
        ];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement disponibilités: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleTimeSlot(DateTime date, DateTime timeSlot) {
    setState(() {
      final dateKey = DateTime(date.year, date.month, date.day);

      // Vérifier si le créneau n'est pas déjà réservé
      if (_bookedSlots[dateKey]?.contains(timeSlot) == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ce créneau est déjà réservé'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_availability[dateKey]?.contains(timeSlot) ?? false) {
        _availability[dateKey]!.remove(timeSlot);
      } else {
        _availability[dateKey] ??= [];
        _availability[dateKey]!.add(timeSlot);
      }
    });
  }

  void _toggleAllDay(DateTime date, bool makeAvailable) {
    setState(() {
      final dateKey = DateTime(date.year, date.month, date.day);

      if (makeAvailable) {
        // Ajouter tous les créneaux de la journée (8h-18h)
        _availability[dateKey] = [];
        for (int hour = 8; hour <= 18; hour++) {
          final timeSlot = DateTime(date.year, date.month, date.day, hour);
          // Ne pas ajouter les créneaux déjà réservés
          if (_bookedSlots[dateKey]?.contains(timeSlot) != true) {
            _availability[dateKey]!.add(timeSlot);
          }
        }
      } else {
        // Supprimer tous les créneaux disponibles (sauf ceux réservés)
        _availability[dateKey]?.clear();
      }
    });
  }

  void _copyDayAvailability(DateTime sourceDate, DateTime targetDate) {
    setState(() {
      final sourceKey =
          DateTime(sourceDate.year, sourceDate.month, sourceDate.day);
      final targetKey =
          DateTime(targetDate.year, targetDate.month, targetDate.day);

      _availability[targetKey] = List.from(_availability[sourceKey] ?? []);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disponibilités copiées avec succès'),
        backgroundColor: Colors.green,
      ),
    );
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
        title: const Text('Gestion des Disponibilités'),
        backgroundColor: Colors.green,
        actions: [
          // Sélecteur de vue
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedView = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'day',
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_day, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Vue Jour'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_week, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Vue Semaine'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_month, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Vue Mois'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailability,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedView == 'day'
              ? _buildDayView()
              : _selectedView == 'week'
                  ? _buildWeekView()
                  : _buildMonthView(),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildDayView() {
    return Column(
      children: [
        // En-tête de date avec navigation
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
                    _selectedDate =
                        _selectedDate.subtract(const Duration(days: 1));
                  });
                },
                tooltip: 'Jour précédent',
              ),
              Column(
                children: [
                  Text(
                    _getFormattedDate(_selectedDate),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _getDayName(_selectedDate.weekday),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                },
                tooltip: 'Jour suivant',
              ),
            ],
          ),
        ),

        // Actions rapides pour la journée
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _toggleAllDay(_selectedDate, true),
                icon: const Icon(Icons.check_circle, size: 16),
                label: const Text('Toute la journée'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _toggleAllDay(_selectedDate, false),
                icon: const Icon(Icons.block, size: 16),
                label: const Text('Aucune dispo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.content_copy, color: Colors.blue),
                onPressed: () => _showCopyDialog(_selectedDate),
                tooltip: 'Copier vers...',
              ),
            ],
          ),
        ),

        // Créneaux horaires
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Créneaux horaires:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildTimeSlotsGrid(),
                ),
                const SizedBox(height: 20),
                _buildLegend(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotsGrid() {
    final dateKey =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final availableSlots = _availability[dateKey] ?? [];
    final bookedSlots = _bookedSlots[dateKey] ?? [];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemCount: 24, // 24 heures
      itemBuilder: (context, index) {
        final hour = index;
        final timeSlot = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          hour,
        );

        final isAvailable = availableSlots.any((slot) => slot.hour == hour);
        final isBooked = bookedSlots.any((slot) => slot.hour == hour);
        final isPast = timeSlot.isBefore(DateTime.now());
        final isWorkingHour = hour >= 8 && hour <= 18;

        return GestureDetector(
          onTap: isPast || isBooked || !isWorkingHour
              ? null
              : () => _toggleTimeSlot(_selectedDate, timeSlot),
          child: Container(
            decoration: BoxDecoration(
              color: _getTimeSlotColor(
                  isAvailable, isBooked, isPast, isWorkingHour),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getTimeSlotBorderColor(
                    isAvailable, isBooked, isPast, isWorkingHour),
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${hour.toString().padLeft(2, '0')}h',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getTimeSlotTextColor(
                          isAvailable, isBooked, isPast, isWorkingHour),
                      fontSize: 12,
                    ),
                  ),
                  if (isBooked)
                    const Icon(Icons.lock, size: 12, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getTimeSlotColor(
      bool isAvailable, bool isBooked, bool isPast, bool isWorkingHour) {
    if (!isWorkingHour) return Colors.grey[100]!;
    if (isPast) return Colors.grey[300]!;
    if (isBooked) return Colors.orange;
    return isAvailable ? Colors.green[100]! : Colors.red[100]!;
  }

  Color _getTimeSlotBorderColor(
      bool isAvailable, bool isBooked, bool isPast, bool isWorkingHour) {
    if (!isWorkingHour) return Colors.grey;
    if (isPast) return Colors.grey;
    if (isBooked) return Colors.orange;
    return isAvailable ? Colors.green : Colors.red;
  }

  Color _getTimeSlotTextColor(
      bool isAvailable, bool isBooked, bool isPast, bool isWorkingHour) {
    if (!isWorkingHour) return Colors.grey;
    if (isPast) return Colors.grey;
    if (isBooked) return Colors.white;
    return Colors.black;
  }

  Widget _buildWeekView() {
    final startOfWeek =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));

    return Column(
      children: [
        // En-tête de la semaine
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
                    _selectedDate =
                        _selectedDate.subtract(const Duration(days: 7));
                  });
                },
              ),
              Text(
                'Semaine du ${_getFormattedDate(startOfWeek)}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 7));
                  });
                },
              ),
            ],
          ),
        ),

        // Grille de la semaine
        Expanded(
          child: ListView.builder(
            itemCount: 7,
            itemBuilder: (context, index) {
              final day = startOfWeek.add(Duration(days: index));
              final isToday = _isSameDay(day, DateTime.now());
              final isSelected = _isSameDay(day, _selectedDate);
              final dateKey = DateTime(day.year, day.month, day.day);
              final availableCount = _availability[dateKey]?.length ?? 0;
              final bookedCount = _bookedSlots[dateKey]?.length ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: isSelected ? Colors.green[50] : null,
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isToday ? Colors.green : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    _getDayName(day.weekday),
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(_getFormattedDate(day)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$availableCount dispo',
                        style:
                            const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                      Text(
                        '$bookedCount réservé',
                        style:
                            const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedDate = day;
                      _selectedView = 'day';
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthView() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    return Column(
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
              ),
              Text(
                '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _focusedDay =
                        DateTime(_focusedDay.year, _focusedDay.month + 1);
                  });
                },
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

        // Grille du mois
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemCount: 42, // 6 semaines
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              final currentDay =
                  DateTime(_focusedDay.year, _focusedDay.month, 1 + dayOffset);
              final isCurrentMonth = currentDay.month == _focusedDay.month;
              final isToday = _isSameDay(currentDay, DateTime.now());
              final dateKey =
                  DateTime(currentDay.year, currentDay.month, currentDay.day);
              final availableCount = _availability[dateKey]?.length ?? 0;

              return GestureDetector(
                onTap: isCurrentMonth
                    ? () {
                        setState(() {
                          _selectedDate = currentDay;
                          _selectedView = 'day';
                        });
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.green[50]
                        : (isCurrentMonth ? Colors.white : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isToday ? Colors.green : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentDay.day.toString(),
                        style: TextStyle(
                          color: isCurrentMonth ? Colors.black : Colors.grey,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isCurrentMonth && availableCount > 0)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'save',
          onPressed: _saveAvailability,
          backgroundColor: Colors.green,
          child: const Icon(Icons.save, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'add',
          onPressed: _showQuickAddDialog,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Légende:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildLegendItem(Colors.green, 'Disponible'),
          _buildLegendItem(Colors.red, 'Indisponible'),
          _buildLegendItem(Colors.orange, 'Réservé'),
          _buildLegendItem(Colors.grey, 'Passé/Hors horaire'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 16, height: 16, color: color),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  void _saveAvailability() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disponibilités sauvegardées avec succès !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showQuickAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajout rapide de disponibilités'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.green),
              title: const Text('Cette semaine'),
              subtitle: const Text('Lundi à vendredi, 8h-18h'),
              onTap: () {
                Navigator.pop(context);
                _addWeekAvailability();
              },
            ),
            ListTile(
              leading: const Icon(Icons.weekend, color: Colors.blue),
              title: const Text('Week-end'),
              subtitle: const Text('Samedi et dimanche, 9h-16h'),
              onTap: () {
                Navigator.pop(context);
                _addWeekendAvailability();
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range, color: Colors.orange),
              title: const Text('Prochains 7 jours'),
              subtitle: const Text('Tous les jours, horaires standards'),
              onTap: () {
                Navigator.pop(context);
                _addNextWeekAvailability();
              },
            ),
          ],
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

  void _showCopyDialog(DateTime sourceDate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copier les disponibilités'),
        content: const Text('Copier les disponibilités de ce jour vers...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _copyDayAvailability(
                  sourceDate, sourceDate.add(const Duration(days: 1)));
            },
            child: const Text('Demain'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _copyToNextWeek(sourceDate);
            },
            child: const Text('Toute la semaine prochaine'),
          ),
        ],
      ),
    );
  }

  void _addWeekAvailability() {
    final now = DateTime.now();
    for (int i = 0; i < 5; i++) {
      // Lundi à vendredi
      final date = now.add(Duration(days: i));
      if (date.weekday >= DateTime.monday && date.weekday <= DateTime.friday) {
        _toggleAllDay(date, true);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disponibilités de la semaine ajoutées'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addWeekendAvailability() {
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        _toggleAllDay(date, true);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disponibilités du week-end ajoutées'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addNextWeekAvailability() {
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      _toggleAllDay(date, true);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disponibilités des 7 prochains jours ajoutées'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _copyToNextWeek(DateTime sourceDate) {
    for (int i = 1; i <= 7; i++) {
      final targetDate = sourceDate.add(Duration(days: i));
      _copyDayAvailability(sourceDate, targetDate);
    }
  }

  // Helper methods
  String _getFormattedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDayName(int weekday) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[weekday - 1];
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
