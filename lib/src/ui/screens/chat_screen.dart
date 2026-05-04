import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/chat_providers.dart';
import '../../chat/chat_repository.dart';
import '../widgets/chat_composer.dart';
import '../widgets/message_bubble.dart';

/// Main chat screen showing messages for a conversation.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  final int conversationId;
  final String title;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  Timer? _scrollDebounce;
  bool _scrollListenerSetup = false;

  bool _isGenerating = false;

  /// Whether the user has scrolled away from the bottom.
  bool _userScrolledAway = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollDebounce?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_userScrolledAway) return;

    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 50), () {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      // Only auto-scroll if user is near the bottom (within 50px).
      if (position.pixels >= position.maxScrollExtent - 50 || _isGenerating) {
        _scrollController.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final atBottom = position.pixels >= position.maxScrollExtent - 50;
    _userScrolledAway = !atBottom && !_isGenerating;
  }

  Future<void> _handleSend(String text) async {
    setState(() => _isGenerating = true);
    _userScrolledAway = false;
    try {
      await ref
          .read(chatControllerProvider(widget.conversationId).notifier)
          .sendMessage(text);
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _handleStop() {
    ref
        .read(chatControllerProvider(widget.conversationId).notifier)
        .cancelGeneration();
    setState(() => _isGenerating = false);
  }

  void _handleRegenerate(int messageId) {
    ref
        .read(chatControllerProvider(widget.conversationId).notifier)
        .regenerate(messageId);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(conversationMessagesProvider(widget.conversationId));
    final controllerState =
        ref.watch(chatControllerProvider(widget.conversationId));

    // Track generating state from controller
    if (controllerState is ChatGenerating) {
      _isGenerating = true;
    } else {
      _isGenerating = false;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Conversation settings',
            onPressed: _showSettingsSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                // Auto-scroll on new messages (debounced).
                if (messages.isNotEmpty) {
                  _scrollToBottom();
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withAlpha(80),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Type a message below to begin',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                // Track whether user scrolled away from bottom.
                if (!_scrollListenerSetup) {
                  _scrollListenerSetup = true;
                  _scrollController.addListener(_onScroll);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isLast = index == messages.length - 1;

                    return MessageBubble(
                      message: msg,
                      isGenerating:
                          isLast && _isGenerating && msg.role == MessageRole.assistant,
                      onRegenerate:
                          msg.role == MessageRole.assistant && !_isGenerating
                              ? () => _handleRegenerate(msg.id)
                              : null,
                      onEdit: msg.role == MessageRole.user
                          ? () => _editMessage(msg)
                          : null,
                      onDeleteFromHere: () => _deleteFromHere(msg),
                      onCopy: () {
                        // onCopy with the default behaviour — can be overridden.
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error: $err'),
              ),
            ),
          ),
          // Composer
          ChatComposer(
            isGenerating: _isGenerating,
            onSend: _handleSend,
            onStop: _handleStop,
          ),
        ],
      ),
    );
  }

  void _editMessage(ChatMessage msg) {
    final controller = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Edit your message...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(chatControllerProvider(widget.conversationId).notifier)
                  .editAndResend(msg.id, controller.text.trim());
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _deleteFromHere(ChatMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete from here?'),
        content: const Text(
          'This will delete this message and all replies after it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(chatRepositoryProvider).archiveBranchFrom(msg.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversation Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('Settings coming soon...'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
