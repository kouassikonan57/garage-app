import 'package:flutter/material.dart';
import 'auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Icon(Icons.car_repair, size: 100, color: Colors.orange),

              SizedBox(height: 20),

              Text(
                'Garage Auto CI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),

              SizedBox(height: 10),

              // AJOUT : Message d'information
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Espace client pour prendre rendez-vous\nEspace garage réservé aux professionnels',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              SizedBox(height: 40),

              // Bouton Client
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuthScreen(isClient: true),
                      ),
                    );
                  },
                  child: Text(
                    'JE SUIS CLIENT',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Bouton Garage
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuthScreen(isClient: false),
                      ),
                    );
                  },
                  child: Text(
                    'JE SUIS LE GARAGE',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // AJOUT : Information sur l'inscription garage
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'L\'inscription garage nécessite une clé d\'accès',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
