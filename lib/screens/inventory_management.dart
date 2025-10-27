import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simple_auth_service.dart';
import '../models/inventory_model.dart';
import '../models/user_model.dart';

class InventoryManagement extends StatefulWidget {
  const InventoryManagement({super.key});

  @override
  _InventoryManagementState createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement> {
  List<InventoryItem> _inventory = [];
  final TextEditingController _searchController = TextEditingController();
  bool _checkingAccess = true;
  bool _isGarage = false;
  bool _isLoading = true;
  String _filterCategory = 'Tous';
  String _sortBy = 'name';
  String _stockFilter = 'all';

  @override
  void initState() {
    super.initState();
    _checkGarageAccess();
  }

  Future<void> _checkGarageAccess() async {
    try {
      print('🔐 Vérification des accès garage pour inventaire...');

      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);
      final currentUser = await authService.getCurrentAppUser();

      if (currentUser != null && currentUser.userType == UserType.garage) {
        print('✅ Accès garage autorisé pour l\'inventaire');
        setState(() {
          _isGarage = true;
          _checkingAccess = false;
        });
        _loadInventory();
      } else {
        print('❌ Accès garage refusé pour l\'inventaire');
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
      print('❌ Erreur vérification accès inventaire: $e');
      setState(() {
        _checkingAccess = false;
        _isGarage = false;
      });
    }
  }

  void _loadInventory() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _inventory = [];
        _isLoading = false;
      });
    });
  }

  List<InventoryItem> get _filteredInventory {
    List<InventoryItem> filtered = _inventory;

    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            item.description
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            item.supplierName
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            item.category
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            item.location
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());
      }).toList();
    }

    if (_filterCategory != 'Tous') {
      filtered =
          filtered.where((item) => item.category == _filterCategory).toList();
    }

    switch (_stockFilter) {
      case 'low':
        filtered = filtered.where((item) => item.isLowStock).toList();
        break;
      case 'out':
        filtered = filtered.where((item) => item.isOutOfStock).toList();
        break;
      case 'normal':
        filtered = filtered
            .where((item) => !item.isLowStock && !item.isOutOfStock)
            .toList();
        break;
    }

    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'quantity':
        filtered.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case 'value':
        filtered.sort((a, b) => b.totalValue.compareTo(a.totalValue));
        break;
      case 'category':
        filtered.sort((a, b) => a.category.compareTo(b.category));
        break;
    }

    return filtered;
  }

  List<String> get _categories {
    final categories = _inventory.map((item) => item.category).toSet().toList();
    categories.sort();
    categories.insert(0, 'Tous');
    return categories;
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

    final lowStockItems = _inventory.where((item) => item.isLowStock).length;
    final outOfStockItems =
        _inventory.where((item) => item.isOutOfStock).length;
    final totalValue =
        _inventory.fold(0.0, (sum, item) => sum + item.totalValue);
    final totalItems = _inventory.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Stocks'),
        backgroundColor: Colors.blue,
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
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload, color: Colors.blue),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Importer',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.green),
                    SizedBox(width: 8),
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
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.orange),
                    SizedBox(width: 8),
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
      ),
      body: Column(
        children: [
          _buildStatsHeader(
              totalItems, lowStockItems, outOfStockItems, totalValue),
          _buildSearchBar(),
          _buildFiltersBar(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredInventory.isEmpty
                    ? _buildEmptyState()
                    : _buildInventoryList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addInventoryItem,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouvel Article',
          style: TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStatsHeader(int totalItems, int lowStockItems,
      int outOfStockItems, double totalValue) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.blue[100]!],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                  totalItems.toString(), 'Articles', Icons.inventory_2),
              _buildStatCard(
                  lowStockItems.toString(), 'Stock Faible', Icons.warning,
                  color: lowStockItems > 0 ? Colors.orange : Colors.green),
              _buildStatCard(outOfStockItems.toString(), 'Rupture', Icons.error,
                  color: outOfStockItems > 0 ? Colors.red : Colors.green),
              _buildStatCard('${(totalValue / 1000).toStringAsFixed(0)}F CFA',
                  'Valeur', Icons.money),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Gérez votre inventaire de pièces auto',
            style: TextStyle(fontSize: 12, color: Colors.blue[700]),
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
                hintText: 'Rechercher...',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
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
                  borderSide: BorderSide(color: Colors.blue.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
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
                  value: _filterCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        category,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterCategory = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                    labelText: 'Catégorie',
                  ),
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _stockFilter,
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(
                        'Tous stocks',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'normal',
                      child: Text(
                        'Stock normal',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'low',
                      child: Text(
                        'Stock faible',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'out',
                      child: Text(
                        'Rupture',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _stockFilter = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                    labelText: 'État stock',
                  ),
                  isExpanded: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _sortBy,
            items: const [
              DropdownMenuItem(
                value: 'name',
                child: Text(
                  'Nom A-Z',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'quantity',
                child: Text(
                  'Quantité',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'value',
                child: Text(
                  'Valeur',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'category',
                child: Text(
                  'Catégorie',
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
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon,
      {Color color = Colors.blue}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
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
            color: Colors.blue,
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

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Inventaire vide'
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
                    ? 'Commencez par ajouter vos pièces auto pour gérer votre inventaire'
                    : 'Aucun article ne correspond à "${_searchController.text}"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addInventoryItem,
              icon: const Icon(Icons.add),
              label: Text(
                _searchController.text.isEmpty
                    ? 'Ajouter premier article'
                    : 'Ajouter article',
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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

  Widget _buildInventoryList() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadInventory();
      },
      child: Column(
        children: [
          if (_searchController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_filteredInventory.length} résultat(s) pour "${_searchController.text}"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
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
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredInventory.length,
              itemBuilder: (context, index) {
                final item = _filteredInventory[index];
                return _buildInventoryCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(InventoryItem item) {
    final stockStatus = item.isOutOfStock
        ? 'RUPTURE'
        : item.isLowStock
            ? 'STOCK FAIBLE'
            : 'DISPONIBLE';
    final statusColor = item.isOutOfStock
        ? Colors.red
        : item.isLowStock
            ? Colors.orange
            : Colors.green;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(item);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: 2,
        child: ListTile(
          leading: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: _getItemColor(item),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getItemIcon(item.category),
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  stockStatus,
                  style: TextStyle(
                    fontSize: 9,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.category, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.category,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.location,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.person, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.supplierName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Stock: ${item.quantity} unités',
                      style: TextStyle(
                        fontSize: 12,
                        color: item.isLowStock ? Colors.orange : Colors.grey,
                        fontWeight: item.isLowStock
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.sellingPrice} FCFA',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (item.isLowStock && !item.isOutOfStock)
                Text(
                  '⚠️ Stock minimum: ${item.minStockLevel}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => _handleInventoryMenu(value, item),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue, size: 18),
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
              const PopupMenuItem(
                value: 'adjust',
                child: Row(
                  children: [
                    Icon(Icons.tune, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Ajuster stock',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'restock',
                child: Row(
                  children: [
                    Icon(Icons.inventory, color: Colors.orange, size: 18),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Réapprovisionner',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 18),
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
          onTap: () => _showItemDetails(item),
        ),
      ),
    );
  }

  Color _getItemColor(InventoryItem item) {
    if (item.isOutOfStock) return Colors.red;
    if (item.isLowStock) return Colors.orange;
    return Colors.blue;
  }

  IconData _getItemIcon(String category) {
    switch (category.toLowerCase()) {
      case 'filtration':
        return Icons.filter_alt;
      case 'freinage':
        return Icons.car_repair;
      case 'pneus':
        return Icons.settings;
      case 'moteur':
        return Icons.engineering;
      case 'électricité':
        return Icons.electrical_services;
      case 'carrosserie':
        return Icons.build;
      default:
        return Icons.inventory_2;
    }
  }

  void _showSearchBar() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _handleAppBarMenu(String value) {
    switch (value) {
      case 'import':
        _showImportDialog();
        break;
      case 'export':
        _exportInventory();
        break;
      case 'refresh':
        _loadInventory();
        break;
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer l\'inventaire'),
        content:
            const Text('Fonctionnalité d\'import en cours de développement...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _exportInventory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export de l\'inventaire réussi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showItemDetails(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Détails - ${item.name}',
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Description:', item.description),
              _buildDetailRow('Catégorie:', item.category),
              _buildDetailRow('Fournisseur:', item.supplierName),
              _buildDetailRow('Emplacement:', item.location),
              _buildDetailRow('Prix d\'achat:', '${item.purchasePrice} F CFA'),
              _buildDetailRow('Prix de vente:', '${item.sellingPrice} F CFA'),
              _buildDetailRow('Quantité:', '${item.quantity}'),
              _buildDetailRow('Stock minimum:', '${item.minStockLevel}'),
              _buildDetailRow('Valeur stock:',
                  '${item.totalValue.toStringAsFixed(0)} F CFA'),
              _buildDetailRow('Profit potentiel:',
                  '${item.potentialProfit.toStringAsFixed(0)} F CFA'),
              _buildDetailRow(
                  'Dernier réappro:', _formatDate(item.lastRestocked)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _adjustStock(item);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'Ajuster Stock',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _addInventoryItem() {
    _showInventoryForm();
  }

  void _editInventoryItem(InventoryItem item) {
    _showInventoryForm(item: item);
  }

  void _showInventoryForm({InventoryItem? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final categoryController =
        TextEditingController(text: item?.category ?? '');
    final descriptionController =
        TextEditingController(text: item?.description ?? '');
    final purchasePriceController =
        TextEditingController(text: item?.purchasePrice.toString() ?? '');
    final sellingPriceController =
        TextEditingController(text: item?.sellingPrice.toString() ?? '');
    final quantityController =
        TextEditingController(text: item?.quantity.toString() ?? '');
    final minStockController =
        TextEditingController(text: item?.minStockLevel.toString() ?? '');
    final locationController =
        TextEditingController(text: item?.location ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          item == null ? 'Nouvel Article' : 'Modifier Article',
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Nom de l\'article *'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Catégorie *'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              TextField(
                controller: purchasePriceController,
                decoration: const InputDecoration(labelText: 'Prix d\'achat *'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: sellingPriceController,
                decoration: const InputDecoration(labelText: 'Prix de vente *'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantité *'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: minStockController,
                decoration: const InputDecoration(labelText: 'Stock minimum *'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Emplacement'),
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
              _saveInventoryItem(
                nameController.text,
                categoryController.text,
                descriptionController.text,
                purchasePriceController.text,
                sellingPriceController.text,
                quantityController.text,
                minStockController.text,
                locationController.text,
                item?.id,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text(
              item == null ? 'Ajouter' : 'Modifier',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _saveInventoryItem(
    String name,
    String category,
    String description,
    String purchasePrice,
    String sellingPrice,
    String quantity,
    String minStock,
    String location,
    String? existingId,
  ) {
    if (name.isEmpty ||
        category.isEmpty ||
        purchasePrice.isEmpty ||
        sellingPrice.isEmpty ||
        quantity.isEmpty) {
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
        final index = _inventory.indexWhere((item) => item.id == existingId);
        if (index != -1) {
          _inventory[index] = _inventory[index].copyWith(
            name: name,
            category: category,
            description: description,
            purchasePrice: double.tryParse(purchasePrice) ?? 0,
            sellingPrice: double.tryParse(sellingPrice) ?? 0,
            quantity: int.tryParse(quantity) ?? 0,
            minStockLevel: int.tryParse(minStock) ?? 0,
            location: location,
          );
        }
      } else {
        final newItem = InventoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          category: category,
          description: description,
          purchasePrice: double.tryParse(purchasePrice) ?? 0,
          sellingPrice: double.tryParse(sellingPrice) ?? 0,
          quantity: int.tryParse(quantity) ?? 0,
          minStockLevel: int.tryParse(minStock) ?? 0,
          supplierId: '1',
          supplierName: 'Fournisseur principal',
          location: location,
          lastRestocked: DateTime.now(),
          createdAt: DateTime.now(),
        );
        _inventory.add(newItem);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(existingId == null
            ? 'Article ajouté avec succès'
            : 'Article modifié avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _adjustStock(InventoryItem item) {
    final quantityController =
        TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Ajuster stock - ${item.name}',
          overflow: TextOverflow.ellipsis,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stock actuel: ${item.quantity}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Nouvelle quantité *',
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
              final newQuantity = int.tryParse(quantityController.text);
              if (newQuantity != null && newQuantity >= 0) {
                _updateItemQuantity(item, newQuantity);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'Mettre à jour',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _updateItemQuantity(InventoryItem item, int newQuantity) {
    setState(() {
      final index = _inventory.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _inventory[index] = _inventory[index].copyWith(
          quantity: newQuantity,
          lastRestocked: DateTime.now(),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stock mis à jour avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleInventoryMenu(String value, InventoryItem item) {
    switch (value) {
      case 'edit':
        _editInventoryItem(item);
        break;
      case 'adjust':
        _adjustStock(item);
        break;
      case 'restock':
        _restockItem(item);
        break;
      case 'delete':
        _deleteInventoryItem(item);
        break;
    }
  }

  void _restockItem(InventoryItem item) {
    final suggestedQuantity = item.minStockLevel * 2;
    final quantityController =
        TextEditingController(text: suggestedQuantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Réapprovisionner - ${item.name}',
          overflow: TextOverflow.ellipsis,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stock actuel: ${item.quantity} (Min: ${item.minStockLevel})'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité à ajouter *',
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
              final quantityToAdd = int.tryParse(quantityController.text);
              if (quantityToAdd != null && quantityToAdd > 0) {
                _updateItemQuantity(item, item.quantity + quantityToAdd);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'Réapprovisionner',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteInventoryItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'article'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${item.name} ? Cette action est irréversible.',
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
                _inventory.removeWhere((i) => i.id == item.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} a été supprimé'),
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

  Future<bool> _showDeleteConfirmation(InventoryItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'article'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${item.name} ? Cette action est irréversible.',
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
