import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Demander les permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('📱 Permissions notifications: ${settings.authorizationStatus}');

    // Gérer les messages en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Message reçu en foreground: ${message.notification?.title}');
    });

    // Gérer les messages en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
          '📨 Message ouvert depuis background: ${message.notification?.title}');
    });
  }

  static Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('❌ Erreur récupération token FCM: $e');
      return null;
    }
  }
}
