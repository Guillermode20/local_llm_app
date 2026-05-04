import 'dart:io';

import 'package:flutter/material.dart';

/// App settings screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Diagnostics section ---
          Text(
            'Diagnostics',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Device Info'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DeviceDiagnosticScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- About section ---
          Text(
            'About',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Open Source Licenses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Local LLM',
                      applicationVersion: '0.1.0',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Device compatibility information.
class DeviceDiagnosticScreen extends StatelessWidget {
  const DeviceDiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceInfo = <String, String>{
      'OS': Platform.operatingSystem,
      'OS Version': Platform.operatingSystemVersion,
      'Host': Platform.localHostname,
      'Dart Version': Platform.version,
      'Number of Processors': '${Platform.numberOfProcessors}',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Info'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: deviceInfo.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  subtitle: Text(entry.value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
