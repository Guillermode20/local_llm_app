import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../chat/chat_providers.dart';
import '../../chat/chat_repository.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

/// Main screen showing the conversation list.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local LLM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createConversation(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha(60),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No conversations yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "New Chat" to begin',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.chat,
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer,
                    ),
                  ),
                  title: Text(
                    conv.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (conv.lastMessagePreview != null)
                        Text(
                          conv.lastMessagePreview!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        '${conv.messageCount} msgs · ${_formatDate(conv.updatedAt)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handleConversationAction(
                      context,
                      ref,
                      value,
                      conv,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                  onTap: () {
                    ref
                        .read(activeConversationIdProvider.notifier)
                        .state = conv.id;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversationId: conv.id,
                          title: conv.title,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _createConversation(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(chatRepositoryProvider);
    final id = await repo.createConversation(title: 'New conversation');

    ref.read(activeConversationIdProvider.notifier).state = id;

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: id,
            title: 'New conversation',
          ),
        ),
      );
    }
  }

  void _handleConversationAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    ConversationSummary conv,
  ) async {
    switch (action) {
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete conversation'),
            content: Text('Delete "${conv.title}" and all its messages?'),
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
          final repo = ref.read(chatRepositoryProvider);
          await repo.deleteConversation(conv.id);
        }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(date);
  }
}
