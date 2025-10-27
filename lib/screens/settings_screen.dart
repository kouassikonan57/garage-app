import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/offline_service.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = LanguageService.currentLanguage;
  bool _appointmentReminders = true;
  bool _statusNotifications = true;
  bool _promotionalNotifications = false;
  bool _offlineMode = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = LanguageService.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(LanguageService.translate('settings')),
            backgroundColor: Colors.orange,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Langue
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LanguageService.translate('language'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${LanguageService.translate('current_language')}: ${LanguageService.getCurrentLanguageFlag()} ${LanguageService.getCurrentLanguageName()}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 10),
                          DropdownButton<String>(
                            value: _selectedLanguage,
                            isExpanded: true,
                            items:
                                LanguageService.availableLanguages.map((lang) {
                              return DropdownMenuItem(
                                value: lang['code'],
                                child: Text('${lang['flag']} ${lang['name']}'),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedLanguage = newValue;
                                });

                                final languageProvider =
                                    Provider.of<LanguageProvider>(context,
                                        listen: false);
                                languageProvider.setLanguage(newValue);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${LanguageService.translate('language_changed')}: ${LanguageService.getCurrentLanguageName()}',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Notifications
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LanguageService.translate('notifications'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile(
                            title: Text(LanguageService.translate(
                                'appointment_reminders')),
                            subtitle: Text(LanguageService.translate(
                                'reminder_description')),
                            value: _appointmentReminders,
                            onChanged: (value) {
                              setState(() {
                                _appointmentReminders = value;
                              });
                            },
                          ),
                          SwitchListTile(
                            title: Text(LanguageService.translate(
                                'status_notifications')),
                            subtitle: Text(LanguageService.translate(
                                'status_description')),
                            value: _statusNotifications,
                            onChanged: (value) {
                              setState(() {
                                _statusNotifications = value;
                              });
                            },
                          ),
                          SwitchListTile(
                            title: Text(LanguageService.translate(
                                'promotional_notifications')),
                            subtitle: Text(LanguageService.translate(
                                'promotional_description')),
                            value: _promotionalNotifications,
                            onChanged: (value) {
                              setState(() {
                                _promotionalNotifications = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Mode hors-ligne
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LanguageService.translate('offline_mode'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile(
                            title: Text(
                                LanguageService.translate('enable_offline')),
                            subtitle: Text(LanguageService.translate(
                                'offline_description')),
                            value: _offlineMode,
                            onChanged: (value) async {
                              setState(() {
                                _offlineMode = value;
                              });

                              final offlineService = OfflineService();

                              if (value) {
                                // Activer le mode hors-ligne
                                await offlineService.initializeTestData();
                                final status =
                                    offlineService.getOfflineStatus();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${LanguageService.translate('offline_activated')} - ${status['dataSize']} ${LanguageService.translate('data_saved')}',
                                    ),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              } else {
                                // Désactiver le mode hors-ligne
                                await offlineService.clearOfflineData();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${LanguageService.translate('offline_deactivated')} - ${LanguageService.translate('data_synchronized')}',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Informations de l'application
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LanguageService.translate('garage_name'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(LanguageService.translate('version')),
                          Text(LanguageService.translate('developed_by')),
                          const SizedBox(height: 8),
                          Text(
                            LanguageService.translate('support_phone'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LanguageService.translate('location'),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            LanguageService.translate('schedule'),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
