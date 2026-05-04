import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inference/inference_config.dart';
import '../../models/model_repository.dart';

/// App settings screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeModel = ref.watch(activeModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Model section ---
          Text(
            'Model',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.model_training),
              title: const Text('Active Model'),
              subtitle: Text(activeModel?.displayName ?? 'None selected'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _ModelSettingsSheet(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // --- Backend section ---
          Text(
            'Backend',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.memory),
                  title: const Text('GPU Backend'),
                  subtitle: const Text('Auto (probe at runtime)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Backend override picker
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Thread Count'),
                  subtitle: Text(
                    '${InferenceConfig.defaults.nThreads} threads',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Thread count picker
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
                  title: const Text('Device Compatibility'),
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.speed),
                  title: const Text('Run Benchmark'),
                  subtitle: const Text(
                    'Measure prompt processing & generation speed',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Run benchmark
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Benchmark requires an active model'),
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

/// Simple model settings sheet.
class _ModelSettingsSheet extends StatelessWidget {
  const _ModelSettingsSheet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Settings'),
      ),
      body: const Center(
        child: Text('Model settings coming soon...'),
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
        title: const Text('Device Compatibility'),
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
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GPU Backend Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'GPU backend probing is performed at app startup.\n'
                    'Results are cached per device.',
                  ),
                  const SizedBox(height: 12),
                  // TODO: Display GPU probe results from BackendProbe
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
