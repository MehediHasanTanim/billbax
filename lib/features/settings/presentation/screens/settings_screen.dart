import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder — settings polish in later phases.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('লগইন'),
            onTap: () => context.push('/login'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('বিলবাক্স'),
            subtitle: Text('v1.0.0 · Phase 0'),
          ),
        ],
      ),
    );
  }
}
