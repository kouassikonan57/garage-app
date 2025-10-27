import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simple_auth_service.dart';
import '../models/supplier_model.dart';
import '../models/user_model.dart';

class SuppliersManagement extends StatefulWidget {
  const SuppliersManagement({super.key});

  @override
  _SuppliersManagementState createState() => _SuppliersManagementState();
}

class _SuppliersManagementState extends State<SuppliersManagement> {
  List<Supplier> _suppliers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _checkingAccess = true;
  bool _isGarage = false;
  bool _isLoading = true;
  String _selectedCategory = 'all';
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _checkGarageAccess();
  }

  Future<void> _checkGarageAccess() async {
    try {
      print('🔐 Vérification des accès garage pour fournisseurs...');

      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);
      final currentUser = await authService.getCurrentAppUser();

      if (currentUser != null && currentUser.userType == UserType.garage) {
        print('✅ Accès garage autorisé pour les fournisseurs');
        setState(() {
          _isGarage = true;
          _checkingAccess = false;
        });
        _loadSuppliers();
      } else {
        print('❌ Accès garage refusé pour les fournisseurs');
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
      print('❌ Erreur vérification accès fournisseurs: $e');
      setState(() {
        _checkingAccess = false;
        _isGarage = false;
      });
    }
  }

  void _loadSuppliers() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _suppliers = [];
        _isLoading = false;
      });
    });
  }

  bool _isSupplierActive(Supplier supplier) {
    final daysSinceLastOrder =
        DateTime.now().difference(supplier.lastOrderDate).inDays;
    return daysSinceLastOrder <= 30;
  }

  List<Supplier> get _filteredSuppliers {
    List<Supplier> filtered = _suppliers;

    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((supplier) {
        return supplier.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            supplier.contactPerson
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            supplier.phone.contains(_searchController.text) ||
            supplier.email
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            supplier.suppliedParts.any((part) => part
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()));
      }).toList();
    }

    switch (_selectedCategory) {
      case 'active':
        filtered = filtered.where((s) => _isSupplierActive(s)).toList();
        break;
      case 'inactive':
        filtered = filtered.where((s) => !_isSupplierActive(s)).toList();
        break;
      case 'high_rating':
        filtered = filtered.where((s) => s.rating >= 4.0).toList();
        break;
    }

    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'last_order':
        filtered.sort((a, b) => b.lastOrderDate.compareTo(a.lastOrderDate));
        break;
      case 'date_added':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
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
        title: const Text('Gestion des Fournisseurs'),
        backgroundColor: Colors.purple,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleAppBarMenu(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload, color: Colors.blue),
                    SizedBox(width: 6),
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
      ),
      body: Column(
        children: [
          _buildStatsHeader(),
          _buildSearchBar(),
          _buildFiltersBar(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredSuppliers.isEmpty
                    ? _buildEmptyState()
                    : _buildSuppliersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSupplier,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text(
          'Nouveau',
          style: TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final activeSuppliers =
        _suppliers.where((s) => _isSupplierActive(s)).length;
    final totalParts = _suppliers.fold(
        0, (sum, supplier) => sum + supplier.suppliedParts.length);
    final averageRating = _suppliers.isEmpty
        ? 0.0
        : _suppliers.map((s) => s.rating).reduce((a, b) => a + b) /
            _suppliers.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple[50]!, Colors.purple[100]!],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                  _suppliers.length.toString(), 'Fournisseurs', Icons.business),
              _buildStatCard(
                  activeSuppliers.toString(), 'Actifs', Icons.check_circle),
              _buildStatCard(
                  totalParts.toString(), 'Pièces', Icons.inventory_2),
              _buildStatCard(
                  averageRating.toStringAsFixed(1), 'Note', Icons.star),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Gérez vos relations avec vos fournisseurs',
            style: TextStyle(fontSize: 12, color: Colors.purple[700]),
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
                hintText: 'Rechercher un fournisseur...',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.purple),
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
                  borderSide: BorderSide(color: Colors.purple.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide:
                      BorderSide(color: Colors.purple.shade500, width: 2),
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

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.purple,
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
            color: Colors.purple,
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
                  value: _selectedCategory,
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(
                        'Tous',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'active',
                      child: Text(
                        'Actifs',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text(
                        'Inactifs',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'high_rating',
                      child: Text(
                        'Bien notés',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                    labelText: 'Filtrer par',
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
                      value: 'name',
                      child: Text(
                        'Nom A-Z',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'rating',
                      child: Text(
                        'Note',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'last_order',
                      child: Text(
                        'Dernière cmd',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'date_added',
                      child: Text(
                        'Date ajout',
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

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 3,
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
            Icon(Icons.business_center, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Aucun fournisseur'
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
                    ? 'Commencez par ajouter vos fournisseurs de pièces auto'
                    : 'Aucun fournisseur ne correspond à "${_searchController.text}"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addSupplier,
              icon: const Icon(Icons.add_business),
              label: Text(
                _searchController.text.isEmpty
                    ? 'Ajouter premier fournisseur'
                    : 'Ajouter fournisseur',
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
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

  Widget _buildSuppliersList() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadSuppliers();
      },
      child: Column(
        children: [
          if (_searchController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.purple[50],
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: Colors.purple[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_filteredSuppliers.length} résultat(s) pour "${_searchController.text}"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple[700],
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
                        color: Colors.purple[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredSuppliers.length,
              itemBuilder: (context, index) {
                final supplier = _filteredSuppliers[index];
                return _buildSupplierCard(supplier);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(Supplier supplier) {
    final isActive = _isSupplierActive(supplier);
    final daysSinceLastOrder =
        DateTime.now().difference(supplier.lastOrderDate).inDays;

    return Dismissible(
      key: Key(supplier.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(supplier);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: 2,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isActive ? Colors.purple[100] : Colors.grey[300],
            child: Icon(
              Icons.business,
              color: isActive ? Colors.purple : Colors.grey,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  supplier.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              Row(
                children: [
                  Icon(Icons.person, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      supplier.contactPerson,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      supplier.phone,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: supplier.suppliedParts.take(2).map((part) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      part,
                      style: const TextStyle(fontSize: 9, color: Colors.purple),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildRatingStars(supplier.rating),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      daysSinceLastOrder == 0
                          ? 'Aujourd\'hui'
                          : daysSinceLastOrder == 1
                              ? 'Hier'
                              : '$daysSinceLastOrder j',
                      style: TextStyle(
                        fontSize: 11,
                        color: daysSinceLastOrder > 30
                            ? Colors.orange
                            : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => _handlePopupMenu(value, supplier),
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
              const PopupMenuItem(
                value: 'contact',
                child: Row(
                  children: [
                    Icon(Icons.phone, color: Colors.green, size: 16),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Contacter',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'order',
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.orange, size: 16),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Commander',
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
          onTap: () => _showSupplierDetails(supplier),
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 14,
        );
      }),
    );
  }

  void _showSupplierDetails(Supplier supplier) {
    final isActive = _isSupplierActive(supplier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Détails - ${supplier.name}',
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Contact:', supplier.contactPerson),
              _buildDetailRow('Téléphone:', supplier.phone),
              _buildDetailRow('Email:', supplier.email),
              _buildDetailRow('Adresse:', supplier.address),
              _buildDetailRow('Conditions:', supplier.paymentTerms),
              _buildDetailRow('Note:', '${supplier.rating}/5'),
              _buildDetailRow('Statut:', isActive ? 'Actif' : 'Inactif'),
              _buildDetailRow(
                  'Pièces fournies:', supplier.suppliedParts.join(', ')),
              _buildDetailRow(
                  'Dernière commande:', _formatDate(supplier.lastOrderDate)),
              _buildDetailRow('Ajouté le:', _formatDate(supplier.createdAt)),
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
              _contactSupplier(supplier);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text(
              'Contacter',
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

  void _contactSupplier(Supplier supplier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contactez ${supplier.name} au ${supplier.phone}'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _addSupplier() {
    _showSupplierForm();
  }

  void _editSupplier(Supplier supplier) {
    _showSupplierForm(supplier: supplier);
  }

  void _showSupplierForm({Supplier? supplier}) {
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final contactController =
        TextEditingController(text: supplier?.contactPerson ?? '');
    final phoneController = TextEditingController(text: supplier?.phone ?? '');
    final emailController = TextEditingController(text: supplier?.email ?? '');
    final addressController =
        TextEditingController(text: supplier?.address ?? '');
    final paymentTermsController =
        TextEditingController(text: supplier?.paymentTerms ?? '30 jours');
    final partsController =
        TextEditingController(text: supplier?.suppliedParts.join(', ') ?? '');
    final ratingController =
        TextEditingController(text: supplier?.rating.toString() ?? '0.0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          supplier == null ? 'Nouveau Fournisseur' : 'Modifier Fournisseur',
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Nom du fournisseur *'),
              ),
              TextField(
                controller: contactController,
                decoration:
                    const InputDecoration(labelText: 'Personne à contacter *'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Téléphone *'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
              TextField(
                controller: paymentTermsController,
                decoration:
                    const InputDecoration(labelText: 'Conditions de paiement'),
              ),
              TextField(
                controller: ratingController,
                decoration: const InputDecoration(labelText: 'Note (0-5)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: partsController,
                decoration: const InputDecoration(
                  labelText: 'Pièces fournies',
                  hintText: 'Séparez par des virgules',
                ),
                maxLines: 2,
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
              _saveSupplier(
                nameController.text,
                contactController.text,
                phoneController.text,
                emailController.text,
                addressController.text,
                paymentTermsController.text,
                partsController.text,
                double.tryParse(ratingController.text) ?? 0.0,
                supplier?.id,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: Text(
              supplier == null ? 'Ajouter' : 'Modifier',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSupplier(
    String name,
    String contactPerson,
    String phone,
    String email,
    String address,
    String paymentTerms,
    String parts,
    double rating,
    String? existingId,
  ) {
    if (name.isEmpty || contactPerson.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir les champs obligatoires (*)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final partsList = parts
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    setState(() {
      if (existingId != null) {
        final index = _suppliers.indexWhere((s) => s.id == existingId);
        if (index != -1) {
          _suppliers[index] = _suppliers[index].copyWith(
            name: name,
            contactPerson: contactPerson,
            phone: phone,
            email: email,
            address: address,
            suppliedParts: partsList,
            rating: rating,
            paymentTerms: paymentTerms,
          );
        }
      } else {
        final newSupplier = Supplier(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          contactPerson: contactPerson,
          phone: phone,
          email: email,
          address: address,
          suppliedParts: partsList,
          rating: rating,
          paymentTerms: paymentTerms,
          lastOrderDate: DateTime.now(),
          createdAt: DateTime.now(),
        );
        _suppliers.add(newSupplier);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(existingId == null
            ? 'Fournisseur ajouté avec succès'
            : 'Fournisseur modifié avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(Supplier supplier) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le fournisseur'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${supplier.name} ? Cette action est irréversible.',
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

  void _handlePopupMenu(String value, Supplier supplier) {
    switch (value) {
      case 'edit':
        _editSupplier(supplier);
        break;
      case 'contact':
        _contactSupplier(supplier);
        break;
      case 'order':
        _createNewOrder(supplier);
        break;
      case 'delete':
        _deleteSupplier(supplier);
        break;
    }
  }

  void _deleteSupplier(Supplier supplier) {
    setState(() {
      _suppliers.removeWhere((s) => s.id == supplier.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${supplier.name} a été supprimé'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleAppBarMenu(String value) {
    switch (value) {
      case 'import':
        _showImportDialog();
        break;
      case 'export':
        _exportSuppliers();
        break;
      case 'refresh':
        _loadSuppliers();
        break;
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer des fournisseurs'),
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

  void _exportSuppliers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export des fournisseurs réussi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _createNewOrder(Supplier supplier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nouvelle commande pour ${supplier.name}'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
