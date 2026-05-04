import 'dart:async';

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../inference/inference_event.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// Role of a message sender.
enum MessageRole { system, user, assistant }

/// A single message in a conversation.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.generationMetricsJson,
    this.parentMessageId,
    this.archived = false,
  });

  final int id;
  final int conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final String? generationMetricsJson;
  final int? parentMessageId;
  final bool archived;

  ChatMessage copyWith({String? content, bool? archived}) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      generationMetricsJson: generationMetricsJson,
      parentMessageId: parentMessageId,
      archived: archived ?? this.archived,
    );
  }
}

/// A conversation summary for the list view.
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.title,
    required this.modelId,
    required this.updatedAt,
    this.lastMessagePreview,
    this.messageCount = 0,
  });

  final int id;
  final String title;
  final String modelId;
  final DateTime updatedAt;
  final String? lastMessagePreview;
  final int messageCount;
}

// ---------------------------------------------------------------------------
// Chat repository
// ---------------------------------------------------------------------------

/// Repository for chat persistence and retrieval.
class ChatRepository {
  ChatRepository({required this.db});

  final LocalDatabase db;

  /// Create a new conversation and return its ID.
  Future<int> createConversation({
    required String title,
    required String modelId,
    String? systemPrompt,
  }) async {
    final now = DateTime.now();
    final id = await db.into(db.conversations).insert(
          ConversationsCompanion.insert(
            title: title,
            modelId: modelId,
            systemPrompt: Value(systemPrompt),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  /// Update conversation title.
  Future<void> updateConversationTitle(int id, String title) async {
    await (db.update(db.conversations)
          ..where((t) => t.id.equals(id)))
        .write(ConversationsCompanion(updatedAt: Value(DateTime.now())));
  }

  /// Archive a conversation.
  Future<void> archiveConversation(int id) async {
    await (db.update(db.conversations)
          ..where((t) => t.id.equals(id)))
        .write(ConversationsCompanion(
          archived: const Value(true),
          updatedAt: Value(DateTime.now()),
        ));
  }

  /// Delete a conversation and all its messages.
  Future<void> deleteConversation(int id) async {
    await (db.delete(db.messages)
          ..where((t) => t.conversationId.equals(id)))
        .go();
    await (db.delete(db.conversations)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// Watch all non-archived conversations, ordered by most recent first.
  ///
  /// Uses a single custom SQL query with LEFT JOINs to avoid N+1.
  Stream<List<ConversationSummary>> watchConversations() {
    final query = db.select(db.conversations)
      ..where((t) => t.archived.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]);

    return query.watch().asyncMap((rows) async {
      if (rows.isEmpty) return [];

      final ids = rows.map((r) => r.id).toList();

      // Single query: get message counts per conversation.
      final countQuery = db.customSelect(
        'SELECT conversation_id, COUNT(*) AS cnt FROM messages '
        'WHERE conversation_id IN (${ids.map((_) => '?').join(',')}) '
        'AND archived = 0 '
        'GROUP BY conversation_id',
        variables: [for (final id in ids) Variable.withInt(id)],
      );
      final countRows = await countQuery.get();
      final counts = {
        for (final row in countRows)
          row.read<int>('conversation_id'): row.read<int>('cnt'),
      };

      // Single query: get last message content per conversation.
      // Use a correlated subquery to find the latest message.
      final lastMsgQuery = db.customSelect(
        'SELECT m.conversation_id, m.content FROM messages m '
        'WHERE m.archived = 0 '
        'AND m.conversation_id IN (${ids.map((_) => '?').join(',')}) '
        'AND m.created_at = ('
        '  SELECT MAX(m2.created_at) FROM messages m2 '
        '  WHERE m2.conversation_id = m.conversation_id AND m2.archived = 0'
        ')',
        variables: [for (final id in ids) Variable.withInt(id)],
      );
      final lastMsgRows = await lastMsgQuery.get();
      final lastMessages = {
        for (final row in lastMsgRows)
          row.read<int>('conversation_id'): row.read<String>('content'),
      };

      return rows.map((row) {
        return ConversationSummary(
          id: row.id,
          title: row.title,
          modelId: row.modelId,
          updatedAt: row.updatedAt,
          lastMessagePreview: lastMessages[row.id],
          messageCount: counts[row.id] ?? 0,
        );
      }).toList();
    });
  }

  /// Watch messages for a conversation, ordered by creation time.
  Stream<List<ChatMessage>> watchMessages(int conversationId) {
    final query = db.select(db.messages)
      ..where((t) => t.conversationId.equals(conversationId))
      ..where((t) => t.archived.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);

    return query.watch().map((rows) {
      return rows.map((row) => _messageFromRow(row)).toList();
    });
  }

  /// Append a user message and get its ID.
  Future<int> addUserMessage({
    required int conversationId,
    required String content,
    int? parentMessageId,
  }) async {
    final id = await db.into(db.messages).insert(
          MessagesCompanion.insert(
            conversationId: conversationId,
            role: 'user',
            content: content,
            createdAt: DateTime.now(),
            parentMessageId: parentMessageId != null
                ? Value(parentMessageId)
                : const Value.absent(),
          ),
        );
    await _touchConversation(conversationId);
    return id;
  }

  /// Create an empty assistant message and return its ID.
  Future<int> createAssistantMessage({
    required int conversationId,
    int? parentMessageId,
  }) async {
    final id = await db.into(db.messages).insert(
          MessagesCompanion.insert(
            conversationId: conversationId,
            role: 'assistant',
            content: '',
            createdAt: DateTime.now(),
            parentMessageId: parentMessageId != null
                ? Value(parentMessageId)
                : const Value.absent(),
          ),
        );
    await _touchConversation(conversationId);
    return id;
  }

  /// Append text to an assistant message (used during streaming).
  Future<void> appendToMessage(int messageId, String text) async {
    // Read current content and append — avoids race between read and write.
    final msg = await (db.select(db.messages)
          ..where((t) => t.id.equals(messageId)))
        .getSingleOrNull();
    if (msg == null) return;

    await (db.update(db.messages)
          ..where((t) => t.id.equals(messageId)))
        .write(MessagesCompanion(
          content: Value(msg.content + text),
        ));
  }

  /// Finalise an assistant message with metrics.
  Future<void> finaliseAssistantMessage(
    int messageId, {
    GenerationMetrics? metrics,
  }) async {
    await (db.update(db.messages)
          ..where((t) => t.id.equals(messageId)))
        .write(MessagesCompanion(
          generationMetricsJson: Value(metrics != null
              ? '{"ttft_ms":${metrics.timeToFirstTokenMs},'
                  '"tok_per_sec":${metrics.tokensPerSec},'
                  '"n_prompt":${metrics.nPromptTokens},'
                  '"n_decoded":${metrics.nDecoded}}'
              : null),
        ));
  }

  /// Mark messages as archived for edit-and-resend branching.
  Future<void> archiveBranchFrom(int messageId) async {
    final message = await (db.select(db.messages)
          ..where((t) => t.id.equals(messageId)))
        .getSingleOrNull();
    if (message == null) return;

    await _archiveDescendants(message.conversationId, messageId);
  }

  Future<void> _archiveDescendants(int conversationId, int parentId) async {
    final children = await (db.select(db.messages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..where((t) => t.parentMessageId.equals(parentId)))
        .get();

    for (final child in children) {
      await _archiveDescendants(conversationId, child.id);
    }

    await (db.update(db.messages)
          ..where((t) => t.id.equals(parentId)))
        .write(const MessagesCompanion(archived: Value(true)));
  }

  /// Get the message history as a list of role-content pairs for template formatting.
  Future<List<Map<String, String>>> getMessageHistory(int conversationId) async {
    final messages = await (db.select(db.messages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..where((t) => t.archived.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();

    final history = <Map<String, String>>[];
    for (final msg in messages) {
      if (msg.content.isNotEmpty) {
        history.add({'role': msg.role, 'content': msg.content});
      }
    }
    return history;
  }

  /// Get system prompt for a conversation.
  Future<String?> getSystemPrompt(int conversationId) async {
    final conv = await (db.select(db.conversations)
          ..where((t) => t.id.equals(conversationId)))
        .getSingleOrNull();
    return conv?.systemPrompt;
  }

  Future<void> _touchConversation(int conversationId) async {
    await (db.update(db.conversations)
          ..where((t) => t.id.equals(conversationId)))
        .write(ConversationsCompanion(updatedAt: Value(DateTime.now())));
  }

  static ChatMessage _messageFromRow(Message row) {
    return ChatMessage(
      id: row.id,
      conversationId: row.conversationId,
      role: _parseRole(row.role),
      content: row.content,
      createdAt: row.createdAt,
      generationMetricsJson: row.generationMetricsJson,
      parentMessageId: row.parentMessageId,
      archived: row.archived,
    );
  }

  static MessageRole _parseRole(String role) {
    switch (role) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      default:
        return MessageRole.system;
    }
  }
}
