// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/user_model.dart';
// import '../models/enriched_client_model.dart';

// class FirebaseAuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Initialiser le service
//   Future<void> init() async {
//     print('✅ FirebaseAuthService initialisé');
//   }

//   // Inscription
//   Future<String?> register({
//     required String email,
//     required String password,
//     required String name,
//     required UserType userType,
//     String? garageSecretKey,
//     required bool isClientSpace,
//   }) async {
//     try {
//       print('🔄 Début inscription Firebase: $email');

//       // Validation pour l'inscription garage
//       if (userType == UserType.garage) {
//         if (garageSecretKey != "GARAGE_SECRET_2024") {
//           return 'Clé d\'inscription garage invalide. Contactez l\'administrateur.';
//         }
//       }

//       // VÉRIFICATION DE SÉCURITÉ : Un client ne peut pas s'inscrire comme garage
//       if (isClientSpace && userType == UserType.garage) {
//         return 'Impossible de créer un compte garage depuis l\'espace client.';
//       }

//       // VÉRIFICATION DE SÉCURITÉ : Un garage ne peut pas s'inscrire comme client
//       if (!isClientSpace && userType == UserType.client) {
//         return 'Impossible de créer un compte client depuis l\'espace garage.';
//       }

//       if (password.length < 6) {
//         return 'Le mot de passe doit contenir au moins 6 caractères';
//       }

//       if (!email.contains('@')) {
//         return 'Email invalide';
//       }

//       if (name.isEmpty) {
//         return 'Veuillez entrer votre nom';
//       }

//       // Vérifier si l'email existe déjà dans Firebase Auth
//       try {
//         final methods = await _auth.fetchSignInMethodsForEmail(email);
//         if (methods.isNotEmpty) {
//           return 'Un compte avec cet email existe déjà';
//         }
//       } catch (e) {
//         // Continuer si l'email n'existe pas
//       }

//       // Créer l'utilisateur dans Firebase Authentication
//       final UserCredential userCredential =
//           await _auth.createUserWithEmailAndPassword(
//         email: email.trim(),
//         password: password,
//       );

//       final String uid = userCredential.user!.uid;

//       // Créer le document utilisateur dans Firestore
//       final appUser = AppUser(
//         uid: uid,
//         email: email.trim(),
//         name: name.trim(),
//         userType: userType,
//         createdAt: DateTime.now(),
//       );

//       await _firestore.collection('users').doc(uid).set(appUser.toMap());

//       // Si c'est un client, créer aussi le profil client
//       if (userType == UserType.client) {
//         final client = EnrichedClient(
//           id: uid,
//           uid: uid, // Même ID que l'utilisateur
//           name: name.trim(),
//           email: email.trim(),
//           phone: '+225 00 00 00 00',
//           address: 'Adresse non spécifiée',
//           registrationDate: DateTime.now(),
//           totalAppointments: 0,
//           totalSpent: 0,
//           loyaltyLevel: 'Nouveau',
//           vehicles: [],
//         );

//         await _firestore.collection('clients').doc(uid).set(client.toMap());
//         print('✅ Profil client créé dans Firestore: $email');
//       }

//       print('✅ Utilisateur créé avec succès dans Firebase: $email');
//       return null; // Succès
//     } on FirebaseAuthException catch (e) {
//       print('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
//       return _handleFirebaseError(e);
//     } catch (e) {
//       print('❌ Erreur inattendue lors de l\'inscription: $e');
//       return 'Une erreur est survenue lors de l\'inscription: $e';
//     }
//   }

//   // Connexion avec gestion du mode hors ligne
//   Future<String?> login(String email, String password,
//       {required bool isClientSpace}) async {
//     try {
//       print('🔄 Tentative de connexion Firebase: $email');

//       if (email.isEmpty || password.isEmpty) {
//         return 'Veuillez remplir tous les champs';
//       }

//       // Connexion avec Firebase Authentication
//       final UserCredential userCredential =
//           await _auth.signInWithEmailAndPassword(
//         email: email.trim(),
//         password: password,
//       );

//       final String uid = userCredential.user!.uid;

//       // Récupérer les données utilisateur depuis Firestore avec gestion hors ligne
//       final userDoc = await _firestore
//           .collection('users')
//           .doc(uid)
//           .get(const GetOptions(source: Source.serverAndCache));

//       if (!userDoc.exists) {
//         await _auth.signOut();
//         return 'Profil utilisateur non trouvé';
//       }

//       final userData = userDoc.data()!;
//       final userType = UserType.values.firstWhere(
//         (e) => e.name == userData['userType'],
//         orElse: () => UserType.client,
//       );

//       // VÉRIFICATION DE SÉCURITÉ CRITIQUE : Vérifier que l'utilisateur a accès à l'espace
//       if (isClientSpace && userType != UserType.client) {
//         await _auth.signOut();
//         return 'Accès refusé. Cet espace est réservé aux clients.';
//       }

//       if (!isClientSpace && userType != UserType.garage) {
//         await _auth.signOut();
//         return 'Accès refusé. Cet espace est réservé aux garages.';
//       }

//       print('✅ Connexion réussie: $email (${userType.name})');
//       return null; // Succès
//     } on FirebaseAuthException catch (e) {
//       print('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
//       return _handleFirebaseError(e);
//     } catch (e) {
//       print('❌ Erreur inattendue lors de la connexion: $e');
//       return 'Une erreur est survenue lors de la connexion: $e';
//     }
//   }

//   // Déconnexion
//   Future<void> logout() async {
//     await _auth.signOut();
//     print('✅ Déconnexion réussie de Firebase');
//   }

//   // Récupérer les informations utilisateur avec gestion hors ligne
//   Future<AppUser?> getCurrentAppUser() async {
//     final User? user = _auth.currentUser;
//     if (user == null) {
//       print('🔍 Aucun utilisateur Firebase connecté');
//       return null;
//     }

//     try {
//       final userDoc = await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .get(const GetOptions(source: Source.serverAndCache));

//       if (!userDoc.exists) {
//         print('❌ Document utilisateur non trouvé dans Firestore');
//         return null;
//       }

//       final appUser = AppUser.fromMap(userDoc.data()!);
//       print('✅ Utilisateur courant récupéré: ${appUser.email}');
//       return appUser;
//     } catch (e) {
//       print('❌ Erreur récupération utilisateur: $e');
//       return null;
//     }
//   }

//   // Vérifier si un utilisateur est connecté
//   bool get isUserLoggedIn => _auth.currentUser != null;

//   // Stream pour les changements d'authentification - CORRIGÉ
//   Stream<User?> get authStateChanges => _auth.authStateChanges();

//   // Gestion des erreurs Firebase
//   String _handleFirebaseError(FirebaseAuthException e) {
//     switch (e.code) {
//       case 'email-already-in-use':
//         return 'Un compte avec cet email existe déjà';
//       case 'invalid-email':
//         return 'Email invalide';
//       case 'weak-password':
//         return 'Le mot de passe doit contenir au moins 6 caractères';
//       case 'user-not-found':
//         return 'Aucun compte trouvé avec cet email';
//       case 'wrong-password':
//         return 'Mot de passe incorrect';
//       case 'too-many-requests':
//         return 'Trop de tentatives. Réessayez plus tard.';
//       case 'network-request-failed':
//         return 'Problème de connexion réseau. Vérifiez votre connexion Internet.';
//       default:
//         return 'Erreur d\'authentification: ${e.message}';
//     }
//   }
// }
