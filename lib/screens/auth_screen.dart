import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simple_auth_service.dart';
import '../models/user_model.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool isClient;

  const AuthScreen({super.key, required this.isClient});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _garageSecretKeyController = TextEditingController();

  // Méthode pour obtenir la largeur responsive
  double _getResponsiveWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return 500; // Tablette et desktop
    } else {
      return double.infinity; // Mobile
    }
  }

  // Méthode pour obtenir le padding responsive
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return const EdgeInsets.symmetric(horizontal: 50, vertical: 40);
    } else {
      return const EdgeInsets.all(20.0);
    }
  }

  // Méthode pour la taille de l'icône responsive
  double _getIconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return 100;
    } else {
      return 80;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<SimpleAuthService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isClient ? 'Espace Client' : 'Espace Garage'),
        backgroundColor: widget.isClient ? Colors.orange : Colors.blue,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: _getResponsivePadding(context),
            child: Container(
              width: _getResponsiveWidth(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image/Logo responsive
                  Container(
                    height: _getIconSize(context) + 40,
                    margin: const EdgeInsets.only(bottom: 30),
                    child: Icon(
                      widget.isClient ? Icons.person : Icons.build,
                      size: _getIconSize(context),
                      color: widget.isClient ? Colors.orange : Colors.blue,
                    ),
                  ),

                  // Titre responsive
                  Text(
                    widget.isClient ? 'Espace Client' : 'Espace Garage',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.isClient ? Colors.orange : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    isLogin
                        ? 'Connectez-vous à votre compte'
                        : 'Créez votre compte',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Formulaire
                  _buildAuthForm(authService, theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm(SimpleAuthService authService, ThemeData theme) {
    return Column(
      children: [
        // Champ Nom (seulement pour l'inscription)
        if (!isLogin) ...[
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom complet *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            ),
          ),
          const SizedBox(height: 15),
        ],

        // Champ clé secrète pour l'inscription garage
        if (!isLogin && !widget.isClient) ...[
          TextField(
            controller: _garageSecretKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Clé d\'inscription garage *',
              hintText: 'Obtenez cette clé auprès de l\'administrateur',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.security),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            ),
          ),
          const SizedBox(height: 15),
        ],

        // Champ Email
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 15),

        // Champ Mot de passe avec œil
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          ),
        ),
        const SizedBox(height: 20),

        // Informations sur les exigences de mot de passe
        if (!isLogin) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Le mot de passe doit contenir au moins 6 caractères',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(),
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
        ],

        // Bouton principal responsive
        if (isLoading)
          const Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Traitement en cours...'),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            height: _getButtonHeight(),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isClient ? Colors.orange : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () => _handleAuth(authService),
              child: Text(
                isLogin ? 'SE CONNECTER' : 'CRÉER UN COMPTE',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize() + 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Lien mot de passe oublié (seulement en mode connexion)
        if (isLogin) ...[
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: Text(
                'Mot de passe oublié ?',
                style: TextStyle(
                  color: widget.isClient ? Colors.orange : Colors.blue,
                  fontWeight: FontWeight.w500,
                  fontSize: _getResponsiveFontSize(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Lien pour basculer entre connexion/inscription
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  setState(() {
                    isLogin = !isLogin;
                    _garageSecretKeyController.clear();
                  });
                },
          child: Text(
            isLogin
                ? 'Pas de compte ? Créer un compte'
                : 'Déjà un compte ? Se connecter',
            style: TextStyle(
              color: widget.isClient ? Colors.orange : Colors.blue,
              fontWeight: FontWeight.w500,
              fontSize: _getResponsiveFontSize(),
            ),
          ),
        ),
      ],
    );
  }

  // Méthodes utilitaires pour le responsive
  double _getResponsiveFontSize() {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return 16; // Tablette et desktop
    } else {
      return 14; // Mobile
    }
  }

  double _getButtonHeight() {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return 60; // Tablette et desktop
    } else {
      return 55; // Mobile
    }
  }

  Future<void> _handleAuth(SimpleAuthService authService) async {
    // Validation basique
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Veuillez remplir tous les champs obligatoires (*)');
      return;
    }

    if (!isLogin && _nameController.text.isEmpty) {
      _showMessage('Veuillez entrer votre nom');
      return;
    }

    if (!isLogin &&
        !widget.isClient &&
        _garageSecretKeyController.text.isEmpty) {
      _showMessage('La clé d\'inscription garage est obligatoire');
      return;
    }

    if (!isLogin && _passwordController.text.length < 6) {
      _showMessage('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      if (isLogin) {
        result = await authService.login(
          _emailController.text.trim(),
          _passwordController.text,
          isClientSpace: widget.isClient,
        );
      } else {
        result = await authService.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          userType: widget.isClient ? UserType.client : UserType.garage,
          garageSecretKey:
              widget.isClient ? null : _garageSecretKeyController.text,
          isClientSpace: widget.isClient,
        );
      }

      setState(() {
        isLoading = false;
      });

      if (result['success'] == true) {
        final appUser = result['user'] as AppUser?;
        _showMessage(
          isLogin ? 'Connexion réussie!' : 'Inscription réussie!',
          isSuccess: true,
        );
        _redirectToHomeScreen(appUser);
      } else {
        _showMessage(result['error']);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showMessage('Une erreur inattendue est survenue: $e');
    }
  }

  void _redirectToHomeScreen(AppUser? user) {
    String userName;
    String userEmail;

    if (user != null) {
      userName = user.name;
      userEmail = user.email;
    } else {
      userName = _nameController.text.isNotEmpty
          ? _nameController.text
          : _emailController.text.split('@')[0];
      userEmail = _emailController.text.trim();
    }

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            isClient: widget.isClient,
            userName: userName,
            userEmail: userEmail,
          ),
        ),
      );
    });
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin:
            EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 20 : 8),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _garageSecretKeyController.dispose();
    super.dispose();
  }
}
