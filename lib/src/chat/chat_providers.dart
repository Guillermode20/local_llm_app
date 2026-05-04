import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import 'chat_repository.dart';

// ---------------------------------------------------------------------------
// Database provider
// ---------------------------------------------------------------------------

/// Singleton provider for the local database.
final databaseProvider = Provider<LocalDatabase>((ref) {
  throw UnimplementedError('Database must be initialised before use');
});

// ---------------------------------------------------------------------------
// Chat repository provider
// ---------------------------------------------------------------------------

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ChatRepository(db: db);
});

// ---------------------------------------------------------------------------
// Conversation list provider
// ---------------------------------------------------------------------------

final conversationListProvider =
    StreamProvider<List<ConversationSummary>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchConversations();
});

// ---------------------------------------------------------------------------
// Active conversation provider
// ---------------------------------------------------------------------------

final activeConversationIdProvider = StateProvider<int?>((ref) => null);

// ---------------------------------------------------------------------------
// Messages provider for a specific conversation
// ---------------------------------------------------------------------------

final conversationMessagesProvider =
    StreamProvider.family<List<ChatMessage>, int>((ref, conversationId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchMessages(conversationId);
});

// ---------------------------------------------------------------------------
// Chat controller provider
// ---------------------------------------------------------------------------

/// State of the chat controller — idle or sending a message.
sealed class ChatControllerState {
  const ChatControllerState();
}

class ChatIdle extends ChatControllerState {
  const ChatIdle();
}

class ChatSending extends ChatControllerState {
  const ChatSending();
}

/// Notifier that handles sending messages (no inference/generation).
final chatControllerProvider =
    NotifierProvider.family<ChatControllerNotifier, ChatControllerState, int>(
  ChatControllerNotifier.new,
);

class ChatControllerNotifier extends FamilyNotifier<ChatControllerState, int> {
  @override
  ChatControllerState build(int arg) {
    return const ChatIdle();
  }

  /// Send a user message and echo back a simple assistant greeting.
  Future<void> sendMessage(String content, {int? parentMessageId}) async {
    final repo = ref.read(chatRepositoryProvider);
    final conversationId = arg;

    state = const ChatSending();

    try {
      // 1. Insert user message.
      await repo.addUserMessage(
        conversationId: conversationId,
        content: content,
        parentMessageId: parentMessageId,
      );

      // 2. Insert a simple assistant placeholder.
      await repo.createAssistantMessage(
        conversationId: conversationId,
        content: '',
        parentMessageId: parentMessageId,
      );

      // 3. Auto-title from first user message.
      await _maybeAutoTitle(repo, conversationId);
    } finally {
      state = const ChatIdle();
    }
  }

  /// Edit a user message and resend.
  Future<void> editAndResend(int messageId, String newContent) async {
    final repo = ref.read(chatRepositoryProvider);

    // Archive from this message onward.
    await repo.archiveBranchFrom(messageId);

    // Send the edited message.
    await sendMessage(newContent, parentMessageId: messageId);
  }

  /// Auto-title the conversation from its first user message.
  Future<void> _maybeAutoTitle(ChatRepository repo, int conversationId) async {
    try {
      final messages = await repo.watchMessages(conversationId).first;
      final firstUser =
          messages.where((m) => m.role == MessageRole.user).firstOrNull;
      if (firstUser == null) return;

      final content = firstUser.content.trim();
      if (content.isEmpty) return;

      final title = content
          .replaceAll(RegExp(r'\s+'), ' ')
          .substring(0, content.length > 60 ? 60 : content.length)
          .trim();

      await repo.updateConversationTitle(conversationId, title);
    } catch (_) {
      // Non-critical — ignore failures.
    }
  }
}
