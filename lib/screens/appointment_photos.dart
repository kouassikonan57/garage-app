import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AppointmentPhotos extends StatefulWidget {
  final String appointmentId;

  const AppointmentPhotos({super.key, required this.appointmentId});

  @override
  _AppointmentPhotosState createState() => _AppointmentPhotosState();
}

class _AppointmentPhotosState extends State<AppointmentPhotos> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<AppointmentPhoto> _appointmentPhotos = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photos du Rendez-vous'),
        actions: [
          if (_selectedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cloud_upload),
              onPressed: _uploadPhotos,
              tooltip: 'Envoyer les photos',
            ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajoutez des photos pour :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Le problème à réparer'),
                Text('• Les pièces défectueuses'),
                Text('• Les documents importants'),
                Text('• La réparation terminée'),
              ],
            ),
          ),

          // Boutons d'action
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Prendre une photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galerie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Photos sélectionnées
          if (_selectedImages.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_selectedImages.length} photo(s) sélectionnée(s)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _buildSelectedPhotosGrid(),
          ],

          // Photos existantes
          if (_appointmentPhotos.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Photos du rendez-vous',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            _buildExistingPhotosGrid(),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedPhotosGrid() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return _buildPhotoItem(_selectedImages[index], index, isNew: true);
        },
      ),
    );
  }

  Widget _buildExistingPhotosGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _appointmentPhotos.length,
      itemBuilder: (context, index) {
        return _buildExistingPhotoItem(_appointmentPhotos[index]);
      },
    );
  }

  Widget _buildPhotoItem(XFile imageFile, int index, {bool isNew = false}) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(File(imageFile.path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (isNew)
          Positioned(
            top: 4,
            right: 12,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExistingPhotoItem(AppointmentPhoto photo) {
    return GestureDetector(
      onTap: () => _showPhotoDetails(photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(photo.url),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Badge type de photo
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPhotoTypeColor(photo.type).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getPhotoTypeLabel(photo.type),
                  style: const TextStyle(fontSize: 8, color: Colors.white),
                ),
              ),
            ),

            // Date
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatTime(photo.timestamp),
                  style: const TextStyle(fontSize: 8, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });

      // Demander le type de photo
      _askPhotoType(image);
    }
  }

  Future<void> _pickFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _askPhotoType(XFile image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Type de photo'),
        content: const Text('Sélectionnez le type de photo :'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ...PhotoType.values.map((type) {
            return TextButton(
              onPressed: () {
                Navigator.pop(context);
                _tagPhoto(image, type);
              },
              child: Text(_getPhotoTypeLabel(type)),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _tagPhoto(XFile image, PhotoType type) {
    // Ajouter des métadonnées à la photo
    print('Photo ${image.name} taguée comme ${_getPhotoTypeLabel(type)}');
  }

  Future<void> _uploadPhotos() async {
    // Upload vers le serveur
    for (final image in _selectedImages) {
      // Implémentation de l'upload
      print('Upload de ${image.name}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photos envoyées avec succès'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _selectedImages.clear();
    });
  }

  void _showPhotoDetails(AppointmentPhoto photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(_getPhotoTypeLabel(photo.type)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Image.network(photo.url),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Ajoutée le ${_formatDate(photo.timestamp)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPhotoTypeColor(PhotoType type) {
    switch (type) {
      case PhotoType.problem:
        return Colors.red;
      case PhotoType.part:
        return Colors.orange;
      case PhotoType.document:
        return Colors.blue;
      case PhotoType.repair:
        return Colors.green;
      case PhotoType.finalResult:
        return Colors.purple;
    }
  }

  String _getPhotoTypeLabel(PhotoType type) {
    switch (type) {
      case PhotoType.problem:
        return 'Problème';
      case PhotoType.part:
        return 'Pièce';
      case PhotoType.document:
        return 'Document';
      case PhotoType.repair:
        return 'Réparation';
      case PhotoType.finalResult:
        return 'Résultat';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class AppointmentPhoto {
  final String id;
  final String url;
  final PhotoType type;
  final DateTime timestamp;
  final String? description;

  AppointmentPhoto({
    required this.id,
    required this.url,
    required this.type,
    required this.timestamp,
    this.description,
  });
}

enum PhotoType {
  problem,
  part,
  document,
  repair,
  finalResult,
}
