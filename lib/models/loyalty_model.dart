class LoyaltyProgram {
  final String id;
  final String clientId;
  final String clientEmail;
  final int points;
  final String currentTier;
  final int totalSpent;
  final int totalVisits;
  final DateTime joinDate;
  final DateTime lastActivity;
  final List<LoyaltyTransaction> transactions;

  LoyaltyProgram({
    required this.id,
    required this.clientId,
    required this.clientEmail,
    required this.points,
    required this.currentTier,
    required this.totalSpent,
    required this.totalVisits,
    required this.joinDate,
    required this.lastActivity,
    required this.transactions,
  });

  String get nextTier {
    switch (currentTier) {
      case 'Nouveau':
        return 'Bronze';
      case 'Bronze':
        return 'Argent';
      case 'Argent':
        return 'Or';
      case 'Or':
        return 'Platine';
      default:
        return 'Max';
    }
  }

  int get pointsToNextTier {
    switch (currentTier) {
      case 'Nouveau':
        return 100 - points;
      case 'Bronze':
        return 300 - points;
      case 'Argent':
        return 600 - points;
      case 'Or':
        return 1000 - points;
      default:
        return 0;
    }
  }

  double get progressToNextTier {
    switch (currentTier) {
      case 'Nouveau':
        return points / 100;
      case 'Bronze':
        return points / 300;
      case 'Argent':
        return points / 600;
      case 'Or':
        return points / 1000;
      default:
        return 1.0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientEmail': clientEmail,
      'points': points,
      'currentTier': currentTier,
      'totalSpent': totalSpent,
      'totalVisits': totalVisits,
      'joinDate': joinDate.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
    };
  }
}

class LoyaltyTransaction {
  final String id;
  final DateTime date;
  final String type; // 'earn', 'redeem', 'bonus'
  final int points;
  final String description;
  final String? appointmentId;

  LoyaltyTransaction({
    required this.id,
    required this.date,
    required this.type,
    required this.points,
    required this.description,
    this.appointmentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type,
      'points': points,
      'description': description,
      'appointmentId': appointmentId,
    };
  }
}

class LoyaltyReward {
  final String id;
  final String name;
  final String description;
  final int pointsRequired;
  final String category;
  final bool isActive;
  final int stock;
  final DateTime validUntil;

  LoyaltyReward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsRequired,
    required this.category,
    required this.isActive,
    required this.stock,
    required this.validUntil,
  });

  bool get isAvailable =>
      isActive && stock > 0 && validUntil.isAfter(DateTime.now());

  // Ajoutez cette méthode copyWith
  LoyaltyReward copyWith({
    String? id,
    String? name,
    String? description,
    int? pointsRequired,
    String? category,
    bool? isActive,
    int? stock,
    DateTime? validUntil,
  }) {
    return LoyaltyReward(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      stock: stock ?? this.stock,
      validUntil: validUntil ?? this.validUntil,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pointsRequired': pointsRequired,
      'category': category,
      'isActive': isActive,
      'stock': stock,
      'validUntil': validUntil.toIso8601String(),
    };
  }
}
