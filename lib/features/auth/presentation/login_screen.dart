import 'package:flutter/material.dart';
import '../../../core/constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_rounded, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'HealthNest',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Employee Wellbeing Monitoring'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppConstants.routeHome);
                },
                child: const Text('Sign In (Demo)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
