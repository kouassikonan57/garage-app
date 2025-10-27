import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.orange[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.car_repair, size: 100, color: Colors.orange),
              SizedBox(height: 20),
              Text(
                'Garage Auto CI',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {},
                child: Text('JE SUIS CLIENT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
