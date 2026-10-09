import 'package:flutter/material.dart';
import '../../../core/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppConstants.routeLogin,
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
