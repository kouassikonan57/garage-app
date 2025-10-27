import 'dart:convert'; // IMPORT AJOUTÉ

enum UserType { client, garage }

class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserType userType;
  final DateTime createdAt;
  final bool isActive;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.userType,
    required this.createdAt,
    this.isActive = true,
  });

  // Méthode pour vérifier l'accès à l'espace garage
  bool get canAccessGarageSpace => userType == UserType.garage;

  // Convertir vers Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'userType': userType.name,
      'createdAt':
          createdAt.millisecondsSinceEpoch, // Firebase préfère timestamp
      'isActive': isActive,
    };
  }

  // Créer depuis Map de Firebase
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      email: map['email'],
      name: map['name'],
      userType: UserType.values.firstWhere(
        (e) => e.name == map['userType'],
        orElse: () => UserType.client,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isActive: map['isActive'] ?? true,
    );
  }

  // NOUVELLE MÉTHODE: Convertir en JSON string pour le stockage local
  String toJsonString() {
    return '''
    {
      "uid": "$uid",
      "email": "$email",
      "name": "$name",
      "userType": "${userType.name}",
      "createdAt": "${createdAt.toIso8601String()}",
      "isActive": $isActive
    }
    ''';
  }

  // NOUVELLE MÉTHODE: Créer depuis JSON string
  factory AppUser.fromJsonString(String jsonString) {
    try {
      // Nettoyer la chaîne JSON
      final cleanedJson = jsonString.replaceAll(RegExp(r'\s+'), ' ').trim();
      final Map<String, dynamic> data = json.decode(cleanedJson);

      return AppUser(
        uid: data['uid'] ?? '',
        email: data['email'] ?? '',
        name: data['name'] ?? '',
        userType: UserType.values.firstWhere(
          (e) => e.name == data['userType'],
          orElse: () => UserType.client,
        ),
        createdAt: data['createdAt'] != null
            ? DateTime.parse(data['createdAt'])
            : DateTime.now(),
        isActive: data['isActive'] ?? true,
      );
    } catch (e) {
      print('❌ Erreur parsing JSON: $e');
      // Retourner un utilisateur par défaut en cas d'erreur
      return AppUser(
        uid: 'default_uid',
        email: 'default@email.com',
        name: 'Utilisateur',
        userType: UserType.client,
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  String toString() {
    return 'AppUser{email: $email, name: $name, userType: $userType}';
  }
}
