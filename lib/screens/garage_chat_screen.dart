import 'package:flutter/material.dart';
import 'dart:async';
// import 'dart:io';
import 'dart:typed_data'; // AJOUT: Pour Uint8List
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert'; // Pour base64
import '../services/chat_service.dart';
import '../models/chat_model.dart';

class GarageChatScreen extends StatefulWidget {
  final String garageId;
  final String garageEmail;

  const GarageChatScreen({
    super.key,
    required this.garageId,
    required this.garageEmail,
  });

  @override
  _GarageChatScreenState createState() => _GarageChatScreenState();
}

class _GarageChatScreenState extends State<GarageChatScreen> {
  final ChatService _chatService = ChatService();
  final ImagePicker _imagePicker = ImagePicker();
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  String? _selectedAppointmentId;
  List<ChatMessage> _currentMessages = [];
  late StreamSubscription<List<ChatMessage>> _messagesSubscription;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _editMessageController = TextEditingController();
  bool _isSending = false;
  bool _isUploading = false;
  final ScrollController _scrollController = ScrollController();
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _messagesSubscription = Stream<List<ChatMessage>>.empty().listen((_) {});
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      print('🔄 Chargement des conversations du garage: ${widget.garageId}');

      await _chatService.debugGarageConversations(widget.garageId);

      final conversations =
          await _chatService.getGarageConversations(widget.garageId);

      print('📞 ${conversations.length} conversations chargées');

      for (var conv in conversations) {
        print(
            '💬 Conversation: ${conv.clientEmail} - "${conv.lastMessage}" - ${conv.updatedAt}');
      }

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });

      if (conversations.isNotEmpty) {
        _selectConversation(
          conversations.first.appointmentId,
          conversations.first.clientEmail,
          conversations.first.clientEmail.split('@').first,
        );
      } else {
        print('⚠️ Aucune conversation trouvée pour ce garage');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement conversations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectConversation(
      String appointmentId, String clientEmail, String clientName) {
    setState(() {
      _selectedAppointmentId = appointmentId;
      _editingMessageId = null;
      _editMessageController.clear();
    });

    _loadChatMessages(appointmentId, clientEmail, clientName);
  }

  Future<void> _loadChatMessages(
      String appointmentId, String clientEmail, String clientName) async {
    try {
      print('💬 Chargement messages pour RDV: $appointmentId');

      final messages = await _chatService.getChatMessages(
        appointmentId,
        widget.garageId,
      );

      setState(() {
        _currentMessages = messages;
      });

      _setupRealtimeUpdates(appointmentId);
      _scrollToBottom();

      print('📨 ${messages.length} messages chargés');
    } catch (e) {
      print('❌ Erreur chargement messages: $e');
    }
  }

  void _setupRealtimeUpdates(String appointmentId) {
    _messagesSubscription.cancel();

    _messagesSubscription = _chatService
        .subscribeToChat(appointmentId, widget.garageId)
        .listen((newMessages) {
      print('🔄 ${newMessages.length} nouveaux messages reçus');
      setState(() {
        _currentMessages = newMessages;
      });
      _scrollToBottom();
    }, onError: (error) {
      print('❌ Erreur écoute temps réel: $error');
    });
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

  // PRENDRE UNE PHOTO
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

  // CHOISIR DEPUIS LA GALERIE
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

      final conversation = _conversations.firstWhere(
        (conv) => conv.appointmentId == _selectedAppointmentId,
        orElse: () => ChatConversation(
          id: '',
          appointmentId: _selectedAppointmentId!,
          garageId: widget.garageId,
          clientEmail: 'client@inconnu.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '📷 Photo', // Contenu textuel pour la préview
        senderType: SenderType.garage,
        type: MessageType.image,
        timestamp: DateTime.now(),
        appointmentId: _selectedAppointmentId!,
        garageId: widget.garageId,
        clientEmail: conversation.clientEmail,
        clientName: conversation.clientEmail.split('@').first,
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

  // JOINDRES UN FICHIER
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

      print('📎 Upload fichier: ${file.name}');
      await Future.delayed(const Duration(seconds: 1));

      final conversation = _conversations.firstWhere(
        (conv) => conv.appointmentId == _selectedAppointmentId,
        orElse: () => ChatConversation(
          id: '',
          appointmentId: _selectedAppointmentId!,
          garageId: widget.garageId,
          clientEmail: 'client@inconnu.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Fichier: ${file.name}',
        senderType: SenderType.garage,
        type: MessageType.file,
        timestamp: DateTime.now(),
        appointmentId: _selectedAppointmentId!,
        garageId: widget.garageId,
        clientEmail: conversation.clientEmail,
        clientName: conversation.clientEmail.split('@').first,
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

  // MODIFIER UN MESSAGE
  Future<void> _editMessage(ChatMessage message, String newContent) async {
    try {
      await _chatService.updateMessage(message.id, newContent);
      _showSuccess('Message modifié');

      if (_selectedAppointmentId != null) {
        _loadChatMessages(
          _selectedAppointmentId!,
          message.clientEmail ?? '',
          message.clientName ?? 'Client',
        );
      }
    } catch (e) {
      print('❌ Erreur modification message: $e');
      _showError('Erreur lors de la modification du message: $e');
    }
  }

  // SUPPRIMER UN MESSAGE
  Future<void> _deleteMessage(
      ChatMessage message, bool deleteForEveryone) async {
    try {
      if (deleteForEveryone) {
        await _chatService.deleteMessageForEveryone(message.id);
        _showSuccess('Message supprimé pour tout le monde');
      } else {
        await _chatService.deleteMessageForGarage(message.id, widget.garageId);
        _showSuccess('Message supprimé pour vous');
      }

      if (_selectedAppointmentId != null) {
        _loadChatMessages(
          _selectedAppointmentId!,
          message.clientEmail ?? '',
          message.clientName ?? 'Client',
        );
      }
    } catch (e) {
      print('❌ Erreur suppression message: $e');
      _showError('Erreur lors de la suppression du message: $e');
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

    final message = _currentMessages.firstWhere(
      (msg) => msg.id == _editingMessageId,
      orElse: () => ChatMessage(
        id: '',
        content: '',
        senderType: SenderType.garage,
        type: MessageType.text,
        timestamp: DateTime.now(),
        appointmentId: _selectedAppointmentId!,
        garageId: widget.garageId,
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
              _deleteMessage(message, false);
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
              _deleteMessage(message, true);
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

  // GESTION DES MÉDIAS
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending || _selectedAppointmentId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final conversation = _conversations.firstWhere(
        (conv) => conv.appointmentId == _selectedAppointmentId,
        orElse: () => ChatConversation(
          id: '',
          appointmentId: _selectedAppointmentId!,
          garageId: widget.garageId,
          clientEmail: 'client@inconnu.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        senderType: SenderType.garage,
        type: MessageType.text,
        timestamp: DateTime.now(),
        appointmentId: _selectedAppointmentId!,
        garageId: widget.garageId,
        clientEmail: conversation.clientEmail,
        clientName: conversation.clientEmail.split('@').first,
      );

      await _chatService.sendMessage(message);
      _messageController.clear();

      _showSuccess('Message envoyé');
      _scrollToBottom();
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

  // MÉTHODES D'AFFICHAGE
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
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
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  // BULLE POUR MESSAGE SUPPRIMÉ
  Widget _buildDeletedMessageBubble(bool isGarage) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isGarage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isGarage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
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
          if (isGarage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: const Icon(Icons.build, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messagerie Clients'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return _buildMobileLayout();
                } else {
                  return _buildDesktopLayout();
                }
              },
            ),
    );
  }

  Widget _buildMobileLayout() {
    return _selectedAppointmentId != null
        ? _buildChatArea()
        : _buildConversationsList();
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildConversationsList(),
        Expanded(
          child: _selectedAppointmentId != null
              ? _buildChatArea()
              : _buildEmptyChat(),
        ),
      ],
    );
  }

  Widget _buildConversationsList() {
    return Container(
      width: 300,
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                const Text(
                  'Conversations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_conversations.length} conversation${_conversations.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _conversations.isEmpty
                ? _buildEmptyConversations()
                : ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _buildConversationItem(conversation);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(ChatConversation conversation) {
    final isSelected = conversation.appointmentId == _selectedAppointmentId;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : Colors.transparent,
        border: isSelected
            ? Border(left: BorderSide(color: Colors.blue, width: 3))
            : null,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected ? Colors.blue : Colors.grey,
          child: Text(
            conversation.clientEmail[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          conversation.clientEmail.split('@').first,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : null,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation.lastMessage,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue[700] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(conversation.updatedAt),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
        trailing: conversation.unreadCount > 0
            ? CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text(
                  conversation.unreadCount > 9
                      ? '9+'
                      : conversation.unreadCount.toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              )
            : null,
        onTap: () => _selectConversation(
          conversation.appointmentId,
          conversation.clientEmail,
          conversation.clientEmail.split('@').first,
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    final conversation = _conversations.firstWhere(
      (conv) => conv.appointmentId == _selectedAppointmentId,
      orElse: () => ChatConversation(
        id: '',
        appointmentId: _selectedAppointmentId!,
        garageId: widget.garageId,
        clientEmail: 'Client',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            color: Colors.white,
          ),
          child: Row(
            children: [
              if (MediaQuery.of(context).size.width < 600) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedAppointmentId = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],
              CircleAvatar(
                backgroundColor: Colors.green,
                child: Text(
                  conversation.clientEmail[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.clientEmail.split('@').first,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      'RDV: ${conversation.appointmentId}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              if (conversation.unreadCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${conversation.unreadCount} non lu${conversation.unreadCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _currentMessages.isEmpty
              ? _buildEmptyMessages()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  reverse: false,
                  itemCount: _currentMessages.length,
                  itemBuilder: (context, index) {
                    final message = _currentMessages[index];
                    return _buildMessageBubble(message);
                  },
                ),
        ),
        _buildMessageInput(conversation),
      ],
    );
  }

  Widget _buildMessageInput(ChatConversation conversation) {
    final isEditing = _editingMessageId != null;
    final hasText = isEditing
        ? _editMessageController.text.trim().isNotEmpty
        : _messageController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        color: Colors.white,
      ),
      child: Column(
        children: [
          if (isEditing)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Modification du message',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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
              if (!isEditing)
                PopupMenuButton<String>(
                  icon: Icon(Icons.add_circle_outline,
                      color: (_isUploading || _isSending)
                          ? Colors.grey
                          : Colors.blue),
                  tooltip: 'Ajouter un média',
                  onSelected: _handleMediaSelection,
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
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 120,
                  ),
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
                      isCollapsed: true,
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
              Container(
                decoration: BoxDecoration(
                  color: (hasText && !_isSending && !_isUploading)
                      ? (isEditing ? Colors.orange : Colors.blue)
                      : Colors.grey[400],
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
                  onPressed: (hasText &&
                          !_isSending &&
                          !_isUploading &&
                          _selectedAppointmentId != null)
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

  Widget _buildMessageBubble(ChatMessage message) {
    final isGarage = message.senderType == SenderType.garage;
    final isEditing = _editingMessageId == message.id;

    if (message.isDeletedForGarage(widget.garageId)) {
      return _buildDeletedMessageBubble(isGarage);
    }

    return GestureDetector(
      onLongPress: () {
        if (isGarage &&
            (message.type == MessageType.text ||
                message.type == MessageType.image)) {
          _showMessageOptionsDialog(message);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment:
              isGarage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isGarage) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green,
                child: Text(
                  message.clientName?[0] ?? 'C',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEditing
                      ? Colors.orange[100]
                      : (isGarage ? Colors.blue[100] : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(16),
                  border: isEditing
                      ? Border.all(color: Colors.orange, width: 2)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isGarage)
                      Text(
                        message.clientName ?? 'Client',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    if (!isGarage) const SizedBox(height: 4),
                    if (message.type == MessageType.text)
                      SelectableText(
                        message.content,
                        style: TextStyle(
                          fontStyle:
                              isEditing ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    if (message.type == MessageType.image)
                      _buildImageMessage(message),
                    if (message.type == MessageType.file)
                      _buildFileMessage(message),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        if (isGarage &&
                            (message.type == MessageType.text ||
                                message.type == MessageType.image))
                          Icon(
                            Icons.more_vert,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isGarage) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: isEditing ? Colors.orange : Colors.blue,
                child: const Icon(Icons.build, size: 16, color: Colors.white),
              ),
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

  // WIDGET POUR LES MESSAGES FICHIER
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
                    maxLines: 1,
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

  Widget _buildEmptyConversations() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucune conversation',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Les conversations avec vos clients\napparaîtront ici',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucun message',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Envoyez le premier message',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Sélectionnez une conversation',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return _formatTime(date);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Hier';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    _messagesSubscription.cancel();
    _messageController.dispose();
    _editMessageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
