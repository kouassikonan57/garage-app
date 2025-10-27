import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class SimpleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SimpleAuthService() {
    print('✅ SimpleAuthService initialisé (avec Firestore)');
  }

  // Inscription simplifiée
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required UserType userType,
    String? garageSecretKey,
    required bool isClientSpace,
  }) async {
    try {
      print('🔄 Inscription: $email - Type: $userType');

      // Validations
      if (password.length < 6) {
        return {
          'success': false,
          'error': 'Le mot de passe doit contenir au moins 6 caractères'
        };
      }

      if (!email.contains('@')) {
        return {'success': false, 'error': 'Email invalide'};
      }

      // Vérifications sécurité
      if (userType == UserType.garage &&
          garageSecretKey != "GARAGE_SECRET_2024") {
        return {
          'success': false,
          'error': 'Clé d\'inscription garage invalide'
        };
      }

      // Créer l'utilisateur Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // SAUVEGARDER DANS FIRESTORE
      final appUser = AppUser(
        uid: uid,
        email: email.trim(),
        name: name.trim(),
        userType: userType,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email.trim(),
        'name': name.trim(),
        'userType': userType.toString().split('.').last, // 'garage' ou 'client'
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sauvegarder aussi localement
      await _saveUserLocally(appUser);

      print('✅ Inscription réussie: $email - Type: $userType');
      return {'success': true, 'user': appUser};
    } on FirebaseAuthException catch (e) {
      final error = _handleFirebaseError(e);
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': 'Erreur inattendue: $e'};
    }
  }

  // Connexion simplifiée - CORRIGÉE
  Future<Map<String, dynamic>> login(String email, String password,
      {required bool isClientSpace}) async {
    try {
      print(
          '🔄 Connexion: $email - Espace: ${isClientSpace ? "client" : "garage"}');

      // Connexion Firebase Auth
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // RÉCUPÉRER DEPUIS FIRESTORE (source de vérité)
      AppUser? appUser = await _getUserFromFirestore(uid);

      // Si pas dans Firestore, créer depuis Auth
      if (appUser == null) {
        appUser = AppUser(
          uid: uid,
          email: email,
          name: email.split('@')[0],
          userType: UserType.client, // Par défaut client
          createdAt: DateTime.now(),
        );

        // Sauvegarder dans Firestore
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': email.trim(),
          'name': email.split('@')[0],
          'userType': 'client',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Sauvegarder localement
      await _saveUserLocally(appUser);

      // Vérifier les permissions
      if (isClientSpace && appUser.userType != UserType.client) {
        await _auth.signOut();
        await _clearLocalUser(uid);
        return {'success': false, 'error': 'Accès réservé aux clients'};
      }

      if (!isClientSpace && appUser.userType != UserType.garage) {
        await _auth.signOut();
        await _clearLocalUser(uid);
        return {'success': false, 'error': 'Accès réservé aux garages'};
      }

      print('✅ Connexion réussie: $email - Type: ${appUser.userType}');
      return {'success': true, 'user': appUser};
    } on FirebaseAuthException catch (e) {
      final error = _handleFirebaseError(e);
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': 'Erreur de connexion: $e'};
    }
  }

  // Récupérer depuis Firestore
  Future<AppUser?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        return AppUser(
          uid: data['uid'] ?? uid,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          userType: _parseUserType(data['userType']),
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      print('❌ Erreur Firestore: $e');
      return null;
    }
  }

  UserType _parseUserType(dynamic userType) {
    if (userType is String) {
      if (userType == 'garage') return UserType.garage;
      if (userType == 'client') return UserType.client;
    }
    return UserType.client; // Par défaut
  }

  // Récupérer utilisateur courant - CORRIGÉE
  Future<AppUser?> getCurrentAppUser() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      // Priorité à Firestore
      AppUser? appUser = await _getUserFromFirestore(user.uid);

      if (appUser != null) {
        // Mettre à jour le stockage local
        await _saveUserLocally(appUser);
        return appUser;
      }

      // Fallback: stockage local
      return await _getUserLocally(user.uid);
    } catch (e) {
      print('❌ Erreur getCurrentAppUser: $e');
      return null;
    }
  }

  // Sauvegarde locale
  Future<void> _saveUserLocally(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_user_${user.uid}', user.toJsonString());
      print('💾 Utilisateur sauvegardé localement: ${user.email}');
    } catch (e) {
      print('❌ Erreur sauvegarde locale: $e');
    }
  }

  // Récupération locale
  Future<AppUser?> _getUserLocally(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('local_user_$uid');
      if (userData != null) {
        return AppUser.fromJsonString(userData);
      }
    } catch (e) {
      print('❌ Erreur récupération locale: $e');
    }
    return null;
  }

  // Nettoyer l'utilisateur local en cas d'erreur
  Future<void> _clearLocalUser(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_user_$uid');
    } catch (e) {
      print('❌ Erreur nettoyage local: $e');
    }
  }

  // Dans SimpleAuthService - Ajoutez cette méthode
  Future<Map<String, dynamic>> createClientAccount({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      print('🔄 Création compte client: $email');

      // Validation
      if (password.length < 6) {
        return {
          'success': false,
          'error': 'Le mot de passe doit contenir au moins 6 caractères'
        };
      }

      if (!email.contains('@')) {
        return {'success': false, 'error': 'Email invalide'};
      }

      // Créer l'utilisateur Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // Sauvegarder dans Firestore
      final appUser = AppUser(
        uid: uid,
        email: email.trim(),
        name: name.trim(),
        userType: UserType.client,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email.trim(),
        'name': name.trim(),
        'userType': 'client',
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'firstLogin': true, // Pour forcer le changement de mot de passe
        'isActive': true,
      });

      // Sauvegarder localement
      await _saveUserLocally(appUser);

      print('✅ Compte client créé avec succès: $email');
      return {'success': true, 'user': appUser};
    } on FirebaseAuthException catch (e) {
      final error = _handleFirebaseError(e);
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': 'Erreur inattendue: $e'};
    }
  }

  // Dans SimpleAuthService - Ajoutez cette méthode
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      print('🔄 Réinitialisation mot de passe pour: $email');

      if (!email.contains('@')) {
        return {'success': false, 'error': 'Email invalide'};
      }

      // Envoyer l'email de réinitialisation via Firebase Auth
      await _auth.sendPasswordResetEmail(email: email.trim());

      print('✅ Email de réinitialisation envoyé à: $email');
      return {
        'success': true,
        'message': 'Un email de réinitialisation a été envoyé à $email'
      };
    } on FirebaseAuthException catch (e) {
      final error = _handleFirebaseError(e);
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': 'Erreur inattendue: $e'};
    }
  }

  // Déconnexion
  Future<void> logout() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _clearLocalUser(user.uid);
    }
    await _auth.signOut();
    print('✅ Déconnexion réussie');
  }

  // CORRECTION: Stream avec parenthèses
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isUserLoggedIn => _auth.currentUser != null;

  // Gestion des erreurs Firebase
  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Un compte avec cet email existe déjà';
      case 'invalid-email':
        return 'Email invalide';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Problème de connexion réseau';
      // AJOUT pour la réinitialisation
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'invalid-credential':
        return 'Identifiants invalides';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}
