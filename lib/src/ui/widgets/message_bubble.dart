import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

import '../../chat/chat_repository.dart';
import '../../inference/inference_event.dart';

/// A single message bubble in the chat.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.isGenerating = false,
    this.generationMetrics,
    this.onRegenerate,
    this.onEdit,
    this.onCopy,
    this.onDeleteFromHere,
  });

  final ChatMessage message;
  final bool isGenerating;
  final GenerationMetrics? generationMetrics;
  final VoidCallback? onRegenerate;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;
  final VoidCallback? onDeleteFromHere;

  bool get isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Role label
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
            child: Text(
              isUser ? 'You' : 'Assistant',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          // Bubble
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) _buildAvatar(context),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context).size.width * (isUser ? 0.78 : 0.72),
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Content (markdown for assistant, plain for user)
                      if (isUser)
                        SelectableText(
                          message.content,
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        _buildAssistantContent(context),
                      // Timestamp
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat.Hm().format(message.createdAt),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            if (isGenerating) ...[
                              const SizedBox(width: 4),
                              _buildTypingIndicator(context),
                            ],
                            if (generationMetrics != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${generationMetrics!.tokensPerSec.toStringAsFixed(1)} tok/s',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
              if (isUser) _buildAvatar(context),
            ],
          ),
          // Action buttons
          if (!isGenerating && message.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionChip(
                    context,
                    Icons.copy,
                    'Copy',
                    onCopy ?? () {
                      Clipboard.setData(ClipboardData(text: message.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  if (!isUser) ...[
                    const SizedBox(width: 4),
                    _buildActionChip(
                      context,
                      Icons.refresh,
                      'Regenerate',
                      onRegenerate,
                    ),
                  ],
                  if (isUser) ...[
                    const SizedBox(width: 4),
                    _buildActionChip(
                      context,
                      Icons.edit,
                      'Edit',
                      onEdit,
                    ),
                  ],
                  const SizedBox(width: 4),
                  _buildActionChip(
                    context,
                    Icons.delete_outline,
                    'Delete',
                    onDeleteFromHere,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: isUser
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 16,
        color: isUser
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSecondary,
      ),
    );
  }

  Widget _buildAssistantContent(BuildContext context) {
    if (message.content.isEmpty && isGenerating) {
      return const SizedBox(
        height: 20,
        child: Text('...'),
      );
    }
    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: Theme.of(context).textTheme.bodyMedium,
        code: TextStyle(
          backgroundColor: Theme.of(context).colorScheme.surfaceDim,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        codeblockDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceDim,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(context),
        const SizedBox(width: 3),
        _dot(context),
        const SizedBox(width: 3),
        _dot(context),
      ],
    );
  }

  Widget _dot(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildActionChip(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
