import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthMiddleware {
  static Future<bool> protectGarageRoute(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isUserLoggedIn) {
      _redirectToWelcome(context, 'Veuillez vous connecter');
      return false;
    }

    final hasAccess = await authService.checkGarageAccess();
    if (!hasAccess) {
      _redirectToWelcome(context, 'Accès réservé aux garages');
      return false;
    }

    return true;
  }

  static bool protectClientRoute(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isUserLoggedIn) {
      _redirectToWelcome(context, 'Veuillez vous connecter');
      return false;
    }

    return true;
  }

  static void _redirectToWelcome(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}
