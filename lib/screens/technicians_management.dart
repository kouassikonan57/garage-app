import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/technician_model.dart';
import '../services/technician_service.dart';
import '../services/simple_auth_service.dart';
import '../models/user_model.dart';
import 'dart:convert'; // Pour base64Encode et base64Decode

class TechniciansManagement extends StatefulWidget {
  const TechniciansManagement({super.key});

  @override
  _TechniciansManagementState createState() => _TechniciansManagementState();
}

class _TechniciansManagementState extends State<TechniciansManagement> {
  final TechnicianService _technicianService = TechnicianService();
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<Technician> _technicians = [];
  List<Technician> _filteredTechnicians = [];
  bool _isLoading = true;
  String? _garageId;

  // Variables pour gérer l'image
  XFile? _selectedImage;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _getCurrentGarage();
  }

  void _getCurrentGarage() async {
    final authService = Provider.of<SimpleAuthService>(context, listen: false);
    final currentUser = await authService.getCurrentAppUser();

    if (currentUser != null && currentUser.userType == UserType.garage) {
      setState(() {
        _garageId = currentUser.uid;
      });
      _loadTechnicians();
    }
  }

  Future<void> _loadTechnicians() async {
    if (_garageId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final technicians = await _technicianService.getTechnicians(_garageId!);
      setState(() {
        _technicians = technicians;
        _filteredTechnicians = technicians;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement techniciens: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du chargement des techniciens'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterTechnicians(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTechnicians = _technicians;
      } else {
        _filteredTechnicians = _technicians.where((technician) {
          return technician.name.toLowerCase().contains(query.toLowerCase()) ||
              technician.specialty
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              technician.skills.any((skill) =>
                  skill.toLowerCase().contains(query.toLowerCase())) ||
              technician.certifications.any(
                  (cert) => cert.toLowerCase().contains(query.toLowerCase())) ||
              (technician.address != null &&
                  technician.address!
                      .toLowerCase()
                      .contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  // Méthode pour sélectionner une image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      print('❌ Erreur sélection image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode simplifiée pour gérer les images (sans Firebase Storage)
  // Méthode pour convertir l'image en base64
  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return null;

    try {
      // Convertir les bytes en base64
      final String base64Image = base64Encode(_imageBytes!);

      // Déterminer le type MIME de l'image
      String mimeType = 'image/jpeg'; // Par défaut
      if (_selectedImage != null) {
        if (_selectedImage!.name.toLowerCase().endsWith('.png')) {
          mimeType = 'image/png';
        } else if (_selectedImage!.name.toLowerCase().endsWith('.gif')) {
          mimeType = 'image/gif';
        } else if (_selectedImage!.name.toLowerCase().endsWith('.webp')) {
          mimeType = 'image/webp';
        }
      }

      // Créer l'URL de données (data URL)
      return 'data:$mimeType;base64,$base64Image';
    } catch (e) {
      print('❌ Erreur conversion image base64: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Techniciens'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTechnicians,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _garageId == null
          ? _buildNoGarageState()
          : _isLoading
              ? _buildLoadingState()
              : _buildMainContent(),
      floatingActionButton: _garageId != null
          ? FloatingActionButton(
              onPressed: _addTechnician,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildNoGarageState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          SizedBox(height: 20),
          Text(
            'Accès non autorisé',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text('Cette fonctionnalité est réservée aux garages'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Chargement des techniciens...'),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildStatsHeader(),
        Expanded(
          child: _technicians.isEmpty
              ? _buildEmptyState()
              : _filteredTechnicians.isEmpty
                  ? _buildNoResultsState()
                  : _buildTechniciansList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un technicien...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterTechnicians('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
        ),
        onChanged: _filterTechnicians,
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalTechnicians = _technicians.length;
    final availableTechnicians =
        _technicians.where((t) => t.isAvailable).length;
    final totalJobs = _technicians.fold(0, (sum, t) => sum + t.completedJobs);
    final averageExperience = _technicians.isEmpty
        ? 0
        : _technicians.fold(0, (sum, t) => sum + t.experience) /
            _technicians.length;
    final certifiedTechnicians =
        _technicians.where((t) => t.hasCertifications).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade50, Colors.orange.shade100],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
              totalTechnicians.toString(), 'Techniciens', Icons.people),
          _buildStatCard(availableTechnicians.toString(), 'Disponibles',
              Icons.check_circle),
          _buildStatCard('${_calculateAverageRating()}', 'Moyenne', Icons.star),
          _buildStatCard(totalJobs.toString(), 'Travaux', Icons.work),
          _buildStatCard('${averageExperience.toStringAsFixed(1)}', 'Ans moy.',
              Icons.timeline),
          _buildStatCard(
              certifiedTechnicians.toString(), 'Certifiés', Icons.verified),
        ],
      ),
    );
  }

  String _calculateAverageRating() {
    if (_technicians.isEmpty) return '0.0';
    final total = _technicians.map((t) => t.rating).reduce((a, b) => a + b);
    return (total / _technicians.length).toStringAsFixed(1);
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration:
              const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.engineering, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text('Aucun technicien',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ajoutez votre premier technicien pour gérer votre équipe',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _addTechnician,
            icon: const Icon(Icons.person_add),
            label: const Text('Ajouter un technicien'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text('Aucun résultat pour "${_searchController.text}"',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              _searchController.clear();
              _filterTechnicians('');
            },
            child: const Text('Effacer la recherche'),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniciansList() {
    return RefreshIndicator(
      onRefresh: _loadTechnicians,
      child: ListView.builder(
        itemCount: _filteredTechnicians.length,
        itemBuilder: (context, index) {
          final technician = _filteredTechnicians[index];
          return _buildTechnicianCard(technician);
        },
      ),
    );
  }

  Widget _buildTechnicianCard(Technician technician) {
    final statusColor = technician.isAvailable ? Colors.green : Colors.red;
    final statusBgColor =
        technician.isAvailable ? Colors.green.shade50 : Colors.red.shade50;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: _buildTechnicianAvatar(technician),
        title: Text(technician.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(technician.specialty,
                    style: TextStyle(
                        color: Colors.grey[600], fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                if (technician.hasCertifications)
                  Icon(Icons.verified, size: 14, color: Colors.blue),
                if (technician.expertiseLevel.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: _getExpertiseColor(technician.expertiseLevel),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(technician.expertiseLevel[0],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(technician.phone,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(width: 12),
                Icon(Icons.email, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(technician.email,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (technician.experience > 0) ...[
                  Icon(Icons.work, size: 12, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text('${technician.experience} ans',
                      style: const TextStyle(fontSize: 11, color: Colors.blue)),
                  const SizedBox(width: 8),
                ],
                if (technician.completedJobs > 0) ...[
                  Icon(Icons.check_circle, size: 12, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('${technician.completedJobs} travaux',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.green)),
                ],
              ],
            ),
            if (technician.skills.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: technician.mainSkills
                    .map((skill) => Chip(
                          label: Text(skill),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text('${technician.rating}'),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    technician.isAvailable ? 'Disponible' : 'Occupé',
                    style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleTechnicianMenu(value, technician),
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'details',
                child: Row(children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Détails')
                ])),
            PopupMenuItem(
                value: 'toggle_availability',
                child: Row(children: [
                  Icon(technician.isAvailable ? Icons.pause : Icons.play_arrow,
                      color: technician.isAvailable
                          ? Colors.orange
                          : Colors.green),
                  const SizedBox(width: 8),
                  Text(technician.isAvailable
                      ? 'Rendre indisponible'
                      : 'Rendre disponible'),
                ])),
            const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Modifier')
                ])),
            const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer')
                ])),
          ],
        ),
        onTap: () => _showTechnicianDetails(technician),
      ),
    );
  }

  Color _getExpertiseColor(String level) {
    switch (level) {
      case 'Expert':
        return Colors.red;
      case 'Senior':
        return Colors.orange;
      case 'Intermédiaire':
        return Colors.blue;
      case 'Débutant':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTechnicianAvatar(Technician technician) {
    if (technician.hasProfileImage) {
      // Vérifier si c'est une image base64
      if (technician.isBase64Image) {
        try {
          // Extraire les données base64 de l'URL de données
          final String base64String = technician.profileImage!.split(',').last;
          final Uint8List bytes = base64Decode(base64String);

          return CircleAvatar(
            radius: 20,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (e) {
          print('❌ Erreur décodage image base64: $e');
          return _buildDefaultAvatar(technician);
        }
      } else {
        // C'est une URL normale
        return CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(technician.profileImage!),
          onBackgroundImageError: (exception, stackTrace) {
            print('❌ Erreur chargement image réseau: $exception');
          },
        );
      }
    }
    return _buildDefaultAvatar(technician);
  }

  Widget _buildDefaultAvatar(Technician technician) {
    return CircleAvatar(
      backgroundColor: Colors.orange.shade100,
      child: Text(
        technician.name.isNotEmpty ? technician.name[0].toUpperCase() : 'T',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  void _handleTechnicianMenu(String value, Technician technician) {
    switch (value) {
      case 'details':
        _showTechnicianDetails(technician);
        break;
      case 'toggle_availability':
        _toggleTechnicianAvailability(technician);
        break;
      case 'edit':
        _editTechnician(technician);
        break;
      case 'delete':
        _deleteTechnician(technician);
        break;
    }
  }

  void _toggleTechnicianAvailability(Technician technician) async {
    try {
      await _technicianService.toggleTechnicianAvailability(
          technician.id, !technician.isAvailable);
      _loadTechnicians();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${technician.name} est maintenant ${technician.isAvailable ? 'indisponible' : 'disponible'}'),
        backgroundColor: Colors.orange,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erreur lors du changement de disponibilité'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showTechnicianDetails(Technician technician) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${technician.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  child: _buildDetailAvatar(technician),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Spécialité:', technician.specialty),
              _buildDetailRow('Téléphone:', technician.phone),
              _buildDetailRow('Email:', technician.email),
              _buildDetailRow('Note:', '${technician.formattedRating}/5'),
              _buildDetailRow('Expérience:', technician.formattedExperience),
              _buildDetailRow('Niveau:', technician.expertiseLevel),
              _buildDetailRow(
                  'Travaux complétés:', technician.formattedCompletedJobs),
              _buildDetailRow(
                  'Compétences:',
                  technician.skills.isNotEmpty
                      ? technician.skills.join(', ')
                      : 'Aucune'),
              if (technician.certifications.isNotEmpty)
                _buildDetailRow(
                    'Certifications:', technician.certifications.join(', ')),
              if (technician.address != null && technician.address!.isNotEmpty)
                _buildDetailRow('Adresse:', technician.address!),
              if (technician.workingHours != null &&
                  technician.workingHours!.isNotEmpty)
                _buildDetailRow('Heures de travail:', technician.workingHours!),
              if (technician.bio != null && technician.bio!.isNotEmpty)
                _buildDetailRow('Bio:', technician.bio!),
              if (technician.createdAt != null)
                _buildDetailRow('Créé le:',
                    '${technician.createdAt!.day}/${technician.createdAt!.month}/${technician.createdAt!.year}'),
              _buildDetailRow('Statut:',
                  technician.isAvailable ? '🟢 Disponible' : '🔴 Indisponible'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
          ElevatedButton(
            onPressed: () => _editTechnician(technician),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailAvatar(Technician technician) {
    if (technician.hasProfileImage) {
      // Vérifier si c'est une image base64
      if (technician.profileImage!.startsWith('data:image')) {
        try {
          // Extraire les données base64 de l'URL de données
          final String base64String = technician.profileImage!.split(',').last;
          final Uint8List bytes = base64Decode(base64String);

          return ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                print('❌ Erreur affichage image base64: $error');
                return _buildDefaultDetailAvatar(technician);
              },
            ),
          );
        } catch (e) {
          print('❌ Erreur décodage image base64: $e');
          return _buildDefaultDetailAvatar(technician);
        }
      } else {
        // C'est une URL normale
        return ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: Image.network(
            technician.profileImage!,
            fit: BoxFit.cover,
            width: 120,
            height: 120,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('❌ Erreur chargement image réseau: $error');
              return _buildDefaultDetailAvatar(technician);
            },
          ),
        );
      }
    }
    return _buildDefaultDetailAvatar(technician);
  }

  Widget _buildDefaultDetailAvatar(Technician technician) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Center(
        child: Text(
          technician.name.isNotEmpty ? technician.name[0].toUpperCase() : 'T',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _addTechnician() {
    final nameController = TextEditingController();
    final specialtyController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final experienceController = TextEditingController();
    final addressController = TextEditingController();
    final workingHoursController = TextEditingController();
    final skillsController = TextEditingController();
    final certificationsController = TextEditingController();
    final bioController = TextEditingController();
    final profileImageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Ajouter un technicien'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Section Image de profil
                  Column(
                    children: [
                      // Aperçu de l'image
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? Image.memory(_imageBytes!,
                                        fit: BoxFit.cover)
                                    : _selectedImage != null
                                        ? Image.file(File(_selectedImage!.path),
                                            fit: BoxFit.cover)
                                        : const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.person,
                                                  size: 40, color: Colors.grey),
                                              SizedBox(height: 4),
                                              Text('Aucune image',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey)),
                                            ],
                                          ),
                              )
                            : profileImageController.text.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                        profileImageController.text,
                                        fit: BoxFit.cover, errorBuilder:
                                            (context, error, stackTrace) {
                                      return const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error,
                                              size: 30, color: Colors.red),
                                          SizedBox(height: 4),
                                          Text('Erreur image',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.red)),
                                        ],
                                      );
                                    }),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person,
                                          size: 40, color: Colors.grey),
                                      SizedBox(height: 4),
                                      Text('Aucune image',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey)),
                                    ],
                                  ),
                      ),
                      const SizedBox(height: 12),
                      // Champ URL manuel
                      TextField(
                        controller: profileImageController,
                        decoration: const InputDecoration(
                          labelText: 'URL de l\'image de profil',
                          border: OutlineInputBorder(),
                          hintText: 'https://example.com/image.jpg',
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            // Réinitialiser l'image locale si on utilise une URL
                            if (value.isNotEmpty) {
                              _selectedImage = null;
                              _imageBytes = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // OU - Boutons de sélection d'image locale
                      const Text('OU sélectionner une image:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _pickImage(ImageSource.gallery);
                                setDialogState(() {
                                  // Effacer l'URL si on sélectionne une image locale
                                  profileImageController.clear();
                                });
                              },
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galerie'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!kIsWeb) // La caméra n'est pas disponible sur le web
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _pickImage(ImageSource.camera);
                                  setDialogState(() {
                                    profileImageController.clear();
                                  });
                                },
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Caméra'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_imageBytes != null) ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              _selectedImage = null;
                              _imageBytes = null;
                            });
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Supprimer l\'image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          kIsWeb
                              ? '✅ L\'image sera sauvegardée dans votre base de données'
                              : '✅ L\'image sera sauvegardée dans votre base de données',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Autres champs du formulaire
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: specialtyController,
                    decoration: const InputDecoration(
                      labelText: 'Spécialité *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: experienceController,
                    decoration: const InputDecoration(
                      labelText: 'Années d\'expérience',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: workingHoursController,
                    decoration: const InputDecoration(
                      labelText: 'Heures de travail (ex: 9h-18h)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: skillsController,
                    decoration: const InputDecoration(
                        labelText: 'Compétences (séparées par des virgules)',
                        border: OutlineInputBorder(),
                        hintText: 'ex: Mécanique, Électricité, Diagnostic'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: certificationsController,
                    decoration: const InputDecoration(
                        labelText: 'Certifications (séparées par des virgules)',
                        border: OutlineInputBorder(),
                        hintText: 'ex: ASE, Bosch, Delphi'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Réinitialiser les variables d'image
                  _selectedImage = null;
                  _imageBytes = null;
                  Navigator.pop(context);
                },
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      specialtyController.text.isEmpty ||
                      phoneController.text.isEmpty ||
                      emailController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Veuillez remplir les champs obligatoires (*)'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    String? finalImageUrl;

                    // CORRECTION : Priorité à l'image locale sélectionnée
                    if (_imageBytes != null) {
                      // Uploader l'image sélectionnée (convertir en base64)
                      finalImageUrl = await _uploadImage();
                    } else if (profileImageController.text.isNotEmpty) {
                      // Utiliser l'URL manuelle si fournie
                      finalImageUrl = profileImageController.text;
                    }
                    // Si aucune image n'est fournie, finalImageUrl reste null

                    // Convertir les compétences et certifications en List<String>
                    final List<String> skills = skillsController.text.isNotEmpty
                        ? skillsController.text
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList()
                        : [];

                    final List<String> certifications =
                        certificationsController.text.isNotEmpty
                            ? certificationsController.text
                                .split(',')
                                .map((s) => s.trim())
                                .where((s) => s.isNotEmpty)
                                .toList()
                            : [];

                    final newTechnician = Technician(
                      id: '', // Firestore générera l'ID
                      name: nameController.text,
                      specialty: specialtyController.text,
                      phone: phoneController.text,
                      email: emailController.text,
                      skills: skills,
                      garageId: _garageId!,
                      experience: int.tryParse(experienceController.text) ?? 0,
                      profileImage:
                          finalImageUrl, // Peut être null, base64 ou URL
                      address: addressController.text.isEmpty
                          ? null
                          : addressController.text,
                      bio: bioController.text.isEmpty
                          ? null
                          : bioController.text,
                      workingHours: workingHoursController.text.isEmpty
                          ? null
                          : workingHoursController.text,
                      certifications: certifications,
                    );

                    await _technicianService.addTechnician(newTechnician);

                    // Réinitialiser les variables d'image
                    _selectedImage = null;
                    _imageBytes = null;

                    Navigator.pop(context);
                    _loadTechnicians();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Technicien ajouté avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print('❌ Erreur ajout technicien: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de l\'ajout: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Ajouter',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editTechnician(Technician technician) {
    final nameController = TextEditingController(text: technician.name);
    final specialtyController =
        TextEditingController(text: technician.specialty);
    final phoneController = TextEditingController(text: technician.phone);
    final emailController = TextEditingController(text: technician.email);
    final experienceController =
        TextEditingController(text: technician.experience.toString());
    final addressController =
        TextEditingController(text: technician.address ?? '');
    final workingHoursController =
        TextEditingController(text: technician.workingHours ?? '');
    final skillsController =
        TextEditingController(text: technician.skills.join(', '));
    final certificationsController =
        TextEditingController(text: technician.certifications.join(', '));
    final bioController = TextEditingController(text: technician.bio ?? '');
    final profileImageController =
        TextEditingController(text: technician.profileImage ?? '');

    // Sauvegarder l'image originale
    final String? originalImageUrl = technician.profileImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Modifier le technicien'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Section Image de profil
                  Column(
                    children: [
                      // Aperçu de l'image
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? Image.memory(_imageBytes!,
                                        fit: BoxFit.cover)
                                    : _selectedImage != null
                                        ? Image.file(File(_selectedImage!.path),
                                            fit: BoxFit.cover)
                                        : const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.person,
                                                  size: 40, color: Colors.grey),
                                              SizedBox(height: 4),
                                              Text('Aucune image',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey)),
                                            ],
                                          ),
                              )
                            : profileImageController.text.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                        profileImageController.text,
                                        fit: BoxFit.cover, errorBuilder:
                                            (context, error, stackTrace) {
                                      return const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error,
                                              size: 30, color: Colors.red),
                                          SizedBox(height: 4),
                                          Text('Erreur image',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.red)),
                                        ],
                                      );
                                    }),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person,
                                          size: 40, color: Colors.grey),
                                      SizedBox(height: 4),
                                      Text('Aucune image',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey)),
                                    ],
                                  ),
                      ),
                      const SizedBox(height: 12),
                      // Champ URL manuel
                      TextField(
                        controller: profileImageController,
                        decoration: const InputDecoration(
                          labelText: 'URL de l\'image de profil',
                          border: OutlineInputBorder(),
                          hintText: 'https://example.com/image.jpg',
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value.isNotEmpty) {
                              _selectedImage = null;
                              _imageBytes = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // OU - Boutons de sélection d'image locale
                      const Text('OU sélectionner une image:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _pickImage(ImageSource.gallery);
                                setDialogState(() {
                                  profileImageController.clear();
                                });
                              },
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galerie'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!kIsWeb)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _pickImage(ImageSource.camera);
                                  setDialogState(() {
                                    profileImageController.clear();
                                  });
                                },
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Caméra'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_imageBytes != null) ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              _selectedImage = null;
                              _imageBytes = null;
                            });
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Supprimer l\'image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          kIsWeb
                              ? '✅ L\'image sera sauvegardée dans votre base de données'
                              : '✅ L\'image sera sauvegardée dans votre base de données',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Autres champs du formulaire
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: specialtyController,
                    decoration: const InputDecoration(
                      labelText: 'Spécialité *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: experienceController,
                    decoration: const InputDecoration(
                      labelText: 'Années d\'expérience',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: workingHoursController,
                    decoration: const InputDecoration(
                      labelText: 'Heures de travail',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: skillsController,
                    decoration: const InputDecoration(
                      labelText: 'Compétences (séparées par des virgules)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: certificationsController,
                    decoration: const InputDecoration(
                      labelText: 'Certifications (séparées par des virgules)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _selectedImage = null;
                  _imageBytes = null;
                  Navigator.pop(context);
                },
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      specialtyController.text.isEmpty ||
                      phoneController.text.isEmpty ||
                      emailController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Veuillez remplir les champs obligatoires (*)'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    String? finalImageUrl;

                    // CORRECTION : Priorité à l'image locale sélectionnée
                    if (_imageBytes != null) {
                      // Uploader la nouvelle image sélectionnée (convertir en base64)
                      finalImageUrl = await _uploadImage();
                    } else if (profileImageController.text.isNotEmpty) {
                      // Utiliser l'URL manuelle si fournie
                      finalImageUrl = profileImageController.text;
                    } else {
                      // Garder l'image originale si aucune nouvelle image n'est fournie
                      finalImageUrl = originalImageUrl;
                    }

                    final List<String> skills = skillsController.text.isNotEmpty
                        ? skillsController.text
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList()
                        : [];

                    final List<String> certifications =
                        certificationsController.text.isNotEmpty
                            ? certificationsController.text
                                .split(',')
                                .map((s) => s.trim())
                                .where((s) => s.isNotEmpty)
                                .toList()
                            : [];

                    final updatedTechnician = technician.copyWith(
                      name: nameController.text,
                      specialty: specialtyController.text,
                      phone: phoneController.text,
                      email: emailController.text,
                      experience: int.tryParse(experienceController.text) ?? 0,
                      profileImage:
                          finalImageUrl, // Peut être null, base64 ou URL
                      address: addressController.text.isEmpty
                          ? null
                          : addressController.text,
                      bio: bioController.text.isEmpty
                          ? null
                          : bioController.text,
                      workingHours: workingHoursController.text.isEmpty
                          ? null
                          : workingHoursController.text,
                      skills: skills,
                      certifications: certifications,
                    );

                    await _technicianService
                        .updateTechnician(updatedTechnician);

                    // Réinitialiser les variables d'image
                    _selectedImage = null;
                    _imageBytes = null;

                    Navigator.pop(context);
                    _loadTechnicians();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Technicien modifié avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print('❌ Erreur modification technicien: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la modification: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Modifier',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteTechnician(Technician technician) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le technicien'),
        content:
            Text('Êtes-vous sûr de vouloir supprimer ${technician.name} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _technicianService.deleteTechnician(technician.id);
                Navigator.pop(context);
                _loadTechnicians();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${technician.name} a été supprimé'),
                    backgroundColor: Colors.red));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Erreur lors de la suppression'),
                    backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
