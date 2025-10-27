import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/loyalty_model.dart';
import '../services/loyalty_service.dart';
import '../services/simple_auth_service.dart';
import '../models/user_model.dart';

class LoyaltyProgramScreen extends StatefulWidget {
  const LoyaltyProgramScreen({super.key});

  @override
  _LoyaltyProgramScreenState createState() => _LoyaltyProgramScreenState();
}

class _LoyaltyProgramScreenState extends State<LoyaltyProgramScreen> {
  List<LoyaltyProgram> _loyaltyPrograms = [];
  List<LoyaltyReward> _rewards = [];
  final TextEditingController _searchController = TextEditingController();
  final LoyaltyService _loyaltyService = LoyaltyService();
  bool _checkingAccess = true;
  bool _isGarage = false;
  bool _isLoading = true;
  String _selectedTierFilter = 'all';
  String _sortBy = 'points';

  int _totalClients = 0;
  int _goldClients = 0;
  int _totalPoints = 0;
  int _activeClients = 0;

  @override
  void initState() {
    super.initState();
    _checkGarageAccess();
  }

  Future<void> _checkGarageAccess() async {
    try {
      print('🔐 Vérification des accès garage pour programme fidélité...');

      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);
      final currentUser = await authService.getCurrentAppUser();

      if (currentUser != null && currentUser.userType == UserType.garage) {
        print('✅ Accès garage autorisé pour le programme fidélité');
        setState(() {
          _isGarage = true;
          _checkingAccess = false;
        });
        _loadRealData();
      } else {
        print('❌ Accès garage refusé pour le programme fidélité');
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
      print('❌ Erreur vérification accès fidélité: $e');
      setState(() {
        _checkingAccess = false;
        _isGarage = false;
      });
    }
  }

  void _loadRealData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final programs = await _loyaltyService.getAllLoyaltyPrograms();
      _calculateStats(programs);

      setState(() {
        _loyaltyPrograms = programs;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement données fidélité: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStats(List<LoyaltyProgram> programs) {
    setState(() {
      _totalClients = programs.length;
      _goldClients = programs
          .where((program) => program.currentTier.toLowerCase() == 'or')
          .length;
      _totalPoints = programs.fold(0, (sum, program) => sum + program.points);
      _activeClients = programs.where((program) {
        final daysSinceLastActivity =
            DateTime.now().difference(program.lastActivity).inDays;
        return daysSinceLastActivity <= 30;
      }).length;
    });
  }

  List<LoyaltyProgram> get _filteredPrograms {
    List<LoyaltyProgram> filtered = _loyaltyPrograms;

    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((program) {
        return program.clientEmail
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            (_getClientDisplayName(program)
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()));
      }).toList();
    }

    if (_selectedTierFilter != 'all') {
      filtered = filtered
          .where((program) =>
              program.currentTier.toLowerCase() == _selectedTierFilter)
          .toList();
    }

    switch (_sortBy) {
      case 'points':
        filtered.sort((a, b) => b.points.compareTo(a.points));
        break;
      case 'name':
        filtered.sort((a, b) =>
            _getClientDisplayName(a).compareTo(_getClientDisplayName(b)));
        break;
      case 'tier':
        final tierOrder = {'Or': 4, 'Argent': 3, 'Bronze': 2, 'Nouveau': 1};
        filtered.sort((a, b) => (tierOrder[b.currentTier] ?? 0)
            .compareTo(tierOrder[a.currentTier] ?? 0));
        break;
      case 'last_activity':
        filtered.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
        break;
    }

    return filtered;
  }

  String _getClientDisplayName(LoyaltyProgram program) {
    return program.clientEmail.split('@').first;
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'or':
        return Colors.amber;
      case 'argent':
        return Colors.grey;
      case 'bronze':
        return Colors.brown;
      case 'nouveau':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'or':
        return Icons.workspace_premium;
      case 'argent':
        return Icons.emoji_events;
      case 'bronze':
        return Icons.emoji_events;
      case 'nouveau':
        return Icons.person_add;
      default:
        return Icons.person;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleClientMenu(String value, LoyaltyProgram program) {
    switch (value) {
      case 'details':
        _showClientDetails(program);
        break;
      case 'add_points':
        _addPointsToClient(program);
        break;
      case 'redeem':
        _redeemPoints(program);
        break;
    }
  }

  void _showClientDetails(LoyaltyProgram program) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du Client'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nom', _getClientDisplayName(program)),
              _buildDetailRow('Email', program.clientEmail),
              _buildDetailRow('Niveau actuel', program.currentTier),
              _buildDetailRow('Points', '${program.points} pts'),
              _buildDetailRow('Progression',
                  '${(program.progressToNextTier * 100).toStringAsFixed(1)}%'),
              _buildDetailRow(
                  'Visites totales', program.totalVisits.toString()),
              _buildDetailRow('Montant total', '${program.totalSpent} FCFA'),
              _buildDetailRow(
                  'Dernière activité', _formatDate(program.lastActivity)),
              _buildDetailRow(
                  'Date d\'inscription', _formatDate(program.joinDate)),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _addPointsToClient(LoyaltyProgram program) {
    final pointsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter des Points'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Client: ${_getClientDisplayName(program)}',
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pointsController,
              decoration: const InputDecoration(
                labelText: 'Points à ajouter',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
              final points = int.tryParse(pointsController.text) ?? 0;
              if (points > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '$points points ajoutés à ${_getClientDisplayName(program)}'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              'Ajouter',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _redeemPoints(LoyaltyProgram program) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Échanger des Points'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Client: ${_getClientDisplayName(program)}',
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Points disponibles: ${program.points}',
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Text('Sélectionnez une récompense:'),
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

  void _handleRewardMenu(String value, LoyaltyReward reward) {
    switch (value) {
      case 'edit':
        _editReward(reward);
        break;
      case 'toggle':
        _toggleReward(reward);
        break;
      case 'delete':
        _deleteReward(reward);
        break;
    }
  }

  void _editReward(LoyaltyReward reward) {
    _showRewardForm(reward: reward);
  }

  void _toggleReward(LoyaltyReward reward) {
    setState(() {
      final index = _rewards.indexWhere((r) => r.id == reward.id);
      if (index != -1) {
        _rewards[index] = _rewards[index].copyWith(
          isActive: !reward.isActive,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Récompense ${reward.isActive ? 'désactivée' : 'activée'}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _deleteReward(LoyaltyReward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la récompense'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${reward.name}" ?',
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _rewards.removeWhere((r) => r.id == reward.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${reward.name}" a été supprimée'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Programme de Fidélité'),
          backgroundColor: Colors.orange,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchBar,
              tooltip: 'Rechercher',
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleAppBarMenu(value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download, color: Colors.green),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Exporter',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.blue),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Paramètres',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.orange),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Actualiser',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.people),
                text: 'Clients',
              ),
              Tab(
                icon: Icon(Icons.card_giftcard),
                text: 'Récompenses',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildClientsTab(),
            _buildRewardsTab(),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildClientsTab() {
    return Column(
      children: [
        _buildStatsHeader(),
        _buildSearchBar(),
        _buildFiltersBar(),
        Expanded(
          child: _isLoading
              ? _buildLoadingState()
              : _filteredPrograms.isEmpty
                  ? _buildEmptyClientsState()
                  : _buildClientsList(),
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange[50]!, Colors.orange[100]!],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLoyaltyStat(
                  _totalClients.toString(), 'Clients', Icons.people),
              _buildLoyaltyStat(
                  _activeClients.toString(), 'Actifs', Icons.emoji_events),
              _buildLoyaltyStat(
                  _goldClients.toString(), 'Or', Icons.workspace_premium),
              _buildLoyaltyStat(
                  _totalPoints.toString(), 'Points', Icons.attach_money),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Fidélisez vos clients et récompensez leur fidélité',
            style: TextStyle(fontSize: 12, color: Colors.orange[700]),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un client...',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.orange.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide:
                      BorderSide(color: Colors.orange.shade500, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTierFilter,
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(
                        'Tous niveaux',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'or',
                      child: Text(
                        'Or',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'argent',
                      child: Text(
                        'Argent',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'bronze',
                      child: Text(
                        'Bronze',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'nouveau',
                      child: Text(
                        'Nouveau',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTierFilter = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                    labelText: 'Niveau',
                  ),
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(
                      value: 'points',
                      child: Text(
                        'Points',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'name',
                      child: Text(
                        'Nom',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'tier',
                      child: Text(
                        'Niveau',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'last_activity',
                      child: Text(
                        'Activité',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                    labelText: 'Trier par',
                  ),
                  isExpanded: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.grey),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.grey),
            title: Container(
              height: 16,
              width: 100,
              color: Colors.grey[300],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 150, color: Colors.grey[300]),
                const SizedBox(height: 4),
                Container(height: 12, width: 120, color: Colors.grey[300]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyClientsState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Aucun client fidèle'
                  : 'Aucun résultat',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _searchController.text.isEmpty
                    ? 'Les clients apparaîtront ici automatiquement après leur premier rendez-vous'
                    : 'Aucun client ne correspond à "${_searchController.text}"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadRealData,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                child: const Text('Effacer la recherche'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClientsList() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadRealData();
      },
      child: Column(
        children: [
          if (_searchController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.orange[50],
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_filteredPrograms.length} résultat(s) pour "${_searchController.text}"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    child: Text(
                      'Effacer',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredPrograms.length,
              itemBuilder: (context, index) {
                final program = _filteredPrograms[index];
                return _buildClientCard(program);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(LoyaltyProgram program) {
    final daysSinceLastActivity =
        DateTime.now().difference(program.lastActivity).inDays;
    final isActive = daysSinceLastActivity <= 30;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: _getTierColor(program.currentTier),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(
            _getTierIcon(program.currentTier),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _getClientDisplayName(program),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Inactif',
                  style: TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📧 ${program.clientEmail}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTierColor(program.currentTier).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: _getTierColor(program.currentTier)),
                  ),
                  child: Text(
                    program.currentTier,
                    style: TextStyle(
                      fontSize: 9,
                      color: _getTierColor(program.currentTier),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${program.points} pts',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: program.progressToNextTier,
              backgroundColor: Colors.grey[300],
              color: _getTierColor(program.currentTier),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${program.totalVisits} visites',
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  '${program.totalSpent} FCFA',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleClientMenu(value, program),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 16),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Détails',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'add_points',
              child: Row(
                children: [
                  Icon(Icons.add, color: Colors.green, size: 16),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Ajouter pts',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'redeem',
              child: Row(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.orange, size: 16),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Échanger',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          _showClientDetails(program);
        },
      ),
    );
  }

  Widget _buildRewardsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.orange[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLoyaltyStat(_rewards.length.toString(), 'Récompenses',
                  Icons.card_giftcard),
              _buildLoyaltyStat(
                _rewards.where((r) => r.isActive).length.toString(),
                'Actives',
                Icons.check_circle,
              ),
              _buildLoyaltyStat(
                _rewards
                    .where((r) => r.category == 'Service')
                    .length
                    .toString(),
                'Services',
                Icons.build,
              ),
            ],
          ),
        ),
        Expanded(
          child: _rewards.isEmpty
              ? _buildEmptyRewardsState()
              : ListView.builder(
                  itemCount: _rewards.length,
                  itemBuilder: (context, index) {
                    final reward = _rewards[index];
                    return _buildRewardCard(reward);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyRewardsState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Aucune récompense',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Créez votre première récompense pour fidéliser vos clients',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addReward,
              icon: const Icon(Icons.add),
              label: const Text('Créer récompense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(LoyaltyReward reward) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: reward.isActive ? Colors.orange : Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.card_giftcard,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                reward.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: reward.isActive ? null : Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!reward.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Inactive',
                  style: TextStyle(fontSize: 9, color: Colors.red),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reward.description,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${reward.pointsRequired} pts',
                    style: const TextStyle(fontSize: 10, color: Colors.orange),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reward.category,
                    style: const TextStyle(fontSize: 10, color: Colors.blue),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  reward.stock == -1
                      ? 'Stock: Illimité'
                      : 'Stock: ${reward.stock}',
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  'Jusqu\'au ${_formatDate(reward.validUntil)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleRewardMenu(value, reward),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue, size: 16),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Modifier',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    reward.isActive ? Icons.pause : Icons.play_arrow,
                    color: reward.isActive ? Colors.orange : Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      reward.isActive ? 'Désactiver' : 'Activer',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 16),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Supprimer',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _addReward,
      backgroundColor: Colors.orange,
      icon: const Icon(Icons.card_giftcard, color: Colors.white),
      label: const Text(
        'Nouvelle Récompense',
        style: TextStyle(color: Colors.white),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showSearchBar() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _handleAppBarMenu(String value) {
    switch (value) {
      case 'export':
        _exportLoyaltyData();
        break;
      case 'settings':
        _showLoyaltySettings();
        break;
      case 'refresh':
        _loadRealData();
        break;
    }
  }

  void _exportLoyaltyData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export des données fidélité réussi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showLoyaltySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres Fidélité'),
        content: const Text(
            'Configuration du programme de fidélité en cours de développement...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _addReward() {
    _showRewardForm();
  }

  void _showRewardForm({LoyaltyReward? reward}) {
    final nameController = TextEditingController(text: reward?.name ?? '');
    final descriptionController =
        TextEditingController(text: reward?.description ?? '');
    final pointsController =
        TextEditingController(text: reward?.pointsRequired.toString() ?? '');
    final categoryController =
        TextEditingController(text: reward?.category ?? 'Service');
    final stockController =
        TextEditingController(text: reward?.stock.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          reward == null ? 'Nouvelle Récompense' : 'Modifier Récompense',
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom *'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(labelText: 'Points requis *'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Catégorie *'),
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock (-1 pour illimité)',
                  hintText: '-1',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveReward(
                nameController.text,
                descriptionController.text,
                pointsController.text,
                categoryController.text,
                stockController.text,
                reward?.id,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(
              reward == null ? 'Ajouter' : 'Modifier',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _saveReward(
    String name,
    String description,
    String pointsRequired,
    String category,
    String stock,
    String? existingId,
  ) {
    if (name.isEmpty || pointsRequired.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir les champs obligatoires (*)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      if (existingId != null) {
        final index = _rewards.indexWhere((r) => r.id == existingId);
        if (index != -1) {
          _rewards[index] = _rewards[index].copyWith(
            name: name,
            description: description,
            pointsRequired: int.tryParse(pointsRequired) ?? 0,
            category: category,
            stock: int.tryParse(stock) ?? 0,
          );
        }
      } else {
        final newReward = LoyaltyReward(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          description: description,
          pointsRequired: int.tryParse(pointsRequired) ?? 0,
          category: category,
          isActive: true,
          stock: int.tryParse(stock) ?? 0,
          validUntil: DateTime.now().add(const Duration(days: 90)),
        );
        _rewards.add(newReward);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(existingId == null
            ? 'Récompense ajoutée avec succès'
            : 'Récompense modifiée avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
