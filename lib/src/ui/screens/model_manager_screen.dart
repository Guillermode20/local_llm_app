import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/model_importer.dart';
import '../../models/model_repository.dart';
import 'get_model_screen.dart';

/// Screen for managing imported GGUF models.
class ModelManagerScreen extends ConsumerWidget {
  const ModelManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(modelListProvider);
    final activeModel = ref.watch(activeModelProvider);
    final importState = ref.watch(modelImportStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(modelListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: importState is ModelImportInProgress
            ? null
            : () => _startImport(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Import Model'),
      ),
      body: _buildBody(context, ref, models, activeModel, importState),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<ModelEntry> models,
    ModelEntry? activeModel,
    ModelImportState importState,
  ) {
    // Show import progress overlay
    if (importState is ModelImportInProgress) {
      return _buildImportProgress(context, importState.progress);
    }

    if (importState is ModelImportFailed) {
      // Show error briefly, then auto-clear on next interaction
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${importState.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(modelImportStateProvider.notifier).state =
            const ModelImportIdle();
      });
    }

    if (models.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.model_training,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No models imported yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Import Model" to add a GGUF file',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GetModelScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Get a Model'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: models.length,
      itemBuilder: (context, index) {
        final model = models[index];
        final isActive = activeModel?.id == model.id;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: _buildQuantBadge(context, model),
            title: Text(
              model.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model.subtitle),
                Text(
                  'Imported ${_formatDate(model.importedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive)
                  Chip(
                    label: const Text('Active'),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 11,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAction(
                    context,
                    ref,
                    value,
                    model,
                  ),
                  itemBuilder: (context) => [
                    if (!isActive)
                      const PopupMenuItem(
                        value: 'set_active',
                        child: Text('Set as active'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            onTap: isActive
                ? null
                : () => _setActiveModel(ref, model.id),
          ),
        );
      },
    );
  }

  Widget _buildQuantBadge(BuildContext context, ModelEntry model) {
    final quant = model.metadata?.prettyQuant ?? '?';
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      child: Text(
        quant.length > 6 ? quant.replaceAll('_', '\n') : quant,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildImportProgress(BuildContext context, ModelImportProgress progress) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              progress.phase,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (progress.totalBytes > 0) ...[
              LinearProgressIndicator(value: progress.fraction),
              const SizedBox(height: 8),
              Text(
                '${_formatSize(progress.bytesCopied)} / ${_formatSize(progress.totalBytes)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startImport(BuildContext context, WidgetRef ref) async {
    final stream = ModelImporter.importModel();
    await for (final state in stream) {
      ref.read(modelImportStateProvider.notifier).state = state;
      if (state is ModelImportComplete) {
        final repo = ref.read(modelRepositoryProvider);
        await repo.addModel(state.result);
        await ref.read(modelListProvider.notifier).refresh();
        ref.read(modelImportStateProvider.notifier).state =
            const ModelImportIdle();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported ${state.result.originalName}')),
          );
        }
      } else if (state is ModelImportFailed) {
        break;
      }
    }
  }

  void _setActiveModel(WidgetRef ref, String id) {
    ref.read(activeModelProvider.notifier).setActive(id);
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    ModelEntry model,
  ) async {
    switch (action) {
      case 'set_active':
        _setActiveModel(ref, model.id);
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete model'),
            content: Text(
              'Delete "${model.displayName}"?\n'
              'This will remove the model file from your device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          final repo = ref.read(modelRepositoryProvider);
          await repo.removeModel(model.id);
          await ref.read(modelListProvider.notifier).refresh();
        }
    }
  }

  static String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  static String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '$bytes B';
  }
}
