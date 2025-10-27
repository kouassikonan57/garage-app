import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simple_auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  // Méthodes responsive
  double _getResponsiveWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return 500;
    } else {
      return double.infinity;
    }
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return const EdgeInsets.symmetric(horizontal: 50, vertical: 40);
    } else {
      return const EdgeInsets.all(20.0);
    }
  }

  double _getIconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return 100;
    } else {
      return 80;
    }
  }

  double _getResponsiveFontSize() {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return 16;
    } else {
      return 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                  // Icône responsive
                  Icon(
                    Icons.lock_reset,
                    size: _getIconSize(context),
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),

                  // Titre responsive
                  Text(
                    'Réinitialiser votre mot de passe',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Description responsive
                  Text(
                    'Entrez votre email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Contenu conditionnel
                  if (!_emailSent)
                    _buildResetForm()
                  else
                    _buildSuccessMessage(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email),
            border: const OutlineInputBorder(),
            hintText: 'votre@email.com',
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SizedBox(
                width: double.infinity,
                height: _getButtonHeight(),
                child: ElevatedButton(
                  onPressed: _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Envoyer le lien de réinitialisation',
                    style: TextStyle(fontSize: _getResponsiveFontSize()),
                  ),
                ),
              ),
        const SizedBox(height: 20),
        _buildBackButton(),
      ],
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle,
                  color: Colors.green, size: _getIconSize(context) * 0.6),
              const SizedBox(height: 16),
              Text(
                'Email envoyé avec succès !',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize() + 2,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Nous avons envoyé un lien de réinitialisation à ${_emailController.text}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: _getResponsiveFontSize()),
              ),
              const SizedBox(height: 16),
              Text(
                'Vérifiez votre boîte de réception et suivez les instructions dans l\'email.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize() - 2,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return MediaQuery.of(context).size.width > 600
        ? Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _emailSent = false;
                      _emailController.clear();
                    });
                  },
                  child: Text('Envoyer à un autre email'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Retour à la connexion'),
                ),
              ),
            ],
          )
        : Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _emailSent = false;
                      _emailController.clear();
                    });
                  },
                  child: Text('Envoyer à un autre email'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Retour à la connexion'),
                ),
              ),
            ],
          );
  }

  Widget _buildBackButton() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Retour à la connexion',
          style: TextStyle(
            color: Colors.blue,
            fontSize: _getResponsiveFontSize(),
          ),
        ),
      ),
    );
  }

  double _getButtonHeight() {
    final width = MediaQuery.of(context).size.width;
    return width > 600 ? 60 : 50;
  }

  void _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showMessage('Veuillez entrer votre email');
      return;
    }

    if (!_emailController.text.contains('@')) {
      _showMessage('Email invalide');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService =
          Provider.of<SimpleAuthService>(context, listen: false);
      final result =
          await authService.resetPassword(_emailController.text.trim());

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        setState(() {
          _emailSent = true;
        });
        _showMessage(result['message'], isSuccess: true);
      } else {
        _showMessage(result['error']);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Erreur lors de la réinitialisation: $e');
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: _getResponsiveFontSize()),
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
    super.dispose();
  }
}
