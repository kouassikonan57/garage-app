class LanguageService {
  static String currentLanguage = 'fr';

  static final Map<String, Map<String, String>> _translations = {
    'fr': {
      // Titres principaux
      'settings': 'Paramètres',
      'language': 'Langue',
      'notifications': 'Notifications',
      'offline_mode': 'Mode Hors-ligne',

      // Section Langue
      'current_language': 'Langue actuelle',
      'language_changed': 'Langue changée',

      // Section Notifications
      'appointment_reminders': 'Rappels de rendez-vous',
      'reminder_description': 'Recevoir des rappels 24h avant',
      'status_notifications': 'Notifications de statut',
      'status_description': 'Quand votre rendez-vous est confirmé/annulé',
      'promotional_notifications': 'Notifications promotionnelles',
      'promotional_description': 'Offres spéciales et promotions',

      // Section Mode hors-ligne
      'enable_offline': 'Activer le mode hors-ligne',
      'offline_description':
          'Synchroniser les données pour utilisation sans internet',
      'offline_activated': 'Mode hors-ligne activé',
      'offline_deactivated': 'Mode hors-ligne désactivé',
      'data_saved': 'données sauvegardées',
      'data_synchronized': 'Données synchronisées',

      // Informations de l'application
      'garage_name': 'Garage Auto Yadi-Group',
      'version': 'Version: 2.0.0',
      'developed_by': 'Développé pour la Côte d\'Ivoire par KFernand',
      'support_phone': '📞 Support: +225 07 57 52 78 81',
      'location': '📍 Abidjan, Côte d\'Ivoire',
      'schedule': '🕒 Lun - Ven: 7h - 18h | Sam: 8h - 16h',
    },
    'en': {
      // Main titles
      'settings': 'Settings',
      'language': 'Language',
      'notifications': 'Notifications',
      'offline_mode': 'Offline Mode',

      // Language Section
      'current_language': 'Current language',
      'language_changed': 'Language changed',

      // Notifications Section
      'appointment_reminders': 'Appointment reminders',
      'reminder_description': 'Receive reminders 24h before',
      'status_notifications': 'Status notifications',
      'status_description': 'When your appointment is confirmed/cancelled',
      'promotional_notifications': 'Promotional notifications',
      'promotional_description': 'Special offers and promotions',

      // Offline Mode Section
      'enable_offline': 'Enable offline mode',
      'offline_description': 'Sync data for use without internet',
      'offline_activated': 'Offline mode activated',
      'offline_deactivated': 'Offline mode deactivated',
      'data_saved': 'data saved',
      'data_synchronized': 'Data synchronized',

      // App Information
      'garage_name': 'Yadi-Group Auto Garage',
      'version': 'Version: 2.0.0',
      'developed_by': 'Developed for Ivory Coast by KFernand',
      'support_phone': '📞 Support: +225 07 57 52 78 81',
      'location': '📍 Abidjan, Ivory Coast',
      'schedule': '🕒 Mon - Fri: 7am - 6pm | Sat: 8am - 4pm',
    },
    'es': {
      // Títulos principales
      'settings': 'Configuración',
      'language': 'Idioma',
      'notifications': 'Notificaciones',
      'offline_mode': 'Modo Sin Conexión',

      // Sección Idioma
      'current_language': 'Idioma actual',
      'language_changed': 'Idioma cambiado',

      // Sección Notificaciones
      'appointment_reminders': 'Recordatorios de citas',
      'reminder_description': 'Recibir recordatorios 24h antes',
      'status_notifications': 'Notificaciones de estado',
      'status_description': 'Cuando su cita es confirmada/cancelada',
      'promotional_notifications': 'Notificaciones promocionales',
      'promotional_description': 'Ofertas especiales y promociones',

      // Sección Modo Sin Conexión
      'enable_offline': 'Activar modo sin conexión',
      'offline_description': 'Sincronizar datos para uso sin internet',
      'offline_activated': 'Modo sin conexión activado',
      'offline_deactivated': 'Modo sin conexión desactivado',
      'data_saved': 'datos guardados',
      'data_synchronized': 'Datos sincronizados',

      // Información de la App
      'garage_name': 'Garage Auto Yadi-Group',
      'version': 'Versión: 2.0.0',
      'developed_by': 'Desarrollado para Costa de Marfil por KFernand',
      'support_phone': '📞 Soporte: +225 07 57 52 78 81',
      'location': '📍 Abiyán, Costa de Marfil',
      'schedule': '🕒 Lun - Vie: 7h - 18h | Sáb: 8h - 16h',
    },
    'de': {
      // Haupttitel
      'settings': 'Einstellungen',
      'language': 'Sprache',
      'notifications': 'Benachrichtigungen',
      'offline_mode': 'Offline-Modus',

      // Sprachbereich
      'current_language': 'Aktuelle Sprache',
      'language_changed': 'Sprache geändert',

      // Benachrichtigungsbereich
      'appointment_reminders': 'Terminerinnerungen',
      'reminder_description': 'Erinnerungen 24h vorher erhalten',
      'status_notifications': 'Statusbenachrichtigungen',
      'status_description': 'Wenn Ihr Termin bestätigt/abgesagt wird',
      'promotional_notifications': 'Werbenachrichten',
      'promotional_description': 'Sonderangebote und Aktionen',

      // Offline-Modus Bereich
      'enable_offline': 'Offline-Modus aktivieren',
      'offline_description':
          'Daten für die Nutzung ohne Internet synchronisieren',
      'offline_activated': 'Offline-Modus aktiviert',
      'offline_deactivated': 'Offline-Modus deaktiviert',
      'data_saved': 'Daten gespeichert',
      'data_synchronized': 'Daten synchronisiert',

      // App-Informationen
      'garage_name': 'Auto Garage Yadi-Group',
      'version': 'Version: 2.0.0',
      'developed_by': 'Entwickelt für die Elfenbeinküste von KFernand',
      'support_phone': '📞 Support: +225 07 57 52 78 81',
      'location': '📍 Abidjan, Elfenbeinküste',
      'schedule': '🕒 Mo - Fr: 7h - 18h | Sa: 8h - 16h',
    },
    'ar': {
      // العناوين الرئيسية
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'notifications': 'الإشعارات',
      'offline_mode': 'وضع عدم الاتصال',

      // قسم اللغة
      'current_language': 'اللغة الحالية',
      'language_changed': 'تم تغيير اللغة',

      // قسم الإشعارات
      'appointment_reminders': 'تذكيرات المواعيد',
      'reminder_description': 'تلقي تذكيرات قبل 24 ساعة',
      'status_notifications': 'إشعارات الحالة',
      'status_description': 'عند تأكيد/إلغاء موعدك',
      'promotional_notifications': 'إشعارات ترويجية',
      'promotional_description': 'عروض خاصة وتخفيضات',

      // قسم وضع عدم الاتصال
      'enable_offline': 'تفعيل وضع عدم الاتصال',
      'offline_description': 'مزامنة البيانات للاستخدام بدون إنترنت',
      'offline_activated': 'تم تفعيل وضع عدم الاتصال',
      'offline_deactivated': 'تم إلغاء وضع عدم الاتصال',
      'data_saved': 'بيانات محفوظة',
      'data_synchronized': 'بيانات متزامنة',

      // معلومات التطبيق
      'garage_name': 'كراج يادي-جروب للسيارات',
      'version': 'الإصدار: 2.0.0',
      'developed_by': 'مطور من أجل ساحل العاج بواسطة KFernand',
      'support_phone': '📞 الدعم: +225 07 57 52 78 81',
      'location': '📍 أبيدجان، ساحل العاج',
      'schedule': '🕒 الإثنين - الجمعة: 7 ص - 6 م | السبت: 8 ص - 4 م',
    },
    'zh': {
      // 主标题
      'settings': '设置',
      'language': '语言',
      'notifications': '通知',
      'offline_mode': '离线模式',

      // 语言部分
      'current_language': '当前语言',
      'language_changed': '语言已更改',

      // 通知部分
      'appointment_reminders': '预约提醒',
      'reminder_description': '提前24小时接收提醒',
      'status_notifications': '状态通知',
      'status_description': '当您的预约被确认/取消时',
      'promotional_notifications': '促销通知',
      'promotional_description': '特别优惠和促销活动',

      // 离线模式部分
      'enable_offline': '启用离线模式',
      'offline_description': '同步数据以便在没有互联网时使用',
      'offline_activated': '离线模式已激活',
      'offline_deactivated': '离线模式已停用',
      'data_saved': '数据已保存',
      'data_synchronized': '数据已同步',

      // 应用信息
      'garage_name': 'Yadi-Group 汽车修理厂',
      'version': '版本: 2.0.0',
      'developed_by': '为科特迪瓦开发 by KFernand',
      'support_phone': '📞 支持: +225 07 57 52 78 81',
      'location': '📍 阿比让, 科特迪瓦',
      'schedule': '🕒 周一 - 周五: 7点 - 18点 | 周六: 8点 - 16点',
    },
  };

  static String translate(String key) {
    return _translations[currentLanguage]?[key] ??
        _translations['fr']?[key] ??
        key;
  }

  static void setLanguage(String languageCode) {
    if (_translations.containsKey(languageCode)) {
      currentLanguage = languageCode;
    }
  }

  static List<Map<String, String>> get availableLanguages {
    return [
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
      {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
      {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    ];
  }

  static String getCurrentLanguageName() {
    final lang = availableLanguages.firstWhere(
      (element) => element['code'] == currentLanguage,
      orElse: () => {'name': 'Français'},
    );
    return lang['name']!;
  }

  static String getCurrentLanguageFlag() {
    final lang = availableLanguages.firstWhere(
      (element) => element['code'] == currentLanguage,
      orElse: () => {'flag': '🇫🇷'},
    );
    return lang['flag']!;
  }
}
