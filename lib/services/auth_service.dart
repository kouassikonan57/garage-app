import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _garageSecretKey = "GARAGE_SECRET_2024";
  static const String _usersKey = 'stored_users';
  static const String _currentUserKey = 'current_user';
  static const String _isInitializedKey = 'auth_service_initialized';

  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _currentUser;
  late SharedPreferences _prefs;

  // Initialiser le service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadUsers();
    await _loadCurrentUser();
    await _markAsInitialized();
  }

  // Marquer le service comme initialisé
  Future<void> _markAsInitialized() async {
    await _prefs.setBool(_isInitializedKey, true);
  }

  // Vérifier si le service est initialisé
  bool get isInitialized => _prefs.getBool(_isInitializedKey) ?? false;

  // Charger les utilisateurs depuis le stockage
  Future<void> _loadUsers() async {
    try {
      final usersJson = _prefs.getStringList(_usersKey);
      if (usersJson != null) {
        _users = usersJson.map((json) {
          final map = _parseJsonString(json);
          return map;
        }).toList();
        print('📊 Utilisateurs chargés: ${_users.length}');

        // DEBUG: Afficher les utilisateurs chargés
        for (var user in _users) {
          print('   - ${user['email']} (${user['userType']})');
        }
      } else {
        print('📊 Aucun utilisateur trouvé dans le stockage');
        _users = [];
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des utilisateurs: $e');
      _users = [];
    }
  }

  // Sauvegarder les utilisateurs
  Future<void> _saveUsers() async {
    try {
      final usersJson = _users.map((user) => _mapToJsonString(user)).toList();
      await _prefs.setStringList(_usersKey, usersJson);
      print('💾 Utilisateurs sauvegardés: ${_users.length}');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde des utilisateurs: $e');
    }
  }

  // Charger l'utilisateur courant
  Future<void> _loadCurrentUser() async {
    try {
      final currentUserJson = _prefs.getString(_currentUserKey);
      if (currentUserJson != null && currentUserJson.isNotEmpty) {
        _currentUser = _parseJsonString(currentUserJson);
        print('👤 Utilisateur courant chargé: ${_currentUser!['email']}');
      } else {
        print('👤 Aucun utilisateur courant trouvé');
        _currentUser = null;
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de l\'utilisateur courant: $e');
      _currentUser = null;
    }
  }

  // Sauvegarder l'utilisateur courant
  Future<void> _saveCurrentUser() async {
    try {
      if (_currentUser != null) {
        final jsonString = _mapToJsonString(_currentUser!);
        await _prefs.setString(_currentUserKey, jsonString);
        print('💾 Utilisateur courant sauvegardé: ${_currentUser!['email']}');
      } else {
        await _prefs.remove(_currentUserKey);
        print('💾 Utilisateur courant supprimé');
      }
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de l\'utilisateur courant: $e');
    }
  }

  // Inscription avec vérification de type
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required UserType userType,
    String? garageSecretKey,
    required bool isClientSpace,
  }) async {
    try {
      // Validation pour l'inscription garage
      if (userType == UserType.garage) {
        if (garageSecretKey != _garageSecretKey) {
          return 'Clé d\'inscription garage invalide. Contactez l\'administrateur.';
        }
      }

      // VÉRIFICATION DE SÉCURITÉ : Un client ne peut pas s'inscrire comme garage
      if (isClientSpace && userType == UserType.garage) {
        return 'Impossible de créer un compte garage depuis l\'espace client.';
      }

      // VÉRIFICATION DE SÉCURITÉ : Un garage ne peut pas s'inscrire comme client
      if (!isClientSpace && userType == UserType.client) {
        return 'Impossible de créer un compte client depuis l\'espace garage.';
      }

      if (password.length < 6) {
        return 'Le mot de passe doit contenir au moins 6 caractères';
      }

      if (!email.contains('@')) {
        return 'Email invalide';
      }

      if (name.isEmpty) {
        return 'Veuillez entrer votre nom';
      }

      // Vérifier si l'email existe déjà
      if (_users.any((user) => user['email'] == email)) {
        return 'Un compte avec cet email existe déjà';
      }

      // Simuler un délai de traitement
      await Future.delayed(const Duration(seconds: 2));

      // Créer le nouvel utilisateur
      final newUser = {
        'uid': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'email': email,
        'password': password,
        'name': name,
        'userType': userType.name,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };

      _users.add(newUser);
      _currentUser = newUser;

      // Sauvegarder les données de manière asynchrone
      await _saveUsers();
      await _saveCurrentUser();

      print('✅ Utilisateur créé: $email (${userType.name})');
      print('📊 Total utilisateurs: ${_users.length}');

      // Vérification immédiate que les données sont bien sauvegardées
      await _verifyDataSaved();

      return null;
    } catch (e) {
      return 'Une erreur est survenue lors de l\'inscription: $e';
    }
  }

  // Vérifier que les données sont bien sauvegardées
  Future<void> _verifyDataSaved() async {
    await _prefs.reload(); // Recharger les préférences
    final savedUsers = _prefs.getStringList(_usersKey);
    final savedCurrentUser = _prefs.getString(_currentUserKey);

    print('🔍 Vérification sauvegarde:');
    print('   - Utilisateurs sauvegardés: ${savedUsers?.length ?? 0}');
    print('   - Utilisateur courant sauvegardé: ${savedCurrentUser != null}');
  }

  // Connexion avec vérification d'accès
  Future<String?> login(String email, String password,
      {required bool isClientSpace}) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return 'Veuillez remplir tous les champs';
      }

      // Simuler un délai de traitement
      await Future.delayed(const Duration(seconds: 2));

      // Rechercher l'utilisateur
      final user = _users.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
        orElse: () => {},
      );

      if (user.isEmpty) {
        return 'Email ou mot de passe incorrect';
      }

      // VÉRIFICATION DE SÉCURITÉ CRITIQUE : Vérifier que l'utilisateur a accès à l'espace
      final userType = UserType.values.firstWhere(
        (e) => e.name == user['userType'],
        orElse: () => UserType.client,
      );

      if (isClientSpace && userType != UserType.client) {
        return 'Accès refusé. Cet espace est réservé aux clients.';
      }

      if (!isClientSpace && userType != UserType.garage) {
        return 'Accès refusé. Cet espace est réservé aux garages.';
      }

      _currentUser = user;
      await _saveCurrentUser();

      print('✅ Connexion réussie: $email (${userType.name})');
      return null;
    } catch (e) {
      return 'Une erreur est survenue lors de la connexion: $e';
    }
  }

  // Déconnexion
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    await _saveCurrentUser();
    print('✅ Déconnexion réussie');
  }

  // Vérifier l'accès à l'espace garage
  Future<bool> checkGarageAccess() async {
    final user = await getCurrentAppUser();
    return user?.userType == UserType.garage;
  }

  // Récupérer les informations utilisateur
  Future<AppUser?> getCurrentAppUser() async {
    if (_currentUser == null) return null;

    try {
      return AppUser(
        uid: _currentUser!['uid'],
        email: _currentUser!['email'],
        name: _currentUser!['name'],
        userType: UserType.values.firstWhere(
          (e) => e.name == _currentUser!['userType'],
          orElse: () => UserType.client,
        ),
        createdAt: DateTime.parse(_currentUser!['createdAt']),
        isActive: _currentUser!['isActive'] ?? true,
      );
    } catch (e) {
      print('Erreur lors de la récupération du user: $e');
      return null;
    }
  }

  // Vérifier si un utilisateur est connecté
  bool get isUserLoggedIn => _currentUser != null;

  // Stream simulé pour l'authentification
  Stream<dynamic> get authStateChanges {
    return Stream.fromIterable([_currentUser]);
  }

  // Méthodes utilitaires pour JSON
  Map<String, dynamic> _parseJsonString(String jsonString) {
    final map = <String, dynamic>{};
    try {
      final pairs = jsonString.split('|');
      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          map[keyValue[0]] = keyValue[1];
        }
      }
    } catch (e) {
      print('Erreur parsing JSON: $e');
    }
    return map;
  }

  String _mapToJsonString(Map<String, dynamic> map) {
    final entries = map.entries.map((e) => '${e.key}:${e.value}').toList();
    return entries.join('|');
  }

  // Méthode de débogage
  void debugPrintUsers() {
    print('=== DEBUG UTILISATEURS ===');
    print('Nombre d\'utilisateurs: ${_users.length}');
    for (var user in _users) {
      print(' - ${user['email']} (${user['userType']})');
    }
    print('Utilisateur actuel: ${_currentUser?['email']}');
    print('==========================');
  }

  // Méthode utilitaire pour vider le cache (uniquement pour le débogage)
  Future<void> clearAllData() async {
    await _prefs.clear();
    _users.clear();
    _currentUser = null;
    print('🗑️ Toutes les données d\'authentification ont été supprimées');
  }

  // Méthode pour réinitialiser uniquement les utilisateurs (débogage)
  Future<void> resetUsers() async {
    _users.clear();
    _currentUser = null;
    await _saveUsers();
    await _saveCurrentUser();
    print('🔄 Liste des utilisateurs réinitialisée');
  }

  // Méthode pour obtenir tous les utilisateurs (débogage)
  List<Map<String, dynamic>> get allUsers => List.from(_users);
}
