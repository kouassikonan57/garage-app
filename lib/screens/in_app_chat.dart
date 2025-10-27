import 'package:flutter/material.dart';
import 'dart:async';
// import 'dart:io';
import 'dart:typed_data'; // Pour Uint8List
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert'; // Pour base64
import '../services/chat_service.dart';
import '../models/chat_model.dart';

class InAppChat extends StatefulWidget {
  final String garageId;
  final String appointmentId;
  final String clientEmail;
  final String clientName;

  const InAppChat({
    super.key,
    required this.garageId,
    required this.appointmentId,
    required this.clientEmail,
    required this.clientName,
  });

  @override
  _InAppChatState createState() => _InAppChatState();
}

class _InAppChatState extends State<InAppChat> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _editMessageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ImagePicker _imagePicker = ImagePicker();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploading = false;
  late StreamSubscription<List<ChatMessage>> _messagesSubscription;
  final ScrollController _scrollController = ScrollController();
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _setupRealtimeUpdates();
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  Future<void> _loadChatHistory() async {
    try {
      print('🔄 Chargement historique du chat...');
      final messages = await _chatService.getChatMessages(
        widget.appointmentId,
        widget.garageId,
      );

      print('📨 ${messages.length} messages chargés');

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print('❌ Erreur chargement chat: $e');
      setState(() {
        _isLoading = false;
      });

      _showError('Erreur de chargement des messages: $e');
    }
  }

  void _setupRealtimeUpdates() {
    print('🎧 Configuration des mises à jour en temps réel...');

    try {
      _messagesSubscription = _chatService
          .subscribeToChat(widget.appointmentId, widget.garageId)
          .listen((newMessages) {
        print('🔄 ${newMessages.length} nouveaux messages reçus');
        setState(() {
          _messages = newMessages;
        });
        _scrollToBottom();
      }, onError: (error) {
        print('❌ Erreur écoute temps réel: $error');
      });
    } catch (e) {
      print('❌ Erreur configuration écoute: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // BULLE POUR MESSAGE SUPPRIMÉ
  Widget _buildDeletedMessageBubble(bool isFromCurrentUser) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromCurrentUser) ...[
            _buildAvatar(true),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline, color: Colors.grey[500], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Message supprimé',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(true),
          ],
        ],
      ),
    );
  }

  // SUPPRIMER UN MESSAGE
  Future<void> _deleteMessage(
      ChatMessage message, bool deleteForEveryone) async {
    try {
      if (deleteForEveryone) {
        // Supprimer pour tout le monde
        await _chatService.deleteMessageForEveryone(message.id);
        _showSuccess('Message supprimé pour tout le monde');
      } else {
        // Supprimer seulement pour moi (le client)
        await _chatService.deleteMessageForClient(
            message.id, widget.clientEmail);
        _showSuccess('Message supprimé pour vous');
      }

      // Recharger les messages
      _loadChatHistory();
    } catch (e) {
      print('❌ Erreur suppression message: $e');
      _showError('Erreur lors de la suppression du message: $e');
    }
  }

  // MODIFIER UN MESSAGE
  Future<void> _editMessage(ChatMessage message, String newContent) async {
    try {
      await _chatService.updateMessage(message.id, newContent);
      _showSuccess('Message modifié');
      _loadChatHistory();
    } catch (e) {
      print('❌ Erreur modification message: $e');
      _showError('Erreur lors de la modification du message: $e');
    }
  }

  // AFFICHER LE MENU DE MODIFICATION/SUPPRESSION
  void _showMessageOptionsDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Options du message'),
        content: const Text('Que voulez-vous faire avec ce message ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          if (message.type == MessageType.text)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startEditingMessage(message);
              },
              child: const Text('Modifier'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteDialog(message);
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // DÉMARRER LA MODIFICATION D'UN MESSAGE
  void _startEditingMessage(ChatMessage message) {
    setState(() {
      _editingMessageId = message.id;
      _editMessageController.text = message.content;
      _messageController.clear();
    });
    _scrollToBottom();
  }

  // ANNULER LA MODIFICATION
  void _cancelEditing() {
    setState(() {
      _editingMessageId = null;
      _editMessageController.clear();
    });
  }

  // SAUVEGARDER LA MODIFICATION
  Future<void> _saveEdit() async {
    if (_editingMessageId == null ||
        _editMessageController.text.trim().isEmpty) {
      return;
    }

    final message = _messages.firstWhere(
      (msg) => msg.id == _editingMessageId,
      orElse: () => ChatMessage(
        id: '',
        content: '',
        senderType: SenderType.client,
        type: MessageType.text,
        timestamp: DateTime.now(),
        appointmentId: widget.appointmentId,
        garageId: widget.garageId,
        clientEmail: widget.clientEmail,
      ),
    );

    await _editMessage(message, _editMessageController.text.trim());
    _cancelEditing();
  }

  // AFFICHER LE DIALOGUE DE SUPPRESSION
  void _showDeleteDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le message'),
        content: const Text('Comment voulez-vous supprimer ce message ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message, false); // Supprimer pour moi
            },
            child: const Text('Supprimer pour moi'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showConfirmDeleteForEveryoneDialog(message);
            },
            child: const Text(
              'Supprimer pour tous',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // CONFIRMATION SUPPRESSION POUR TOUS
  void _showConfirmDeleteForEveryoneDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce message pour tous les participants ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message, true); // Supprimer pour tous
            },
            child: const Text(
              'Supprimer pour tous',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // CONVERTIR L'IMAGE EN BASE64
  Future<String> _imageToBase64(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      print('❌ Erreur conversion image en base64: $e');
      throw e;
    }
  }

  // FONCTIONNALITÉ PHOTO - PRENDRE UNE PHOTO
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (photo != null) {
        await _sendImageMessage(photo);
      }
    } catch (e) {
      print('❌ Erreur prise de photo: $e');
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  // FONCTIONNALITÉ PHOTO - CHOISIR DEPUIS LA GALERIE
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (image != null) {
        await _sendImageMessage(image);
      }
    } catch (e) {
      print('❌ Erreur sélection image: $e');
      _showError('Erreur lors de la sélection de l\'image: $e');
    }
  }

  // ENVOYER UN MESSAGE IMAGE - CORRIGÉ
  Future<void> _sendImageMessage(XFile imageFile) async {
    try {
      setState(() {
        _isUploading = true;
      });

      print('📸 Conversion image: ${imageFile.name}');

      // Convertir l'image en base64
      final imageBase64 = await _imageToBase64(imageFile);
      print('✅ Image convertie en base64 (${imageBase64.length} caractères)');

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '📷 Photo', // Contenu textuel pour la préview
        senderType: SenderType.client,
        type: MessageType.image,
        timestamp: DateTime.now(),
        appointmentId: widget.appointmentId,
        garageId: widget.garageId,
        clientEmail: widget.clientEmail,
        clientName: widget.clientName,
        imageBase64: imageBase64, // Stocker l'image en base64
      );

      await _chatService.sendMessage(message);
      _showSuccess('Photo envoyée');

      print('✅ Image envoyée et stockée en base64');
    } catch (e) {
      print('❌ Erreur envoi image: $e');
      _showError('Erreur lors de l\'envoi de la photo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // FONCTIONNALITÉ FICHIER - JOINDRES UN FICHIER
  Future<void> _attachFile() async {
    try {
      setState(() {
        _isUploading = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        await _sendFileMessage(result.files.single);
      }
    } catch (e) {
      print('❌ Erreur sélection fichier: $e');
      _showError('Erreur lors de la sélection du fichier: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // ENVOYER UN MESSAGE FICHIER
  Future<void> _sendFileMessage(PlatformFile file) async {
    try {
      setState(() {
        _isUploading = true;
      });

      // SIMULATION UPLOAD - À REMPLACER PAR VOTRE LOGIQUE CLOUD
      print('📎 Upload fichier: ${file.name}');
      await Future.delayed(const Duration(seconds: 1)); // Simulation upload

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Fichier: ${file.name}',
        senderType: SenderType.client,
        type: MessageType.file,
        timestamp: DateTime.now(),
        appointmentId: widget.appointmentId,
        garageId: widget.garageId,
        clientEmail: widget.clientEmail,
        clientName: widget.clientName,
        fileName: file.name,
        fileSize: file.size,
      );

      await _chatService.sendMessage(message);
      _showSuccess('Fichier envoyé: ${file.name}');
    } catch (e) {
      print('❌ Erreur envoi fichier: $e');
      _showError('Erreur lors de l\'envoi du fichier: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingMessageId != null;
    final hasText = isEditing
        ? _editMessageController.text.trim().isNotEmpty
        : _messageController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion Rendez-vous'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Indicateur d'upload
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              _handleMenuSelection(value);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Actualiser'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('Effacer l\'historique'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Informations'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête du chat amélioré
          _buildChatHeader(),

          // Séparateur
          const Divider(height: 1, color: Colors.grey),

          // Messages
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _messages.isEmpty
                    ? _buildEmptyChat()
                    : _buildChatMessages(),
          ),

          // Input message
          _buildMessageInput(hasText, isEditing),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Première ligne : Titre avec icône
          Row(
            children: [
              Icon(Icons.chat, size: 18, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                'Discussion Rendez-vous',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Deuxième ligne : Informations détaillées
          Row(
            children: [
              // Checkbox stylisée
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.grey),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conversation avec ${widget.clientName}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RDV: ${widget.appointmentId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Chargement des messages...',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun message',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Envoyez un message pour démarrer la conversation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadChatHistory,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Recharger'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessages() {
    return Column(
      children: [
        // Indicateur de statut de connexion
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          color: Colors.green[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 8, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Connecté • ${_messages.length} message${_messages.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),

        // Liste des messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            reverse: false,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isClient = message.senderType == SenderType.client;
    final isFromCurrentUser =
        isClient && message.clientEmail == widget.clientEmail;
    final isEditing = _editingMessageId == message.id;

    // VÉRIFIER SI LE MESSAGE EST SUPPRIMÉ
    if (message.isDeletedForClient(widget.clientEmail)) {
      return _buildDeletedMessageBubble(isFromCurrentUser);
    }

    return GestureDetector(
      onLongPress: () {
        if (isFromCurrentUser &&
            (message.type == MessageType.text ||
                message.type == MessageType.image)) {
          _showMessageOptionsDialog(message);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: isFromCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isFromCurrentUser) ...[
              _buildAvatar(isClient),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEditing
                      ? Colors.orange[100]
                      : (isFromCurrentUser
                          ? Colors.blue[100]
                          : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(12),
                  border: isEditing
                      ? Border.all(color: Colors.orange, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isFromCurrentUser) _buildSenderName(message, isClient),

                    // Contenu du message selon le type
                    if (message.type == MessageType.text)
                      Text(
                        message.content,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle:
                              isEditing ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),

                    if (message.type == MessageType.image)
                      _buildImageMessage(message),

                    if (message.type == MessageType.file)
                      _buildFileMessage(message),

                    const SizedBox(height: 6),
                    _buildMessageMeta(message, isFromCurrentUser),
                  ],
                ),
              ),
            ),
            if (isFromCurrentUser) ...[
              const SizedBox(width: 8),
              _buildAvatar(isClient, isEditing: isEditing),
            ],
          ],
        ),
      ),
    );
  }

  // WIDGET POUR LES MESSAGES IMAGE - CORRIGÉ
  Widget _buildImageMessage(ChatMessage message) {
    // Vérifier si on a une image en base64
    if (message.imageBase64 == null || message.imageBase64!.isEmpty) {
      return Container(
        width: 200,
        height: 150,
        color: Colors.grey[200],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo, color: Colors.grey, size: 40),
            SizedBox(height: 8),
            Text(
              'Image non disponible',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    try {
      // Convertir base64 en bytes
      final imageBytes = base64Decode(message.imageBase64!);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showFullScreenImage(imageBytes),
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 200,
                maxHeight: 150,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  imageBytes,
                  width: 200,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Erreur affichage image: $error');
                    return Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey[200],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.grey),
                          SizedBox(height: 4),
                          Text(
                            'Erreur image',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '[Image]',
            style: TextStyle(
                fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      );
    } catch (e) {
      print('❌ Erreur décodage image base64: $e');
      return Container(
        width: 200,
        height: 150,
        color: Colors.grey[200],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              'Erreur image',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFileMessage(ChatMessage message) {
    return GestureDetector(
      onTap: () => _downloadFile(message),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.5,
        ),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'Fichier',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.fileSize != null)
                    Text(
                      _formatFileSize(message.fileSize!),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            Icon(Icons.download, color: Colors.blue[700], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isClient, {bool isEditing = false}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color:
            isEditing ? Colors.orange : (isClient ? Colors.green : Colors.blue),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        isClient ? Icons.person : Icons.build,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSenderName(ChatMessage message, bool isClient) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        isClient ? message.clientName ?? 'Client' : 'Garage',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isClient ? Colors.green[700] : Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildMessageMeta(ChatMessage message, bool isFromCurrentUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.timestamp),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        if (message.isRead && isFromCurrentUser) ...[
          const SizedBox(width: 6),
          const Icon(Icons.done_all, size: 14, color: Colors.blue),
        ],
        if (isFromCurrentUser &&
            (message.type == MessageType.text ||
                message.type == MessageType.image)) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.more_vert,
            size: 12,
            color: Colors.grey[500],
          ),
        ],
      ],
    );
  }

  Widget _buildMessageInput(bool hasText, bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          // BANNIÈRE D'ÉDITION
          if (isEditing)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Modification du message',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: _cancelEditing,
                  ),
                ],
              ),
            ),

          Row(
            children: [
              // Boutons d'action (cachés pendant l'édition)
              if (!isEditing)
                Row(
                  children: [
                    // Menu déroulant pour les médias
                    PopupMenuButton<String>(
                      icon: Icon(Icons.add_circle_outline,
                          color: Colors.blue[600]),
                      tooltip: 'Ajouter un média',
                      onSelected: (value) {
                        _handleMediaSelection(value);
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'camera',
                          child: Row(
                            children: [
                              Icon(Icons.photo_camera, size: 20),
                              SizedBox(width: 8),
                              Text('Prendre une photo'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'gallery',
                          child: Row(
                            children: [
                              Icon(Icons.photo_library, size: 20),
                              SizedBox(width: 8),
                              Text('Choisir depuis la galerie'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'file',
                          child: Row(
                            children: [
                              Icon(Icons.attach_file, size: 20),
                              SizedBox(width: 8),
                              Text('Joindre un fichier'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              // Champ de texte
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller:
                        isEditing ? _editMessageController : _messageController,
                    decoration: InputDecoration(
                      hintText: isEditing
                          ? 'Modifier votre message...'
                          : 'Tapez votre message...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) =>
                        isEditing ? _saveEdit() : _sendMessage(),
                    onChanged: (text) {
                      setState(() {});
                    },
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Bouton d'envoi/mise à jour
              Container(
                decoration: BoxDecoration(
                  color: hasText && !_isSending && !_isUploading
                      ? (isEditing ? Colors.orange : Colors.blue)
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (hasText && !_isSending && !_isUploading)
                      BoxShadow(
                        color: (isEditing ? Colors.orange : Colors.blue)
                            .withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: IconButton(
                  icon: _isSending || _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          isEditing ? Icons.check : Icons.send,
                          color: Colors.white,
                        ),
                  onPressed: hasText && !_isSending && !_isUploading
                      ? (isEditing ? _saveEdit : _sendMessage)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'refresh':
        _loadChatHistory();
        break;
      case 'clear':
        _showClearConfirmation();
        break;
      case 'info':
        _showChatInfo();
        break;
    }
  }

  void _handleMediaSelection(String value) {
    switch (value) {
      case 'camera':
        _takePhoto();
        break;
      case 'gallery':
        _pickImageFromGallery();
        break;
      case 'file':
        _attachFile();
        break;
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer l\'historique'),
        content: const Text(
            'Voulez-vous vraiment effacer tout l\'historique de cette conversation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccess('Fonctionnalité à implémenter');
            },
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations de la conversation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${widget.clientName}'),
            Text('Email: ${widget.clientEmail}'),
            Text('RDV: ${widget.appointmentId}'),
            Text('Garage: ${widget.garageId}'),
            const SizedBox(height: 8),
            Text('Messages: ${_messages.length}'),
          ],
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        senderType: SenderType.client,
        type: MessageType.text,
        timestamp: DateTime.now(),
        appointmentId: widget.appointmentId,
        garageId: widget.garageId,
        clientEmail: widget.clientEmail,
        clientName: widget.clientName,
      );

      await _chatService.sendMessage(message);
      _messageController.clear();

      _showSuccess('Message envoyé');
    } catch (error) {
      print('❌ Erreur envoi message: $error');
      _showError('Erreur d\'envoi: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showFullScreenImage(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadFile(ChatMessage message) {
    _showSuccess('Téléchargement de ${message.fileName}');
    // Implémenter la logique de téléchargement réel ici
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _editMessageController.dispose();
    _messagesSubscription.cancel();
    _scrollController.dispose();
    _chatService.dispose();
    super.dispose();
  }
}
