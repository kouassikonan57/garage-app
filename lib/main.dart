import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'firebase_options.dart';
import 'providers/language_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/garage_management_screen.dart';
import 'services/simple_auth_service.dart';
import 'services/firebase_messaging_service.dart';
import 'services/advanced_reminder_service.dart';
import 'services/firebase_client_service.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase (Auth seulement)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('✅ Firebase Auth initialisé');

  // Initialiser le système de rappels avancés
  await AdvancedReminderService.initialize();
  await FirebaseMessagingService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SimpleAuthService>(
          create: (context) => SimpleAuthService(),
        ),
        Provider(create: (context) => FirebaseClientService()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Garage Auto Yadi-Group',
            theme: ThemeData(
              primaryColor: Colors.orange,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.orange,
                primary: Colors.orange,
                secondary: Colors.blue,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 2,
                centerTitle: true,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              fontFamily: 'Roboto',
              useMaterial3: true,
            ),
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
            routes: {
              '/garage-management': (context) => const GarageManagementScreen(),
            },
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/garage-management':
                  return MaterialPageRoute(
                      builder: (context) => const GarageManagementScreen());
                default:
                  return null;
              }
            },
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Page non trouvée')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Page non trouvée: ${settings.name}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Retour'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<SimpleAuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<AppUser?>(
            future: authService.getCurrentAppUser(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              final appUser = userSnapshot.data;
              if (appUser != null) {
                return HomeScreen(
                  isClient: appUser.userType == UserType.client,
                  userName: appUser.name,
                  userEmail: appUser.email,
                );
              } else {
                return const WelcomeScreen();
              }
            },
          );
        } else {
          return const WelcomeScreen();
        }
      },
    );
  }
}

// Écran de chargement animé
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animé avec fond sombre pour mieux contraster
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blueGrey[800],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueGrey.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 3,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  width: 80,
                  height: 80,
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .rotate(duration: 4000.ms, curve: Curves.easeInOut)
                .animate(onPlay: (controller) => controller.repeat())
                .scaleXY(duration: 2500.ms, begin: 0.85, end: 1.15)
                .then(delay: 500.ms)
                .shimmer(duration: 2000.ms, delay: 1000.ms),

            const SizedBox(height: 30),

            // Titre avec animations améliorées
            const Text(
              'Garage Auto Yadi-Group',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                fontFamily: 'Roboto',
                letterSpacing: 1.2,
              ),
            )
                .animate()
                .fadeIn(duration: 1200.ms, delay: 300.ms)
                .slideY(begin: 0.8, end: 0, curve: Curves.elasticOut),

            const SizedBox(height: 10),

            const Text(
              'Service de qualité en Côte d\'Ivoire',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            )
                .animate()
                .fadeIn(delay: 800.ms)
                .slideY(begin: 0.5, end: 0, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 400;
          final isVerySmallScreen = constraints.maxWidth < 350;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 10.0 : 14.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: isSmallScreen ? 5 : 8),

                    // LOGO AVEC FOND SOMBRE
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: isSmallScreen ? 85 : 100,
                        height: isSmallScreen ? 85 : 100,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[800],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueGrey.withOpacity(0.6),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.contain,
                            width: isSmallScreen ? 60 : 70,
                            height: isSmallScreen ? 60 : 70,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.orange, Colors.deepOrange],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.directions_car_filled,
                                  size: isSmallScreen ? 35 : 40,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // Titre responsive
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                              stops: [0.3, 0.7],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: Text(
                              'Garage Auto Yadi-Group',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Roboto',
                                letterSpacing: 1.0,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ).animate().slideY(
                              begin: 1.0,
                              end: 0,
                              duration: 1000.ms,
                              curve: Curves.elasticOut),

                          SizedBox(height: isSmallScreen ? 6 : 8),

                          // Sous-titre responsive
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 10 : 12,
                              vertical: isSmallScreen ? 5 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              'Service de qualité en Côte d\'Ivoire',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 500.ms)
                              .scale(delay: 500.ms, duration: 700.ms)
                              .slideY(
                                  begin: 0.5, end: 0, curve: Curves.easeOut),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Bouton Client responsive
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: double.infinity,
                          height: isSmallScreen ? 45 : 48,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              elevation: 4,
                              shadowColor: Colors.orange.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              _controller
                                  .animateTo(0.1,
                                      duration:
                                          const Duration(milliseconds: 100))
                                  .then((_) => _controller.animateTo(1.0,
                                      duration:
                                          const Duration(milliseconds: 300)));

                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const AuthScreen(isClient: true),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 500),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person,
                                    size: isSmallScreen ? 16 : 18,
                                    color: Colors.white),
                                SizedBox(width: isSmallScreen ? 5 : 6),
                                Flexible(
                                  child: Text(
                                    'JE SUIS CLIENT',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms).slideX(
                        begin: -1.0,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOut),

                    SizedBox(height: isSmallScreen ? 8 : 10),

                    // Bouton Garage responsive
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: double.infinity,
                          height: isSmallScreen ? 45 : 48,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              elevation: 4,
                              shadowColor: Colors.blue.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              _controller
                                  .animateTo(0.1,
                                      duration:
                                          const Duration(milliseconds: 100))
                                  .then((_) => _controller.animateTo(1.0,
                                      duration:
                                          const Duration(milliseconds: 300)));

                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const AuthScreen(isClient: false),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 500),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.build_circle,
                                    size: isSmallScreen ? 16 : 18,
                                    color: Colors.white),
                                SizedBox(width: isSmallScreen ? 5 : 6),
                                Flexible(
                                  child: Text(
                                    'JE SUIS LE GARAGE',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 900.ms).slideX(
                        begin: 1.0,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOut),

                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // SECTION CONTACT RESPONSIVE
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Color(0xFFFFF8E1)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Titre contact responsive
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 10,
                                vertical: isSmallScreen ? 4 : 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.phone_in_talk,
                                      size: isSmallScreen ? 16 : 18,
                                      color: Colors.orange[700]),
                                  SizedBox(width: isSmallScreen ? 4 : 5),
                                  Text(
                                    'Contactez-nous',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                      fontSize: isSmallScreen ? 13 : 14,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().scale(
                                duration: 600.ms, curve: Curves.elasticOut),

                            SizedBox(height: isSmallScreen ? 10 : 12),

                            // CONTACTS SUR LA MÊME LIGNE - RESPONSIVE
                            _buildResponsiveContacts(
                                isSmallScreen, isVerySmallScreen),

                            SizedBox(height: isSmallScreen ? 10 : 12),

                            // Horaires et badge urgence responsive
                            _buildScheduleAndEmergency(isSmallScreen),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 1100.ms).slideY(
                        begin: 1.0,
                        end: 0,
                        duration: 700.ms,
                        curve: Curves.easeOut),

                    SizedBox(height: isSmallScreen ? 8 : 12),

                    // Footer responsive
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            '© 2024 Yadi-Group - Tous droits réservés',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 8 : 9,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 3 : 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 6 : 8,
                              vertical: isSmallScreen ? 2 : 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Développé par KFernand',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 7 : 8,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 1300.ms),
                    ),

                    SizedBox(height: isSmallScreen ? 5 : 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveContacts(bool isSmallScreen, bool isVerySmallScreen) {
    if (isVerySmallScreen) {
      return Column(
        children: [
          _ResponsiveContactItem(
            number: '+225 07 00 00 00 00',
            icon: Icons.phone,
            iconColor: Colors.orange,
            label: 'Principal',
            isSmallScreen: isSmallScreen,
            isVerySmallScreen: isVerySmallScreen,
          ),
          SizedBox(height: 6),
          _ResponsiveContactItem(
            number: '+225 05 00 00 00 00',
            icon: Icons.chat,
            iconColor: Colors.green,
            label: 'WhatsApp',
            isSmallScreen: isSmallScreen,
            isVerySmallScreen: isVerySmallScreen,
          ),
          SizedBox(height: 6),
          _ResponsiveContactItem(
            number: '+225 01 00 00 00 00',
            icon: Icons.emergency,
            iconColor: Colors.red,
            label: 'Urgence',
            isEmergency: true,
            isSmallScreen: isSmallScreen,
            isVerySmallScreen: isVerySmallScreen,
          ),
        ],
      )
          .animate()
          .fadeIn(delay: 200.ms)
          .slideY(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOut);
    } else {
      return Row(
        children: [
          Expanded(
            child: _ResponsiveContactItem(
              number: '+225 00 00 00 00 00',
              icon: Icons.phone,
              iconColor: Colors.orange,
              label: 'Principal',
              isSmallScreen: isSmallScreen,
              isVerySmallScreen: isVerySmallScreen,
            ),
          ),
          SizedBox(width: isSmallScreen ? 4 : 6),
          Expanded(
            child: _ResponsiveContactItem(
              number: '+225 05 00 00 00 00',
              icon: Icons.chat,
              iconColor: Colors.green,
              label: 'WhatsApp',
              isSmallScreen: isSmallScreen,
              isVerySmallScreen: isVerySmallScreen,
            ),
          ),
          SizedBox(width: isSmallScreen ? 4 : 6),
          Expanded(
            child: _ResponsiveContactItem(
              number: '+225 01 00 00 00 00',
              icon: Icons.emergency,
              iconColor: Colors.red,
              label: 'Urgence',
              isEmergency: true,
              isSmallScreen: isSmallScreen,
              isVerySmallScreen: isVerySmallScreen,
            ),
          ),
        ],
      )
          .animate()
          .fadeIn(delay: 200.ms)
          .slideY(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOut);
    }
  }

  Widget _buildScheduleAndEmergency(bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 10,
              vertical: isSmallScreen ? 5 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time,
                    size: isSmallScreen ? 10 : 12, color: Colors.blue[700]),
                SizedBox(width: isSmallScreen ? 3 : 4),
                Flexible(
                  child: Text(
                    'Lun-Ven: 7h-18h\nSam: 8h-16h',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 8 : 9,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 4 : 6),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 6 : 8,
              vertical: isSmallScreen ? 4 : 5,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emergency,
                    size: isSmallScreen ? 10 : 12, color: Colors.white),
                SizedBox(width: isSmallScreen ? 2 : 3),
                Flexible(
                  child: Text(
                    '24h/24',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 8 : 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scaleXY(duration: 2000.ms, begin: 0.98, end: 1.02),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }
}

// WIDGET RESPONSIVE POUR LES CONTACTS
class _ResponsiveContactItem extends StatelessWidget {
  final String number;
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isEmergency;
  final bool isSmallScreen;
  final bool isVerySmallScreen;

  const _ResponsiveContactItem({
    required this.number,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isSmallScreen,
    required this.isVerySmallScreen,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: isEmergency ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône responsive
          Container(
            width: isSmallScreen ? 24 : 28,
            height: isSmallScreen ? 24 : 28,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withOpacity(0.15),
                width: 1.2,
              ),
            ),
            child: Icon(
              icon,
              size: isSmallScreen ? 12 : 14,
              color: iconColor,
            ),
          ),

          SizedBox(height: isSmallScreen ? 3 : 4),

          // Numéro de téléphone - SUR UNE SEULE LIGNE
          SizedBox(
            height: isSmallScreen ? 16 : 18,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                number,
                style: TextStyle(
                  fontSize: isSmallScreen ? 9 : 10,
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 2 : 3),

          // Label responsive
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 3 : 4,
              vertical: isSmallScreen ? 1 : 2,
            ),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(isEmergency ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: iconColor.withOpacity(0.2),
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEmergency)
                  Icon(Icons.flash_on,
                      size: isSmallScreen ? 6 : 7, color: iconColor),
                if (isEmergency) SizedBox(width: isSmallScreen ? 1 : 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 6 : 7,
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
