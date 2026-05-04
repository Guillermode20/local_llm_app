import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper screen with links to download Gemma 3n E2B GGUFs from Hugging Face.
class GetModelScreen extends StatelessWidget {
  const GetModelScreen({super.key});

  static const _modelSources = [
    _ModelSource(
      name: 'ggml-org (Official)',
      url: 'https://huggingface.co/ggml-org/gemma-3n-E2B-it-GGUF',
      description: 'Official GGUF conversion from the ggml team.',
      recommended: true,
    ),
    _ModelSource(
      name: 'Unsloth',
      url: 'https://huggingface.co/unsloth/gemma-3n-E2B-it-GGUF',
      description: 'Community conversion with optimised GGUFs.',
      recommended: false,
    ),
    _ModelSource(
      name: 'Bartowski',
      url: 'https://huggingface.co/bartowski/google_gemma-3n-E2B-it-GGUF',
      description: 'Multiple quantisation options including Q4_K_M (recommended for mobile).',
      recommended: true,
    ),
  ];

  static const _recommendedHash =
      'b29adbcff5e0458d8bfa0b26fe6acb2c722f9eaa84890995dfd394d24c236389';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get a Model'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Important',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This app does not bundle any model files. You need to '
                    'download a compatible GGUF file and import it via the '
                    'Model Manager.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recommended quant info
          Text(
            'Recommended: Q4_K_M',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'For mobile devices with 6-8 GB RAM, the Q4_K_M quantisation '
            'provides the best balance of quality and memory usage.\n'
            'SHA-256: $_recommendedHash',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(text: _recommendedHash),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hash copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy hash'),
          ),
          const SizedBox(height: 16),

          // Model sources
          Text(
            'Download Sources',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          ..._modelSources.map((source) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: source.recommended
                      ? Icon(
                          Icons.verified,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : const Icon(Icons.cloud_download),
                  title: Row(
                    children: [
                      Text(source.name),
                      if (source.recommended) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: const Text('Recommended'),
                          labelStyle: const TextStyle(fontSize: 10),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    source.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openUrl(context, source.url),
                ),
              )),

          const SizedBox(height: 16),

          // Terms notice
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'License Information',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gemma 3n E2B weights are under the Gemma Terms of Use. '
                    'By downloading a GGUF file, you agree to those terms.\n\n'
                    'This app does not redistribute model weights; you '
                    'download and import models yourself.\n\n'
                    'llama.cpp (MIT), GGML (MIT), and the OpenCL ICD Loader '
                    '(Apache 2.0) are used under their respective open-source '
                    'licenses.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }
}

class _ModelSource {
  const _ModelSource({
    required this.name,
    required this.url,
    required this.description,
    this.recommended = false,
  });

  final String name;
  final String url;
  final String description;
  final bool recommended;
}
