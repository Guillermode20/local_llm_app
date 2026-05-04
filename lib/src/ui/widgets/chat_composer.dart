import 'package:flutter/material.dart';

/// Chat input bar with send/stop button.
///
/// Enter submits on mobile keyboards (via textInputAction: send).
/// On desktop keyboards, use the Send button for multi-line messages.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.isGenerating,
    this.onSend,
    this.onStop,
  });

  final bool isGenerating;
  final void Function(String text)? onSend;
  final VoidCallback? onStop;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend?.call(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: widget.isGenerating
                    ? 'Generating...'
                    : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabled: !widget.isGenerating,
              ),
              onSubmitted:
                  widget.isGenerating ? null : (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            width: 48,
            child: widget.isGenerating
                ? FloatingActionButton.small(
                    onPressed: widget.onStop,
                    backgroundColor: Theme.of(context).colorScheme.error,
                    child: Icon(
                      Icons.stop,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  )
                : FloatingActionButton.small(
                    onPressed: _handleSend,
                    child: const Icon(Icons.arrow_upward),
                  ),
          ),
        ],
      ),
    );
  }
}
