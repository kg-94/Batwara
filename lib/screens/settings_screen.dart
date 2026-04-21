import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About Batwara'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Batwara',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 Batwara Team',
              );
            },
          ),
        ],
      ),
    );
  }
}
